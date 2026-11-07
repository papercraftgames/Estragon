import assert from 'node:assert/strict';
import { test } from 'node:test';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { ROOT, sha256, runCommand } from '../../tools/compat-kit.ts';
import { measureRoutine } from '../../tools/measure-routine-ci.ts';
import { planCI } from '../../tools/ci-plan.ts';
import { verifyEngine } from '../../tools/verified-engine.ts';
import { collectMetrics, assertFocusedGraphics } from '../../tools/ci-metrics.ts';
test('routine PR and main always stay tiny, docs skip native, unknown paths cannot select exhaustive suites',()=>{
    for(const event of ['push','pull_request','workflow_dispatch']) {
        assert.equal(planCI(event,['docs/TESTING.md','docs/example.png']).native,false);
        for(const file of ['tools/compat-kit.ts','.github/workflows/ci.yml','addons/estragon/compiler/compiler.gd','unknown/script']) {
            assert.deepEqual(planCI(event,[file]),{mode:'routine',native:true,smoke:'compiler-bindable',budget_seconds:60});
        }
        assert.equal(planCI(event,[]).native,true);
    }
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
test('routine workflows cannot launch editors/full suites; certification is an explicit hard publication dependency',()=>{
    const routine=fs.readFileSync(path.join(ROOT,'.github/workflows/ci.yml'),'utf8');
    const fast=routine.slice(0,routine.indexOf('  certify:'));
    assert(!/^\s+paths(-ignore)?:/m.test(routine));assert(fast.includes('Native check policy status'));
    assert(fast.includes("if: always() && inputs.verification_mode != 'certification'"));
    assert(fast.includes('test "$TOOLING_RESULT" = success'));
    for(const heavy of ['check-native-addon.ts','apt-get','xvfb','--editor','--suites'])assert(!fast.includes(heavy),heavy);
    assert(fast.includes('check-routine-smoke.ts'));assert(fast.includes('timeout-minutes: 1'));
    assert(fast.includes('runner.os')&&fast.includes('runner.arch')&&fast.includes('steps.engine.outputs.sha256'));
    const smoke=fs.readFileSync(path.join(ROOT,'tools/check-routine-smoke.ts'),'utf8');
    assert(!smoke.includes('indexProject'));assert(smoke.includes('timeout:10000'));assert(!smoke.includes("'--editor'"));
    const release=fs.readFileSync(path.join(ROOT,'.github/workflows/npm-release.yml'),'utf8');
    assert(release.includes('needs: [certify, prepare]'));assert(release.includes('needs: [certify, prepare, publish, consumer]'));
    assert(release.includes("if: github.event_name == 'release'"));assert(!release.includes('NPM_BOOTSTRAP_TOKEN'));
    const cert=fs.readFileSync(path.join(ROOT,'.github/workflows/certify.yml'),'utf8');
    assert(cert.includes("version: ['4.0.4', '4.7']"));assert(cert.includes('check-native-addon.ts'));assert(!cert.includes('--suites'));
    assert(cert.includes('EXPECTED_SOURCE'));assert(cert.includes('git status --porcelain'));
    const verifier=fs.readFileSync(path.join(ROOT,'tools/verify-npm-release.ts'),'utf8');
    assert(verifier.includes('verifyCertificationJobs(jobs.jobs)'));assert(verifier.includes('assessFile('));assert(!verifier.includes('selectVerificationRun'));
});
test('optimized editor harnesses retain both Play entrypoints, negative observation, rollback/unsavable/recovery scenarios',()=>{
    for(const suite of ['native_ui','ggx','bindable','reactive','composition','conditional','lists','twoway','package-consumer']) {
        const driver=fs.readFileSync(path.join(ROOT,'tests',suite,'editor/driver.gd'),'utf8');
        for(const required of ['play_main_scene()','play_current_scene()','await _wait(0.8)','Script identity/source','DirAccess.make_dir_absolute(SOURCE)','CI_EDITOR_TIMING','get_tree().process_frame','not _plugin._extensions_pending','not _interface.is_playing_scene()'])assert(driver.includes(required),suite+': '+required);
        assert(!driver.includes('await _wait(1)'));assert(!driver.includes('_interface.stop_playing_scene()\n\tawait _wait(0.5)'));
    }
});

test('proof-file existence precedes complete JSON; editor harnesses wait for and cache validated snapshots',()=>{
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),'estragon-proof-race-'));
    try {
        const proof=path.join(dir,'play.json'),writer=fs.openSync(proof,'w');
        try {
            assert(fs.existsSync(proof));
            assert.throws(()=>JSON.parse(fs.readFileSync(proof,'utf8')),'file-exists polling exposes an empty write');
            fs.writeSync(writer,'{"width":');
            assert.throws(()=>JSON.parse(fs.readFileSync(proof,'utf8')),'partial content is not a completed proof');
            fs.writeSync(writer,'77,"dimension":3,"native":true}');
        }finally{fs.closeSync(writer);}
        const snapshot=JSON.parse(fs.readFileSync(proof,'utf8'));
        fs.writeFileSync(proof,'');
        assert.deepEqual(snapshot,{width:77,dimension:3,native:true},'a validated snapshot survives subsequent file changes');
        for(const suite of ['native_ui','ggx','bindable','reactive','composition','conditional','lists','twoway','package-consumer']) {
            const driver=fs.readFileSync(path.join(ROOT,'tests',suite,'editor/driver.gd'),'utf8');
            const helper=driver.slice(driver.indexOf('func _proof_ready()'),driver.indexOf('func _clear_proof()'));
            assert(helper.includes('parsed.parse(FileAccess.get_file_as_string(PROOF)) != OK: return false'),suite);
            assert(helper.indexOf('parsed.parse(')<helper.indexOf('_ready_proof = parsed.data'),suite);
            assert(helper.includes('not parsed.data is Dictionary or parsed.data.is_empty()'),suite);
            assert(driver.includes('await _until(_proof_ready,'),suite);
            assert(driver.includes('var proof := _ready_proof'),suite);
            assert(driver.includes('func _clear_proof() -> void:\n\t_ready_proof = {}'),suite);
            assert(!driver.includes('JSON.parse_string(FileAccess.get_file_as_string(PROOF))'),suite);
        }
    }finally{fs.rmSync(dir,{recursive:true,force:true});}
});

test('routine budget measures end-to-end required checks, separates queue and rejects missing/failed checks',()=>{
    const stamp=(seconds:number)=>new Date(Date.UTC(2026,0,1,0,0,seconds)).toISOString();
    const jobs=['tooling','addon (4.0.4)','addon (4.7)'].map((name,i)=>({name,status:'completed',conclusion:'success',started_at:stamp(i?20:3),completed_at:stamp(i===2?50:18+i),steps:[]}));
    const run={id:1,event:'push',head_sha:'source',created_at:stamp(0)};
    const result=measureRoutine(run,jobs);assert.equal(result.queue_seconds,3);assert.equal(result.execution_wall_seconds,47);assert(result.within_budget);
    assert.equal(measureRoutine(run,[...jobs.slice(0,2),{...jobs[2],completed_at:stamp(65)}]).within_budget,false);
    assert.throws(()=>measureRoutine(run,jobs.slice(0,2)));
    assert.throws(()=>measureRoutine(run,jobs.map(j=>({...j,conclusion:'cancelled'}))));
});

test('focused editor UX stays opt-in and cannot expand routine or publication certification',()=>{
    const workflow=fs.readFileSync(path.join(ROOT,'.github/workflows/editor-ux.yml'),'utf8');
    assert(workflow.includes('types: [labeled]'));
    assert(workflow.includes("github.event.label.name == 'editor-ux-acceptance'"));
    assert(!/^  push:/m.test(workflow));
    assert(workflow.includes('permissions:\n  contents: read'));
    assert(workflow.includes('check-editor-ux.ts'));
    assert(!workflow.includes('npm publish'));
    const routine=fs.readFileSync(path.join(ROOT,'.github/workflows/ci.yml'),'utf8');
    const release=fs.readFileSync(path.join(ROOT,'.github/workflows/npm-release.yml'),'utf8');
    assert(!routine.includes('editor-ux'));assert(!release.includes('editor-ux'));
});
