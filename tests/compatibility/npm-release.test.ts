import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { createHash } from 'node:crypto';
import { ROOT, sha256 } from '../../tools/compat-kit.ts';
import { releaseContext, selectVerificationRun, REPOSITORY } from '../../tools/release-context.ts';
import { executePublication, verifyPreparedIdentity } from '../../tools/publish-prepared.ts';
import { downloadRegistryPackage } from '../../tools/verify-published-package.ts';
import { publicationAction, verifyRegistryIdentity, verifyRegistryTar, PACKAGE } from '../../tools/registry-package.ts';
const version='0.1.0-beta.1',head='reviewed',source={head,dirty:false};
const event={repository:{full_name:REPOSITORY},action:'published',release:{id:42,draft:false,prerelease:true,tag_name:'v'+version}};
const context=releaseContext(event,'release','refs/tags/v'+version,version,source);
test('only matching published main-source prerelease authorizes publishing; dispatch is preview',()=>{
    assert.equal(context.mode,'release');
    assert.equal(releaseContext(event,'workflow_dispatch','refs/heads/main',version,source).mode,'preview');
    for(const release of [{draft:true},{prerelease:false},{tag_name:'v0.1.0-beta.2'},{id:null}])assert.throws(()=>releaseContext({...event,release:{...event.release,...release}},'release','refs/tags/v'+version,version,source));
    for(const [name,ref]of [['push','refs/heads/main'],['release','refs/heads/main'],['workflow_dispatch','refs/heads/feature']])assert.throws(()=>releaseContext(event,name!,ref!,version,source));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,version,source,'moved-tag'));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,version,source,head,false));
    assert.throws(()=>releaseContext(event,'release','refs/tags/v'+version,version,{...source,dirty:true}));
    assert.throws(()=>releaseContext({...event,repository:{full_name:'fork/Estragon'}},'release','refs/tags/v'+version,version,source));
});
test('automatic CI discovery waits for latest exact main push and cannot fall back to stale green',()=>{
    const run={id:1,head_sha:head,head_branch:'main',event:'push',path:'.github/workflows/ci.yml',status:'completed',conclusion:'success'};
    assert.equal(selectVerificationRun([{...run,head_sha:'old'},run],head),run);
    assert.equal(selectVerificationRun([{...run,event:'pull_request'}],head),null);
    assert.equal(selectVerificationRun([run,{...run,id:2,status:'in_progress'}],head),null);
    assert.throws(()=>selectVerificationRun([run,{...run,id:2,conclusion:'failure'}],head));
    assert.equal(selectVerificationRun([],head),null);
});
function fixture() {
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-release-test-'));
    const tarball='papercraftgames-estragon-'+version+'.tgz',file=path.join(dir,tarball);
    fs.writeFileSync(file,'already-tested-tar');
    const bytes=fs.readFileSync(file),integrity='sha512-'+createHash('sha512').update(bytes).digest('base64');
    const report={...context,repository:REPOSITORY,published:false,tarball,tarball_sha256:sha256(file),integrity};
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
test('new package stages exact tar once, waits for 2FA; existing package uses tokenless OIDC; rerun only verifies',async()=>{
    const f=fixture();try {
        const calls:Array<{args:string[],env:NodeJS.ProcessEnv}>=[];
        const io={readRegistry:async()=>f.registry as any,runNpm:(args:string[],env:NodeJS.ProcessEnv)=>{calls.push({args,env});},wait:async()=>{},environment:{NPM_BOOTSTRAP_TOKEN:'never-log',NODE_AUTH_TOKEN:'stale'},bootstrapToken:'one-time'};
        let reads=0;
        await executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>++reads===1?null:f.registry});
        assert.deepEqual(calls[0]!.args,['stage','publish',f.file,'--access','public','--tag','beta','--provenance','--ignore-scripts']);
        assert.equal(calls[0]!.env.NODE_AUTH_TOKEN,'one-time');assert.equal(calls[0]!.env.NPM_BOOTSTRAP_TOKEN,undefined);
        calls.length=0;reads=0;
        await executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>++reads===1?{name:PACKAGE,versions:{'0.0.1':{}}}:f.registry});
        assert.equal(calls[0]!.args[0],'publish');assert.equal(calls[0]!.env.NODE_AUTH_TOKEN,undefined);assert.equal(calls[0]!.env.NPM_BOOTSTRAP_TOKEN,undefined);
        calls.length=0;await executePublication(f.report,f.file,f.dir,io);assert.equal(calls.length,0);
        assert.equal(publicationAction({name:PACKAGE,versions:{'0.0.0-stage':{}}},f.report,false),'await-approval');
        assert.throws(()=>publicationAction(null,f.report,false));
        await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>{throw Error('503');}}));assert.equal(calls.length,0);
        reads=0;await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>++reads===1?{name:PACKAGE,versions:{'0.0.0-stage':{}}}:null}));assert.equal(calls.length,0);
        await assert.rejects(executePublication(f.report,f.file,f.dir,{...io,readRegistry:async()=>({name:PACKAGE,versions:{}}),runNpm:()=>{throw Error('OIDC denied');}}));
    }finally{fs.rmSync(f.dir,{recursive:true,force:true});}
});
test('release workflow uses Voltra trigger/environment and isolates OIDC, bootstrap and native registry smoke',()=>{
    const yaml=fs.readFileSync(path.join(ROOT,'.github/workflows/npm-release.yml'),'utf8');
    assert(yaml.includes('types: [published]'));assert(yaml.includes('workflow_dispatch: {}'));assert(yaml.includes('environment: npm-publish'));assert(yaml.includes("node-version: '24'"));
    assert(!yaml.includes('verification_run:'));assert(!yaml.includes('NPM_PUBLISH_ENABLED'));assert(!yaml.includes('inputs.publish'));assert(!/^  (push|pull_request):/m.test(yaml));
    assert.equal(yaml.match(/id-token: write/g)?.length,1);assert(yaml.includes("if: github.event_name == 'release'"));
    assert(yaml.includes("version: ['4.0.4', '4.7']"));assert(yaml.includes('ESTRAGON_PUBLISHED_PACKAGE_DIRECTORY:'));assert(yaml.includes('needs: [prepare, publish, consumer]'));
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
