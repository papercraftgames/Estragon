/** UI-05: immutable direct-Yarn native value-control acceptance. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,runCommand,writeJSON,sha256,indexProject,ERROR} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
const geometryOnly=process.argv.includes("--geometry-only");
const controlsOnly=geometryOnly||process.argv.includes("--controls-only");
const options=parseCLI(process.argv.slice(2).filter(arg=>!["--controls-only","--geometry-only"].includes(arg)),{editor:true});
if(geometryOnly&&options.editor)throw Error("Geometry-only mode is a native fixture check, not editor acceptance");
if(process.platform!=='linux')throw Error('Approved Linux engines only');
fs.mkdirSync(options.output,{recursive:true});
const packed=buttonImportsPackage(path.join(options.output,'packed'),'values');
for(const selection of options.engines){
 const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
 fs.mkdirSync(out,{recursive:true});
 try{
  async function run(name:string,args:string[],marker?:string,env=box.env){
   const editing=name.startsWith('editor'),negative=editing||name==='rejections'||name==='data-runtime';
   const result=await runCommand(args,name==='install'?box.project:box.workspace,env,path.join(out,name+'.log'),marker,{timeout:editing?360000:120000,abortOnError:!negative,expectedErrors:negative});
   const log=fs.readFileSync(path.join(out,name+'.log'),'utf8');
   if(negative){
    // Exact expected diagnostics/counts; no generic Script-error suppression.
    const allowed=editing?[/^ERROR: An EditorPlugin build callback failed\.$/]:name==='data-runtime'?[
     /^ERROR: ArrayCollection: ArrayCollection\[1\]\.id: incompatible value type 4$/,
     /^ERROR: ArrayCollection: insert index out of range$/,
     /^ERROR: fixture\.gogo:1:1\.items\[1\]: unknown field unknown$/,
     /^ERROR: Invalid composition output or foreign boundary conflict; previous tree retained$/,
    ]:[
     /^ERROR: examples\/values\/Values\.gogo:\d+:\d+(?: \(spread key '[^']+'\))?: attribute '[^']+': .+; previous tree retained$/,
     /^ERROR: Estragon numeric (?:step|value): .+$/,
     /^ERROR: examples\/values\/Negative\.gogo:10:\d+: .+; previous tree retained$/,
    ];
    const counts=allowed.map(()=>0),unexpected:string[]=[];
    for(const line of log.split(/\r?\n/))if(ERROR.test(line)){
     const index=allowed.findIndex(pattern=>pattern.test(line));
     if(index<0)unexpected.push(line);else counts[index]=(counts[index]??0)+1;
    }
    const expected=editing?[name==='editor'?4:0]:name==='data-runtime'?[1,1,1,1]:[11,2,3];
    if(unexpected.length||counts.some((count,index)=>count!==expected[index])){result.status='FAIL';result.reason=JSON.stringify({unexpected,counts,expected});}
   }
   results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
   if(result.status!=='PASS')throw Error('UI05 '+name+' failed: '+result.reason);
  }
  writeJSON(path.join(out,'provenance.json'),{...packed.manifest,engine:box.version,binary_sha256:box.inputHash,command:process.argv});
  fs.mkdirSync(box.project,{recursive:true});
  writeJSON(path.join(box.project,'package.json'),{name:'values-consumer',private:true,packageManager:'yarn@1.22.22'});
  await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
  const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
  const suites=controlsOnly?['value']:['value','radio','input','checkbox','focus','data'];
  for(const suite of suites){
   for(const folder of ['tests/'+suite,...(suite==='focus'?[]:['examples/'+(suite==='value'?'values':suite)])]){
    fs.mkdirSync(path.join(box.project,folder),{recursive:true});
    for(const entry of fs.readdirSync(path.join(ROOT,folder),{withFileTypes:true}))if(entry.isFile()){
     const fixtures=suite==='input'?['frontend','game','scene']:suite==='checkbox'?['game','scene']:suite==='radio'?['game','scene']:suite==='data'?['frontend','runtime']:['runtime'];
     if(folder.startsWith('tests/')&&suite!=='value'&&!fixtures.some(name=>[name+'.gd',name+'.gd.uid'].includes(entry.name)))continue;
     let text=fs.readFileSync(path.join(ROOT,folder,entry.name),'utf8').replaceAll('res://addons/estragon','res://'+addon);
     if(entry.name.endsWith('.gogo'))text=text.replaceAll('../../../addons/estragon','../../../'+addon);
     if(folder.startsWith('examples/')&&entry.name.endsWith('.gd'))text=text.replaceAll('../../addons/estragon','../../'+addon);
     if(folder.startsWith('tests/')&&suite!=='value')text=text.replaceAll('app/','examples/'+suite+'/');
     if(suite==='value'&&entry.name==='Values.gogo')text+='\nfunc _ready() -> void:\n    if OS.get_environment("UI05_EDITOR")=="1": _value_probe.call_deferred()\nfunc _value_probe() -> void:\n    var probe=preload("res://tests/value/game.gd").new()\n    var result=await probe.run(self)\n    var file=FileAccess.open("res://.godot/ui05-game.json",FileAccess.WRITE)\n    file.store_string(JSON.stringify(result))\n    file.close()\n';
     fs.writeFileSync(path.join(box.project,folder,entry.name),text);
    }
    if(folder.startsWith('examples/')){
     fs.mkdirSync(path.join(box.project,folder,'generated'),{recursive:true});
     for(const name of fs.readdirSync(path.join(ROOT,folder,'generated')).filter(name=>name.endsWith('.gd.uid')))fs.copyFileSync(path.join(ROOT,folder,'generated',name),path.join(box.project,folder,'generated',name));
    }
   }
  }
  if(!controlsOnly){
  fs.mkdirSync(path.join(box.project,'examples/scrollbars/generated'),{recursive:true});
  for(const entry of fs.readdirSync(path.join(ROOT,'examples/scrollbars'),{withFileTypes:true}))if(entry.isFile())fs.writeFileSync(path.join(box.project,'examples/scrollbars',entry.name),fs.readFileSync(path.join(ROOT,'examples/scrollbars',entry.name),'utf8').replaceAll('../../../addons/estragon','../../../'+addon));
  for(const name of fs.readdirSync(path.join(ROOT,'examples/scrollbars/generated')).filter(name=>name.endsWith('.gd.uid')))fs.copyFileSync(path.join(ROOT,'examples/scrollbars/generated',name),path.join(box.project,'examples/scrollbars/generated',name));
  }
  for(const file of ['examples/godot_button.gd','examples/godot_button.gd.uid',...(!controlsOnly?['tests/responsive/math.gd','tests/responsive/math.gd.uid','tests/responsive/constraints.gd','tests/responsive/constraints.gd.uid','tests/scrollbars/placement_runtime.gd','tests/scrollbars/placement_runtime.gd.uid','tests/scrollbars/placement_game.gd','tests/scrollbars/placement_game.gd.uid','tests/scrollbars/game.gd','tests/scrollbars/game.gd.uid']:[])]){
   const target=path.join(box.project,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,fs.readFileSync(path.join(ROOT,file),'utf8').replaceAll('res://addons/estragon','res://'+addon).replaceAll('app/','examples/scrollbars/'));
  }
  writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:[...suites.filter(suite=>suite!=='focus').map(suite=>'examples/'+(suite==='value'?'values':suite)),...(!controlsOnly?['examples/scrollbars']:[])]});
  fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="UI05 native choices"\nrun/main_scene="res://examples/values/Values.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=840\nwindow/size/viewport_height=840\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
  if(geometryOnly){
   await run('geometry',[...args,...graphics,'--script','res://tests/value/geometry.gd'],'UI05_GEOMETRY_OK');
   for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes changed: '+file);
   writeJSON(path.join(out,'summary.json'),{status:'PASS',scope:'geometry-only',checks:results,tarball_sha256:packed.manifest.tarball_sha256,canonical_uids:packed.manifest.canonical_uids,installed_bytes_unchanged:true});
   continue;
  }
  await run('build',[...args,'--headless','--script','res://tests/value/build.gd'],'UI05_BUILD_OK');
  for(const [name,script,marker]of [
   ['frontend','tests/value/frontend.gd','UI05_FRONTEND_OK'],
   ...(!controlsOnly?[['input-frontend','tests/input/frontend.gd','UI03_FRONTEND_OK'],
   ['data-frontend','tests/data/frontend.gd','CORE02_FRONTEND_OK'],
   ['data-runtime','tests/data/runtime.gd','CORE02_RUNTIME_OK'],
   ['layout-math','tests/responsive/math.gd','L0910_MATH_OK'],
   ['layout-native','tests/responsive/constraints.gd','LAYOUT01_NATIVE_OK']]:[]),
  ])await run(name!,[...args,'--headless','--script','res://'+script],marker);
  for(const [name,script,marker]of [
   ['graphics','tests/value/scene.gd','UI05_GRAPHICS_OK'],
   ['wheel','tests/value/wheel.gd','UI05_WHEEL_OK'],
   ['geometry','tests/value/geometry.gd','UI05_GEOMETRY_OK'],
   ['rejections','tests/value/rejections.gd','UI05_REJECTIONS_OK'],
   ...(!controlsOnly?[['radio-native','tests/radio/scene.gd','UI04_GRAPHICS_OK'],
   ['input-native','tests/input/scene.gd','UI03_SCENE_OK'],
   ['checkbox-native','tests/checkbox/scene.gd','UI02_SCENE_OK'],
   ['focus-native','tests/focus/runtime.gd','UI01_RUNTIME_OK'],
   ['scrollbar-native','tests/scrollbars/placement_runtime.gd','U04_NATIVE_OK']]:[]),
  ])await run(name!,[...args,...graphics,'--script','res://'+script],marker);
  if(options.editor){
   writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['examples/values']});
   results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
   if(results.import.status!=='PASS')throw Error('UI05 clean import failed');
   fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
   fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
   fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/value/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
   box.env.UI05_EDITOR='1';
   for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'UI05_EDITOR_OK');
  }
  for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed bytes/UID changed: '+file);
  for(const name of ['Values','Model','Item']){
   const generated=path.join(box.project,'examples/values/generated',name+'.gd'),source=path.join(box.project,'examples/values',name+'.gogo'),map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
   if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.generatedHash!==sha256(generated)||map.sourceName!=='examples/values/'+name+'.gogo'||sha256(generated+'.uid')!==sha256(path.join(ROOT,'examples/values/generated',name+'.gd.uid')))throw Error('Stale map or changed UID '+name);
   writeJSON(path.join(out,name+'-map.json'),{source:sha256(source),generated:sha256(generated),map:sha256(generated+'.map.json'),uid:sha256(generated+'.uid'),verified:true});
  }
  for(const name of fs.readdirSync(box.project).filter(name=>name.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
  writeJSON(path.join(out,'summary.json'),{status:'PASS',scope:controlsOnly?'controls-only':'full',checks:results,tarball_sha256:packed.manifest.tarball_sha256,canonical_uids:packed.manifest.canonical_uids,installed_bytes_unchanged:true,manual_interactive_smoke:'UNTESTED',os_ime:'UNTESTED',assistive_technology:'UNTESTED'});
 }finally{box.dispose();}
}
console.log('UI05_ACCEPTANCE_OK');
