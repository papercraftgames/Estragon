/** S03 bounded native attribute spread compiler/reconciler and direct-Yarn editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
const editorOnly=process.argv.includes('--editor-only'), editor=editorOnly||process.argv.includes('--editor');
const options=parseCLI(process.argv.slice(2).filter(a=>!['--editor','--editor-only'].includes(a)));
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash,command:process.argv});
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const negative=name==='rejections',editing=name.startsWith('editor'),logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!negative&&!editing,expectedErrors:negative||editing,timeout:editing?120000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative||editing){
    let bracket=false,starts=0,count=0;const unexpected:string[]=[];
    for(const line of log.split(/\r?\n/)){
     if(line===(negative?'S03_EXPECTED_REJECTION_BEGIN':'S03_EXPECTED_PLAY_REJECTION_BEGIN')){bracket=true;starts++;}
     else if(line===(negative?'S03_EXPECTED_REJECTION_END':'S03_EXPECTED_PLAY_REJECTION_END'))bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&(negative?/^ERROR: app\/RejectionHost\.gogo:\d+:\d+(?: \(spread key '.*'\))?: .*previous tree retained$/.test(line):line==='ERROR: An EditorPlugin build callback failed.'))count++;
      else unexpected.push(line);
     }
    }
    if(bracket||unexpected.length||(negative?(starts!==1||count!==27):(starts>2||count!==starts))) {result.status='FAIL';result.reason='Unexpected diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('S03 '+name+' failed');
  }
  const packed=packAddon(path.join(out,'packed'),true);
  results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'s03-spread-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const fixtures=path.join(box.project,'tests/spreads');copyTree(path.join(ROOT,'tests/spreads'),fixtures);
  for(const name of fs.readdirSync(fixtures).filter(n=>n.endsWith('.gd'))){const file=path.join(fixtures,name);fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  fs.mkdirSync(path.join(box.project,'app'),{recursive:true});
  for(const name of ['SpreadGallery','NestedSpread','RejectionHost']){
   let source=fs.readFileSync(path.join(ROOT,name==='RejectionHost'?'tests/spreads':'examples/spreads',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
   if(name==='SpreadGallery')source+='\nfunc _ready() -> void:\n\tif OS.get_environment("S03_EDITOR")=="1": _s03_probe.call_deferred()\nfunc _s03_probe() -> void:\n\tvar probe = preload("res://tests/spreads/game.gd").new()\n\tawait probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="S03 attribute spreads"\nrun/main_scene="res://app/SpreadGallery.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/spreads/build.gd'],'S03_BUILD_OK');
  if(!editorOnly){
   await run('frontend',[...args,'--headless','--script','res://tests/spreads/frontend.gd'],'S03_FRONTEND_OK');
   await run('rejections',[...args,'--headless','--script','res://tests/spreads/rejections.gd'],'S03_REJECTIONS_OK');
   await run('runtime',[...args,...graphics,'--script','res://tests/spreads/runtime.gd'],'S03_RUNTIME_OK');
  }
  if(editor){
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/spreads/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.S03_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'S03_EDITOR_OK');
   delete box.env.S03_EDITOR;
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),direct_yarn:true,package_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256});
 }finally{
  if(fs.existsSync(box.project)){
   for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
   const game=path.join(box.project,'.godot/s03-game.json');if(fs.existsSync(game))fs.copyFileSync(game,path.join(out,'s03-game.json'));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
