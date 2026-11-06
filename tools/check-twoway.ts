/** F05-B: native twoway property/runtime/editor/graphics acceptance. */
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
        for (const dir of ['addons/estragon', 'examples', 'tests/twoway'])
            copyTree(path.join(ROOT, dir), path.join(box.project, dir));
        fs.copyFileSync(path.join(ROOT, 'gogo.config.json'),path.join(box.project, 'gogo.config.json'));
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="F05-B two-way GGX"\nrun/main_scene="res://examples/twoway/Demo.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
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
                    if (l === 'ERROR: An EditorPlugin build callback failed.' || l === 'ERROR: Cannot save text file \'res://examples/twoway/Demo.gogo\'.')
                        return false;
                    if ((/^SCRIPT ERROR: Parse Error:/.test(l) && /res:\/\/examples\/twoway\/generated\/Demo\.gd:\d+\)/.test(lines[i + 1] || '') || /^examples\/twoway\/Demo\.gogo:\d+:\d+: Parse Error:/.test(l)) && /Identifier "missing_handler" not declared|Cannot find member|Cannot assign|Cannot pass|Invalid argument|Cannot convert|Invalid access/.test(l)) return false;
                    return true;
                });
                stage.unexpected_errors = errors;
                if (errors.length || /TWOWAY_EDITOR_CHECK .*: false/.test(text) || !text.includes('TWOWAY_EDITOR_CHECK'))
                    stage.status = 'FAIL';
            }
            if (/instances leaked|Resources still in use/.test(text))
                stage.status = 'FAIL';
            stages[name] = stage;
            writeJSON(path.join(out, 'results.json'), stages);
            if (stage.status !== 'PASS')
                throw Error('TwoWay ' + name + ' failed');
        }
        await run('build', ['--script', 'res://tests/twoway/build.gd'], 'TWOWAY_BUILD_OK');
        copyTree(path.join(box.project, 'examples/twoway/generated'), path.join(out, 'generated'));
        for (const name of ['counter','ggx','bindable','reactive','composition','conditional','inventory','twoway']) copyTree(path.join(box.project,'examples',name,'generated'),path.join(out,'generated-all','examples',name,'generated'));
        stages.import = await indexProject(box, box.project, path.join(out, 'import.log'), ['--audio-driver', 'Dummy']);
        if (stages.import.status !== 'PASS')
            throw Error('TwoWay indexing failed');
        for (const dir of ['addons/estragon', 'examples', 'tests/twoway'])
            for (const file of listGDScripts(path.join(box.project, dir))) {
                if (fs.existsSync(file + '.uid')) {
                    const target = path.join(out, 'canonical-uids', path.relative(box.project, file) + '.uid');
                    fs.mkdirSync(path.dirname(target), { recursive: true });
                    fs.copyFileSync(file + '.uid', target);
                }
            }
        await run('runtime', ['--script', 'res://tests/twoway/runtime.gd'], 'TWOWAY_RUNTIME_OK');
        
        fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/twoway/editor/plugin.cfg")\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
        box.env.ESTRAGON_TWOWAY_PROOF = '1';
        await run('editor', ['--editor'], 'TWOWAY_EDITOR_OK', true);
        delete box.env.ESTRAGON_TWOWAY_PROOF;
        const visual = await runCommand([box.binary, '--audio-driver', 'Dummy', '--path', box.project, '--script', 'res://tests/twoway/visual.gd'], box.workspace, box.env, path.join(out, 'visual.log'), 'TWOWAY_VISUAL_OK', { abortOnError: true });
        stages.visual = visual;
        process.stdout.write(fs.readFileSync(path.join(out, 'visual.log'), 'utf8'));
        for (const file of fs.readdirSync(box.project).filter(n => n.endsWith('.png'))) fs.copyFileSync(path.join(box.project,file),path.join(out,file));
        if (visual.status !== 'PASS') throw Error('TwoWay graphics failed');
    }
    finally {
        writeJSON(path.join(out, 'results.json'), stages);
        box.dispose();
    }
}
