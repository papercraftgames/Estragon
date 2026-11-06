/** Read one completed run; no polling or reruns. Queue reported separately. */
import { execFileSync } from 'node:child_process';
export function measureRoutine(run:any,jobs:any[]) {
    const required=['tooling','addon (4.0.4)','addon (4.7)'].map(name=>{
        const matches=jobs.filter(job=>job.name===name);
        if(matches.length!==1 || matches[0].status!=='completed' || matches[0].conclusion!=='success')throw Error('Routine required check incomplete/failed: '+name);
        return matches[0];
    });
    const start=Math.min(...required.map(j=>Date.parse(j.started_at)));
    const end=Math.max(...required.map(j=>Date.parse(j.completed_at)));
    if(!Number.isFinite(start)||!Number.isFinite(end))throw Error('Missing actual job timestamps');
    return {
        run:run.id,event:run.event,head:run.head_sha,
        queue_seconds:(start-Date.parse(run.created_at))/1000,
        execution_wall_seconds:(end-start)/1000,budget_seconds:60,within_budget:end-start<=60000,
        jobs:required.map(j=>({
            name:j.name,seconds:(Date.parse(j.completed_at)-Date.parse(j.started_at))/1000,
            steps:j.steps.filter((s:any)=>s.started_at&&s.completed_at).map((s:any)=>({
                name:s.name,seconds:(Date.parse(s.completed_at)-Date.parse(s.started_at))/1000,
            })),
        })),
    };
}
if(import.meta.url==='file://'+process.argv[1]) {
    const runId=process.argv[2];if(!runId||!/^\d+$/.test(runId))throw Error('Completed run ID required');
    const api=(route:string)=>JSON.parse(execFileSync('gh',['api','repos/papercraftgames/Estragon/actions/'+route],{encoding:'utf8'}));
    const report=measureRoutine(api('runs/'+runId),api('runs/'+runId+'/jobs?filter=latest&per_page=100').jobs);
    console.log(JSON.stringify(report,null,2));if(!report.within_budget)process.exitCode=1;
}
