/** Current-run pre-publication certification gate. Routine main CI is never sufficient. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { ROOT, gitHead, gitDirty, sha256, writeJSON } from './compat-kit.ts';
import { assessFile } from './assert-release.ts';
import { currentContext, REPOSITORY } from './release-context.ts';
import { addonVersion, stagedPackageJson } from './package-version.ts';
export function verifyReleaseIdentity(run:any,expectedVersion:string,repository:string,source={head:gitHead(),dirty:gitDirty()},runId=process.env.GITHUB_RUN_ID) {
    const allowed=run.path==='.github/workflows/npm-release.yml' && ['release','workflow_dispatch'].includes(run.event) || run.path==='.github/workflows/ci.yml' && run.event==='workflow_dispatch';
    if(repository!==REPOSITORY || run.repository?.full_name!==repository || !allowed || !runId || String(run.id)!==runId || run.head_sha!==source.head || run.status!=='in_progress' || run.conclusion!==null)throw Error('Exact current release/preview run required; routine main or prior CI cannot certify publication');
    if(expectedVersion!==addonVersion() || !/^0\.\d+\.\d+-beta\.\d+$/.test(expectedVersion) || source.dirty)throw Error('Exact canonical prerelease version and clean source required');
}
export function verifyCertificationJobs(jobs:any[]) {
    for(const name of ['release-policy','release-certification (4.0.4)','release-certification (4.7)']) {
        const matches=jobs.filter(job=>job.name===name || job.name.endsWith('/ '+name));
        if(matches.length!==1 || matches[0].status!=='completed' || matches[0].conclusion!=='success')throw Error('Both current-run certification jobs must succeed before artifact preparation');
    }
}
if(import.meta.url==='file://'+process.argv[1]) {
    const [output]=process.argv.slice(2);
    if(!output || !path.isAbsolute(output)||fs.existsSync(output))throw Error('Usage: verify-npm-release.ts NEW_ABSOLUTE_OUTPUT');
    const context=currentContext(), version=context.version, repository=REPOSITORY;
    const runId=process.env.GITHUB_RUN_ID;
    if(!runId || !/^\d+$/.test(runId))throw Error('Current workflow run ID required');
    const run=JSON.parse(execFileSync('gh',['api','repos/'+repository+'/actions/runs/'+runId],{encoding:'utf8'}));
    verifyReleaseIdentity(run,version,repository);
    const jobs=JSON.parse(execFileSync('gh',['api','repos/'+repository+'/actions/runs/'+runId+'/jobs?filter=latest&per_page=100'],{encoding:'utf8'}));
    if(jobs.total_count>100)throw Error('Unexpected certification job inventory');
    verifyCertificationJobs(jobs.jobs);
    fs.mkdirSync(output,{recursive:true});
    for(const label of ['4.0.4','4.7'])execFileSync('gh',['run','download',runId,'--repo',repository,'--name','native-addon-'+label,'--dir',path.join(output,label)],{stdio:'inherit'});
    const reports=['4.0.4','4.7'].map(label=>assessFile(path.join(output,label,'native-addon',label,'addon-evidence.json')));
    if(reports.some(report=>report.profile!=='fast-release'||report.source_commit!==gitHead()||report.assessment.status!=='PASS') || new Set(reports.map(r=>r.label)).size!==2)throw Error('Complete matching two-engine fast-release evidence required');
    const packages=reports.map(report=>{
        const dir=path.join(output,report.label,'native-addon',report.label,'package',''+report.label,'packed');
        const manifest=JSON.parse(fs.readFileSync(path.join(dir,'package-manifest.json'),'utf8'));
        if(manifest.sourceHead!==gitHead() || manifest.sourceDirty || manifest.version!==version || manifest.name!=='@papercraftgames/estragon' || !manifest.reproducible_pack || !/^[a-z0-9.-]+\.tgz$/.test(manifest.tarball))throw Error('Package source/version identity mismatch');
        const expected=execFileSync('git',['ls-files','-z','addons/estragon'],{cwd:ROOT,encoding:'utf8'}).split('\0').filter(Boolean).concat(['package.json','README.md','CHANGELOG.md','LICENSE']).sort();
        if(JSON.stringify(Object.keys(manifest.files).sort())!==JSON.stringify(expected))throw Error('Package manifest is not the exact reviewed allowlist');
        const tarball=path.join(dir,manifest.tarball);
        if(sha256(tarball)!==manifest.tarball_sha256)throw Error('Package tarball digest mismatch');
        // Bind content to this exact reviewed checkout, not just a manifest's claims.
        for(const [file,hash]of Object.entries(manifest.files)) {
            if(!/^(addons\/estragon\/[a-z0-9_/.-]+|package\.json|README\.md|CHANGELOG\.md|LICENSE)$/.test(file)||file.split('/').includes('..'))throw Error('Unsafe package file');
            const source=path.join(ROOT,file.startsWith('addons/')||file==='LICENSE'?file:'packages/estragon/'+file);
            const actualHash=file==='package.json'
                ? createHash('sha256').update(stagedPackageJson(JSON.parse(fs.readFileSync(source,'utf8')),version)).digest('hex')
                : sha256(source);
            if(actualHash!==hash)throw Error('Package differs from reviewed source: '+file);
        }
        const content=createHash('sha256').update(JSON.stringify(expected.map(file=>[file,manifest.files[file]]))).digest('hex');
        if(content!==manifest.source_content_sha256)throw Error('Package content digest mismatch');
        const members=execFileSync('tar',['-tzf',tarball],{encoding:'utf8'}).trim().split('\n').sort();
        if(JSON.stringify(members)!==JSON.stringify(expected.map(file=>'package/'+file).sort()) || execFileSync('tar',['-tvzf',tarball],{encoding:'utf8'}).trim().split('\n').some(line=>!line.startsWith('-')))throw Error('Unsafe/unexpected package tar members');
        const unpacked=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-release-unpack-'));
        try {
            execFileSync('tar',['-xzf',tarball,'-C',unpacked]);
            for(const file of expected)if(sha256(path.join(unpacked,'package',file))!==manifest.files[file])throw Error('Release tar bytes differ from reviewed source: '+file);
        } finally {fs.rmSync(unpacked,{recursive:true,force:true});}
        return {manifest,tarball};
    });
    if(packages[0]!.manifest.tarball_sha256!==packages[1]!.manifest.tarball_sha256 || packages[0]!.manifest.source_content_sha256!==packages[1]!.manifest.source_content_sha256)throw Error('Engine jobs did not test the same reproducible tarball');
    const artifact=packages[0]!;
    fs.copyFileSync(artifact.tarball,path.join(output,artifact.manifest.tarball));
    writeJSON(path.join(output,'release-ready.json'),{...context,repository,sourceHead:gitHead(),version,verification_run:runId,source_content_sha256:artifact.manifest.source_content_sha256,tarball:artifact.manifest.tarball,tarball_sha256:artifact.manifest.tarball_sha256,integrity:artifact.manifest.integrity,files:artifact.manifest.files,published:false,dist_tag:'beta'});
    console.log('NPM_RELEASE_PREPARATION_OK');
}
