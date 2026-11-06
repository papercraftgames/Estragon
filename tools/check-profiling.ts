/** F06: bounded warm real-Godot counters/timings; startup excluded. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, indexProject, runCommand, writeJSON, gitHead, gitDirty } from './compat-kit.ts';
const options = parseCLI(process.argv.slice(2));
fs.mkdirSync(options.output, {recursive:true});
for (const selection of options.engines) {
    const box = newSandbox(selection), out = path.join(options.output,selection.label);
    fs.mkdirSync(out,{recursive:true});
    const stages: Record<string, any> = {};
    try {
        for (const name of ['addons/estragon','examples','tests/profiling']) copyTree(path.join(ROOT,name),path.join(box.project,name));
        fs.copyFileSync(path.join(ROOT,'gogo.config.json'),path.join(box.project,'gogo.config.json'));
        fs.writeFileSync(path.join(box.project,'project.godot'),'config_version=5\n[application]\nconfig/name="F06 bounded profiling"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
        async function run(name:string, marker:string) {
            const args = [box.binary,...(name==='build'?['--headless']:[]),'--audio-driver','Dummy','--path',box.project,'--script','res://tests/profiling/'+(name==='build'?'build':'runtime')+'.gd'];
            const result = await runCommand(args,box.workspace,box.env,path.join(out,name+'.log'),marker,{abortOnError:true,timeout:360000});
            stages[name]=result;
            process.stdout.write(fs.readFileSync(path.join(out,name+'.log'),'utf8'));
            writeJSON(path.join(out,'results.json'),stages);
            if(result.status!=='PASS') throw Error('Profiling '+name+' failed');
        }
        await run('build','PROFILING_BUILD_OK');
        stages.import = await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
        if(stages.import.status!=='PASS') throw Error('Profiling import failed');
        await run('runtime','PROFILING_RUNTIME_OK');
        fs.copyFileSync(path.join(box.project,'profile.json'),path.join(out,'profile.json'));
        const profile = JSON.parse(fs.readFileSync(path.join(out,'profile.json'),'utf8'));
        function percentile(values:number[], p:number) { const sorted=values.slice().sort((a,b)=>a-b); return sorted[Math.max(0,Math.ceil(sorted.length*p)-1)] ?? null; }
        const summary = profile.cases.map((entry:any)=>({name:entry.name, samples:entry.samples?.length, median_us:entry.samples?percentile(entry.samples.map((s:any)=>s.mutation_drain_us).filter((n:any)=>n!==undefined),0.5):null,min_us:entry.samples?percentile(entry.samples.map((s:any)=>s.mutation_drain_us).filter((n:any)=>n!==undefined),0):null,max_us:entry.samples?percentile(entry.samples.map((s:any)=>s.mutation_drain_us).filter((n:any)=>n!==undefined),1):null,p95_us:entry.samples?percentile(entry.samples.map((s:any)=>s.mutation_drain_us).filter((n:any)=>n!==undefined),0.95):null,first:entry.samples?.[0],last:entry.samples?.at(-1),...(!entry.samples?entry:{})}));
        writeJSON(path.join(out,'summary.json'),{engine:profile.engine,platform:profile.platform,warmup:profile.warmup,samples:profile.samples,cases:summary});
        writeJSON(path.join(out,'environment.json'),{platform:process.platform,arch:process.arch,node:process.version,runner:process.env.RUNNER_OS,graphics:'Xvfb/Mesa software native window; compiler/import startup excluded from samples'});
    } finally {if(fs.existsSync(path.join(box.project,'profile.json'))) fs.copyFileSync(path.join(box.project,'profile.json'),path.join(out,'profile.json'));writeJSON(path.join(out,'results.json'),stages);box.dispose();}
}
