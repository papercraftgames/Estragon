/** EL02 native layout declarations; immutable direct-Yarn graphics/editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const editorOnly=process.argv.includes('--editor-only'), editor=editorOnly||process.argv.includes('--editor');
const argv=process.argv.slice(2).filter(a=>!['--editor','--editor-only'].includes(a));
const options=parseCLI(argv);
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,"packed"),"layouts");
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash,command:process.argv});
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const editing=name.startsWith('editor'),negative=name==='runtime',logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!editing&&!negative,expectedErrors:editing||negative,timeout:editing?120000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative){
    let bracket=false,starts=0,count=0;const unexpected:string[]=[];
    for(const line of log.split(/\r?\n/)){
     if(line==='EL02_EXPECTED_RUNTIME_REJECTION_BEGIN'){bracket=true;starts++;}
     else if(line==='EL02_EXPECTED_RUNTIME_REJECTION_END')bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&/^ERROR: app\/Layouts\.gogo:32:28: invalid style 'background_color': Color requires a native Color, #rgb\/#rgba\/#rrggbb\/#rrggbbaa or transparent; previous tree retained$/.test(line))count++;
      else unexpected.push(line);
     }
    }
    if(bracket||starts!==1||count!==1||unexpected.length){result.status='FAIL';result.reason='Unexpected runtime diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
   }
   if(editing){
    let bracket=false,starts=0,count=0,typed=0,mapped=0;const unexpected:string[]=[];
    const lines=log.split(/\r?\n/);
    for(const [index,line] of lines.entries()){
     if(line==='EL02_EXPECTED_PLAY_REJECTION_BEGIN'){bracket=true;starts++;}
     else if(line==='EL02_EXPECTED_PLAY_REJECTION_END')bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&line==='ERROR: An EditorPlugin build callback failed.')count++;
      else if(bracket&&line==='SCRIPT ERROR: Parse Error: Cannot return value of type "int" because the function return type is "Node2D".'&&/^\s+at: GDScript::reload \(res:\/\/app\/generated\/Layouts\.gd:\d+\)$/.test(lines[index+1]||''))typed++;
      else if(bracket&&/^app\/Layouts\.gogo:\d+:1: Parse Error: Cannot return value of type "int" because the function return type is "Node2D"\.$/.test(line))mapped++;
      else unexpected.push(line);
     }
    }
    const expected=starts;
    if(bracket||unexpected.length||count!==expected||starts!==(name==='editor'?8:0)||(name==='editor'?(typed<2||typed>4||(mapped!==0&&mapped!==typed)):(typed!==0||mapped!==0))) {result.status='FAIL';result.reason='Unexpected diagnostics '+JSON.stringify({bracket,starts,count,typed,mapped,unexpected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('EL02 '+name+' failed');
  }
  results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'layouts-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const fixtures=path.join(box.project,'tests/layouts');fs.mkdirSync(fixtures,{recursive:true});
  for(const entry of fs.readdirSync(path.join(ROOT,'tests/layouts'),{withFileTypes:true}))if(entry.isFile())fs.copyFileSync(path.join(ROOT,'tests/layouts',entry.name),path.join(fixtures,entry.name));
  for(const name of fs.readdirSync(fixtures).filter(n=>n.endsWith('.gd'))){const file=path.join(fixtures,name);fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  fs.mkdirSync(path.join(box.project,'app'),{recursive:true});
  // A real authored fixture identity, not a temporary runner UID. Godot 4.0
  // does not generate script sidecars; both engines must preserve this one.
  fs.mkdirSync(path.join(box.project,'app/generated'),{recursive:true});
  const fixtureUID=path.join(ROOT,'examples/layouts/generated/Layouts.gd.uid');
  for(const name of ['Layouts','Header','Library'])fs.copyFileSync(path.join(ROOT,'examples/layouts/generated',name+'.gd.uid'),path.join(box.project,'app/generated',name+'.gd.uid'));
  for(const name of ['Layouts','Header','Library']){
   let source=fs.readFileSync(path.join(ROOT,'examples/layouts',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
   if(name==='Layouts')source+='\nfunc _ready() -> void:\n    if OS.get_environment("EL02_EDITOR")=="1": _layout_probe.call_deferred()\nfunc _layout_probe() -> void:\n    var probe = preload("res://tests/layouts/game.gd").new()\n    await probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="EL02 layout gallery"\nrun/main_scene="res://app/Layouts.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  for(const name of ['godot_button.gd','godot_button.gd.uid'])fs.copyFileSync(path.join(ROOT,'examples',name),path.join(box.project,name));
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/layouts/build.gd'],'EL02_BUILD_OK');
  if(!editorOnly){
   for(const [name,marker] of [['frontend','EL02_FRONTEND_OK'],['runtime','EL02_RUNTIME_OK']])
    await run(name!,[...args,...graphics,'--script','res://tests/layouts/'+name+'.gd'],marker);
  }
  if(editor){
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   writeJSON(path.join(out,'results.json'),results);
   if(results.import.status!=='PASS')throw Error('EL02 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/layouts/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.EL02_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'EL02_EDITOR_OK');
   delete box.env.EL02_EDITOR;
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  const source=path.join(box.project,'app/Layouts.gogo'),generated=path.join(box.project,'app/generated/Layouts.gd');
  const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
  if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!=='app/Layouts.gogo'||map.generatedHash!==sha256(generated))throw Error('Stale authored/generated map after editor repair');
  if(sha256(generated+'.uid')!==sha256(fixtureUID))throw Error('Authored gallery UID changed');
  writeJSON(path.join(out,'map-proof.json'),{source_sha256:sha256(source),generated_sha256:sha256(generated),map_sha256:sha256(generated+'.map.json'),uid_sha256:sha256(generated+'.uid'),canonical_uid_source:'examples/layouts/generated/Layouts.gd.uid',source_content_matches:true,generated_hash_matches:true});
  for(const name of ['Header','Library']){
   const generated=path.join(box.project,'app/generated',name+'.gd'),source=path.join(box.project,'app',name+'.gogo');
   const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!=='app/'+name+'.gogo'||map.generatedHash!==sha256(generated))throw Error('Stale imported source/map '+name);
   const canonical=path.join(ROOT,'examples/layouts/generated',name+'.gd.uid');
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
   const game=path.join(box.project,'.godot/el02-game.json');if(fs.existsSync(game))fs.copyFileSync(game,path.join(out,'el02-game.json'));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
