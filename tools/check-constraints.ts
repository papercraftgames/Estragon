/** LAYOUT-01 mode of check-responsive.ts; one immutable direct-Yarn consumer. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256, indexProject} from './compat-kit.ts';
import {buttonImportsPackage} from './button-imports-package.ts';
export async function runConstraints(argv:string[]){
 const editor=argv.includes('--editor'),options=parseCLI(argv.filter(a=>a!=='--editor'));
 if(process.platform!=='linux')throw Error('Approved Linux engines only');
 fs.mkdirSync(options.output,{recursive:true});
 const packed=buttonImportsPackage(path.join(options.output,'packed'),'constraint-layout');
 for(const selection of options.engines){
  const box=newSandbox(selection),out=path.join(options.output,selection.label),results:Record<string,any>={};
  fs.mkdirSync(out,{recursive:true});
  try{
   writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,binary_sha256:box.inputHash,command:process.argv,tarball_sha256:packed.manifest.tarball_sha256});
   async function run(name:string,args:string[],marker?:string,env=box.env){
    const editing=name.startsWith('editor'),negative=name==='data-runtime'||editing,logFile=path.join(out,name+'.log');
    const result=await runCommand(args,name==='install'?box.project:box.workspace,env,logFile,marker,{abortOnError:!negative,expectedErrors:negative,timeout:editing?360000:60000});
    const log=fs.readFileSync(logFile,'utf8');
    if(negative){
     const allowed=editing?[/^ERROR: An EditorPlugin build callback failed\.$/]:[
      /^ERROR: ArrayCollection: ArrayCollection\[1\]\.id: incompatible value type 4$/,
      /^ERROR: ArrayCollection: insert index out of range$/,
      /^ERROR: fixture\.gogo:1:1\.items\[1\]: unknown field unknown$/,
      /^ERROR: Invalid composition output or foreign boundary conflict; previous tree retained$/,
     ];
     const counts=allowed.map(()=>0),unexpected:string[]=[];
     for(const line of log.split(/\r?\n/))if(ERROR.test(line)){
      const index=allowed.findIndex(re=>re.test(line));
      if(index<0)unexpected.push(line);else counts[index]=(counts[index]??0)+1;
     }
     const expected=editing?(name==='editor'?4:0):1;
     if(unexpected.length||counts.some(count=>count!==expected)){result.status='FAIL';result.reason=JSON.stringify({unexpected,counts,expected});}
    }
    results[name]=result;writeJSON(path.join(out,'results.json'),results);process.stdout.write(log);
    if(result.status!=='PASS')throw Error('LAYOUT01 '+name+' failed: '+result.reason);
   }
   fs.mkdirSync(box.project,{recursive:true});
   writeJSON(path.join(box.project,'package.json'),{name:'constraint-layout-consumer',private:true,packageManager:'yarn@1.22.22'});
   await run('install',['corepack','yarn@1.22.22','add','--offline','--exact','--ignore-scripts','--non-interactive','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+packed.tarball],undefined,process.env);
   const addon='node_modules/@papercraftgames/estragon/addons/estragon',installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
   for(const folder of ['tests/responsive','tests/data','examples/constraint_layout','examples/data']){
    fs.mkdirSync(path.join(box.project,folder),{recursive:true});
    for(const entry of fs.readdirSync(path.join(ROOT,folder),{withFileTypes:true}))if(entry.isFile()){
     if(folder==='tests/responsive'&&!entry.name.startsWith('constraint')&&!['math.gd','math.gd.uid'].includes(entry.name))continue;
     let text=fs.readFileSync(path.join(ROOT,folder,entry.name),'utf8').replaceAll('res://addons/estragon','res://'+addon);
     if(entry.name.endsWith('.gogo'))text=text.replaceAll('../../../addons/estragon','../../../'+addon);
     if(folder==='examples/constraint_layout'&&entry.name==='Constraints.gogo')text+='\nfunc _ready() -> void:\n    if OS.get_environment("LAYOUT01_EDITOR")=="1":\n        _constraint_probe.call_deferred()\nfunc _constraint_probe() -> void:\n    var probe=preload("res://tests/responsive/constraint_game.gd").new()\n    var result=await probe.run(self)\n    var file=FileAccess.open("res://.godot/layout01-game.json",FileAccess.WRITE)\n    file.store_string(JSON.stringify(result))\n    file.close()\n';
     fs.writeFileSync(path.join(box.project,folder,entry.name),text);
    }
    if(folder.startsWith('examples/')){
     fs.mkdirSync(path.join(box.project,folder,'generated'),{recursive:true});
     for(const name of fs.readdirSync(path.join(ROOT,folder,'generated')).filter(name=>name.endsWith('.gd.uid')))fs.copyFileSync(path.join(ROOT,folder,'generated',name),path.join(box.project,folder,'generated',name));
    }
   }
   for(const file of ['tests/lengths/proportions.gd','tests/lengths/proportions.gd.uid','tests/scrollbars/geometry.gd','tests/scrollbars/geometry.gd.uid','tests/scrollbars/placement_geometry.gd','tests/scrollbars/placement_geometry.gd.uid','tests/scrollbars/placement_runtime.gd','tests/scrollbars/placement_runtime.gd.uid','tests/scrollbars/placement_game.gd','tests/scrollbars/placement_game.gd.uid','tests/scrollbars/game.gd','tests/scrollbars/game.gd.uid']){
    const target=path.join(box.project,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,fs.readFileSync(path.join(ROOT,file),'utf8').replaceAll('res://addons/estragon','res://'+addon));
   }
   fs.mkdirSync(path.join(box.project,'app/generated'),{recursive:true});
   for(const name of ['Scrollbars','ScrollPanel']){
    fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),fs.readFileSync(path.join(ROOT,'examples/scrollbars',name+'.gogo'),'utf8').replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon)));
    fs.copyFileSync(path.join(ROOT,'examples/scrollbars/generated',name+'.gd.uid'),path.join(box.project,'app/generated',name+'.gd.uid'));
   }
   writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['examples/constraint_layout','examples/data','app']});
   fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="LAYOUT01 native constraints"\nrun/main_scene="res://examples/constraint_layout/Constraints.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=460\nwindow/size/viewport_height=420\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
   const args=[box.binary,'--audio-driver','Dummy','--path',box.project],graphics=['--rendering-method','gl_compatibility','--rendering-driver','opengl3'];
   await run('build',[...args,'--headless','--script','res://tests/responsive/constraint_build.gd'],'LAYOUT01_BUILD_OK');
   for(const [name,script,marker]of [
    ['math','tests/responsive/math.gd','L0910_MATH_OK'],
    ['constraints','tests/responsive/constraints.gd','LAYOUT01_NATIVE_OK'],
    ['l12','tests/lengths/proportions.gd','L12_PERCENT_OK'],
    ['gutters','tests/scrollbars/geometry.gd','U03_MATH_OK'],
    ['chrome','tests/scrollbars/placement_geometry.gd','U04_MATH_OK'],
    ['data-frontend','tests/data/frontend.gd','CORE02_FRONTEND_OK'],
    ['data-runtime','tests/data/runtime.gd','CORE02_RUNTIME_OK'],
   ])await run(name!,[...args,'--headless','--script','res://'+script],marker);
   await run('graphics',[...args,...graphics,'--script','res://tests/responsive/constraint_graphics.gd'],'LAYOUT01_GRAPHICS_OK');
   await run('chrome-native',[...args,...graphics,'--script','res://tests/scrollbars/placement_runtime.gd'],'U04_NATIVE_OK');
   if(editor){
    results.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
    writeJSON(path.join(out,'results.json'),results);
    if(results.import.status!=='PASS')throw Error('LAYOUT01 clean import failed');
    fs.mkdirSync(path.join(box.project,'.godot/editor'),{recursive:true});
    fs.writeFileSync(path.join(box.project,'.godot/editor/project_metadata.cfg'),'[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
    fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://'+addon+'/editor/plugin.cfg", "res://tests/responsive/constraint_plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
    box.env.LAYOUT01_EDITOR='1';
    for(const stage of ['editor','editor-restart'])await run(stage,[...args,...graphics,'--editor'],'LAYOUT01_EDITOR_OK');
   }
   for(const [file,hash]of Object.entries(packed.manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Installed package changed: '+file);
   for(const folder of ['examples/constraint_layout','examples/data'])for(const name of fs.readdirSync(path.join(ROOT,folder)).filter(name=>name.endsWith('.gogo'))){
    const generated=path.join(box.project,folder,'generated',name.replace(/\.gogo$/,'.gd')),source=path.join(box.project,folder,name);
    const map=JSON.parse(fs.readFileSync(generated+'.map.json','utf8'));
    if(map.sourceContent!==fs.readFileSync(source,'utf8')||map.sourceName!==folder+'/'+name||map.generatedHash!==sha256(generated))throw Error('Stale constraint map '+name);
    if(sha256(generated+'.uid')!==sha256(path.join(ROOT,folder,'generated',path.basename(generated)+'.uid')))throw Error('Constraint UID changed '+name);
    writeJSON(path.join(out,path.basename(folder)+'-'+path.basename(generated)+'-map.json'),{source:sha256(source),generated:sha256(generated),map:sha256(generated+'.map.json'),uid:sha256(generated+'.uid'),verified:true});
   }
   for(const name of fs.readdirSync(box.project).filter(name=>/^constraint-layout-\d+\.png$/.test(name)))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
   writeJSON(path.join(out,'summary.json'),{status:'PASS',checks:results,installed_bytes_unchanged:true,manual_interactive_smoke:'UNTESTED',os_ime:'UNTESTED'});
  }finally{box.dispose();}
 }
 console.log('LAYOUT01_ACCEPTANCE_OK');
}
