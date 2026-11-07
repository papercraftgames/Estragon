import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
import * as os from 'node:os';
import * as path from 'node:path';
import { ROOT, sha256 } from '../../tools/compat-kit.ts';
import { packAddon } from '../../tools/pack-addon.ts';
import { verifyReleaseIdentity } from '../../tools/verify-npm-release.ts';
import { addonVersion, stagedPackageJson } from '../../tools/package-version.ts';
test('addon-only npm artifact is reproducible, private-tooling separated and rooted for Godot',()=>{
    const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-package-test-'));
    try {
        const output=path.join(temporary,'packed');const {manifest,tarball}=packAddon(output);
        assert.equal(manifest.name,'@papercraftgames/estragon');assert(manifest.reproducible_pack);
        assert.equal(sha256(tarball),manifest.tarball_sha256);
        assert(Object.keys(manifest.files).includes('addons/estragon/editor/plugin.cfg'));
        assert(Object.keys(manifest.files).includes('addons/estragon/compiler/diagnostic_capture.gd.txt'));
        assert(Object.keys(manifest.files).includes('addons/estragon/runtime/composition/profile.tres'));
        assert(!Object.keys(manifest.files).some(p=>/^(tests|examples|Assets|tools|node_modules)\//.test(p)||p.includes('.godot')||p.includes('.npmrc')));
        assert.equal(fs.readFileSync(path.join(output,'unpacked/package/LICENSE'),'utf8'),fs.readFileSync(path.join(ROOT,'LICENSE'),'utf8'));
        assert.equal(JSON.parse(fs.readFileSync(path.join(ROOT,'package.json'),'utf8')).private,true);
        const metadata=JSON.parse(fs.readFileSync(path.join(output,'unpacked/package/package.json'),'utf8'));
        assert(!metadata.scripts && !metadata.dependencies && !metadata.bin);
        const spec=JSON.parse(fs.readFileSync(path.join(ROOT,'packages/estragon/package.json'),'utf8'));
        assert.equal(Object.hasOwn(spec,'version'),false,'npm version must not be committed');
        assert.equal(metadata.version,addonVersion());
        assert.equal(fs.readFileSync(path.join(output,'unpacked/package/package.json'),'utf8'),stagedPackageJson(spec,addonVersion()));
        assert.throws(()=>stagedPackageJson({...spec,version:addonVersion()},addonVersion()));
    } finally {fs.rmSync(temporary,{recursive:true,force:true});}
});
test('pre-publication preparation rejects routine main or stale/mismatched run identities',()=>{
    const version='0.3.7-beta.8';
    const run={id:123,repository:{full_name:'papercraftgames/Estragon'},path:'.github/workflows/npm-release.yml',event:'release',head_sha:'approved',status:'in_progress',conclusion:null};
    const source={head:'approved',dirty:false};
    const verify=(candidate:any)=>verifyReleaseIdentity(candidate,version,'papercraftgames/Estragon',source,'123');
    assert.doesNotThrow(()=>verify(run));
    assert.doesNotThrow(()=>verify({...run,event:'workflow_dispatch',path:'.github/workflows/ci.yml'}));
    for(const change of [{id:122},{event:'pull_request'},{event:'push',path:'.github/workflows/ci.yml'},{head_sha:'other'},{conclusion:'failure'},{conclusion:'cancelled'},{status:'completed'},{path:'.github/workflows/other.yml'},{repository:{full_name:'fork/Estragon'}}])assert.throws(()=>verify({...run,...change}));
    assert.throws(()=>verifyReleaseIdentity(run,version.replace(/^0/,'1'),'papercraftgames/Estragon',source,'123'));
    assert.throws(()=>verifyReleaseIdentity(run,version,'papercraftgames/Estragon',{...source,dirty:true},'123'));
});

test('Git metadata is development-only; release numbers exist only in events or test fixtures',()=>{
    const root=ROOT;
    const plugin=fs.readFileSync(path.join(root,'addons/estragon/editor/plugin.cfg'),'utf8');
    assert.equal((plugin.match(/^version=/gm)||[]).length,1);
    assert.equal(addonVersion(),plugin.match(/^version="([^"]+)"$/m)?.[1]);
    const metadata=JSON.parse(fs.readFileSync(path.join(root,'packages/estragon/package.json'),'utf8'));
    assert.equal(Object.hasOwn(metadata,'version'),false);
    const tracked=execFileSync('git',['ls-files','-z'],{cwd:root,encoding:'utf8'}).split('\0').filter(Boolean);
    const pinnedPrerelease=/\b0\.\d+\.\d+-beta\.\d+\b/i;
    const version=addonVersion();
    assert.equal(version,'0.0.0-dev');
    for(const file of tracked.filter(file=>file.endsWith('.md'))) {
        const contents=fs.readFileSync(path.join(root,file),'utf8');
        assert(!pinnedPrerelease.test(contents),'Documentation must not hardcode package release versions: '+file);
    }
    for(const file of tracked.filter(file=>/\.(?:ts|tsx|json|cfg|gd|gogo|yml|yaml|md)$/.test(file) && file!=='addons/estragon/editor/plugin.cfg')) {
        const contents=fs.readFileSync(path.join(root,file),'utf8');
        if(!file.startsWith('tests/') && !file.startsWith('tools/'))assert(!pinnedPrerelease.test(contents),'Release version must not be committed metadata: '+file);
    }
});

test('P02 production dependencies and emitted injections have no fixed installation root',()=>{
    const files=execFileSync('git',['ls-files','-z','addons/estragon'],{cwd:ROOT,encoding:'utf8'}).split('\0').filter(file=>/\.(gd|tres)$/.test(file));
    for(const file of files) {
        const code=fs.readFileSync(path.join(ROOT,file),'utf8');
        assert(!/addons\/estragon|node_modules\//.test(code),'Fixed addon root: '+file);
        for(const match of code.matchAll(/(?:preload\(|load\(|extends\s+|path=)"([a-zA-Z0-9_./:-]+)"/g)) {
            assert(!match[1]!.startsWith('res://'),'Internal dependencies must be script-relative: '+file);
            assert(fs.existsSync(path.resolve(ROOT,path.dirname(file),match[1]!)),'Missing relative dependency: '+file);
        }
    }
    const emitter=fs.readFileSync(path.join(ROOT,'addons/estragon/compiler/emitter.gd'),'utf8');
    for(const resource of ['State','Element','Binding'])assert(emitter.includes('_resource('+resource+')'));
    const consumer=fs.readFileSync(path.join(ROOT,'tools/check-package.ts'),'utf8');
    assert(!consumer.includes("fs.cpSync(") && !consumer.includes("fs.symlinkSync("));
    assert(consumer.includes("['direct', 'node_modules/@papercraftgames/estragon/addons/estragon']"));
    assert(consumer.includes("['relocated', 'modules/UI toolkit']"));
    assert(consumer.includes("['standard', 'addons/estragon']"));
    assert(!consumer.includes("writeFileSync(path.join(box.project,'node_modules/.gdignore')"));
});
