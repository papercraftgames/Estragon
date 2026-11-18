/** D07 local development consumer only: Yarn pack, no release overlay/certification. */
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {ROOT,gitHead,gitDirty,sha256,writeJSON} from './compat-kit.ts';
export function buttonImportsPackage(output:string,name="button-imports"){
 if(!/^[a-z0-9-]+$/.test(name))throw Error('Invalid development package name');
 if(gitDirty())throw Error('Native acceptance requires committed clean source');
 if(!path.isAbsolute(output)||fs.existsSync(output))throw Error('New absolute package directory required');
 const stage=path.join(output,'stage');fs.mkdirSync(stage,{recursive:true});
 const files=execFileSync('git',['ls-files','-z','addons/estragon'],{cwd:ROOT,encoding:'utf8'}).split('\0').filter(Boolean).sort();
 const hashes:Record<string,string>={},uids=new Set<string>();
 function copy(source:string,target:string){
  if(!fs.lstatSync(source).isFile()||fs.lstatSync(source).isSymbolicLink())throw Error('Regular source files required');
  const dest=path.join(stage,target);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(source,dest);
 }
 for(const file of files){
  if(!/^addons\/estragon\/[a-z0-9_/.-]+\.(?:gd|gd\.uid|gd\.txt|tres|cfg)$/.test(file))throw Error('Unexpected addon payload '+file);
  if(file.endsWith('.gd')&&!files.includes(file+'.uid'))throw Error('Missing UID '+file);
  if(file.endsWith('.gd.uid')){const uid=fs.readFileSync(path.join(ROOT,file),'utf8').trim();if(!/^uid:\/\/[a-z0-9]+$/.test(uid)||uids.has(uid))throw Error('Invalid/duplicate UID');uids.add(uid);}
  copy(path.join(ROOT,file),file);
 }
 for(const name of ['README.md','CHANGELOG.md'])copy(path.join(ROOT,'packages/estragon',name),name);
 copy(path.join(ROOT,'LICENSE'),'LICENSE');
 const spec=JSON.parse(fs.readFileSync(path.join(ROOT,'packages/estragon/package.json'),'utf8'));
 if(Object.hasOwn(spec,'version')||spec.name!=='@papercraftgames/estragon'||['scripts','dependencies','devDependencies'].some(k=>k in spec))throw Error('Unexpected development package metadata');
 writeJSON(path.join(stage,'package.json'),{...spec,version:'0.0.0-dev'});
 for(const name of [...files,'README.md','CHANGELOG.md','LICENSE','package.json'])hashes[name]=sha256(path.join(stage,name));
 const tarball=path.join(output,name+'-dev.tgz');
 execFileSync('corepack',['yarn@1.22.22','pack','--filename',tarball],{cwd:stage,env:{...process.env,COREPACK_ENABLE_PROJECT_SPEC:'0'},stdio:'pipe'});
 const repeated=path.join(output,'repeat.tgz');
 execFileSync('corepack',['yarn@1.22.22','pack','--filename',repeated],{cwd:stage,env:{...process.env,COREPACK_ENABLE_PROJECT_SPEC:'0'},stdio:'pipe'});
 if(sha256(tarball)!==sha256(repeated))throw Error('Yarn development pack is not reproducible');
 const members=execFileSync('tar',['-tzf',tarball],{encoding:'utf8'}).trim().split('\n').filter(x=>x!=='package').map(x=>x.replace(/^package\//,'').replace(/\/$/,'')).filter(x=>!fs.existsSync(path.join(stage,x))||!fs.lstatSync(path.join(stage,x)).isDirectory()).sort();
 if(JSON.stringify(members)!==JSON.stringify(Object.keys(hashes).sort()))throw Error('Yarn package payload differs from exact allowlist');
 const unpacked=path.join(output,'unpacked');fs.mkdirSync(unpacked);execFileSync('tar',['-xzf',tarball,'-C',unpacked]);
 for(const [file,hash]of Object.entries(hashes))if(sha256(path.join(unpacked,'package',file))!==hash)throw Error('Packed bytes differ '+file);
 const manifest={sourceHead:gitHead(),sourceDirty:false,mode:'development-yarn-only',version:'0.0.0-dev',files:hashes,canonical_uids:uids.size,tarball_sha256:sha256(tarball),reproducible:true};
 writeJSON(path.join(output,'package-manifest.json'),manifest);
 return {tarball,manifest};
}
