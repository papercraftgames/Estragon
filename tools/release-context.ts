/** Pure release authorization/selection rules shared by preparation and publishing. */
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
import { ROOT, gitHead, gitDirty } from './compat-kit.ts';
import { addonVersion } from './package-version.ts';
export const REPOSITORY='papercraftgames/Estragon';
export function releaseContext(event:any, eventName:string, ref:string, version:string, source={head:gitHead(),dirty:gitDirty()}, tagHead=source.head, onMain=true) {
    if(event.repository?.full_name!==REPOSITORY || source.dirty || !onMain || !/^0\.\d+\.\d+-beta\.\d+$/.test(version))throw Error('Canonical clean reviewed main prerelease required');
    if(eventName==='workflow_dispatch' && ref==='refs/heads/main')return {mode:'preview',version,sourceHead:source.head,tag:null,release_id:null};
    const release=event.release;
    if(eventName!=='release' || event.action!=='published' || !release?.id || release.draft!==false || release.prerelease!==true || release.tag_name!=='v'+version || ref!=='refs/tags/'+release.tag_name || tagHead!==source.head)throw Error('Published GitHub prerelease must match exact reviewed version/tag/source');
    return {mode:'release',version,sourceHead:source.head,tag:release.tag_name,release_id:release.id};
}
export function currentContext() {
    const event=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH!,'utf8'));
    const version=addonVersion();
    let onMain=false;
    try {execFileSync('git',['merge-base','--is-ancestor',gitHead(),'origin/main'],{cwd:ROOT,stdio:'pipe'});onMain=true;}catch{}
    const tagHead=event.release?.tag_name && /^v0\.\d+\.\d+-beta\.\d+$/.test(event.release.tag_name)?execFileSync('git',['rev-parse','refs/tags/'+event.release.tag_name+'^{commit}'],{cwd:ROOT,encoding:'utf8'}).trim():gitHead();
    return releaseContext(event,process.env.GITHUB_EVENT_NAME||'',process.env.GITHUB_REF||'',version,undefined,tagHead,onMain);
}
export function selectVerificationRun(runs:any[],head:string) {
    // Select newest exact-source main push, never fall back to a prior green run.
    const matching=runs.filter(run=>run.head_sha===head && run.head_branch==='main' && run.event==='push' && run.path==='.github/workflows/ci.yml').sort((a,b)=>b.id-a.id);
    const run=matching[0];
    if(!run || run.status!=='completed')return null;
    if(run.conclusion!=='success')throw Error('Newest exact main CI is not successful');
    return run;
}
