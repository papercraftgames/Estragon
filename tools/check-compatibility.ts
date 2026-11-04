/** Current addon frontend and actual-path publication/cache acceptance. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,copyTree,indexProject,runCommand,engineRecord,writeJSON,reportMetadata,gitHead,gitDirty} from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));fs.mkdirSync(options.output,{recursive:true});const engines=[];
for(const selection of options.engines){
 const sandbox=newSandbox(selection),output=path.join(options.output,selection.label);fs.mkdirSync(output,{recursive:true});
 const record=engineRecord(selection,sandbox);engines.push(record);
 try{
  copyTree(path.join(ROOT,'addons'),path.join(sandbox.project,'addons'));
  copyTree(path.join(ROOT,'tests/native_compiler'),path.join(sandbox.project,'tests/native_compiler'));
  fs.writeFileSync(path.join(sandbox.project,'project.godot'),'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  fs.mkdirSync(path.join(sandbox.project,'ui/generated'),{recursive:true});
  fs.writeFileSync(path.join(sandbox.project,'ui/generated/Registered.gd'),'class_name EstragonPublicationProbe\nextends RefCounted\nvar state: int = 1\nfunc value() -> int: return 1\n');
  writeJSON(path.join(output,"provenance.json"),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:sandbox.version,original_binary_sha256:sandbox.inputHash});
  record.stages.import=await indexProject(sandbox,sandbox.project,path.join(output,'import.log'),['--audio-driver','Dummy']);
  if(record.stages.import.status!=='PASS')throw Error('Compiler import failed');
  for(const name of ['frontend','publication']){const uid=path.join(sandbox.project,'tests/native_compiler',name+'.gd.uid');if(fs.existsSync(uid))fs.copyFileSync(uid,path.join(output,name+'.gd.uid'));}
  for(const name of ['frontend','registered','positive','rollback','fresh_failure']){
   const candidate=path.join(sandbox.workspace,name);fs.cpSync(sandbox.project,candidate,{recursive:true});
   const expected=name==='rollback'||name==='fresh_failure';const log=path.join(output,name+'.log');
   const args=name==='frontend'?['res://tests/native_compiler/frontend.gd']:['res://tests/native_compiler/publication.gd','--',name];
   const stage=await runCommand([sandbox.binary,'--headless','--audio-driver','Dummy','--path',candidate,'--script',...args],sandbox.workspace,sandbox.env,log,name==='frontend'?'NATIVE_FRONTEND_OK':'ESTRAGON_NATIVE_PUBLICATION_OK',{expectedErrors:expected,abortOnError:!expected});
   const text=fs.readFileSync(log,'utf8');process.stdout.write(text);
   if(expected){const errors=text.split(/\r?\n/).filter(l=>/SCRIPT ERROR:|^ERROR:/.test(l));const match=name==='rollback'?'return type is "int"':'missing_publication_value';if(errors.length!==1||!errors[0]!.includes(match))stage.status='FAIL';}
   if(/instances leaked|Resources still in use/.test(text))stage.status='FAIL';
   record.stages[name]=stage;writeJSON(path.join(output,'results.json'),record.stages);
   if(stage.status!=='PASS')throw Error('Native compiler '+name+' failed');
  }
 }finally{writeJSON(path.join(options.output,'results.json'),{...reportMetadata(),engines});sandbox.dispose();}
}
