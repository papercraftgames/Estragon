/** One proportionate, current-addon Linux acceptance run; no legacy matrix. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { spawnSync } from 'node:child_process';
import { ROOT, parseCLI, readJSON, writeJSON, gitHead, gitDirty, sha256 } from './compat-kit.ts';
import { SUITES } from './ci-plan.ts';
import { collectMetrics, assertFocusedGraphics } from './ci-metrics.ts';
import type { Stage } from './compat-kit.ts';
const argv = process.argv.slice(2), focused = argv.includes('--focused'), distributionOnly = argv.includes('--distribution-only'), bindableOnly = argv.includes('--bindable-only'), reactiveOnly = argv.includes('--reactive-only'), compositionOnly = argv.includes('--composition-only'), conditionalOnly = argv.includes('--conditional-only'), listsOnly = argv.includes('--lists-only'), twowayOnly = argv.includes('--twoway-only'), profilingOnly = argv.includes('--profiling-only'), packageOnly = argv.includes('--package-only'), cutoverOnly = argv.includes('--cutover-only');
const requested=argv.find(a=>a.startsWith('--suites='))?.slice(9).split(',');
if(requested && (!requested.length || requested.some(s=>!SUITES.includes(s as any)) || new Set(requested).size!==requested.length))throw Error('Unknown/duplicate focused suite');
const options = parseCLI(argv.filter(a => !['--focused', '--distribution-only', '--bindable-only', '--reactive-only', '--composition-only', '--conditional-only', '--lists-only', '--cutover-only', '--twoway-only', '--profiling-only', '--package-only'].includes(a) && !a.startsWith('--suites=')));
fs.mkdirSync(options.output, { recursive: true });
for (const selection of options.engines) {
    const output = path.join(options.output, selection.label);
    fs.mkdirSync(output, { recursive: true });
    const tools: Record<string, string> = { compiler: 'check-compatibility', runtime: 'check-node-runtime', ggx: 'check-ggx', ui: 'check-native-ui', metadata: 'check-godot-metadata', distribution: 'check-distribution', bindable: 'check-bindable', reactive: 'check-reactive', composition: 'check-composition', conditional: 'check-conditional', lists: 'check-lists', twoway: 'check-twoway', profiling: 'check-profiling', package: 'check-package' };
    const timings:Array<{name:string;seconds:number;exit_code:number|null}>=[];
    for (const [name, tool] of Object.entries(tools)) {
        if (requested && !requested.includes(name))continue;
        if (packageOnly && name !== 'package' || profilingOnly && name !== 'profiling' || twowayOnly && name !== 'twoway' || cutoverOnly && !['compiler', 'ggx', 'ui', 'reactive'].includes(name) || listsOnly && name !== 'lists' || conditionalOnly && name !== 'conditional' || compositionOnly && name !== 'composition' || reactiveOnly && name !== 'reactive' || bindableOnly && name !== 'bindable' || focused && !['compiler', 'ui', 'distribution'].includes(name) || distributionOnly && name !== 'distribution')
            continue;
        const args = [path.join(ROOT, 'tools', tool + '.ts'), '--engine', selection.label + '=' + selection.binary, '--output', path.join(output, name)];
        if (['runtime', 'ggx', 'ui'].includes(name))
            args.push('--graphics');
        const started=performance.now();
        const result = spawnSync(process.execPath, ['--experimental-strip-types', ...args], { cwd: ROOT, env: process.env, stdio: 'inherit' });
        timings.push({name,seconds:Math.round((performance.now()-started)/10)/100,exit_code:result.status});
        const metrics=collectMetrics(output,timings);
        writeJSON(path.join(output,'ci-performance.json'),metrics);
        if(requested)assertFocusedGraphics(metrics);
        console.log('CI_SUITE_TIMING '+name+' '+timings[timings.length-1]!.seconds+'s');
        if(process.env.GITHUB_STEP_SUMMARY)fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,'- '+selection.label+' / '+name+': '+timings[timings.length-1]!.seconds+'s (exit '+result.status+')\n');
        if (result.status !== 0)
            throw Error(name + ' acceptance failed');
    }
    if (requested || focused || distributionOnly || bindableOnly || reactiveOnly || compositionOnly || conditionalOnly || listsOnly || cutoverOnly || twowayOnly || profilingOnly || packageOnly)
        continue;
    const stages: Record<string, Stage> = {};
    const files: Record<string, string> = {};
    for (const name of Object.keys(tools)) {
        const location = path.join(output, name, selection.label, 'results.json');
        const value = readJSON<any>(location);
        if (name === 'metadata')
            stages.metadata = { status: value.status };
        else
            for (const [key, stage] of Object.entries(value))
                stages[name + '.' + key] = stage as Stage;
    }
    function scan(dir: string) {
        for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
            const file = path.join(dir, item.name);
            if (item.isDirectory())
                scan(file);
            else
                files[path.relative(output, file)] = sha256(file);
        }
    }
    scan(output);
    const provenance = readJSON<any>(path.join(output, 'ui', selection.label, 'provenance.json'));
    writeJSON(path.join(output, 'addon-evidence.json'), { source_commit: gitHead(), source_dirty: gitDirty(), label: selection.label, version: provenance.version, binary_sha256: provenance.original_binary_sha256, stages, files });
    const checked = spawnSync(process.execPath, ['--experimental-strip-types', path.join(ROOT, 'tools/assert-release.ts'), path.join(output, 'addon-evidence.json')], { stdio: 'inherit' });
    if (checked.status !== 0)
        throw Error('Native addon release acceptance failed');
}
