/** L0910 bounded responsive Wrap and native Grid and direct-Yarn editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
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
   const negative=name==='runtime',editing=name.startsWith('editor'),logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!negative&&!editing,expectedErrors:negative||editing,timeout:editing?120000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative||editing){
    let bracket=false,starts=0,count=0;const unexpected:string[]=[];
    for(const line of log.split(/\r?\n/)){
     if(line===(negative?'L0910_EXPECTED_REJECTION_BEGIN':'L0910_EXPECTED_PLAY_REJECTION_BEGIN')){bracket=true;starts++;}
     else if(line===(negative?'L0910_EXPECTED_REJECTION_END':'L0910_EXPECTED_PLAY_REJECTION_END'))bracket=false;
     else if(ERROR.test(line)){
      if(bracket&&(negative?/^ERROR: (app\/ResponsiveGallery\.gogo:\d+:\d+(?: \(spread key '.*'\))?: .*previous tree retained|Estragon (Box:|responsive:).*)$/.test(line):line==='ERROR: An EditorPlugin build callback failed.'))count++;
      else unexpected.push(line);
     }
    }
    if(bracket||unexpected.length||(negative?(starts!==3||count!==21):(starts>2||count!==starts))) {result.status='FAIL';result.reason='Unexpected diagnostics '+JSON.stringify({bracket,starts,count,unexpected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('L0910 '+name+' failed');
  }
  const packed=packAddon(path.join(out,'packed'),true);
  results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'l0910-responsive-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const fixtures=path.join(box.project,'tests/responsive');copyTree(path.join(ROOT,'tests/responsive'),fixtures);
  for(const name of fs.readdirSync(fixtures).filter(n=>n.endsWith('.gd'))){const file=path.join(fixtures,name);fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  fs.mkdirSync(path.join(box.project,'app'),{recursive:true});
  for(const name of ['ResponsiveGallery','NestedResponsive']){
   let source=fs.readFileSync(path.join(ROOT,'examples/responsive',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon));
   if(name==='ResponsiveGallery')source+='\nfunc _ready() -> void:\n\tif OS.get_environment("L0910_EDITOR")=="1": _l0910_probe.call_deferred()\nfunc _l0910_probe() -> void:\n\tvar probe = preload("res://tests/responsive/game.gd").new()\n\tawait probe.run(self)\n';
   fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),source);
  }
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="L0910 Box responsive"\nrun/main_scene="res://app/ResponsiveGallery.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=480\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/responsive/build.gd'],'L0910_BUILD_OK');
  if(!editorOnly){
   await run('frontend',[...args,'--headless','--script','res://tests/responsive/frontend.gd'],'L0910_FRONTEND_OK');
   await run('math',[...args,'--headless','--script','res://tests/responsive/math.gd'],'L0910_MATH_OK');
    await run('runtime',[...args,'--headless','--script','res://tests/responsive/runtime.gd'],'L0910_RUNTIME_OK');
  await run('graphics',[...args,...graphics,'--script','res://tests/responsive/graphics.gd'],'L0910_GRAPHICS_OK');
  }
  if(editor){
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   writeJSON(path.join(out,'results.json'),results);
   if(results.import.status!=='PASS')throw Error('L0910 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/responsive/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.L0910_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'L0910_EDITOR_OK');
   delete box.env.L0910_EDITOR;
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),direct_yarn:true,package_unchanged:true,canonical_uids:packed.manifest.canonical_uids,tarball_sha256:packed.manifest.tarball_sha256});
 }finally{
  if(fs.existsSync(box.project)){
   for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
   const game=path.join(box.project,'.godot/l0910-game.json');if(fs.existsSync(game))fs.copyFileSync(game,path.join(out,'l0910-game.json'));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
