/** T09-A: bundled native compile/runtime and real model editor Play/rollback. */
import * as fs from 'node:fs';import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,copyTree,indexProject,runCommand,listGDScripts,gitHead,gitDirty,writeJSON} from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){const box=newSandbox(selection),out=path.join(options.output,selection.label);fs.mkdirSync(out,{recursive:true});const stages:Record<string,any>={};
try{
 for(const dir of ['addons/estragon','examples/bindable','tests/bindable'])copyTree(path.join(ROOT,dir),path.join(box.project,dir));
 fs.writeFileSync(path.join(box.project,'gogo.config.json'),JSON.stringify({version:1,source_roots:['examples/bindable']}));
 fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="T09-A models"\nrun/main_scene="res://examples/bindable/Demo.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
 writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
 async function run(name:string,args:string[],marker:string,negative=false){
  const log=path.join(out,name+'.log');const stage=await runCommand([box.binary,'--headless','--audio-driver','Dummy','--path',box.project,...args],box.workspace,box.env,log,marker,{abortOnError:!negative,expectedErrors:negative,timeout:negative?240000:60000});const text=fs.readFileSync(log,'utf8');process.stdout.write(text);
  if(negative){
   const lines=text.split(/\r?\n/);const errors=lines.filter((l,i)=>{
    if(!/SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed:/.test(l))return false;
    if(l==='ERROR: An EditorPlugin build callback failed.'||l==='ERROR: Cannot save text file \'res://examples/bindable/Model.gogo\'.')return false;
    if(/^SCRIPT ERROR: Parse Error:/.test(l)&&/res:\/\/examples\/bindable\/generated\/Model\.gd:\d+\)/.test(lines[i+1]||'')&&/(Cannot assign|Invalid operands|Cannot find|Invalid argument|Cannot convert|Cannot pass)/.test(l))return false;
    if(/^examples\/bindable\/Model\.gogo:\d+:\d+: Parse Error:/.test(l)&&/(Cannot assign|Invalid operands|Cannot find|Invalid argument|Cannot convert|Cannot pass)/.test(l))return false;
    return true;
   });stage.unexpected_errors=errors;if(errors.length||/BINDABLE_EDITOR_CHECK .*: false/.test(text)||!text.includes('BINDABLE_EDITOR_CHECK'))stage.status='FAIL';
  }
  if(/instances leaked|Resources still in use/.test(text))stage.status='FAIL';stages[name]=stage;writeJSON(path.join(out,'results.json'),stages);if(stage.status!=='PASS')throw Error('Bindable '+name+' failed');
 }
 await run('build',['--script','res://tests/bindable/build.gd'],'BINDABLE_BUILD_OK');
 copyTree(path.join(box.project,'examples/bindable/generated'),path.join(out,'generated'));
 stages.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);if(stages.import.status!=='PASS')throw Error('Bindable indexing failed');
 for(const dir of ['addons/estragon','examples/bindable','tests/bindable'])for(const file of listGDScripts(path.join(box.project,dir))){if(fs.existsSync(file+'.uid')){const target=path.join(out,'canonical-uids',path.relative(box.project,file)+'.uid');fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(file+'.uid',target);}}
 await run('runtime',['--script','res://tests/bindable/runtime.gd'],'BINDABLE_RUNTIME_OK');
 fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/bindable/editor/plugin.cfg")\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
 box.env.ESTRAGON_BINDABLE_PROOF='1';await run('editor',['--editor'],'BINDABLE_EDITOR_OK',true);delete box.env.ESTRAGON_BINDABLE_PROOF;
}finally{writeJSON(path.join(out,'results.json'),stages);box.dispose();}
}
