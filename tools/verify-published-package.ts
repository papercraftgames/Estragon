/** Download exact public registry bytes for fresh native consumer acceptance. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { writeJSON, gitHead, gitDirty } from './compat-kit.ts';
import { registryPackage, verifyRegistryIdentity, verifyRegistryTar, verifyRegistryProvenance } from './registry-package.ts';
export async function downloadRegistryPackage(report:any,output:string,readRegistry=registryPackage,request:typeof fetch=fetch) {
    if(fs.existsSync(output))throw Error('New registry evidence output required');
    const version=verifyRegistryIdentity(await readRegistry(),report);
    const response=await request(version.dist.tarball);if(!response.ok)throw Error('Registry tarball download failed');
    const bytes=new Uint8Array(await response.arrayBuffer());verifyRegistryTar(bytes,report);
    const attestation=await request(version.dist.attestations.url);if(!attestation.ok)throw Error('Registry provenance unavailable');
    const provenance:any=await attestation.json();
    verifyRegistryProvenance(provenance,report);
    fs.mkdirSync(output,{recursive:true});fs.writeFileSync(path.join(output,report.tarball),bytes);
    writeJSON(path.join(output,'registry-provenance.json'),provenance);
    writeJSON(path.join(output,'package-manifest.json'),{...report,name:'@papercraftgames/estragon',source_content_sha256:report.source_content_sha256,registry:true});
}
if(import.meta.url==='file://'+process.argv[1]) {
    const [approved,output]=process.argv.slice(2);
    if(!approved||!output)throw Error('Approved directory and new output required');
    const report=JSON.parse(fs.readFileSync(path.join(approved,'release-ready.json'),'utf8'));
    if(report.sourceHead!==gitHead()||gitDirty())throw Error('Registry consumer must use exact clean reviewed source');
    await downloadRegistryPackage(report,output);
    console.log('PACKAGE_PACK_OK REGISTRY_EXACT_TESTED_TARBALL');
}
