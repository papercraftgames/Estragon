/** Public registry reads and pure identity checks; never mutates npm. */
import { createHash } from 'node:crypto';
export const PACKAGE='@papercraftgames/estragon';
export async function registryPackage() {
    const response=await fetch('https://registry.npmjs.org/'+encodeURIComponent(PACKAGE));
    if(response.status===404)return null;
    if(!response.ok)throw Error('Registry lookup failed: '+response.status);
    return response.json();
}
export function publicationAction(registry:any, report:any, bootstrapAvailable:boolean) {
    if(!registry) {
        if(!bootstrapAvailable)throw Error('New npm package needs one-time CI staging credential; see PACKAGING bootstrap checklist');
        return 'bootstrap';
    }
    if(registry.name!==PACKAGE)throw Error('Unexpected registry package');
    if(registry.versions?.[report.version])return 'verify';
    if(registry.versions?.['0.0.0-stage'] && Object.keys(registry.versions).length===1)return 'await-approval';
    return 'oidc'; // Never use bootstrap credentials for an existing package.
}
export function verifyRegistryIdentity(registry:any, report:any) {
    const version=registry?.versions?.[report.version];
    if(registry?.name!==PACKAGE || version?.name!==PACKAGE || version.version!==report.version || registry['dist-tags']?.beta!==report.version || registry['dist-tags']?.latest===report.version || version.dist?.integrity!==report.integrity || !version.dist?.attestations?.url)throw Error('Published identity/beta/integrity/provenance mismatch');
    if(!version.dist.tarball?.startsWith('https://registry.npmjs.org/@papercraftgames/estragon/-/') || !version.dist.attestations.url.startsWith('https://registry.npmjs.org/'))throw Error('Unexpected registry artifact host');
    return version;
}
export function verifyRegistryTar(bytes:Uint8Array, report:any) {
    if(createHash('sha256').update(bytes).digest('hex')!==report.tarball_sha256 || 'sha512-'+createHash('sha512').update(bytes).digest('base64')!==report.integrity)throw Error('Registry tarball differs from tested tarball');
}
export function verifyRegistryProvenance(provenance:any,report:any) {
    const signed=provenance.attestations?.find((a:any)=>a.predicateType==='https://slsa.dev/provenance/v1');
    const envelope=signed?.bundle?.dsseEnvelope;
    if(!envelope?.signatures?.length || !signed.bundle.verificationMaterial)throw Error('Registry signed SLSA bundle missing');
    const statement=JSON.parse(Buffer.from(envelope.payload,'base64').toString('utf8'));
    const build=statement.predicate?.buildDefinition, workflow=build?.externalParameters?.workflow;
    const digest=Buffer.from(report.integrity.replace(/^sha512-/,''),'base64').toString('hex');
    if(statement.predicateType!=='https://slsa.dev/provenance/v1' || !statement.subject?.some((s:any)=>s.digest?.sha512===digest) || workflow?.repository!=='https://github.com/papercraftgames/Estragon' || workflow?.path!=='.github/workflows/npm-release.yml' || workflow?.ref!=='refs/tags/'+report.tag || !build.resolvedDependencies?.some((d:any)=>d.digest?.gitCommit===report.sourceHead) || statement.predicate?.runDetails?.builder?.id!=='https://github.com/actions/runner/github-hosted')throw Error('Registry provenance does not describe exact release tar/source/workflow');
}
