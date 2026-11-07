/** Routine PR/main checks are never release certification. */
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
// Development-only --suites remains available, never used by routine workflows.
export const SUITES=['compiler','runtime','ggx','ui','metadata','distribution','bindable','reactive','composition','conditional','lists','twoway','profiling','package'] as const;
export type Suite=typeof SUITES[number];
export function planCI(_event:string,files:string[]) {
    const docs=files.length>0 && files.every(file=>/^(docs\/.*\.(md|png|jpg|jpeg|svg|webp|gif|txt)|README\.md|AGENTS\.md|CONTRIBUTING\.md|LICENSE)$/.test(file));
    return {mode:'routine',native:!docs,smoke:docs?'none':'compiler-bindable',budget_seconds:60};
}
if(import.meta.url==='file://'+process.argv[1]) {
    const event=process.env.GITHUB_EVENT_NAME||'',payload=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH!,'utf8'));
    let files:string[]=[];
    const base=event==='pull_request'?payload.pull_request?.base?.sha:payload.before;
    const head=event==='pull_request'?payload.pull_request?.head?.sha:payload.after;
    if(base && head && /^[a-f0-9]{40}$/.test(base) && !/^0+$/.test(base) && /^[a-f0-9]{40}$/.test(head))files=execFileSync('git',['diff','--name-only','--no-renames','-z',event==='pull_request'?base+'...'+head:base+'..'+head],{encoding:'utf8'}).split('\0').filter(Boolean);
    else if(event==='pull_request')throw Error('Exact PR base/head required');
    const plan=planCI(event,files);
    if(process.env.GITHUB_OUTPUT)fs.appendFileSync(process.env.GITHUB_OUTPUT,'native='+plan.native+'\n');
    console.log(JSON.stringify({event,files,...plan},null,2));
}
