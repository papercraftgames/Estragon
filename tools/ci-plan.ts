/** Conservative PR selection. A focused plan is never release-certification evidence. */
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
export const SUITES=['compiler','runtime','ggx','ui','metadata','distribution','bindable','reactive','composition','conditional','lists','twoway','profiling','package'] as const;
export type Suite=typeof SUITES[number];
export function planCI(event:string, files:string[]) {
    if(event!=='pull_request')return {mode:'acceptance',suites:[...SUITES],native:true};
    const selected=new Set<Suite>();
    for(const file of files) {
        if(/^(docs\/.*\.md|README\.md|AGENTS\.md|CONTRIBUTING\.md|LICENSE)$/.test(file))continue;
        const match=/^tests\/(native_compiler|node_runtime|native_ui|ggx|metadata|distribution|bindable|reactive|composition|conditional|lists|twoway|profiling|package-consumer)\//.exec(file);
        if(match){const aliases:Record<string,Suite>={native_compiler:'compiler',node_runtime:'runtime',native_ui:'ui','package-consumer':'package'};selected.add(aliases[match[1]!]||match[1] as Suite);continue;}
        const example=/^examples\/(counter|node_runtime|ggx|bindable|reactive|composition|conditional|inventory|twoway)\//.exec(file);
        if(example){const map:Record<string,Suite>={counter:'ui',node_runtime:'runtime',inventory:'lists'};selected.add(map[example[1]!]||example[1] as Suite);selected.add('distribution');continue;}
        if(file.startsWith('addons/estragon/compiler/')){for(const s of ['compiler','ggx','ui','bindable'] as const)selected.add(s);continue;}
        if(file.startsWith('addons/estragon/editor/')){for(const s of ['compiler','ui','package'] as const)selected.add(s);continue;}
        if(file.startsWith('addons/estragon/runtime/composition/')){for(const s of ['composition','conditional','lists','twoway','profiling'] as const)selected.add(s);continue;}
        if(file.startsWith('addons/estragon/runtime/node/')){for(const s of ['runtime','ggx','ui','twoway'] as const)selected.add(s);continue;}
        if(file.startsWith('packages/estragon/') || /^tools\/(pack-addon|package-version|.*npm-release|.*published-package|publish-prepared|registry-package|release-context)\.ts$/.test(file)){selected.add('package');continue;}
        // Infrastructure has its own policy tests plus representative native/editor/package proof.
        if(/^\.github\/workflows\//.test(file) || /^tools\/(ci-plan|ci-metrics|verified-engine|download-compat-engine|check-native-addon)\.ts$/.test(file) || /^tests\/compatibility\/(ci|npm-release|package).*\.test\.ts$/.test(file)){for(const s of ['compiler','ui','package'] as const)selected.add(s);continue;}
        const tool=/^tools\/check-(node-runtime|native-ui|compatibility|godot-metadata|[a-z]+)\.ts$/.exec(file);
        if(tool){const map:Record<string,Suite>={'node-runtime':'runtime','native-ui':'ui',compatibility:'compiler','godot-metadata':'metadata'};const suite=map[tool[1]!]||tool[1] as Suite;if(SUITES.includes(suite)){selected.add(suite);continue;}}
        // Shared helpers, unknown paths, deleted/renamed destinations fail toward broad coverage.
        for(const s of SUITES)selected.add(s);
    }
    return {mode:'focused',suites:SUITES.filter(s=>selected.has(s)),native:selected.size>0};
}
if(import.meta.url==='file://'+process.argv[1]) {
    const event=process.env.GITHUB_EVENT_NAME||'';
    let files:string[]=[];
    if(event==='pull_request') {
        const payload=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH!,'utf8'));
        const base=payload.pull_request?.base?.sha,head=payload.pull_request?.head?.sha;
        if(!/^[a-f0-9]{40}$/.test(base)||!/^[a-f0-9]{40}$/.test(head))throw Error('Exact PR base/head required');
        // --no-renames includes both old and new paths, preventing a renamed code file being treated as docs.
        files=execFileSync('git',['diff','--name-only','--no-renames','-z',base+'...'+head],{encoding:'utf8'}).split('\0').filter(Boolean);
        if(!files.length)throw Error('PR changes unavailable; refusing empty plan');
    }
    const plan=planCI(event,files);
    if(process.env.GITHUB_OUTPUT)fs.appendFileSync(process.env.GITHUB_OUTPUT,'native='+plan.native+'\nsuites='+plan.suites.join(',')+'\n');
    console.log(JSON.stringify({event,files,...plan},null,2));
}
