/** E02 focused native editor proof. No exhaustive/release profile or Docker. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,copyTree,runCommand,writeJSON,gitHead,gitDirty,sha256,ERROR} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
const scenes=process.argv.includes('--scenes');
const chains=process.argv.includes('--chains');
const generated=process.argv.includes('--generated');
const components=chains||generated||process.argv.includes('--components');
const probeOnly=process.argv.includes('--probe-only');
if(probeOnly&&!components || scenes&&components)throw Error('Use --components [--probe-only] independently of --scenes');
const creationOnly=scenes||components||process.argv.includes('--creation');
const options=parseCLI(process.argv.slice(2).filter(arg=>!['--creation','--scenes','--components','--probe-only','--generated','--chains'].includes(arg)));
if(process.platform!=='linux')throw Error('E02 native acceptance uses approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 if(creationOnly)box.env.ESTRAGON_EDITOR_CREATION_ONLY='1';
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
  async function command(name:string,args:string[],env=box.env,marker?:string,negative=false){
   if(process.env.ESTRAGON_EDITOR_VERBOSE==='1' && name.startsWith('editor'))args.push('--verbose');
   const log=path.join(out,name+'.log');
   const stage=await runCommand(args,name==='install'?box.project:box.workspace,env,log,marker,{abortOnError:!negative,expectedErrors:negative,timeout:negative?180000:60000});
   const text=fs.readFileSync(log,'utf8');process.stdout.write(text);
   if(negative){
    let unsavable=false;
    stage.unexpected_errors=text.split(/\r?\n/).filter(line=>{
     if(line==='E02_EXPECTED_UNSAVABLE_BEGIN')unsavable=true;
     if(line==='E02_EXPECTED_UNSAVABLE_END')unsavable=false;
     return ERROR.test(line) && line!=='ERROR: An EditorPlugin build callback failed.' && !(unsavable && line==="ERROR: Cannot save text file 'res://app/Screens/Home.gogo'.");
    });
    if((stage.unexpected_errors as string[]).length || /E02_EDITOR_CHECK .*: false/.test(text))stage.status='FAIL';
   }
   results[name]=stage;writeJSON(path.join(out,'results.json'),results);
   if(stage.status!=='PASS')throw Error('E02 '+name+' failed');
  }
  const packed=packAddon(path.join(out,'packed'),true);results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'e02-direct-yarn-consumer',private:true,packageManager:'yarn@1.22.22'});
  await command('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],process.env);
  const addonRoot='node_modules/@papercraftgames/estragon/addons/estragon';
  const installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  for(const [name,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,name))!==hash)throw Error('Installed byte mismatch: '+name);
  fs.mkdirSync(path.join(box.project,'app/Screens'),{recursive:true});
  fs.mkdirSync(path.join(box.project,'app/Screens/Nested'),{recursive:true});
  fs.writeFileSync(path.join(box.project,'app/Existing.gogo'),'extends Node2D\nvar existing: int = 1\n');
  fs.writeFileSync(path.join(box.project,'app/Ordinary.gd'),'extends Node\nvar ordinary: int = 1\n');
  fs.writeFileSync(path.join(box.project,'app/ProjectRect.gd'),'class_name Rect\nextends Node2D\n');
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  copyTree(path.join(ROOT,'tests/editor_ux'),path.join(box.project,'tests/editor_ux'));
  if(scenes||components){const cfg=path.join(box.project,'tests/editor_ux/plugin.cfg');fs.writeFileSync(cfg,fs.readFileSync(cfg,'utf8').replace('script="driver.gd"','script="'+(chains?'chain_driver.gd':generated?'generated_driver.gd':components?'project_driver.gd':'scene_driver.gd')+'"'));}
  function configure(root:string){for(const name of ['driver.gd','scene_driver.gd','probe.gd','project_fixture.gd','project_probe.gd','project_driver.gd','generated_driver.gd','chain_driver.gd','chain_probe.gd'].filter(name=>fs.existsSync(path.join(ROOT,'tests/editor_ux',name)))){
   const original=fs.readFileSync(path.join(ROOT,'tests/editor_ux',name),'utf8');
   fs.writeFileSync(path.join(box.project,'tests/editor_ux',name),original.replaceAll('res://addons/estragon','res://'+root));
  }}
  configure(addonRoot);
  const settings='config_version=5\n[application]\nconfig/name="E02 direct Yarn editor"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
  fs.writeFileSync(path.join(box.project,'project.godot'),settings);
  if(components){
   if(generated||chains)box.env.ESTRAGON_E07_PATH_ONLY='1';
   await command('project-components',[box.binary,'--headless','--audio-driver','Dummy','--path',box.project,'--script','res://tests/editor_ux/project_probe.gd'],box.env,'E07_PROJECT_OK');
   delete box.env.ESTRAGON_E07_PATH_ONLY;
   // Each phase begins cold: native probes must not supply generated scripts
   // or cached project state to the real editor fixture.
   fs.rmSync(path.join(box.project,'app'),{recursive:true,force:true});
   fs.mkdirSync(path.join(box.project,'app/Screens'),{recursive:true});
   fs.mkdirSync(path.join(box.project,'app/Screens/Nested'),{recursive:true});
   if(chains)await command('method-chains',[box.binary,'--headless','--audio-driver','Dummy','--path',box.project,'--script','res://tests/editor_ux/chain_probe.gd'],box.env,'E10_CHAIN_OK');
   if(probeOnly)continue;
  }
  if(!components){
   await command('lexical-and-template',[box.binary,'--headless','--audio-driver','Dummy','--path',box.project,'--script','res://tests/editor_ux/probe.gd'],box.env,'E02_PROBE_OK');
   fs.copyFileSync(path.join(box.project,'e03-capabilities.json'),path.join(out,'capabilities.json'));
  }else {box.env.ESTRAGON_E07_GAME='1';if(chains)box.env.ESTRAGON_E10_GAME='1';}
  if(!creationOnly)fs.copyFileSync(path.join(box.project,'e03-native-cache.json'),path.join(out,'native-class-removal.json'));
  // Probe outputs are disposable and must not add un-authored fixtures to builds.
  fs.rmSync(path.join(box.project,'app/Screens/generated'),{recursive:true,force:true});
  fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addonRoot+'/editor/plugin.cfg", "res://tests/editor_ux/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
  await command('editor',[box.binary,'--audio-driver','Dummy','--rendering-method','gl_compatibility','--rendering-driver','opengl3','--path',box.project,'--editor'],box.env,'E02_EDITOR_OK',true);
  if(!creationOnly)fs.copyFileSync(path.join(box.project,'e03-editor-capabilities.json'),path.join(out,'editor-capabilities.json'));
  await command('editor-restart',[box.binary,'--audio-driver','Dummy','--rendering-method','gl_compatibility','--rendering-driver','opengl3','--path',box.project,'--editor'],box.env,'E02_EDITOR_OK',true);
  for(const file of fs.readdirSync(box.project).filter(name=>/^e0[23]-.*\.png$/.test(name)))fs.copyFileSync(path.join(box.project,file),path.join(out,file.slice(4)));
  for(const [name,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,name))!==hash)throw Error('Editor changed installed package bytes/UIDs: '+name);
  if(fs.existsSync(path.join(box.project,'addons/estragon')) || fs.existsSync(path.join(box.project,'node_modules/.gdignore')))throw Error('Forbidden copy/ignore fallback');
  // Focused template-only path proofs; no repeated three-layout editor suites.
  let previous=path.join(box.project,addonRoot);
  for(const [label,root]of [['relocated','modules/UI toolkit'],['standard','addons/estragon']]){
   const target=path.join(box.project,root!);fs.mkdirSync(path.dirname(target),{recursive:true});fs.renameSync(previous,target);previous=target;
   configure(root!);fs.writeFileSync(path.join(box.project,'project.godot'),settings);fs.rmSync(path.join(box.project,'.godot'),{recursive:true,force:true});
   if(components){
    fs.rmSync(path.join(box.project,'app'),{recursive:true,force:true});
    box.env.ESTRAGON_E07_PATH_ONLY='1';delete box.env.ESTRAGON_E07_GAME;
   }
   await command('template-'+label,[box.binary,'--headless','--audio-driver','Dummy','--path',box.project,'--script','res://tests/editor_ux/'+(components?'project_probe.gd':'probe.gd')],box.env,components?'E07_PROJECT_OK':'E02_PROBE_OK');
  }
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),profile:chains?'E10-method-chains':generated?'E09-generated-editors':components?'E07-project-components':scenes?'E05-scenes':creationOnly?'E04-creation':'full-editor-ux',tarball_sha256:packed.manifest.tarball_sha256,direct_yarn:true,package_unchanged:true,template_layouts:['direct','relocated','standard'],external_compiler:false});
 }finally{
  // Preserve actual graphics even when a later native/lifecycle assertion fails.
  if(fs.existsSync(box.project))for(const file of fs.readdirSync(box.project).filter(name=>/^e0[23]-.*\.png$/.test(name)))fs.copyFileSync(path.join(box.project,file),path.join(out,file.slice(4)));
  for(const relative of ['app/Screens/Home.gogo','app/Screens/Nested/Spatial.gogo','app/Screens/generated/Home.gd']){
   const file=path.join(box.project,relative);if(fs.existsSync(file)&&fs.statSync(file).isFile())fs.copyFileSync(file,path.join(out,relative.replaceAll('/','-')));
  }
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
