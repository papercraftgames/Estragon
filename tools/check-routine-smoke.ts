/** One cold native process; no editor/import/rendering/full-suite orchestration. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, runCommand, writeJSON } from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));
if(options.engines.length!==1 || options.engines[0]!.label!=='4.7')throw Error('Routine smoke uses pinned Linux4.7 only');
const box=newSandbox(options.engines[0]!);
try {
    copyTree(path.join(ROOT,'addons/estragon'),path.join(box.project,'addons/estragon'));
    fs.mkdirSync(path.join(box.project,'tests/native_compiler'),{recursive:true});
    for(const file of ['smoke.gd','smoke.gd.uid'])fs.copyFileSync(path.join(ROOT,'tests/native_compiler',file),path.join(box.project,'tests/native_compiler',file));
    fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n');
    const stage=await runCommand([box.binary,'--headless','--audio-driver','Dummy','--path',box.project,'--script','res://tests/native_compiler/smoke.gd'],box.workspace,box.env,path.join(options.output,'smoke.log'),'ROUTINE_SMOKE_OK',{timeout:10000,abortOnError:true});
    process.stdout.write(fs.readFileSync(path.join(options.output,'smoke.log'),'utf8'));
    writeJSON(path.join(options.output,'routine-smoke.json'),stage);
    if(stage.status!=='PASS')throw Error('Routine native smoke failed');
}finally{box.dispose();}
