/** Only invoked by the separately owner-enabled protected release job. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { execFileSync } from 'node:child_process';
import { gitHead, sha256 } from './compat-kit.ts';
const directory=process.argv[2];if(!directory)throw Error('Approved artifact directory required');
const report=JSON.parse(fs.readFileSync(path.join(directory,'release-ready.json'),'utf8'));
if(process.env.GITHUB_REPOSITORY!=='papercraftgames/Estragon'||process.env.GITHUB_REF!=='refs/heads/main'||report.repository!==process.env.GITHUB_REPOSITORY||report.sourceHead!==gitHead()||report.published!==false||!/^papercraftgames-estragon-0\.\d+\.\d+-beta\.\d+\.tgz$/.test(report.tarball)||!/^0\.\d+\.\d+-beta\.\d+$/.test(report.version))throw Error('Protected release source/artifact identity required');
const file=path.join(directory,report.tarball);if(sha256(file)!==report.tarball_sha256)throw Error('Approved tarball changed');
// npm's trusted-publisher OIDC path is intentionally the only CI credential.
// Workflow dispatch defaults to preview; the repository flag/environment are
// owner setup, not enabled or invoked by the P01 implementation task.
execFileSync('npm',['publish',path.resolve(file),'--access','public','--tag','beta','--provenance','--ignore-scripts'],{stdio:'inherit'});
// Published package smoke uses Yarn acquisition; no addon/compiler executes JS.
const smoke=path.join(directory,'published-smoke');fs.mkdirSync(smoke);fs.writeFileSync(path.join(smoke,'package.json'),JSON.stringify({private:true,packageManager:'yarn@1.22.22'}));
execFileSync('corepack',['yarn@1.22.22','add','--exact','--ignore-scripts','--non-interactive','@papercraftgames/estragon@'+report.version],{cwd:smoke,stdio:'inherit'});
for(const [name,hash]of Object.entries(report.files as Record<string,string>))if(sha256(path.join(smoke,'node_modules/@papercraftgames/estragon',name))!==hash)throw Error('Published Yarn payload differs from approved artifact: '+name);
const registry=JSON.parse(execFileSync('npm',['view','@papercraftgames/estragon@'+report.version,'--json'],{encoding:'utf8'}));
if(registry.name!=='@papercraftgames/estragon'||registry.version!==report.version||registry.dist?.integrity!==report.integrity||!registry.dist?.attestations?.url)throw Error('Published version/provenance not confirmed');
console.log('NPM_PUBLISHED_VERSION_AND_PROVENANCE_CONFIRMED');
