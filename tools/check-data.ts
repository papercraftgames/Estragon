/** CORE-02 immutable direct-Yarn native data/compiler/graphics/editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const editor=process.argv.includes('--editor');
const options=parseCLI(process.argv.slice(2).filter(a=>a!=='--editor'));
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,'packed'),'core-data');
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,binary_sha256:box.inputHash,command:process.argv,tarball_sha256:packed.manifest.tarball_sha256});
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const editing=name.startsWith('editor'),negative=name==='runtime'||editing,logFile=path.join(out,name+'.log');
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!negative,expectedErrors:negative,timeout:editing?360000:60000});
   const log=fs.readFileSync(logFile,'utf8');
   if(negative){
    const allowed=name==='runtime'?[
     /^ERROR: ArrayCollection: ArrayCollection\[1\]\.id: incompatible value type 4$/,
     /^ERROR: ArrayCollection: insert index out of range$/,
     /^ERROR: fixture\.gogo:1:1\.items\[1\]: unknown field unknown$/,
     /^ERROR: Invalid composition output or foreign boundary conflict; previous tree retained$/,
    ]:[/^ERROR: An EditorPlugin build callback failed\.$/];
    const counts=allowed.map(()=>0),unexpected:string[]=[];
    for(const line of log.split(/\r?\n/))if(ERROR.test(line)){
     const index=allowed.findIndex(re=>re.test(line));
     if(index<0)unexpected.push(line);else counts[index]=(counts[index]??0)+1;
    }
    const expected=editing?(name==='editor'?4:0):1;
    if(unexpected.length||counts.some(count=>count!==expected)){result.status='FAIL';result.reason=JSON.stringify({unexpected,counts,expected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('CORE02 '+name+' failed: '+result.reason);
  }
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'core-data-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  for(const folder of ['tests/data','examples/data']){
   fs.mkdirSync(path.join(box.project,folder),{recursive:true});
   for(const entry of fs.readdirSync(path.join(ROOT,folder),{withFileTypes:true}))if(entry.isFile()){
    let text=fs.readFileSync(path.join(ROOT,folder,entry.name),'utf8').replaceAll('res://addons/estragon','res://'+addon);
    if(entry.name.endsWith('.gogo'))text=text.replaceAll('../../../addons/estragon','../../../'+addon);
    if(entry.name==='Gallery.gogo')text+='\nfunc _ready() -> void:\n    if OS.get_environment("CORE02_EDITOR")=="1": _data_probe.call_deferred()\nfunc _data_probe() -> void:\n    var probe=preload("res://tests/data/game.gd").new()\n    var result=await probe.run(self)\n    var file=FileAccess.open("res://.godot/core02-game.json",FileAccess.WRITE)\n    file.store_string(JSON.stringify(result))\n    file.close()\n';
    fs.writeFileSync(path.join(box.project,folder,entry.name),text);
   }
  }
  fs.mkdirSync(path.join(box.project,'examples/data/generated'),{recursive:true});
  for(const name of ['Details','Item','Inventory','Gallery'])fs.copyFileSync(path.join(ROOT,'examples/data/generated',name+'.gd.uid'),path.join(box.project,'examples/data/generated',name+'.gd.uid'));
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['examples/data']});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="CORE02 native data"\nrun/main_scene="res://examples/data/Gallery.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  fs.writeFileSync(path.join(box.project,'examples/data/Gallery.tscn'),'[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://examples/data/generated/Gallery.gd" id="1"]\n[node name="Gallery" type="Node2D"]\nscript = ExtResource("1")\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  await run('build',[...args,'--headless','--script','res://tests/data/build.gd'],'CORE02_BUILD_OK');
  for(const [name,marker]of [['frontend','CORE02_FRONTEND_OK'],['runtime','CORE02_RUNTIME_OK'],['integration','CORE02_INTEGRATION_OK']])await run(name!,[...args,...graphics,'--script','res://tests/data/'+name+'.gd'],marker);
  if(editor){
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   writeJSON(path.join(out,'results.json'),results);
   if(results.import.status!=='PASS')throw Error('CORE02 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/data/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.CORE02_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'CORE02_EDITOR_OK');
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed package changed: '+file);
  for(const name of ['Details','Item','Inventory','Gallery']){
   const generated=path.join(box.project,'examples/data/generated',name+'.gd'),source=path.join(box.project,'examples/data',name+'.gogo');
   const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!=='examples/data/'+name+'.gogo'||map.generatedHash!==sha256(generated))throw Error('Stale data map '+name);
   if(sha256(generated+'.uid')!==sha256(path.join(ROOT,'examples/data/generated',name+'.gd.uid')))throw Error('Data UID changed '+name);
   writeJSON(path.join(out,name+'-map.json'),{source:sha256(source),generated:sha256(generated),map:sha256(generated+'.map.json'),uid:sha256(generated+'.uid'),verified:true});
  }
  for(const name of fs.readdirSync(box.project).filter(name=>/^data-game-\d+\.png$/.test(name)))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
  writeJSON(path.join(out,'summary.json'),{status:'PASS',checks:results,installed_bytes_unchanged:true,manual_interactive_smoke:'UNTESTED',os_ime:'UNTESTED'});
 }finally{box.dispose();}
}
console.log('CORE02_ACCEPTANCE_OK');
