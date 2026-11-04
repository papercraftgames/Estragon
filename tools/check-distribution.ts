/** Fresh Godot addon install/source-only rebuild/resource-pack integration. */
import * as fs from 'node:fs';import * as path from 'node:path';
import {ROOT,parseCLI,newSandbox,freshProject,copyTree,indexProject,runCommand,writeJSON,gitHead,gitDirty} from './compat-kit.ts';
import type {Stage} from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines){const box=newSandbox(selection),output=path.join(options.output,selection.label);fs.mkdirSync(output,{recursive:true});const stages:Record<string,Stage>={};
 try{
  freshProject(box,true);copyTree(path.join(ROOT,'tests/distribution'),path.join(box.project,'tests/distribution'));
  writeJSON(path.join(output,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
  const config=fs.readFileSync(path.join(box.project,'project.godot'),'utf8');
  stages.package_layout={status:config.includes('config/features=PackedStringArray("4.0", "GL Compatibility")')&&!fs.existsSync(path.join(box.project,'.godot'))?'PASS':'FAIL'};
  async function run(name:string,project:string,script:string,marker:string,extra:string[]=[]){const stage=await runCommand([box.binary,'--headless','--audio-driver','Dummy','--path',project,'--script',script,...extra],box.workspace,box.env,path.join(output,name+'.log'),marker,{abortOnError:true});const log=fs.readFileSync(path.join(output,name+'.log'),'utf8');if(/instances leaked|Resources still in use/.test(log))stage.status='FAIL';stages[name]=stage;process.stdout.write(log);writeJSON(path.join(output,'results.json'),stages);if(stage.status!=='PASS')throw Error('Addon distribution '+name+' failed');}
  stages.import=await indexProject(box,box.project,path.join(output,'import.log'),['--audio-driver','Dummy']);if(stages.import.status!=='PASS')throw Error('Native addon install import failed');
  const packUID=path.join(box.project,'tests/distribution/pack.gd.uid');if(fs.existsSync(packUID))fs.copyFileSync(packUID,path.join(output,'pack.gd.uid'));
  await run('scenes',box.project,'res://tests/distribution/scenes.gd','ADDON_DISTRIBUTION_OK');
  const cold=path.join(box.workspace,'cold');fs.cpSync(box.project,cold,{recursive:true});fs.rmSync(path.join(cold,'.godot'),{recursive:true,force:true});
  for(const name of ['counter','ggx'])fs.rmSync(path.join(cold,'examples',name,'generated'),{recursive:true,force:true});
  await run('cold_build',cold,'res://tests/distribution/build.gd','ADDON_COLD_BUILD_OK');
  await run('cold_scenes',cold,'res://tests/distribution/scenes.gd','ADDON_DISTRIBUTION_OK');
  const pack=path.join(output,'addon.pck');await run('pack_write',box.project,'res://tests/distribution/pack.gd','ADDON_PACK_OK',['--',pack]);
  const bare=path.join(box.workspace,'pack-runtime');fs.mkdirSync(bare);
  const stage=await runCommand([box.binary,'--headless','--audio-driver','Dummy','--path',bare,'--main-pack',pack,'--script','res://tests/distribution/scenes.gd'],box.workspace,box.env,path.join(output,'pack_runtime.log'),'ADDON_DISTRIBUTION_OK',{abortOnError:true});stages.pack_runtime=stage;process.stdout.write(fs.readFileSync(path.join(output,'pack_runtime.log'),'utf8'));if(stage.status!=='PASS')throw Error('Native addon pack runtime failed');
 }finally{writeJSON(path.join(output,'results.json'),stages);box.dispose();}
}
