/** Curated npm-format Godot addon. Local pack only; never publishes. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { ROOT, gitHead, gitDirty, sha256, writeJSON } from './compat-kit.ts';
import { currentContext, developmentContext, validateOverlay, type VersionContext } from './release-context.ts';
import { addonVersion, stagedPackageJson, stagedPluginCfg } from './package-version.ts';
export function packAddon(output: string, requireClean = false, overlay:VersionContext=developmentContext()) {
    if (!path.isAbsolute(output) || fs.existsSync(output)) throw Error('Package output must be a new absolute directory');
    if (requireClean && gitDirty()) throw Error('Release package requires clean source');
    const rootPackage = JSON.parse(fs.readFileSync(path.join(ROOT,'package.json'),'utf8'));
    if (rootPackage.name!=='estragon-tooling' || rootPackage.private!==true) throw Error('Root tooling must remain private');
    const spec = JSON.parse(fs.readFileSync(path.join(ROOT,'packages/estragon/package.json'),'utf8'));
    addonVersion();
    validateOverlay(overlay);
    const version=overlay.version;
    if(overlay.sourceHead!==gitHead())throw Error("Overlay source mismatch");
    if(Object.hasOwn(spec,'version') || spec.name!=='@papercraftgames/estragon' || spec.license!=='MIT' || spec.repository?.url!=='git+https://github.com/papercraftgames/Estragon.git' || spec.publishConfig?.access!=='public' || spec.publishConfig?.tag!=='beta' || spec.publishConfig?.registry!=='https://registry.npmjs.org/') throw Error('Unexpected prepared package identity');
    if (['scripts','dependencies','devDependencies','optionalDependencies','bin','bundledDependencies'].some(key=>key in spec)) throw Error('Addon-only artifact has no lifecycle scripts/dependency/compiler payload');
    const tracked = execFileSync('git',['ls-files','-z','addons/estragon'],{cwd:ROOT,encoding:'utf8'}).split('\0').filter(Boolean).sort();
    if(!tracked.length) throw Error('No tracked addon files');
    const stage = path.join(output,'stage'), hashes:Record<string,string> = {}, uids = new Set<string>();
    fs.mkdirSync(stage,{recursive:true});
    function copy(from:string, target:string) {
        if(!fs.lstatSync(from).isFile() || fs.lstatSync(from).isSymbolicLink()) throw Error('Only regular curated files allowed: '+from);
        const destination=path.join(stage,target);fs.mkdirSync(path.dirname(destination),{recursive:true});fs.copyFileSync(from,destination);
    }
    for(const file of tracked) {
        if(!/^addons\/estragon\/[a-z0-9_/.-]+$/.test(file) || !/\.(?:gd|gd\.uid|gd\.txt|tres|cfg)$/.test(file) || file.split('/').some(part=>part.startsWith('.'))) throw Error('Unreviewed addon payload path/type: '+file);
        if(file.endsWith('.gd') && !tracked.includes(file+'.uid')) throw Error('Missing canonical script UID: '+file);
        if(file.endsWith('.gd.uid')) {const uid=fs.readFileSync(path.join(ROOT,file),'utf8').trim();if(!/^uid:\/\/[a-z0-9]+$/.test(uid)||uids.has(uid))throw Error('Invalid/duplicate addon UID');uids.add(uid);}
        copy(path.join(ROOT,file),file);
    }
    // Materialize both authorized substitutions before any artifact hashing.
    const pluginFile=path.join(stage,'addons/estragon/editor/plugin.cfg');
    fs.writeFileSync(pluginFile,stagedPluginCfg(fs.readFileSync(pluginFile,'utf8'),version));
    const stagedManifest=path.join(stage,'package.json');
    fs.writeFileSync(stagedManifest,stagedPackageJson(spec,version));

    for(const name of ['README.md','CHANGELOG.md'])copy(path.join(ROOT,'packages/estragon',name),name);
    copy(path.join(ROOT,'LICENSE'),'LICENSE');
    for(const file of [...tracked,'package.json','README.md','CHANGELOG.md','LICENSE'])hashes[file]=sha256(path.join(stage,file));
    const plugin=fs.readFileSync(path.join(stage,'addons/estragon/editor/plugin.cfg'),'utf8');
    if(!plugin.includes('script="plugin.gd"') || /Bun compilation/.test(plugin)) throw Error('Incorrect native plugin metadata');
    for(const file of tracked.filter(p=>/\.(?:gd|tres)$/.test(p))) {
        const code=fs.readFileSync(path.join(stage,file),'utf8');
        if(code.includes('node_modules/') || code.includes('addons/estragon/'))throw Error('Fixed installation path in production: '+file);
        for(const match of code.matchAll(/(?:preload\(|extends\s+|path=)"([a-zA-Z0-9_./-]+)"/g)) {
            const target=path.posix.normalize(path.posix.join(path.posix.dirname(file),match[1]!));
            if(!hashes[target])throw Error('Addon depends on non-package file: '+file+' -> '+target);
        }
    }
    function npm(args:string[]) {return execFileSync('npm',args,{cwd:stage,encoding:'utf8',env:{...process.env,npm_config_ignore_scripts:'true'},maxBuffer:8*1024*1024});}
    const dry=JSON.parse(npm(['pack','--dry-run','--ignore-scripts','--json']))[0];
    const expected=Object.keys(hashes).sort();
    if(JSON.stringify(dry.files.map((f:any)=>f.path).sort())!==JSON.stringify(expected))throw Error('npm dry-run payload differs from exact allowlist');
    writeJSON(path.join(output,'pack-dry-run.json'),dry);
    const packed=JSON.parse(npm(['pack','--ignore-scripts','--json','--pack-destination',output]))[0];
    const tarball=path.join(output,packed.filename);
    const repeated=path.join(output,'repeat');fs.mkdirSync(repeated);
    const second=JSON.parse(npm(['pack','--ignore-scripts','--json','--pack-destination',repeated]))[0];
    if(sha256(tarball)!==sha256(path.join(repeated,second.filename)))throw Error('Repeated same-source npm pack is not reproducible');
    const names=execFileSync('tar',['-tzf',tarball],{encoding:'utf8'}).trim().split('\n').sort();
    if(JSON.stringify(names)!==JSON.stringify(expected.map(p=>'package/'+p).sort()))throw Error('Tar members differ from curated regular-file allowlist');
    const unpacked=path.join(output,'unpacked');fs.mkdirSync(unpacked);execFileSync('tar',['-xzf',tarball,'-C',unpacked]);
    for(const [file,hash]of Object.entries(hashes))if(sha256(path.join(unpacked,'package',file))!==hash)throw Error('Packed bytes differ: '+file);
    const content=createHash('sha256').update(JSON.stringify(expected.map(p=>[p,hashes[p]]))).digest('hex');
    const manifest={name:spec.name,version,overlay,sourceHead:gitHead(),sourceDirty:gitDirty(),source_content_sha256:content,npm_version:execFileSync('npm',['--version'],{encoding:'utf8'}).trim(),tarball:packed.filename,tarball_sha256:sha256(tarball),integrity:packed.integrity,files:hashes,canonical_uids:uids.size,reproducible_pack:true};
    writeJSON(path.join(output,'package-manifest.json'),manifest);
    return {tarball,manifest};
}
if(import.meta.url==='file://'+process.argv[1]) {
    const [output,...flags]=process.argv.slice(2);if(!output || flags.some(f=>!['--require-clean','--release-context'].includes(f)))throw Error('Usage: pack-addon.ts NEW_ABSOLUTE_OUTPUT [--require-clean] [--release-context]');
    const result=packAddon(output,flags.includes('--require-clean'),flags.includes('--release-context')?currentContext():developmentContext());console.log(JSON.stringify({...result.manifest,tarball:result.tarball},null,2));console.log("PACKAGE_PACK_OK");
}
