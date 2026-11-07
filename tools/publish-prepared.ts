/** Invoked only by release.published; preview can never reach registry writes. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { execFileSync } from 'node:child_process';
import { sha256, writeJSON } from './compat-kit.ts';
import { currentContext, REPOSITORY, assertOverlay } from './release-context.ts';
import { registryPackage, publicationAction, verifyRegistryIdentity } from './registry-package.ts';
export type PublicationIO = {
    readRegistry:typeof registryPackage;
    runNpm:(args:string[],env:NodeJS.ProcessEnv)=>void;
    wait:()=>Promise<void>;
    environment:NodeJS.ProcessEnv;
    summary?:string|undefined;
};
export async function executePublication(report:any,file:string,directory:string,io:PublicationIO) {
    if(report.mode!=='release' || !Number.isSafeInteger(report.release_id) || report.release_id<=0)throw Error('Preview cannot publish');
    const environment={...io.environment};delete environment.NPM_BOOTSTRAP_TOKEN;delete environment.NODE_AUTH_TOKEN;
    const initial=await io.readRegistry(), action=publicationAction(initial,report);
    writeJSON(path.join(directory,'publication-status.json'),{state:action,source:report.sourceHead,release_id:report.release_id,version:report.version});
    const flags=[path.resolve(file),'--access','public','--tag','beta','--provenance','--ignore-scripts'];
    if(action==='oidc')io.runNpm(['publish',...flags],environment);
    // Also resumes verification after a post-publish failure or a staged-approval timeout.
    let registry:any;
    for(let attempt=0;attempt<240;attempt++) {
        registry=await io.readRegistry();
        if(registry?.versions?.[report.version])break;
        if(attempt===239)throw Error('Publication not visible; release failed/incomplete. Never republish different bytes.');
        await io.wait();
    }
    verifyRegistryIdentity(registry,report);
    writeJSON(path.join(directory,'publication-status.json'),{state:'registry-verified-native-smoke-pending',source:report.sourceHead,release_id:report.release_id,version:report.version,integrity:report.integrity});
    console.log('NPM_REGISTRY_IDENTITY_CONFIRMED_NATIVE_SMOKE_PENDING');
}
export function verifyPreparedIdentity(report:any,context:ReturnType<typeof currentContext>,directory:string,repository=process.env.GITHUB_REPOSITORY) {
    if(repository!==REPOSITORY || context.mode!=='release' || report.mode!=='release' || report.release_id!==context.release_id || report.tag!==context.tag || report.repository!==REPOSITORY || report.sourceHead!==context.sourceHead || report.published!==false || report.version!==context.version || !/^papercraftgames-estragon-0\.\d+\.\d+-beta\.\d+\.tgz$/.test(report.tarball))throw Error('Release event/source/artifact identity required');
    assertOverlay(report.overlay,context);
    const file=path.join(directory,report.tarball);if(sha256(file)!==report.tarball_sha256)throw Error('Tested tarball changed');
    return file;
}
if(import.meta.url==='file://'+process.argv[1]) {
    const directory=process.argv[2];if(!directory)throw Error('Verified artifact directory required');
    const report=JSON.parse(fs.readFileSync(path.join(directory,'release-ready.json'),'utf8'));
    const file=verifyPreparedIdentity(report,currentContext(),directory);
    await executePublication(report,file,directory,{
        readRegistry:registryPackage,
        runNpm:(args,env)=>{execFileSync('npm',args,{env,stdio:'inherit'});},
        wait:()=>new Promise(resolve=>setTimeout(resolve,15000)),
        environment:process.env,summary:process.env.GITHUB_STEP_SUMMARY,
    });
}
