/** C2 normal native build/editor/runtime, with no external end-user toolchain. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, runCommand, sourceHashes, listGDScripts, gitHead, gitDirty, writeJSON, indexProject } from './compat-kit.ts';
const argv=process.argv.slice(2), buildOnly=argv.includes('--build-only');
function unexpectedErrors(log:string):string[] {
 const lines=log.split(/\r?\n/);
 return lines.filter((line,i)=>{
  if(!/SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|Assertion failed:/.test(line))return false;
  if(/^SCRIPT ERROR: Parse Error: (Identifier "missing_handler" not declared|Cannot pass a value of type "String" as "float"\.|Invalid argument for "_gogo_build_0\(\)" function: argument 2 should be "float" but is "String"\.)/.test(line)&&/at: GDScript::reload \(res:\/\/examples\/ggx\/generated\/(TwoD|ThreeD)\.gd:\d+\)/.test(lines[i+1]||''))return false;
  if(/^examples\/ggx\/(TwoD|ThreeD)\.gogo:\d+:\d+: Parse Error: (Identifier "missing_handler" not declared|Cannot pass a value of type "String" as "float"\.|Invalid argument for "_gogo_build_0\(\)" function: argument 2 should be "float" but is "String"\.)/.test(line))return false;
  return line!=='ERROR: An EditorPlugin build callback failed.'&&!/^ERROR: Cannot save text file 'res:\/\/examples\/ggx\/(TwoD|ThreeD)\.gogo'\.$/.test(line);
 });
}
const options=parseCLI(argv.filter(a=>a!=='--build-only'),{graphics:true});
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
 const sandbox=newSandbox(selection), output=path.join(options.output,selection.label);
 fs.mkdirSync(output,{recursive:true});
 fs.writeFileSync(path.join(sandbox.workspace,'_sc_'),'');
 try {
  for(const dir of ['addons/estragon','examples/ggx','tests/ggx'])copyTree(path.join(ROOT,dir),path.join(sandbox.project,dir));
  fs.writeFileSync(path.join(sandbox.project,'gogo.config.json'),JSON.stringify({version:1,source_roots:['examples/ggx']}));
  const settings='config_version=5\n[application]\nconfig/name="C2 isolated GGX"\nrun/main_scene="res://examples/ggx/TwoD.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
  fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
  const sources=['addons/estragon/compiler','addons/estragon/editor','addons/estragon/runtime/node','examples/ggx','tests/ggx'].flatMap(dir=>listGDScripts(path.join(ROOT,dir))).map(p=>path.relative(ROOT,p)).concat(['examples/ggx/TwoD.gogo','examples/ggx/ThreeD.gogo','examples/ggx/TwoD.tscn','examples/ggx/ThreeD.tscn','addons/estragon/compiler/diagnostic_capture.gd.txt','gogo.config.json','tools/check-ggx.ts','tools/compat-kit.ts']);
  const stages:Record<string,unknown>={};
  writeJSON(path.join(output,'provenance.json'),{version:sandbox.version,original_binary_sha256:sandbox.inputHash,sourceHead:gitHead(),sourceDirty:gitDirty(),sourceHashes:sourceHashes(sources),command:process.argv});
  async function run(name:string,args:string[],marker:string,graphics=false,expectedErrors=false) {
   const stage=await runCommand([sandbox.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',sandbox.project,...args],sandbox.workspace,sandbox.env,path.join(output,name+'.log'),marker,{abortOnError:!expectedErrors,expectedErrors,timeout:expectedErrors?240000:60000});
   const log=fs.readFileSync(path.join(output,name+'.log'),'utf8');
   if(/ObjectDB instances leaked|Resources still in use/.test(log)){stage.status='FAIL';stage.reason='Native resource leak';}
   if(expectedErrors) {
    const errors=unexpectedErrors(log);
    stage.unexpected_errors=errors;
    if(errors.length||/C2_EDITOR_CHECK .*: false/.test(log)||!log.includes('C2_EDITOR_CHECK')){stage.status='FAIL';stage.reason='Unexpected errors or failed editor assertions';}
   }
   stages[name]=stage;process.stdout.write(log);writeJSON(path.join(output,'results.json'),stages);
   if(stage.status!=='PASS')throw Error('C2 '+name+' failed');
  }
  await run('build',['--script','res://tests/ggx/build.gd'],'GGX_C2_BUILD_OK');
  copyTree(path.join(sandbox.project,'examples/ggx/generated'),path.join(output,'generated'));
  if(!buildOnly) {
   stages.import=await indexProject(sandbox,sandbox.project,path.join(output,'import.log'),['--audio-driver','Dummy']);
   if((stages.import as {status:string}).status!=='PASS')throw Error('C2 import failed');
   await run('runtime',['--script','res://tests/ggx/runtime.gd'],'GGX_C2_RUNTIME_OK',true);
   fs.appendFileSync(path.join(sandbox.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/ggx/editor/plugin.cfg")\n');
   // Match the established C01 Play harness: real editor APIs and actual
   // child games, with no host audio device or embedded X11 game window.
   // Runtime and visual stages above/below still use the native renderer.
   fs.appendFileSync(path.join(sandbox.project,'project.godot'),'\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
   sandbox.env.ESTRAGON_C2_PROOF='1';
   await run('editor',['--editor'],'GGX_C2_EDITOR_OK',false,true);
   delete sandbox.env.ESTRAGON_C2_PROOF;
   fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
   if(options.graphics) {
    await run('visual',['--script','res://tests/ggx/visual.gd'],'GGX_C2_VISUAL_OK',true);
    for(const name of fs.readdirSync(sandbox.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(sandbox.project,name),path.join(output,name));
   }
  }
  console.log('GGX_C2_PASS '+sandbox.version);
 } finally {sandbox.dispose();}
}
