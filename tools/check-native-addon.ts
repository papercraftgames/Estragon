/** One proportionate, current-addon Linux acceptance run; no legacy matrix. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { spawnSync } from 'node:child_process';
import { ROOT, parseCLI, readJSON, writeJSON, gitHead, gitDirty, sha256 } from './compat-kit.ts';
import type { Stage } from './compat-kit.ts';
const argv = process.argv.slice(2), focused = argv.includes('--focused'), distributionOnly = argv.includes('--distribution-only'), bindableOnly = argv.includes('--bindable-only'), reactiveOnly = argv.includes('--reactive-only'), compositionOnly = argv.includes('--composition-only'), conditionalOnly = argv.includes('--conditional-only'), listsOnly = argv.includes('--lists-only');
const options = parseCLI(argv.filter(a => !['--focused', '--distribution-only', '--bindable-only', '--reactive-only', '--composition-only', '--conditional-only', '--lists-only'].includes(a)));
fs.mkdirSync(options.output, { recursive: true });
for (const selection of options.engines) {
    const output = path.join(options.output, selection.label);
    fs.mkdirSync(output, { recursive: true });
    const tools: Record<string, string> = { compiler: 'check-compatibility', runtime: 'check-node-runtime', ggx: 'check-ggx', ui: 'check-native-ui', metadata: 'check-godot-metadata', distribution: 'check-distribution', bindable: 'check-bindable', reactive: 'check-reactive', composition: 'check-composition', conditional: 'check-conditional', lists: 'check-lists' };
    for (const [name, tool] of Object.entries(tools)) {
        if (listsOnly && name !== 'lists' || conditionalOnly && name !== 'conditional' || compositionOnly && name !== 'composition' || reactiveOnly && name !== 'reactive' || bindableOnly && name !== 'bindable' || focused && !['compiler', 'ui', 'distribution'].includes(name) || distributionOnly && name !== 'distribution')
            continue;
        const args = [path.join(ROOT, 'tools', tool + '.ts'), '--engine', selection.label + '=' + selection.binary, '--output', path.join(output, name)];
        if (['runtime', 'ggx', 'ui'].includes(name))
            args.push('--graphics');
        const result = spawnSync(process.execPath, ['--experimental-strip-types', ...args], { cwd: ROOT, env: process.env, stdio: 'inherit' });
        if (result.status !== 0)
            throw Error(name + ' acceptance failed');
    }
    if (focused || distributionOnly || bindableOnly || reactiveOnly || compositionOnly || conditionalOnly || listsOnly)
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
