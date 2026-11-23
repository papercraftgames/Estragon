/** UI-03: one immutable direct-Yarn payload, real native editor commands/Play. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,runCommand,writeJSON,sha256,indexProject,ERROR} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const options=parseCLI(process.argv.slice(2));
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,'packed'),'input');
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,unknown>={};
 fs.mkdirSync(out,{recursive:true});
 async function run(name:string,args:string[],marker?:string,env=box.env){
  const editing=name.startsWith('editor'),negative=name==='rejections',logFile=path.join(out,name+'.log');
  const result=await runCommand(args,box.project,env,logFile,marker,{timeout:editing?180000:120000,abortOnError:!editing&&!negative,expectedErrors:editing||negative});
  if(editing){
   let bracket=false,starts=0,count=0,typed=0,mapped=0;const unexpected:string[]=[];
   for(const line of fs.readFileSync(logFile,'utf8').split(/\r?\n/)){
    if(line==='UI03_EXPECTED_PLAY_REJECTION_BEGIN'){bracket=true;starts++;}
    else if(line==='UI03_EXPECTED_PLAY_REJECTION_END')bracket=false;
    else if(ERROR.test(line)){
     if(bracket&&line==='ERROR: An EditorPlugin build callback failed.')count++;
     else if(bracket&&starts===2&&/^SCRIPT ERROR: Parse Error: (?:Cannot pass a value of type "bool" as "String"\.|Invalid argument for "_gogo_build_\d+\(\)" function: argument \d+ should be "String" but is "bool"\.)$/.test(line))typed++;
     else if(bracket&&starts===2&&/^app\/Inputs\.gogo:\d+:\d+: Parse Error: (?:Cannot pass a value of type "bool" as "String"\.|Invalid argument for "_gogo_build_\d+\(\)" function: argument \d+ should be "String" but is "bool"\.)$/.test(line))mapped++;
     else unexpected.push(line);
    }
   }
   if(bracket||starts!==(name==='editor'?2:0)||count!==starts||(name==='editor'?(typed<2||typed>8||(mapped!==0&&mapped!==typed)):(typed!==0||mapped!==0))||unexpected.length){result.status='FAIL';result.reason='Unexpected editor diagnostics '+JSON.stringify({bracket,starts,count,typed,mapped,unexpected});}
  }
  if(negative){
   let bracket=false,starts=0,count=0;const unexpected:string[]=[];
   for(const line of fs.readFileSync(logFile,'utf8').split(/\r?\n/)){
    if(line==='UI03_EXPECTED_REJECTION_BEGIN'){bracket=true;starts++;}
    else if(line==='UI03_EXPECTED_REJECTION_END')bracket=false;
    else if(ERROR.test(line)){
     if(bracket&&/^ERROR: app\/Rejection\.gogo:\d+:\d+(?: \(spread key '[^']+'\))?: .+previous tree retained$/.test(line))count++;
     else unexpected.push(line);
    }
   }
   if(bracket||starts!==5||count!==5||unexpected.length){result.status='FAIL';result.reason='Unexpected rejection diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
  }
  results[name]=result;writeJSON(path.join(out,'results.json'),results);
  if(result.status!=='PASS')throw Error('UI03 '+name+' failed: '+JSON.stringify(result));
 }
 try{
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(out,'provenance.json'),{...packed.manifest,engine:box.version,binary_sha256:box.inputHash,command:process.argv});
  writeJSON(path.join(box.project,'package.json'),{name:'input-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,{...process.env,COREPACK_ENABLE_PROJECT_SPEC:'0'});
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  for(const suite of ['input','layouts']){
   const dest=path.join(box.project,'tests',suite);fs.mkdirSync(dest,{recursive:true});
   for(const entry of fs.readdirSync(path.join(ROOT,'tests',suite),{withFileTypes:true}))if(entry.isFile()){
    const source=path.join(ROOT,'tests',suite,entry.name),target=path.join(dest,entry.name);
    if(entry.name.endsWith('.gd'))fs.writeFileSync(target,fs.readFileSync(source,'utf8').replaceAll('res://addons/estragon','res://'+addon));
    else fs.copyFileSync(source,target);
   }
  }
  fs.mkdirSync(path.join(box.project,'app/generated'),{recursive:true});
  for(const name of ['Inputs','Model']){
   fs.copyFileSync(path.join(ROOT,'examples/input/generated',name+'.gd.uid'),path.join(box.project,'app/generated',name+'.gd.uid'));
  }
  fs.writeFileSync(path.join(box.project,'app/Model.gogo'),fs.readFileSync(path.join(ROOT,'examples/input/Model.gogo'),'utf8'));

  fs.copyFileSync(path.join(ROOT,'examples/godot_button.gd'),path.join(box.project,'godot_button.gd'));
  fs.copyFileSync(path.join(ROOT,'examples/godot_button.gd.uid'),path.join(box.project,'godot_button.gd.uid'));
  let source=fs.readFileSync(path.join(ROOT,'examples/input/Inputs.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
  source+='\nfunc _ready() -> void:\n    if OS.get_environment("UI03_EDITOR")=="1": _input_probe.call_deferred()\nfunc _input_probe() -> void:\n    var probe = preload("res://tests/input/game.gd").new()\n    await probe.run(self)\n';
  fs.writeFileSync(path.join(box.project,'app/Inputs.gogo'),source);
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="UI03 native input"\nrun/main_scene="res://app/Inputs.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=700\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('frontend',[...args,'--headless','--script','res://tests/input/frontend.gd'],'UI03_FRONTEND_OK');
  await run('build',[...args,'--headless','--script','res://tests/input/build.gd'],'UI03_BUILD_OK');
  await run('scene',[...args,...graphics,'--script','res://tests/input/scene.gd'],'UI03_SCENE_OK');
  await run('rejections',[...args,'--headless','--script','res://tests/input/rejections.gd'],'UI03_REJECTION_OK');
  results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
  writeJSON(path.join(out,'results.json'),results);
  if((results.import as {status:string}).status!=='PASS')throw Error('Clean import failed');
  fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
  fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
  fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/input/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
  box.env.UI03_EDITOR='1';
  for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'UI03_EDITOR_OK');
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  for(const name of ['Inputs','Model']){
   const generated=path.join(box.project,'app/generated',name+'.gd'),source=path.join(box.project,'app',name+'.gogo'),map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.generatedHash!==sha256(generated)||map.sourceName!=='app/'+name+'.gogo'||sha256(generated+'.uid')!==sha256(path.join(ROOT,'examples/input/generated',name+'.gd.uid')))throw Error('Stale map or changed UID '+name);
  }
  results.immutable={status:'PASS',sourceHead:packed.manifest.sourceHead,direct_yarn:true,installed_bytes_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256};
 }finally{
  if(fs.existsSync(box.project))for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
