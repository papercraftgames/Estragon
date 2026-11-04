import assert from 'node:assert/strict';import {test} from 'node:test';
import * as fs from 'node:fs';import * as os from 'node:os';import * as path from 'node:path';
import {REQUIRED,assessRelease} from '../../tools/release-policy.ts';
import {assessFile} from '../../tools/assert-release.ts';
import {classify,parseCLI,sha256,writeJSON,ROOT} from '../../tools/compat-kit.ts';
import type {Stage} from '../../tools/compat-kit.ts';
test('native addon requirements replace obsolete legacy and standalone gates',()=>{
 const stages=Object.fromEntries(REQUIRED.map(n=>[n,{status:'PASS'}])) as Record<string,Stage>;
 assert.equal(assessRelease(stages).status,'PASS');
 assert(!REQUIRED.some(n=>/legacy|hybrid_runtime|executable_export|helper_/.test(n)));
 for(const name of REQUIRED){const missing={...stages};delete missing[name];assert.equal(assessRelease(missing).status,'BLOCKED');for(const status of ['FAIL','BLOCKED','UNTESTED'] as const)assert.equal(assessRelease({...stages,[name]:{status}}).status,'BLOCKED');}
 assert.equal(assessRelease({...stages,unknown:{status:'FAIL'}}).status,'BLOCKED');
});
test('logs fail closed for errors, missing markers and timeouts',()=>{
 assert.equal(classify(0,'SCRIPT ERROR: failure','DONE'),'FAIL');assert.equal(classify(0,'','DONE'),'FAIL');assert.equal(classify(0,'DONE','DONE',true),'FAIL');assert.equal(classify(0,'DONE','DONE'),'PASS');
});
test('engine budget rejects additional or unsupported versions',()=>{
 assert.throws(()=>parseCLI(['--engine','4.7.2=/tmp/x','--output','/tmp/not-created-c4']));
 assert.throws(()=>parseCLI(['--engine','4.1=/tmp/x','--output','/tmp/not-created-c4']));
});
function fixture(){const root=fs.mkdtempSync(path.join(os.tmpdir(),'addon-policy-'));const label='4.7';const pin=JSON.parse(fs.readFileSync(path.join(ROOT,'tests/compatibility/linux-engines.json'),'utf8')).find((p:any)=>p.version.startsWith('4.7.'));const stages:Record<string,Stage>={},files:Record<string,string>={};
 for(const group of ['compiler','runtime','ggx','ui','metadata','distribution']){const p=group+'/'+label+'/results.json';const entries=Object.fromEntries(REQUIRED.filter(n=>n.startsWith(group+'.')).map(n=>[n.slice(group.length+1),{status:'PASS'}]));const result=group==='metadata'?{status:'PASS',sourceHead:'source',sourceDirty:false,version:pin.version,original_binary_sha256:pin.binary_sha256}:entries;writeJSON(path.join(root,p),result);files[p]=sha256(path.join(root,p));if(group==='metadata')stages.metadata={status:'PASS'};else for(const [n,s]of Object.entries(entries))stages[group+'.'+n]=s as Stage;}
 const report={source_commit:'source',source_dirty:false,label,version:pin.version,binary_sha256:pin.binary_sha256,stages,files};const file=path.join(root,'addon-evidence.json');writeJSON(file,report);return{root,file,report};}
test('matching native evidence passes; dirty, missing, mismatched or forged evidence rejects',()=>{
 const f=fixture();try{assert.equal(assessFile(f.file).assessment.status,'PASS');
 for(const patch of [{source_dirty:true},{binary_sha256:'wrong'},{files:{}},{source_commit:'wrong'},{stages:{}}]){writeJSON(f.file,{...f.report,...patch});assert.throws(()=>assessFile(f.file));}
 writeJSON(f.file,f.report);fs.appendFileSync(path.join(f.root,'compiler/4.7/results.json'),' ');assert.throws(()=>assessFile(f.file));
 }finally{fs.rmSync(f.root,{recursive:true,force:true});}
});
