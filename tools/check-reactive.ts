/** T09-A: bundled native compile/runtime and real model editor Play/rollback. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, indexProject, runCommand, listGDScripts, gitHead, gitDirty, writeJSON } from './compat-kit.ts';
const options = parseCLI(process.argv.slice(2));
fs.mkdirSync(options.output, { recursive: true });
for (const selection of options.engines) {
    const box = newSandbox(selection), out = path.join(options.output, selection.label);
    fs.mkdirSync(out, { recursive: true });
    const stages: Record<string, any> = {};
    try {
        for (const dir of ['addons/estragon', 'examples/reactive', 'examples/counter', 'tests/reactive'])
            copyTree(path.join(ROOT, dir), path.join(box.project, dir));
        fs.writeFileSync(path.join(box.project, 'gogo.config.json'), JSON.stringify({ version: 1, source_roots: ['examples/reactive', 'examples/counter'] }));
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="T09-A models"\nrun/main_scene="res://examples/reactive/Demo.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        writeJSON(path.join(out, 'provenance.json'), { sourceHead: gitHead(), sourceDirty: gitDirty(), version: box.version, original_binary_sha256: box.inputHash });
        async function run(name: string, args: string[], marker: string, negative = false) {
            const log = path.join(out, name + '.log');
            const stage = await runCommand([box.binary, '--headless', '--audio-driver', 'Dummy', '--path', box.project, ...args], box.workspace, box.env, log, marker, { abortOnError: !negative, expectedErrors: negative, timeout: negative ? 240000 : 60000 });
            const text = fs.readFileSync(log, 'utf8');
            process.stdout.write(text);
            if (negative) {
                const lines = text.split(/\r?\n/);
                const errors = lines.filter((l, i) => {
                    if (!/SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed:/.test(l))
                        return false;
                    if (l === 'ERROR: An EditorPlugin build callback failed.' || l === 'ERROR: Cannot save text file \'res://examples/reactive/Demo.gogo\'.')
                        return false;
                    if ((/^SCRIPT ERROR: Parse Error:/.test(l) && /res:\/\/examples\/reactive\/generated\/Demo\.gd:\d+\)/.test(lines[i + 1] || '') || /^examples\/reactive\/Demo\.gogo:\d+:\d+: Parse Error:/.test(l)) && /Cannot find member|Cannot assign|Cannot pass|Invalid argument|Cannot convert|Invalid access/.test(l)) return false;
                    return true;
                });
                stage.unexpected_errors = errors;
                if (errors.length || /REACTIVE_EDITOR_CHECK .*: false/.test(text) || !text.includes('REACTIVE_EDITOR_CHECK'))
                    stage.status = 'FAIL';
            }
            if (/instances leaked|Resources still in use/.test(text))
                stage.status = 'FAIL';
            stages[name] = stage;
            writeJSON(path.join(out, 'results.json'), stages);
            if (stage.status !== 'PASS')
                throw Error('Reactive ' + name + ' failed');
        }
        await run('build', ['--script', 'res://tests/reactive/build.gd'], 'REACTIVE_BUILD_OK');
        copyTree(path.join(box.project, 'examples/reactive/generated'), path.join(out, 'generated'));
        stages.import = await indexProject(box, box.project, path.join(out, 'import.log'), ['--audio-driver', 'Dummy']);
        if (stages.import.status !== 'PASS')
            throw Error('Reactive indexing failed');
        for (const dir of ['addons/estragon', 'examples/reactive', 'tests/reactive'])
            for (const file of listGDScripts(path.join(box.project, dir))) {
                if (fs.existsSync(file + '.uid')) {
                    const target = path.join(out, 'canonical-uids', path.relative(box.project, file) + '.uid');
                    fs.mkdirSync(path.dirname(target), { recursive: true });
                    fs.copyFileSync(file + '.uid', target);
                }
            }
        await run('runtime', ['--script', 'res://tests/reactive/runtime.gd'], 'REACTIVE_RUNTIME_OK');
        fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/reactive/editor/plugin.cfg")\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
        box.env.ESTRAGON_REACTIVE_PROOF = '1';
        await run('editor', ['--editor'], 'REACTIVE_EDITOR_OK', true);
        delete box.env.ESTRAGON_REACTIVE_PROOF;
        const visual = await runCommand([box.binary, '--audio-driver', 'Dummy', '--path', box.project, '--script', 'res://tests/reactive/visual.gd'], box.workspace, box.env, path.join(out, 'visual.log'), 'REACTIVE_VISUAL_OK', { abortOnError: true });
        stages.visual = visual;
        process.stdout.write(fs.readFileSync(path.join(out, 'visual.log'), 'utf8'));
        for (const file of fs.readdirSync(box.project).filter(n => n.endsWith('.png'))) fs.copyFileSync(path.join(box.project,file),path.join(out,file));
        if (visual.status !== 'PASS') throw Error('Reactive graphics failed');
    }
    finally {
        writeJSON(path.join(out, 'results.json'), stages);
        box.dispose();
    }
}
