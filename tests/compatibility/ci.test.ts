import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { ROOT, sha256, runCommand } from '../../tools/compat-kit.ts';
import { planCI, SUITES } from '../../tools/ci-plan.ts';
import { verifyEngine } from '../../tools/verified-engine.ts';
import { collectMetrics, assertFocusedGraphics } from '../../tools/ci-metrics.ts';
test('main/dispatch always select full certification, docs PR skips native, changes select conservative suites',()=>{
    for(const event of ['push','workflow_dispatch'])assert.deepEqual(planCI(event,['docs/TESTING.md']),{mode:'acceptance',native:true,suites:[...SUITES]});
    assert.equal(planCI('pull_request',['README.md','AGENTS.md','docs/TESTING.md']).native,false);
    assert.deepEqual(planCI('pull_request',['tests/composition/editor/driver.gd']).suites,['composition']);
    assert.deepEqual(planCI('pull_request',['addons/estragon/editor/plugin.gd']).suites,['compiler','ui','package']);
    assert(planCI('pull_request',['addons/estragon/compiler/native/emitter.gd']).suites.includes('bindable'));
    for(const file of ['tools/compat-kit.ts','unknown/new.script','docs/live.gd','tests/compatibility/linux-engines.json','.github/actions/unexpected/action.yml'])assert.deepEqual(planCI('pull_request',[file]).suites,[...SUITES]);
    const combined=planCI('pull_request',['tests/lists/runtime.gd','tests/twoway/editor/driver.gd']);assert.deepEqual(combined.suites,['lists','twoway']);
    assert(planCI('pull_request',['.github/workflows/ci.yml']).suites.includes('package'));
});
test('cache hits require exact regular-file checksum and version, corruption never reaches execution',()=>{
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-cache-test-'));try {
        const binary=path.join(dir,'godot');fs.writeFileSync(binary,'verified bytes');
        const pin={binary_sha256:sha256(binary),version:'pinned-engine'};let executions=0;
        verifyEngine(binary,pin,()=>{executions++;return pin.version;});assert.equal(executions,1);
        assert.throws(()=>verifyEngine(binary,pin,()=> 'wrong-engine'));
        fs.symlinkSync(binary,path.join(dir,'linked'));assert.throws(()=>verifyEngine(path.join(dir,'linked'),pin,()=>pin.version));
        fs.writeFileSync(binary,'corrupt');assert.throws(()=>verifyEngine(binary,pin,()=>{executions++;return pin.version;}));assert.equal(executions,1);
    }finally{fs.rmSync(dir,{recursive:true,force:true});}
});
test('telemetry preserves failures, stage/editor timing and distinguishes actual direct PIDs from banners',async()=>{
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-metrics-test-'));try {
        const log=path.join(dir,'command.log');const result=await runCommand([process.execPath,'-e','console.log("timed");process.exit(2)'],dir,process.env,log);
        assert.equal(result.status,'FAIL');assert(Number(result.seconds)>=0);
        const out=path.join(dir,'composition','4.7');fs.mkdirSync(out,{recursive:true});
        fs.writeFileSync(path.join(out,'editor.log'),'Godot Engine v4.7\nCI_EDITOR_TIMING success_current 0.25\nGodot Engine v4.7\n');
        fs.writeFileSync(path.join(out,'results.json'),JSON.stringify({editor:{...result,command:['/tmp/godot','--editor'],godot_pid:123,log:'editor.log'}}));
        const metrics=collectMetrics(dir,[{name:'composition',seconds:1.5,exit_code:1}]);
        assert.equal(metrics.direct_godot_commands,1);assert.equal(metrics.recorded_godot_pids,1);assert.equal(metrics.observed_startup_banners,2);
        assert.deepEqual(metrics.stages[0].editor_scenarios,[{scenario:'success_current',seconds:0.25}]);assert.equal(metrics.stages[0].status,'FAIL');
        assert.throws(()=>assertFocusedGraphics(metrics));
        fs.appendFileSync(path.join(out,'editor.log'),'OpenGL API 4.5 Using Device: Mesa llvmpipe\n');
        assert.doesNotThrow(()=>assertFocusedGraphics(collectMetrics(dir,[])));
        assert.doesNotThrow(()=>assertFocusedGraphics({stages:[]} as any));
    }finally{fs.rmSync(dir,{recursive:true,force:true});}
});
test('workflow retains visible PR statuses and immutable reverified cache; release certification cannot use focused reports',()=>{
    const yaml=fs.readFileSync(path.join(ROOT,'.github/workflows/ci.yml'),'utf8');
    assert(!/^\s+paths(-ignore)?:/m.test(yaml));assert(yaml.includes('Native check policy status'));
    assert(yaml.includes("github.event_name != 'pull_request' || matrix.version == '4.7'"));
    assert(yaml.includes('runner.os')&&yaml.includes('runner.arch')&&yaml.includes('steps.engine.outputs.sha256'));assert(!yaml.includes('restore-keys:'));
    assert(yaml.includes('Authenticate official Linux engine'));assert(yaml.includes('if [ "$EVENT_NAME" = pull_request ]; then'));assert(yaml.includes('Actual Godot logs must prove llvmpipe'));assert(yaml.includes("'[\"4.0.4\", \"4.7\"]'"));
    const orchestrator=fs.readFileSync(path.join(ROOT,'tools/check-native-addon.ts'),'utf8');
    assert(orchestrator.includes('if (requested || focused ||'));assert(orchestrator.indexOf('if (requested || focused ||')<orchestrator.indexOf("'addon-evidence.json'"));
    const release=fs.readFileSync(path.join(ROOT,'tools/verify-npm-release.ts'),'utf8');assert(release.includes("run.event!=='push'"));assert(release.includes("run.head_branch!=='main'"));assert(release.includes('assessFile('));
});
test('optimized editor harnesses retain both Play entrypoints, negative observation, rollback/unsavable/recovery scenarios',()=>{
    for(const suite of ['native_ui','ggx','bindable','reactive','composition','conditional','lists','twoway','package-consumer']) {
        const driver=fs.readFileSync(path.join(ROOT,'tests',suite,'editor/driver.gd'),'utf8');
        for(const required of ['play_main_scene()','play_current_scene()','await _wait(0.8)','Script identity/source','DirAccess.make_dir_absolute(SOURCE)','CI_EDITOR_TIMING','get_tree().process_frame','not _plugin._extensions_pending','not _interface.is_playing_scene()'])assert(driver.includes(required),suite+': '+required);
        assert(!driver.includes('await _wait(1)'));assert(!driver.includes('_interface.stop_playing_scene()\n\tawait _wait(0.5)'));
    }
});
