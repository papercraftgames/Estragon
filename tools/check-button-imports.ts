/** D07 opt-in import-selected Buttons; immutable direct-Yarn graphics/editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const editorOnly=process.argv.includes('--editor-only'), editor=editorOnly||process.argv.includes('--editor');
const argv=process.argv.slice(2).filter(a=>!['--editor','--editor-only'].includes(a));
const options=parseCLI(argv);
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,"packed"));
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash,command:process.argv});
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const editing=name.startsWith('editor'),logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!editing,expectedErrors:editing,timeout:editing?120000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative||editing){
    let bracket=false,starts=0,count=0;const unexpected:string[]=[];
    for(const line of log.split(/\r?\n/)){
     if(line==='D07_EXPECTED_PLAY_REJECTION_BEGIN'){bracket=true;starts++;}
     else if(line==='D07_EXPECTED_PLAY_REJECTION_END')bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&line==='ERROR: An EditorPlugin build callback failed.')count++;
      else unexpected.push(line);
     }
    }
    const expected=starts;
    if(bracket||unexpected.length||count!==expected||starts!==(name==='editor'?2:0)) {result.status='FAIL';result.reason='Unexpected diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('D07 '+name+' failed');
  }
  results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'button-imports-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const fixtures=path.join(box.project,'tests/button_imports');copyTree(path.join(ROOT,'tests/button_imports'),fixtures);
  for(const name of fs.readdirSync(fixtures).filter(n=>n.endsWith('.gd'))){const file=path.join(fixtures,name);fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  fs.mkdirSync(path.join(box.project,'app'),{recursive:true});
  // A real authored fixture identity, not a temporary runner UID. Godot 4.0
  // does not generate script sidecars; both engines must preserve this one.
  fs.mkdirSync(path.join(box.project,'app/generated'),{recursive:true});
  const fixtureUID=path.join(ROOT,'examples/button_imports/generated/Buttons.gd.uid');
  for(const name of ['Buttons','NativeOnly','TypedButton','LegacyAlias'])fs.copyFileSync(path.join(ROOT,name==='LegacyAlias'?'tests/button_imports/generated':'examples/button_imports/generated',name+'.gd.uid'),path.join(box.project,'app/generated',name+'.gd.uid'));
  for(const name of ['Buttons','NativeOnly','TypedButton','LegacyAlias']){
   let source=fs.readFileSync(path.join(ROOT,name==='LegacyAlias'?'tests/button_imports':'examples/button_imports',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon)).replaceAll('../../surfaces/panel_gradient.tres','../panel_gradient.tres');
   if(name==='Buttons')source+='\nfunc _ready() -> void:\n\tif OS.get_environment("D07_EDITOR")=="1": _button_probe.call_deferred()\nfunc _button_probe() -> void:\n\tvar probe = preload("res://tests/button_imports/game.gd").new()\n\tawait probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  fs.copyFileSync(path.join(ROOT,'examples/surfaces/panel_gradient.tres'),path.join(box.project,'app/panel_gradient.tres'));
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="D07 combined gallery"\nrun/main_scene="res://app/Buttons.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  for(const name of ['godot_button.gd','godot_button.gd.uid'])fs.copyFileSync(path.join(ROOT,'examples',name),path.join(box.project,name));
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/button_imports/build.gd'],'D07_BUILD_OK');
  if(!editorOnly){
   for(const [name,marker] of [['frontend','D07_FRONTEND_OK'],['runtime','D07_RUNTIME_OK']])
    await run(name!,[...args,...graphics,'--script','res://tests/button_imports/'+name+'.gd'],marker);
  }
  if(editor){
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   writeJSON(path.join(out,'results.json'),results);
   if(results.import.status!=='PASS')throw Error('D07 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/button_imports/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.D07_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'D07_EDITOR_OK');
   delete box.env.D07_EDITOR;
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  const source=path.join(box.project,'app/Buttons.gogo'),generated=path.join(box.project,'app/generated/Buttons.gd');
  const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
  if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!=='app/Buttons.gogo'||map.generatedHash!==sha256(generated))throw Error('Stale authored/generated map after editor repair');
  if(sha256(generated+'.uid')!==sha256(fixtureUID))throw Error('Authored gallery UID changed');
  writeJSON(path.join(out,'map-proof.json'),{source_sha256:sha256(source),generated_sha256:sha256(generated),map_sha256:sha256(generated+'.map.json'),uid_sha256:sha256(generated+'.uid'),canonical_uid_source:'examples/button_imports/generated/Buttons.gd.uid',source_content_matches:true,generated_hash_matches:true});
  for(const name of ['NativeOnly','TypedButton','LegacyAlias']){
   const generated=path.join(box.project,'app/generated',name+'.gd'),source=path.join(box.project,'app',name+'.gogo');
   const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!=='app/'+name+'.gogo'||map.generatedHash!==sha256(generated))throw Error('Stale imported source/map '+name);
   const canonical=path.join(ROOT,name==='LegacyAlias'?'tests/button_imports/generated':'examples/button_imports/generated',name+'.gd.uid');
   if(sha256(generated+'.uid')!==sha256(canonical))throw Error('Changed imported UID '+name);
  }
  // U02 intentionally removes this beta API, including its UID and catalog entry.
  for(const file of Object.keys(packed.manifest.files)){
   if(/scroll_view\.gd(?:\.uid)?$/.test(file))throw Error('Obsolete public scroll component packaged: '+file);
   if(/\.(?:gd|json)$/.test(file)&&/EstragonScrollView|scroll_view\.gd/.test(fs.readFileSync(path.join(installed,file),'utf8')))throw Error('Obsolete scroll import/catalog entry: '+file);
  }
  const classes=path.join(box.project,'.godot/global_script_class_cache.cfg');
  if(fs.existsSync(classes)&&/EstragonScrollView|scroll_view\.gd/.test(fs.readFileSync(classes,'utf8')))throw Error('Obsolete scroll class registered');
  results.immutable={status:'PASS',obsolete_component_absent:true,installed_bytes_unchanged:true};
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),direct_yarn:true,package_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256});
 }finally{
  if(fs.existsSync(box.project)){
   for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
   const game=path.join(box.project,'.godot/d07-game.json');if(fs.existsSync(game))fs.copyFileSync(game,path.join(out,'d07-game.json'));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
