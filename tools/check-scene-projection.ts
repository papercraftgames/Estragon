/** E08 focused direct-Yarn native nested-host layout/render/input acceptance. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,copyTree,runCommand,writeJSON,gitHead,gitDirty,sha256,ERROR} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
const editor=process.argv.includes("--editor");
const options=parseCLI(process.argv.slice(2).filter(a=>!['--editor'].includes(a)));
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
  async function run(name:string,args:string[],marker?:string,env=box.env,negative=false){
   const result=await runCommand(args,name==="install"?box.project:box.workspace,env,path.join(out,name+'.log'),marker,{abortOnError:!negative,expectedErrors:negative,timeout:60000});if(negative){const log=fs.readFileSync(path.join(out,name+'.log'),'utf8');result.unexpected_errors=log.split(/\r?\n/).filter(line=>ERROR.test(line)&&!/^ERROR: (?:An EditorPlugin build callback failed\.|(?:app\/Home\.gogo:\d+:\d+: GGX scene child referenced more than once: .*|negative\.gogo:1:1: GGX borrowed children must be persistent direct children of the rendering host: .*|Invalid composition output or foreign boundary conflict; previous tree retained))$/.test(line));if((result.unexpected_errors as string[]).length||/E08_(?:EDITOR_)?CHECK .*: false/.test(log))result.status='FAIL';}results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(fs.readFileSync(path.join(out,name+'.log'),'utf8'));if(result.status!=='PASS')throw Error('E08 '+name+' failed');
  }
  const packed=packAddon(path.join(out,'packed'),true);results.pack={status:'PASS',tarball_sha256:packed.manifest.tarball_sha256};
  fs.mkdirSync(box.project,{recursive:true});writeJSON(path.join(box.project,'package.json'),{name:'e08-native-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  copyTree(path.join(ROOT,'tests/scene_projection'),path.join(box.project,'tests/scene_projection'));
  for(const name of fs.readdirSync(path.join(box.project,'tests/scene_projection')).filter(n=>n.endsWith('.gd'))){const p=path.join(box.project,'tests/scene_projection',name);fs.writeFileSync(p,fs.readFileSync(p,'utf8').replaceAll('res://addons/estragon','res://'+addon));}
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['app']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="E08 native layout"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project];
  await run('build',[...args,'--headless','--script','res://tests/scene_projection/build.gd'],'E08_BUILD_OK');
await run('runtime',[...args,'--rendering-method','gl_compatibility','--rendering-driver','opengl3','--script','res://tests/scene_projection/runtime.gd'],'E08_RUNTIME_OK');
box.env.E08_NEGATIVE='1';
await run('negative',[...args,'--rendering-method','gl_compatibility','--rendering-driver','opengl3','--script','res://tests/scene_projection/runtime.gd'],'E08_NEGATIVE_OK',box.env,true);
delete box.env.E08_NEGATIVE;
  if(editor){
   box.env.E08_EDITOR_PROOF='1';
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/scene_projection/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   for(const name of ['editor','editor-restart'])await run(name,[...args,'--rendering-method','gl_compatibility','--rendering-driver','opengl3','--editor'],'E08_EDITOR_OK',box.env,true);
  }
  for(const [n,h]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,n))!==h)throw Error('Installed bytes/UID changed: '+n);
  writeJSON(path.join(out,'consumer.json'),{source:gitHead(),profile:'E08-scene-projection',direct_yarn:true,package_unchanged:true,tarball_sha256:packed.manifest.tarball_sha256});
 }finally{
  if(fs.existsSync(box.project))for(const name of fs.readdirSync(box.project).filter(n=>n.endsWith('.png')||['before.json','after.json','geometry.json'].includes(n)))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
  writeJSON(path.join(out,'results.json'),results);box.dispose();
 }
}
