/** Suite/stage/editor timing and observed launch telemetry, outside release stage results. */
import * as fs from 'node:fs';
import * as path from 'node:path';
export function collectMetrics(output:string,suites:Array<{name:string;seconds:number;exit_code:number|null}>) {
    const stages:any[]=[];
    function visit(dir:string) {
        for(const entry of fs.readdirSync(dir,{withFileTypes:true})) {
            const file=path.join(dir,entry.name);
            if(entry.isDirectory())visit(file);
            else if(entry.name==='results.json') {
                const results=JSON.parse(fs.readFileSync(file,'utf8'));
                for(const [name,value]of Object.entries(results)) {
                    const stage=value as any;if(!stage || typeof stage!=='object' || !stage.command)continue;
                    const log=stage.log?path.join(dir,stage.log):'';
                    const text=log && fs.existsSync(log)?fs.readFileSync(log,'utf8'):'';
                    stages.push({suite:path.relative(output,file).split('/')[0],stage:name,seconds:stage.seconds,status:stage.status,
                        // Exact directly spawned command PID; banners include nested editor/game processes and are diagnostic only.
                        direct_godot_command:path.basename(stage.command[0])==='godot',direct_godot_pid:stage.godot_pid??null,observed_startup_banners:(text.match(/^Godot Engine v/gm)||[]).length,
                        editor_scenarios:[...text.matchAll(/^CI_EDITOR_TIMING (.+) ([0-9.]+)$/gm)].map(m=>({scenario:m[1],seconds:Number(m[2])}))});
                }
            }
        }
    }
    visit(output);
    return {suites,stages,total_suite_seconds:suites.reduce((n,s)=>n+s.seconds,0),direct_godot_commands:stages.filter(s=>s.direct_godot_command).length,recorded_godot_pids:stages.filter(s=>s.direct_godot_pid).length,
        observed_startup_banners:stages.reduce((n,s)=>n+s.observed_startup_banners,0),
        launch_count_scope:'direct runCommand Godot PIDs only; --version probes and nested semantic/editor/game processes excluded. Startup banners are not unique process counts.'};
}

if(import.meta.url==='file://'+process.argv[1]) {
    const [input,output]=process.argv.slice(2);if(!input||!output)throw Error('Usage: ci-metrics.ts EVIDENCE_DIRECTORY OUTPUT_JSON');
    fs.writeFileSync(output,JSON.stringify(collectMetrics(input,[]),null,2)+'\n');
}
