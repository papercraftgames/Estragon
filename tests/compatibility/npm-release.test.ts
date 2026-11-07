import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { createHash } from 'node:crypto';
import { ROOT, sha256 } from '../../tools/compat-kit.ts';
import { releaseContext, REPOSITORY } from '../../tools/release-context.ts';
import { executePublication, verifyPreparedIdentity } from '../../tools/publish-prepared.ts';
import { downloadRegistryPackage } from '../../tools/verify-published-package.ts';
import { publicationAction, verifyRegistryIdentity, verifyRegistryTar, PACKAGE } from '../../tools/registry-package.ts';
import { verifyCertificationJobs } from '../../tools/verify-npm-release.ts';
const version='0.3.7-beta.8',head='a'.repeat(40),source={head,dirty:false};
const event={repository:{full_name:REPOSITORY},action:'published',release:{id:42,draft:false,prerelease:true,tag_name:'v'+version}};
const context=releaseContext(event,'release','refs/tags/v'+version,'',source);
test('only matching published main-source prerelease authorizes publishing; dispatch is preview',()=>{
    assert.equal(context.mode,'release');
    assert.equal(releaseContext({...event,inputs:{candidate_tag:'v'+version}},'workflow_dispatch','refs/heads/feature','v'+version,source,head,false).mode,'preview');
    assert.equal(releaseContext({...event,inputs:{candidate_tag:'v'+version}},'workflow_dispatch','refs/heads/main','v'+version,source).mode,'preview');
    for(const release of [{draft:true},{prerelease:false},{tag_name:'v'+version.replace(/\d+$/,n=>String(Number(n)+1))},{id:null}])assert.throws(()=>releaseContext({...event,release:{...event.release,...release}},'release','refs/tags/v'+version,'',source));
    for(const [name,ref]of [['push','refs/heads/main'],['release','refs/heads/main']])assert.throws(()=>releaseContext(event,name!,ref!,'',source));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,'',source,'moved-tag'));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,'',source,head,false));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,'',{...source,dirty:true}));
    assert.throws(()=>releaseContext({...event,repository:{full_name:'fork/Estragon'}},'release','refs/tags/v'+version,'',source));
});
test('only two completed successful current-run certification jobs authorize preparation',()=>{
    const jobs=['4.0.4','4.7'].map(label=>({name:'certify / release-certification ('+label+')',status:'completed',conclusion:'success'}));
    jobs.push({name:'certify / release-policy',status:'completed',conclusion:'success'});
    assert.doesNotThrow(()=>verifyCertificationJobs(jobs));
    for(const conclusion of ['failure','cancelled','skipped',null]) {
        assert.throws(()=>verifyCertificationJobs(jobs.map((job,index)=>index===1?{...job,conclusion}:job)));
        assert.throws(()=>verifyCertificationJobs(jobs.map((job,index)=>index===2?{...job,conclusion}:job)));
    }
    assert.throws(()=>verifyCertificationJobs([jobs[0]]));
    assert.throws(()=>verifyCertificationJobs([...jobs,jobs[0]]));
    assert.throws(()=>verifyCertificationJobs(jobs.map(j=>({...j,status:'in_progress'}))));
    assert.throws(()=>verifyCertificationJobs([{name:'addon (4.0.4)',status:'completed',conclusion:'success'},{name:'addon (4.7)',status:'completed',conclusion:'success'}]));
});
function fixture() {
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-release-test-'));
    const tarball='papercraftgames-estragon-'+version+'.tgz',file=path.join(dir,tarball);
    fs.writeFileSync(file,'already-tested-tar');
    const bytes=fs.readFileSync(file),integrity='sha512-'+createHash('sha512').update(bytes).digest('base64');
    const report={...context,overlay:context,repository:REPOSITORY,published:false,tarball,tarball_sha256:sha256(file),integrity};
    const metadata={name:PACKAGE,version,dist:{integrity,tarball:'https://registry.npmjs.org/@papercraftgames/estragon/-/'+tarball,attestations:{url:'https://registry.npmjs.org/-/npm/v1/attestations/test'}}};
    const registry={name:PACKAGE,versions:{[version]:metadata},'dist-tags':{beta:version}};
    return {dir,file,report,registry,bytes};
}
test('release artifact and registry checks reject altered tar, context, integrity, latest tag or missing provenance',()=>{
    const f=fixture();try {
        assert.equal(verifyPreparedIdentity(f.report,context,f.dir,REPOSITORY),f.file);
        for(const delta of [{mode:'preview'},{release_id:43},{sourceHead:'other'},{tarball:'../escape'},{published:true}])assert.throws(()=>verifyPreparedIdentity({...f.report,...delta},context,f.dir,REPOSITORY));
        assert.throws(()=>verifyPreparedIdentity(f.report,{...context,mode:'preview'},f.dir,REPOSITORY));
        verifyRegistryIdentity(f.registry,f.report);verifyRegistryTar(f.bytes,f.report);
        assert.throws(()=>verifyRegistryTar(Buffer.from('altered'),f.report));
        for(const change of [{'dist-tags':{beta:'other'}},{'dist-tags':{beta:version,latest:version}},{versions:{[version]:{name:PACKAGE,version,dist:{integrity:'other'}}}},{name:'wrong'}])assert.throws(()=>verifyRegistryIdentity({...f.registry,...change},f.report));
        fs.appendFileSync(f.file,'changed');assert.throws(()=>verifyPreparedIdentity(f.report,context,f.dir,REPOSITORY));
    }finally{fs.rmSync(f.dir,{recursive:true,force:true});}
});
test('publication is OIDC only, missing package fails and an existing exact version only verifies',async()=>{
    const f=fixture();try {
        const calls:Array<{args:string[],env:NodeJS.ProcessEnv}>=[];
        const io={readRegistry:async()=>f.registry as any,runNpm:(args:string[],env:NodeJS.ProcessEnv)=>{calls.push({args,env});},wait:async()=>{},environment:{NPM_BOOTSTRAP_TOKEN:'never-log',NODE_AUTH_TOKEN:'stale'}};
        await assert.rejects(executePublication({...f.report,mode:'preview'},f.file,f.dir,io));assert.equal(calls.length,0);
        let reads=0;
        await executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>++reads===1?{name:PACKAGE,versions:{'older':{}}}:f.registry});
        assert.deepEqual(calls[0]!.args,['publish',f.file,'--access','public','--tag','beta','--provenance','--ignore-scripts']);
        assert.equal(calls[0]!.env.NODE_AUTH_TOKEN,undefined);assert.equal(calls[0]!.env.NPM_BOOTSTRAP_TOKEN,undefined);
        calls.length=0;await executePublication(f.report,f.file,f.dir,io);assert.equal(calls.length,0);
        assert.throws(()=>publicationAction(null,f.report));
        await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>{throw Error('503');}}));assert.equal(calls.length,0);
        await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>null}));assert.equal(calls.length,0);
        await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>({name:PACKAGE,versions:{}}),runNpm:()=>{throw Error('OIDC denied');}}));
    }finally{fs.rmSync(f.dir,{recursive:true,force:true});}
});
test('release workflow retains owner trigger/OIDC, hard certification and post-publication consumers',()=>{
    const yaml=fs.readFileSync(path.join(ROOT,'.github/workflows/npm-release.yml'),'utf8');
    assert(yaml.includes('types: [published]'));assert(yaml.includes('candidate_tag:'));assert(yaml.includes('environment: npm-publish'));assert(yaml.includes("node-version: '24'"));
    assert(!yaml.includes('verification_run:'));assert(!yaml.includes('NPM_PUBLISH_ENABLED'));assert(!yaml.includes('inputs.publish'));assert(!/^  (push|pull_request):/m.test(yaml));
    assert.equal(yaml.match(/id-token: write/g)?.length,1);assert(yaml.includes("if: github.event_name == 'release'"));
    assert(yaml.includes("version: ['4.0.4', '4.7']"));assert(yaml.includes('needs: [certify, prepare]'));assert(yaml.includes('ESTRAGON_PUBLISHED_PACKAGE_DIRECTORY:'));assert(yaml.includes('needs: [certify, prepare, publish, consumer]'));
});

test('registry verification prints the exact native package success marker as one line',()=>{
    const publishedVerifier=fs.readFileSync(path.join(ROOT,'tools/verify-published-package.ts'),'utf8');
    const consumer=fs.readFileSync(path.join(ROOT,'tools/check-package.ts'),'utf8');
    assert(consumer.includes("'PACKAGE_PACK_OK'"));
    assert(publishedVerifier.includes("console.log('PACKAGE_PACK_OK');"));
    assert(!publishedVerifier.includes("console.log('PACKAGE_PACK_OK "));
});

test('registry consumer downloads original tar and rejects changed bytes or unrelated/missing signed provenance',async()=>{
    const f=fixture();try {
        const statement={predicateType:'https://slsa.dev/provenance/v1',subject:[{digest:{sha512:Buffer.from(f.report.integrity.slice(7),'base64').toString('hex')}}],predicate:{buildDefinition:{externalParameters:{workflow:{repository:'https://github.com/papercraftgames/Estragon',path:'.github/workflows/npm-release.yml',ref:'refs/tags/'+f.report.tag}},resolvedDependencies:[{digest:{gitCommit:head}}]},runDetails:{builder:{id:'https://github.com/actions/runner/github-hosted'}}}};
        const signed=(value:any)=>({attestations:[{predicateType:'https://slsa.dev/provenance/v1',bundle:{verificationMaterial:{},dsseEnvelope:{payload:Buffer.from(JSON.stringify(value)).toString('base64'),signatures:[{sig:'test-only'}]}}}]});
        const request=(bytes:Uint8Array,provenance:any)=>(async(url:any)=>String(url).includes('/attestations/')?Response.json(provenance):new Response(bytes as any)) as typeof fetch;
        await downloadRegistryPackage(f.report,path.join(f.dir,'valid'),async()=>f.registry,request(f.bytes,signed(statement)));
        assert.equal(sha256(path.join(f.dir,'valid',f.report.tarball)),f.report.tarball_sha256);
        await assert.rejects(downloadRegistryPackage(f.report,path.join(f.dir,'changed'),async()=>f.registry,request(Buffer.from('changed'),signed(statement))));
        await assert.rejects(downloadRegistryPackage(f.report,path.join(f.dir,'missing'),async()=>f.registry,request(f.bytes,{})));
        await assert.rejects(downloadRegistryPackage(f.report,path.join(f.dir,'unrelated'),async()=>f.registry,request(f.bytes,signed({...statement,subject:[]}))));
        statement.predicate.buildDefinition.resolvedDependencies[0]!.digest.gitCommit='other';
        await assert.rejects(downloadRegistryPackage(f.report,path.join(f.dir,'wrong-source'),async()=>f.registry,request(f.bytes,signed(statement))));
    }finally{fs.rmSync(f.dir,{recursive:true,force:true});}
});
