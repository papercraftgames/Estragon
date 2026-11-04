/** C3 normal native build/editor/runtime, with no external end-user toolchain. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, runCommand, sourceHashes, listGDScripts, gitHead, gitDirty, writeJSON, indexProject } from './compat-kit.ts';
const argv=process.argv.slice(2), buildOnly=argv.includes('--build-only'), runtimeOnly=argv.includes('--runtime-only');
function unexpectedErrors(log:string):string[] {
 const lines=log.split(/\r?\n/);
 return lines.filter((line,i)=>{
  if(!/SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|Assertion failed:/.test(line))return false;
  if(/^SCRIPT ERROR: Parse Error: (Identifier "missing_handler" not declared|Cannot pass a value of type "String" as "float"\.|Invalid argument for "_gogo_build_0\(\)" function: argument 5 should be "float" but is "String"\.)/.test(line)&&/at: GDScript::reload \(res:\/\/examples\/counter\/generated\/(Counter)\.gd:\d+\)/.test(lines[i+1]||''))return false;
  if(/^examples\/counter\/(Counter)\.gogo:\d+:\d+: Parse Error: (Identifier "missing_handler" not declared|Cannot pass a value of type "String" as "float"\.|Invalid argument for "_gogo_build_0\(\)" function: argument 5 should be "float" but is "String"\.)/.test(line))return false;
  return line!=='ERROR: An EditorPlugin build callback failed.'&&!/^ERROR: Cannot save text file 'res:\/\/examples\/counter\/(Counter)\.gogo'\.$/.test(line);
 });
}
const options=parseCLI(argv.filter(a=>a!=='--build-only'&&a!=='--runtime-only'),{graphics:true});
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
 const sandbox=newSandbox(selection), output=path.join(options.output,selection.label);
 fs.mkdirSync(output,{recursive:true});
 fs.writeFileSync(path.join(sandbox.workspace,'_sc_'),'');
 try {
  for(const dir of ['addons/estragon','examples/counter','tests/native_ui'])copyTree(path.join(ROOT,dir),path.join(sandbox.project,dir));
  fs.writeFileSync(path.join(sandbox.project,'gogo.config.json'),JSON.stringify({version:1,source_roots:['examples/counter']}));
  const settings='config_version=5\n[application]\nconfig/name="C3 isolated GGX"\nrun/main_scene="res://examples/counter/Counter.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
  fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
  const sources=['addons/estragon/compiler','addons/estragon/editor','addons/estragon/runtime/node','examples/counter','tests/native_ui'].flatMap(dir=>listGDScripts(path.join(ROOT,dir))).map(p=>path.relative(ROOT,p)).concat(['examples/counter/Counter.gogo','examples/counter/Counter.tscn','addons/estragon/compiler/diagnostic_capture.gd.txt','gogo.config.json','tools/check-native-ui.ts','tools/compat-kit.ts']);
  const stages:Record<string,unknown>={};
  writeJSON(path.join(output,'provenance.json'),{version:sandbox.version,original_binary_sha256:sandbox.inputHash,sourceHead:gitHead(),sourceDirty:gitDirty(),sourceHashes:sourceHashes(sources),command:process.argv});
  async function run(name:string,args:string[],marker:string,graphics=false,expectedErrors=false) {
   const stage=await runCommand([sandbox.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',sandbox.project,...args],sandbox.workspace,sandbox.env,path.join(output,name+'.log'),marker,{abortOnError:!expectedErrors,expectedErrors,timeout:expectedErrors?240000:60000});
   const log=fs.readFileSync(path.join(output,name+'.log'),'utf8');
   if(/ObjectDB instances leaked|Resources still in use/.test(log)){stage.status='FAIL';stage.reason='Native resource leak';}
   if(expectedErrors) {
    const errors=unexpectedErrors(log);
    stage.unexpected_errors=errors;
    if(errors.length||/C3_EDITOR_CHECK .*: false/.test(log)||!log.includes('C3_EDITOR_CHECK')){stage.status='FAIL';stage.reason='Unexpected errors or failed editor assertions';}
   }
   stages[name]=stage;process.stdout.write(log);writeJSON(path.join(output,'results.json'),stages);
   if(stage.status!=='PASS')throw Error('C3 '+name+' failed');
  }
  await run('build',['--script','res://tests/native_ui/build.gd'],'C3_BUILD_OK');
  copyTree(path.join(sandbox.project,'examples/counter/generated'),path.join(output,'generated'));
  if(!buildOnly) {
   stages.import=await indexProject(sandbox,sandbox.project,path.join(output,'import.log'),['--audio-driver','Dummy']);
   if((stages.import as {status:string}).status!=='PASS')throw Error('C3 import failed');
   // Preserve canonical script UID candidates from native editor import only;
   // never export the temporary indexing driver or arbitrary sandbox copies.
   for(const file of sources.filter(p=>p.endsWith('.gd')).concat(['examples/counter/generated/Counter.gd'])) {
    const sidecar=path.join(sandbox.project,file+'.uid');
    if(fs.existsSync(sidecar)) {
     const target=path.join(output,'canonical-uids',file+'.uid');
     fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(sidecar,target);
    }
   }
   await run('runtime',['--script','res://tests/native_ui/runtime.gd'],'C3_RUNTIME_OK',true);
   if(!runtimeOnly) {
   fs.appendFileSync(path.join(sandbox.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/native_ui/editor/plugin.cfg")\n');
   // Match the established C01 Play harness: real editor APIs and actual
   // child games, with no host audio device or embedded X11 game window.
   // Runtime and visual stages above/below still use the native renderer.
   fs.appendFileSync(path.join(sandbox.project,'project.godot'),'\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
   sandbox.env.ESTRAGON_C3_PROOF='1';
   await run('editor',['--editor'],'C3_EDITOR_OK',false,true);
   delete sandbox.env.ESTRAGON_C3_PROOF;
   }
   fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
   if(options.graphics) {
    await run('visual',['--script','res://tests/native_ui/visual.gd'],'C3_VISUAL_OK',true);
    for(const name of fs.readdirSync(sandbox.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(sandbox.project,name),path.join(output,name));
   }
  }
  console.log('C3_PASS '+sandbox.version);
 } finally {sandbox.dispose();}
}
