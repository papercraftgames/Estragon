/** E11 stock-editor lazy-gutter repro and normal-tab activation control.
 * No Estragon payload is copied into this project. Expected upstream diagnostics
 * are confined to one explicit bracket; every other native error fails closed.
 */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,copyTree,runCommand,writeJSON,gitHead,gitDirty,ERROR} from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));
if(process.platform!=='linux')throw Error('Only approved Linux engines');
fs.mkdirSync(options.output,{recursive:true});
for(const engine of options.engines){
 const box=newSandbox(engine),out=path.join(options.output,engine.label);fs.mkdirSync(out,{recursive:true});
 try{
  copyTree(path.join(ROOT,'tests/editor_gutters'),path.join(box.project,'tests/editor_gutters'));
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="E11 stock editor"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n[editor_plugins]\nenabled=PackedStringArray("res://tests/editor_gutters/plugin.cfg")\n');
  const log=path.join(out,'upstream.log');
  const result=await runCommand([box.binary,'--audio-driver','Dummy','--rendering-method','gl_compatibility','--path',box.project,'--editor'],box.workspace,box.env,log,'E11_UPSTREAM_CONTROL_OK',{expectedErrors:true,timeout:60000});
  const text=fs.readFileSync(log,'utf8');let bracket=false,count=0,begins=0,ends=0;
  const unexpected:string[]=[];
  for(const line of text.split(/\r?\n/)){
   if(line==='E11_UPSTREAM_EXPECTED_BEGIN'){bracket=true;begins++;}
   if(line==='E11_UPSTREAM_EXPECTED_END'){bracket=false;ends++;}
   if(ERROR.test(line)){
    if(bracket&&line==='ERROR: Index p_gutter = -1 is out of bounds (gutters.size() = 4).')count++;
    else unexpected.push(line);
   }
  }
  // Baseline4.0 may already initialize inactive native tabs; record exact
  // observation, never invent a failure. Pinned4.7 must reproduce4 errors.
  if(unexpected.length||begins!==1||ends!==1||bracket||engine.label==='4.7'&&count!==4||engine.label==='4.0.4'&&count!==0&&count!==4)result.status='FAIL';
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash,estragon_installed:false});
  writeJSON(path.join(out,'results.json'),{upstream_probe:result,expected_lazy_validation_errors:count,unexpected_errors:unexpected,normal_activation_control:result.status});
  process.stdout.write(text);
  if(result.status!=='PASS')throw Error('E11 stock editor isolation failed');
 }finally{box.dispose();}
}
