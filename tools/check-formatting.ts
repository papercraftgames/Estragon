/** EDIT-01: one immutable direct-Yarn payload, real native editor commands/Play. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,runCommand,writeJSON,sha256,indexProject,ERROR} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const options=parseCLI(process.argv.slice(2));
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,'packed'),'formatting');
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,unknown>={};
 fs.mkdirSync(out,{recursive:true});
 async function run(name:string,args:string[],marker?:string,env=box.env){
  const editing=name.startsWith('editor'),logFile=path.join(out,name+'.log');
  const result=await runCommand(args,box.project,env,logFile,marker,{timeout:120000,abortOnError:!editing,expectedErrors:editing});
  if(editing){
   let bracket=false,starts=0,count=0;const unexpected:string[]=[];
   for(const line of fs.readFileSync(logFile,'utf8').split(/\r?\n/)){
    if(line==='EDIT01_EXPECTED_PLAY_REJECTION_BEGIN'){bracket=true;starts++;}
    else if(line==='EDIT01_EXPECTED_PLAY_REJECTION_END')bracket=false;
    else if(ERROR.test(line)){
     if(bracket&&line==='ERROR: An EditorPlugin build callback failed.')count++;
     else unexpected.push(line);
    }
   }
   if(bracket||starts!==(name==='editor'?2:0)||count!==starts||unexpected.length){result.status='FAIL';result.reason='Unexpected editor diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
  }
  results[name]=result;writeJSON(path.join(out,'results.json'),results);
  if(result.status!=='PASS')throw Error('EDIT01 '+name+' failed: '+JSON.stringify(result));
 }
 try{
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(out,'provenance.json'),{...packed.manifest,engine:box.version,binary_sha256:box.inputHash,command:process.argv});
  writeJSON(path.join(box.project,'package.json'),{name:'formatting-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,{...process.env,COREPACK_ENABLE_PROJECT_SPEC:'0'});
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  for(const suite of ['formatting','layouts']){
   const dest=path.join(box.project,'tests',suite);fs.mkdirSync(dest,{recursive:true});
   for(const entry of fs.readdirSync(path.join(ROOT,'tests',suite),{withFileTypes:true}))if(entry.isFile()){
    const source=path.join(ROOT,'tests',suite,entry.name),target=path.join(dest,entry.name);
    if(entry.name.endsWith('.gd'))fs.writeFileSync(target,fs.readFileSync(source,'utf8').replaceAll('res://addons/estragon','res://'+addon));
    else fs.copyFileSync(source,target);
   }
  }
  // Real Home/Layouts/Core authored samples, including their literal contents.
  for(const sample of ['nested_layout/Home','layouts/Layouts','core_reactivity/Core']){
   const target=path.join(box.project,'examples',sample+'.gogo');fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(ROOT,'examples',sample+'.gogo'),target);
  }
  fs.mkdirSync(path.join(box.project,'app/generated'),{recursive:true});
  for(const name of ['Layouts','Header','Library']){
   fs.copyFileSync(path.join(ROOT,'examples/layouts/generated',name+'.gd.uid'),path.join(box.project,'app/generated',name+'.gd.uid'));
   let source=fs.readFileSync(path.join(ROOT,'examples/layouts',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
   if(name==='Layouts')source+='\nfunc _ready() -> void:\n    if OS.get_environment("EL02_EDITOR")=="1": _layout_probe.call_deferred()\nfunc _layout_probe() -> void:\n    var probe = preload("res://tests/layouts/game.gd").new()\n    await probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  for(const name of ['godot_button.gd','godot_button.gd.uid'])fs.copyFileSync(path.join(ROOT,'examples',name),path.join(box.project,name));
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="EDIT01 native formatting"\nrun/main_scene="res://app/Layouts.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('frontend',[...args,'--headless','--script','res://tests/formatting/frontend.gd'],'EDIT01_FRONTEND_OK');
  await run('buffer',[...args,'--headless','--script','res://tests/formatting/buffer.gd'],'EDIT01_BUFFER_OK');
  await run('build',[...args,'--headless','--script','res://tests/layouts/build.gd'],'EL02_BUILD_OK');
  results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
  writeJSON(path.join(out,'results.json'),results);
  if((results.import as {status:string}).status!=='PASS')throw Error('Clean import failed');
  fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
  fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
  fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/formatting/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
  box.env.EL02_EDITOR='1';
  for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'EDIT01_EDITOR_OK');
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  for(const name of ['Layouts','Header','Library']){
   const generated=path.join(box.project,'app/generated',name+'.gd'),source=path.join(box.project,'app',name+'.gogo'),map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.generatedHash!==sha256(generated)||map.sourceName!=='app/'+name+'.gogo'||sha256(generated+'.uid')!==sha256(path.join(ROOT,'examples/layouts/generated',name+'.gd.uid')))throw Error('Stale map or changed UID '+name);
  }
  results.immutable={status:'PASS',sourceHead:packed.manifest.sourceHead,direct_yarn:true,installed_bytes_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256};
 }finally{
  if(fs.existsSync(box.project))for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')||n==='edit01-final-generated.txt'))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
