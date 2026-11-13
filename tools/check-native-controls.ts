/** L04 focused direct-Yarn native scene projection/editor/render/input proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, writeJSON, gitHead, gitDirty, sha256, ERROR} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
const editor = process.argv.includes('--editor');
const options = parseCLI(process.argv.slice(2).filter(a => a !== '--editor'));
if (process.platform !== 'linux') throw Error('Approved Linux engines only');
fs.mkdirSync(options.output, {recursive: true});
for (const selection of options.engines) {
    const box = newSandbox(selection), out = path.join(options.output, selection.label);
    const results: Record<string, any> = {};
    fs.mkdirSync(out, {recursive: true});
    try {
        writeJSON(path.join(out, 'provenance.json'), {
            sourceHead: gitHead(), sourceDirty: gitDirty(), version: box.version,
            original_binary_sha256: box.inputHash, command: process.argv,
        });
        async function run(name: string, args: string[], marker?: string, env = box.env, negative = false) {
            const logFile = path.join(out, name + '.log');
            const result = await runCommand(args, name === 'install' ? box.project : box.workspace,
                env, logFile, marker, {abortOnError: !negative, expectedErrors: negative, timeout: name.startsWith('editor') ? 120000 : 60000});
            const log = fs.readFileSync(logFile, 'utf8');
            if (negative) {
                // Only these deliberately triggered diagnostics are permitted.
                const expected = /^ERROR: An EditorPlugin build callback failed\.$/;
                result.unexpected_errors = log.split(/\r?\n/).filter(line => ERROR.test(line) && !expected.test(line));
                if ((result.unexpected_errors as string[]).length || /L04_(?:EDITOR_)?CHECK .*: false/.test(log)) result.status = 'FAIL';
            }
            results[name] = result;
            writeJSON(path.join(out, 'results.json'), results);
            process.stdout.write(log);
            if (result.status !== 'PASS') throw Error('L04 ' + name + ' failed');
        }
        const packed = packAddon(path.join(out, 'packed'), true);
        results.pack = {status: 'PASS', tarball_sha256: packed.manifest.tarball_sha256};
        fs.mkdirSync(box.project, {recursive: true});
        writeJSON(path.join(box.project, 'package.json'), {name: 'l04-native-consumer', private: true, packageManager: 'yarn@1.22.22'});
        await run('install', ['corepack', 'yarn@1.22.22', 'add', '--offline', '--exact', '--ignore-scripts', '--non-interactive',
            '--cache-folder', path.join(box.workspace, 'yarn-cache'), 'file:' + packed.tarball], undefined, process.env);
        const addon = 'node_modules/@papercraftgames/estragon/addons/estragon';
        const installed = path.join(box.project, 'node_modules/@papercraftgames/estragon');
        const fixtures = path.join(box.project, 'tests/native_controls');
        copyTree(path.join(ROOT, 'tests/native_controls'), fixtures);
        for (const name of fs.readdirSync(fixtures).filter(n => n.endsWith('.gd'))) {
            const file = path.join(fixtures, name);
            fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replaceAll('res://addons/estragon', 'res://' + addon));
        }
        writeJSON(path.join(box.project, 'gogo.config.json'), {version: 1, source_roots: ['app']});
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="L04 native projection"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        const args = [box.binary, '--audio-driver', 'Dummy', '--path', box.project];
        const graphics = ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3'];
        await run('build', [...args, '--headless', '--script', 'res://tests/native_controls/build.gd'], 'L04_BUILD_OK');
        await run('runtime', [...args, ...graphics, '--script', 'res://tests/native_controls/runtime.gd'], 'L04_RUNTIME_OK');
        box.env.L04_EXIT = '1';
        await run('exit', [...args, ...graphics, '--script', 'res://tests/native_controls/runtime.gd'], 'L04_EXIT_QUIT');
        delete box.env.L04_EXIT;
        if (editor) {
            box.env.L04_EDITOR_PROOF = '1';
            fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://' + addon + '/editor/plugin.cfg", "res://tests/native_controls/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
            for (const name of ['editor', 'editor-restart']) {
                await run(name, [...args, ...graphics, '--editor'], 'L04_EDITOR_OK', box.env, true);
            }
            delete box.env.L04_EDITOR_PROOF;
        }
        const examples = path.join(box.project, 'examples/nested_layout');
        copyTree(path.join(ROOT, 'examples/nested_layout'), examples);
        for (const name of fs.readdirSync(examples).filter(n => n.endsWith('.gogo'))) {
            const file = path.join(examples, name);
            fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replaceAll('../../../addons/estragon', '../../../' + addon));
        }
        writeJSON(path.join(box.project, 'gogo.config.json'), {version: 1, source_roots: ['examples/nested_layout']});
        box.env.L04_EXAMPLES = '1';
        await run('examples-build', [...args, '--headless', '--script', 'res://tests/native_controls/build.gd'], 'L04_BUILD_OK');
        await run('examples', [...args, ...graphics, '--script', 'res://tests/native_controls/runtime.gd'], 'L04_EXAMPLES_OK');
        delete box.env.L04_EXAMPLES;
        for (const [file, hash] of Object.entries(packed.manifest.files)) {
            if (sha256(path.join(installed, file)) !== hash) throw Error('Installed bytes/UID changed: ' + file);
        }
        writeJSON(path.join(out, 'consumer.json'), {source: gitHead(), profile: 'L04-native-controls', direct_yarn: true,
            package_unchanged: true, canonical_uids: packed.manifest.canonical_uids, tarball_sha256: packed.manifest.tarball_sha256});
    } finally {
        if (fs.existsSync(box.project)) {
            for (const name of fs.readdirSync(box.project).filter(n => n.endsWith('.png') || ['geometry.json','after.json','before.json'].includes(n))) {
                fs.copyFileSync(path.join(box.project, name), path.join(out, name));
            }
            for (const name of ['ControlsReload.tscn', 'app/Home.tscn', 'app/Borrow.tscn', '.godot/l04-game.json', '.godot/l04-borrow-game.json']) {
                const file = path.join(box.project, name);
                if (fs.existsSync(file)) fs.copyFileSync(file, path.join(out, path.basename(name) + '.txt'));
            }
        }
        writeJSON(path.join(out, 'results.json'), results);
        box.dispose();
    }
}
