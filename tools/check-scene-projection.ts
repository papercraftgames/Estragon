/** E08 focused direct-Yarn native scene projection/editor/render/input proof. */
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
                env, logFile, marker, {abortOnError: !negative, expectedErrors: negative, timeout: 60000});
            const log = fs.readFileSync(logFile, 'utf8');
            if (negative) {
                // Only these deliberately triggered diagnostics are permitted.
                const expected = name === 'negative'
                    ? /^ERROR: (?:app\/Home\.gogo:\d+:\d+: GGX scene child referenced more than once: .*|negative\.gogo:1:1: GGX borrowed children must be persistent direct children of the rendering host: .*|Invalid composition output or foreign boundary conflict; previous tree retained)$/
                    : /^ERROR: An EditorPlugin build callback failed\.$/;
                result.unexpected_errors = log.split(/\r?\n/).filter(line => ERROR.test(line) && !expected.test(line));
                const count = log.split(/\r?\n/).filter(line => expected.test(line)).length;
                if ((result.unexpected_errors as string[]).length || /E08_(?:EDITOR_)?CHECK .*: false/.test(log)
                    || name === 'negative' && count !== 3) result.status = 'FAIL';
            }
            results[name] = result;
            writeJSON(path.join(out, 'results.json'), results);
            process.stdout.write(log);
            if (result.status !== 'PASS') throw Error('E08 ' + name + ' failed');
        }
        const packed = packAddon(path.join(out, 'packed'), true);
        results.pack = {status: 'PASS', tarball_sha256: packed.manifest.tarball_sha256};
        fs.mkdirSync(box.project, {recursive: true});
        writeJSON(path.join(box.project, 'package.json'), {name: 'e08-native-consumer', private: true, packageManager: 'yarn@1.22.22'});
        await run('install', ['corepack', 'yarn@1.22.22', 'add', '--offline', '--exact', '--ignore-scripts', '--non-interactive',
            '--cache-folder', path.join(box.workspace, 'yarn-cache'), 'file:' + packed.tarball], undefined, process.env);
        const addon = 'node_modules/@papercraftgames/estragon/addons/estragon';
        const installed = path.join(box.project, 'node_modules/@papercraftgames/estragon');
        const fixtures = path.join(box.project, 'tests/scene_projection');
        copyTree(path.join(ROOT, 'tests/scene_projection'), fixtures);
        for (const name of fs.readdirSync(fixtures).filter(n => n.endsWith('.gd'))) {
            const file = path.join(fixtures, name);
            fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replaceAll('res://addons/estragon', 'res://' + addon));
        }
        writeJSON(path.join(box.project, 'gogo.config.json'), {version: 1, source_roots: ['app']});
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="E08 native projection"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        const args = [box.binary, '--audio-driver', 'Dummy', '--path', box.project];
        const graphics = ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3'];
        await run('build', [...args, '--headless', '--script', 'res://tests/scene_projection/build.gd'], 'E08_BUILD_OK');
        await run('runtime', [...args, ...graphics, '--script', 'res://tests/scene_projection/runtime.gd'], 'E08_RUNTIME_OK');
        box.env.E08_NEGATIVE = '1';
        await run('negative', [...args, ...graphics, '--script', 'res://tests/scene_projection/runtime.gd'], 'E08_NEGATIVE_OK', box.env, true);
        delete box.env.E08_NEGATIVE;
        if (editor) {
            box.env.E08_EDITOR_PROOF = '1';
            fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://' + addon + '/editor/plugin.cfg", "res://tests/scene_projection/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
            for (const name of ['editor', 'editor-restart']) {
                await run(name, [...args, ...graphics, '--editor'], 'E08_EDITOR_OK', box.env, true);
            }
        }
        for (const [file, hash] of Object.entries(packed.manifest.files)) {
            if (sha256(path.join(installed, file)) !== hash) throw Error('Installed bytes/UID changed: ' + file);
        }
        writeJSON(path.join(out, 'consumer.json'), {source: gitHead(), profile: 'E08-scene-projection', direct_yarn: true,
            package_unchanged: true, canonical_uids: packed.manifest.canonical_uids, tarball_sha256: packed.manifest.tarball_sha256});
    } finally {
        if (fs.existsSync(box.project)) {
            for (const name of fs.readdirSync(box.project).filter(n => n.endsWith('.png') || n === 'geometry.json')) {
                fs.copyFileSync(path.join(box.project, name), path.join(out, name));
            }
            for (const name of ['Reload.tscn', 'app/Home.tscn', '.godot/e08-game.json']) {
                const file = path.join(box.project, name);
                if (fs.existsSync(file)) fs.copyFileSync(file, path.join(out, path.basename(name) + '.txt'));
            }
        }
        writeJSON(path.join(out, 'results.json'), results);
        box.dispose();
    }
}
