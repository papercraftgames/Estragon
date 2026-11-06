import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
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
test('automatic npm preparation rejects unverified or mismatched repository/source/version evidence',()=>{
    const version=addonVersion();
    const run={repository:{full_name:'papercraftgames/Estragon'},path:'.github/workflows/ci.yml',event:'push',head_branch:'main',head_sha:'approved',status:'completed',conclusion:'success'};
    const source={head:'approved',dirty:false};
    assert.doesNotThrow(()=>verifyReleaseIdentity(run,version,'papercraftgames/Estragon',source));
    for(const change of [{event:'pull_request'},{head_branch:'feature'},{head_sha:'other'},{conclusion:'failure'},{status:'in_progress'},{path:'.github/workflows/other.yml'},{repository:{full_name:'fork/Estragon'}}])assert.throws(()=>verifyReleaseIdentity({...run,...change},version,'papercraftgames/Estragon',source));
    assert.throws(()=>verifyReleaseIdentity(run,version.replace(/^0/,'1'),'papercraftgames/Estragon',source));
    assert.throws(()=>verifyReleaseIdentity(run,version,'fork/Estragon',source));
    assert.throws(()=>verifyReleaseIdentity(run,version,'papercraftgames/Estragon',{...source,dirty:true}));
});

test('only the Godot plugin commits a release version; documentation contains no pinned beta versions',()=>{
    const root=ROOT;
    const plugin=fs.readFileSync(path.join(root,'addons/estragon/editor/plugin.cfg'),'utf8');
    assert.equal((plugin.match(/^version=/gm)||[]).length,1);
    assert.equal(addonVersion(),plugin.match(/^version="([^"]+)"$/m)?.[1]);
    const metadata=JSON.parse(fs.readFileSync(path.join(root,'packages/estragon/package.json'),'utf8'));
    assert.equal(Object.hasOwn(metadata,'version'),false);
    const pages=[
        'README.md',
        'packages/estragon/README.md',
        'packages/estragon/CHANGELOG.md',
        'docs/PACKAGING.md',
        'docs/WORK_STATUS.md',
        'docs/EXECUTION_PLAN.md',
    ];
    const pinnedPrerelease=/\\b\\d+\\.\\d+\\.\\d+-(?:alpha|beta|rc)\\.\\d+\\b/i;
    for(const page of pages) {
        const contents=fs.readFileSync(path.join(root,page),'utf8');
        assert(!pinnedPrerelease.test(contents),'Documentation must use an npm dist-tag, not a pinned release version: '+page);
    }
});
