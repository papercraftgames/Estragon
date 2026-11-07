/** Event-bound authorization is reconstructed independently in every release job. */
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
import { ROOT, gitHead, gitDirty } from './compat-kit.ts';
import { DEVELOPMENT_VERSION, OVERLAY_RECIPE, tagVersion } from './package-version.ts';
export const REPOSITORY='papercraftgames/Estragon';
export type VersionContext={mode:'development'|'preview'|'release';version:string;sourceHead:string;tag:string|null;release_id:number|null;overlayRecipe:string};
export function developmentContext():VersionContext {return {mode:'development',version:DEVELOPMENT_VERSION,sourceHead:gitHead(),tag:null,release_id:null,overlayRecipe:OVERLAY_RECIPE};}
export function releaseContext(event:any,eventName:string,ref:string,candidateTag:string,source={head:gitHead(),dirty:gitDirty()},tagHead=source.head,onMain=true):VersionContext {
    if(event.repository?.full_name!==REPOSITORY || source.dirty || !/^[a-f0-9]{40}$/.test(source.head))throw Error('Canonical clean immutable source required');
    if(eventName==='workflow_dispatch' && /^refs\/heads\/[A-Za-z0-9_./-]+$/.test(ref) && !ref.includes('..')) {
        if(event.inputs?.candidate_tag!==candidateTag)throw Error('Preview candidate must match actual dispatch input');
        return {mode:'preview',version:tagVersion(candidateTag),sourceHead:source.head,tag:candidateTag,release_id:null,overlayRecipe:OVERLAY_RECIPE};
    }
    const release=event.release;
    const version=tagVersion(release?.tag_name);
    if(!onMain || eventName!=='release' || event.action!=='published' || !Number.isSafeInteger(release?.id) || release.id<=0 || release.draft!==false || release.prerelease!==true || ref!=='refs/tags/'+release.tag_name || tagHead!==source.head || candidateTag)throw Error('Published GitHub prerelease must match exact reviewed tag/source');
    return {mode:'release',version,sourceHead:source.head,tag:release.tag_name,release_id:release.id,overlayRecipe:OVERLAY_RECIPE};
}
export function currentContext():VersionContext {
    if(process.env.GITHUB_REPOSITORY!==REPOSITORY || process.env.GITHUB_SHA!==gitHead())throw Error('Checkout must match actual GitHub event source/repository');
    const event=JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH!,'utf8'));
    let onMain=false;
    try {execFileSync('git',['merge-base','--is-ancestor',gitHead(),'origin/main'],{cwd:ROOT,stdio:'pipe'});onMain=true;}catch{}
    const name=process.env.GITHUB_EVENT_NAME||'';
    let tagHead=gitHead();
    if(name==='release') {
        tagVersion(event.release?.tag_name);
        tagHead=execFileSync('git',['rev-parse','refs/tags/'+event.release.tag_name+'^{commit}'],{cwd:ROOT,encoding:'utf8'}).trim();
    }
    return releaseContext(event,name,process.env.GITHUB_REF||'',name==='workflow_dispatch'?event.inputs?.candidate_tag||'':'',undefined,tagHead,onMain);
}
export function validateOverlay(value:any):asserts value is VersionContext {
    const keys=['mode','version','sourceHead','tag','release_id','overlayRecipe'];
    if(!value || JSON.stringify(Object.keys(value).sort())!==JSON.stringify(keys.sort()) || value.overlayRecipe!==OVERLAY_RECIPE || !/^[a-f0-9]{40}$/.test(value.sourceHead))throw Error('Invalid overlay recipe/source/schema');
    if(value.mode==='development') {
        if(value.version!==DEVELOPMENT_VERSION || value.tag!==null || value.release_id!==null)throw Error('Invalid development overlay');
    } else {
        if(tagVersion(value.tag)!==value.version || !['release','preview'].includes(value.mode))throw Error('Invalid tag overlay');
        if(value.mode==='preview'?value.release_id!==null:!Number.isSafeInteger(value.release_id)||value.release_id<=0)throw Error('Invalid overlay authorization mode');
    }
}
export function assertOverlay(actual:unknown,expected:VersionContext):void {
    validateOverlay(actual);validateOverlay(expected);
    if(Object.keys(expected).some(key=>(actual as any)[key] !== (expected as any)[key]))throw Error('Missing, altered or unauthorized version overlay');
}
