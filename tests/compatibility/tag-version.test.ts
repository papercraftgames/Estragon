import assert from 'node:assert/strict';
import {test} from 'node:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import {ROOT,gitHead,sha256} from '../../tools/compat-kit.ts';
import {tagVersion,pluginVersion,stagedPluginCfg,DEVELOPMENT_VERSION} from '../../tools/package-version.ts';
import {releaseContext,assertOverlay,REPOSITORY} from '../../tools/release-context.ts';
import {packAddon} from '../../tools/pack-addon.ts';
import {verifyPackArtifact} from '../../tools/verify-npm-release.ts';
const tag='v0.3.7-beta.8',source={head:gitHead(),dirty:false};
const event={repository:{full_name:REPOSITORY},action:'published',release:{id:19,draft:false,prerelease:true,tag_name:tag}};
const release=()=>releaseContext(event,'release','refs/tags/'+tag,'',source);
test('strict tag version is independent of Git development metadata and preview is not authorization',()=>{
    assert.equal(release().version,tag.slice(1));
    for(const bad of ['v1.2.3','v0.1.2','0.1.2-beta.1','v0.01.2-beta.1','v0.1.02-beta.1','v0.1.2-beta.01','v0.1.2-beta.1+build','v0.1.2-beta.1\n','v0.1.2-beta.99999999999999999','v0.1.2-beta.1/escape'])assert.throws(()=>tagVersion(bad));
    for(const candidate of ['v0.8.4-beta.2',tag]) {
        const preview=releaseContext({repository:event.repository,inputs:{candidate_tag:candidate}},'workflow_dispatch','refs/heads/candidate',candidate,source,source.head,false);
        assert.equal(preview.mode,'preview');assert.equal(preview.release_id,null);assert.equal(preview.version,candidate.slice(1));
    }
    assert.throws(()=>releaseContext(event,'workflow_dispatch','refs/heads/main',tag,source));
    assert.throws(()=>releaseContext({...event,inputs:{candidate_tag:tag}},'workflow_dispatch','refs/tags/'+tag,tag,source));
    assert.throws(()=>releaseContext(event,'release','refs/tags/'+tag,tag,source));
    assert.throws(()=>releaseContext(event,'release','refs/tags/'+tag,'',{...source,dirty:true}));
    assert.throws(()=>assertOverlay(undefined,release()));
    assert.throws(()=>assertOverlay({...release(),overlayRecipe:'tampered'},release()));
    const cfg=fs.readFileSync(path.join(ROOT,'addons/estragon/editor/plugin.cfg'),'utf8');
    assert.equal(pluginVersion(cfg),DEVELOPMENT_VERSION);
    assert.equal(pluginVersion(stagedPluginCfg(cfg,release().version)),release().version);
    assert.throws(()=>stagedPluginCfg(cfg+'\nversion="duplicate"\n',release().version));
});
test('actual tag-versioned packs reproduce, source stays untouched, verifier rejects overlay/file/tar mutations',()=>{
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-tag-pack-'));
    const cfg=path.join(ROOT,'addons/estragon/editor/plugin.cfg'),before=fs.readFileSync(cfg);
    try {
        const context=release(),a=packAddon(path.join(dir,'first'),false,context),b=packAddon(path.join(dir,'second'),false,context);
        assert.deepEqual(fs.readFileSync(cfg),before);
        assert.equal(a.manifest.tarball_sha256,b.manifest.tarball_sha256);
        const root=path.join(dir,'first'),plugin='addons/estragon/editor/plugin.cfg';
        assert.equal(pluginVersion(fs.readFileSync(path.join(root,'unpacked/package',plugin),'utf8')),context.version);
        assert.equal(JSON.parse(fs.readFileSync(path.join(root,'unpacked/package/package.json'),'utf8')).version,context.version);
        // Isolated verifier fixtures model clean CI even while a contributor edits.
        // Native acceptance independently requires a real clean Git checkout.
        const manifest={...a.manifest,sourceDirty:false};
        const file=path.join(root,'package-manifest.json');
        const save=(value:unknown)=>fs.writeFileSync(file,JSON.stringify(value));
        save(manifest);assert.equal(verifyPackArtifact(root,context).manifest.version,context.version);
        for(const delta of [{overlay:undefined},{overlay:{...context,tag:'v0.3.7-beta.9'}},{overlay:{...context,mode:'preview'}},{overlay:{...context,overlayRecipe:'wrong'}},{version:'0.3.7-beta.9'},{sourceHead:'b'.repeat(40)},{sourceDirty:true},{files:{...manifest.files,extra:'bad'}}]) {
            save({...manifest,...delta});assert.throws(()=>verifyPackArtifact(root,context));
        }
        const mutated=stagedPluginCfg(before.toString(),'0.3.7-beta.9');
        fs.writeFileSync(path.join(root,'stage',plugin),mutated);
        save({...manifest,files:{...manifest.files,[plugin]:sha256(path.join(root,'stage',plugin))}});
        assert.throws(()=>verifyPackArtifact(root,context),'rehashing an unauthorized staged plugin cannot authorize it');
        save(manifest);fs.appendFileSync(a.tarball,'tampered');assert.throws(()=>verifyPackArtifact(root,context));
    } finally {fs.rmSync(dir,{recursive:true,force:true});}
});
