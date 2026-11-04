/** C1 native bounds, lifetime, real editor persistence and graphics proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, runCommand, sourceHashes, listGDScripts, gitHead, gitDirty, writeJSON, indexProject } from './compat-kit.ts';
const argv=process.argv.slice(2), runtimeOnly=argv.includes('--runtime-only');
const options=parseCLI(argv.filter(arg=>arg!=='--runtime-only'),{graphics:true});
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
 const sandbox=newSandbox(selection), output=path.join(options.output,selection.label);
 fs.mkdirSync(output,{recursive:true});
 // Godot's self-contained mode isolates macOS editor settings as well as XDG.
 fs.writeFileSync(path.join(sandbox.workspace,'_sc_'),'');
 try {
  for(const dir of ['addons/estragon/runtime/node','examples/node_runtime','tests/node_runtime']) copyTree(path.join(ROOT,dir),path.join(sandbox.project,dir));
  const settings='config_version=5\n[application]\nconfig/name="C1 isolated proof"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
  fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
  const sources=['addons/estragon/runtime/node','examples/node_runtime','tests/node_runtime'].flatMap(dir=>listGDScripts(path.join(ROOT,dir))).map(p=>path.relative(ROOT,p)).concat(['tools/check-node-runtime.ts','tools/compat-kit.ts']);
  const stages:Record<string,unknown>={};
  writeJSON(path.join(output,'provenance.json'),{version:sandbox.version,original_binary_sha256:sandbox.inputHash,sourceHead:gitHead(),sourceDirty:gitDirty(),sourceHashes:sourceHashes(sources),command:process.argv});
  async function run(name:string,args:string[],marker:string,graphics=true) {
   const stage=await runCommand([sandbox.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',sandbox.project,...args],sandbox.workspace,sandbox.env,path.join(output,name+'.log'),marker,{abortOnError:true});
   const log=fs.readFileSync(path.join(output,name+'.log'),'utf8');
   if(/ObjectDB instances leaked|Resources still in use/.test(log)) {stage.status='FAIL';stage.reason='Native resource leak';}
   stages[name]=stage;
   process.stdout.write(log);
   writeJSON(path.join(output,'results.json'),stages);
   if(stage.status!=='PASS')throw Error('C1 '+name+' failed');
  }
  await run('core',['--script','res://tests/node_runtime/core.gd'],'GGX_B2_CORE_OK',false);
  await run('runtime',['--script','res://tests/node_runtime/runtime.gd'],'GGX_C1_RUNTIME_OK');
  if(!runtimeOnly) {
   stages.import=await indexProject(sandbox,sandbox.project,path.join(output,'import.log'),['--audio-driver','Dummy']);
   if((stages.import as {status:string}).status!=='PASS')throw Error('C1 indexing failed');
   fs.appendFileSync(path.join(sandbox.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://tests/node_runtime/editor/plugin.cfg")\n');
   for(const pass of [1,2]) await run('editor-'+pass,['--editor'],'GGX_C1_EDITOR_OK');
   fs.writeFileSync(path.join(sandbox.project,'project.godot'),settings);
   if(options.graphics) {
    await run('visual',['--script','res://tests/node_runtime/visual.gd'],'GGX_C1_VISUAL_OK');
    for(const name of fs.readdirSync(sandbox.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(sandbox.project,name),path.join(output,name));
   }
   for(const dimension of [2,3])fs.copyFileSync(path.join(sandbox.project,`tests/node_runtime/Persisted${dimension}.tscn`),path.join(output,`Persisted${dimension}.tscn.txt`));
  }
  console.log('GGX_C1_PASS '+sandbox.version);
 } finally {sandbox.dispose();}
}
