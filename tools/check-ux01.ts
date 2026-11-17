/** UX01 combined syntax, maxima, wrapping and inherited Component2D scrolling and direct-Yarn editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
import {developmentContext, type VersionContext} from './release-context.ts';
import {tagVersion, OVERLAY_RECIPE} from './package-version.ts';
const editorOnly=process.argv.includes('--editor-only'), editor=editorOnly||process.argv.includes('--editor');
const argv=process.argv.slice(2).filter(a=>!['--editor','--editor-only'].includes(a));
const candidateIndex=argv.indexOf('--candidate-tag');
const candidate=candidateIndex<0?null:argv.splice(candidateIndex,2)[1];
if(candidateIndex>=0&&!candidate)throw Error('Missing read-only preview candidate tag');
const options=parseCLI(argv);
const overlay:VersionContext=candidate?{mode:'preview',version:tagVersion(candidate),sourceHead:gitHead(),tag:candidate,release_id:null,overlayRecipe:OVERLAY_RECIPE}:developmentContext();
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash,command:process.argv});
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const negative=['syntax','rejections'].includes(name),editing=name.startsWith('editor'),logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!negative&&!editing,expectedErrors:negative||editing,timeout:editing?120000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative||editing){
    let bracket=false,starts=0,count=0;const unexpected:string[]=[];
    for(const line of log.split(/\r?\n/)){
     if(line===(negative?'UX01_EXPECTED_BEGIN':'UX01_EXPECTED_PLAY_REJECTION_BEGIN')){bracket=true;starts++;}
     else if(line===(negative?'UX01_EXPECTED_END':'UX01_EXPECTED_PLAY_REJECTION_END'))bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&(negative?/^ERROR: (?:app\/(?:UXGallery|Ergonomics)\.gogo|tests\/ux01\/rejections\.gd):\d+:\d+(?: \(spread key '.*'\))?: .*previous tree retained$/.test(line)||name==='rejections'&&/^ERROR: Estragon scrolling (?:scroll_offset requires a finite nonnegative Vector2|(?:scroll_range|content_extent) is read-only)$/.test(line):line==='ERROR: An EditorPlugin build callback failed.'))count++;
      else unexpected.push(line);
     }
    }
    const expected=name==='syntax'?2:name==='rejections'?13:starts;
    if(bracket||unexpected.length||count!==expected||(negative&&starts!==expected)||(!negative&&starts>2)) {result.status='FAIL';result.reason='Unexpected diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('UX01 '+name+' failed');
  }
  const packed=packAddon(path.join(out,'packed'),true,overlay);
  results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'ux01-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const fixtures=path.join(box.project,'tests/ux01');copyTree(path.join(ROOT,'tests/ux01'),fixtures);
  for(const name of fs.readdirSync(fixtures).filter(n=>n.endsWith('.gd'))){const file=path.join(fixtures,name);fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  fs.mkdirSync(path.join(box.project,'app'),{recursive:true});
  for(const name of ['UXGallery','Ergonomics','WrapReproduction','UXRose','UXSettings','ScrollProof','InheritedScrolling']){
   let source=fs.readFileSync(path.join(ROOT,'examples/ux01',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
   if(name==='UXGallery')source+='\nfunc _ready() -> void:\n\tif OS.get_environment("UX01_EDITOR")=="1": _ux01_probe.call_deferred()\nfunc _ux01_probe() -> void:\n\tvar probe = preload("res://tests/ux01/game.gd").new()\n\tawait probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="UX01 combined gallery"\nrun/main_scene="res://app/UXGallery.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/ux01/build.gd'],'UX01_BUILD_OK');
  if(!editorOnly){
   for(const [name,marker] of [['wrap_capacity','UX01_A_MATH_OK'],['syntax','UX01_B_OK'],['maxima','UX01_C_OK'],['clipping_probe','UX01_CLIP_OK'],['scroll_native','UX01_NATIVE_SCROLL_OK'],['scroll_nested','UX01_NESTED_OK'],['scrolling','UX01_SCROLL_OK'],['rejections','UX01_REJECTIONS_OK'],['reproduction','UX01_REPRO_OK'],['gallery','UX01_GALLERY_OK'],['inherited','U02_INHERITED_OK']])
    await run(name!,[...args,...graphics,'--script','res://tests/ux01/'+name+'.gd'],marker);
  }
  if(editor){
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   writeJSON(path.join(out,'results.json'),results);
   if(results.import.status!=='PASS')throw Error('UX01 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/ux01/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.UX01_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'UX01_EDITOR_OK');
   delete box.env.UX01_EDITOR;
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  // U02 intentionally removes this beta API, including its UID and catalog entry.
  for(const file of Object.keys(packed.manifest.files)){
   if(/scroll_view\.gd(?:\.uid)?$/.test(file))throw Error('Obsolete public scroll component packaged: '+file);
   if(/\.(?:gd|json)$/.test(file)&&/EstragonScrollView|scroll_view\.gd/.test(fs.readFileSync(path.join(installed,file),'utf8')))throw Error('Obsolete scroll import/catalog entry: '+file);
  }
  const classes=path.join(box.project,'.godot/global_script_class_cache.cfg');
  if(fs.existsSync(classes)&&/EstragonScrollView|scroll_view\.gd/.test(fs.readFileSync(classes,'utf8')))throw Error('Obsolete scroll class registered');
  results.removal={status:'PASS',obsolete_component_absent:true,installed_bytes_unchanged:true};
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),direct_yarn:true,package_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256});
 }finally{
  if(fs.existsSync(box.project)){
   for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
   const game=path.join(box.project,'.godot/ux01-game.json');if(fs.existsSync(game))fs.copyFileSync(game,path.join(out,'ux01-game.json'));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
