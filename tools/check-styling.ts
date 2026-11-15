/** S01 focused direct-Yarn local styling / border-box native and editor proof. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import {ROOT, parseCLI, newSandbox, copyTree, runCommand, ERROR, writeJSON, gitHead, gitDirty, sha256} from './compat-kit.ts';
import {packAddon} from './pack-addon.ts';
const editorOnly = process.argv.includes('--editor-only');
const editor = editorOnly || process.argv.includes('--editor');
const options = parseCLI(process.argv.slice(2).filter(a => !['--editor', '--editor-only'].includes(a)));
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
        async function run(name: string, args: string[], marker?: string, env = box.env) {
            const logFile = path.join(out, name + '.log');
            const negative = name === 'rejections';
            const result = await runCommand(args, name === 'install' ? box.project : box.workspace,
                env, logFile, marker, {abortOnError: !negative, expectedErrors: negative, timeout: name.startsWith('editor') ? 120000 : 60000});
            const log = fs.readFileSync(logFile, 'utf8');
            if (negative) {
                let bracket = false, count = 0;
                const unexpected: string[] = [];
                for (const line of log.split(/\r?\n/)) {
                    if (line === 'S01_EXPECTED_REJECTION_BEGIN') bracket = true;
                    else if (line === 'S01_EXPECTED_REJECTION_END') bracket = false;
                    else if (ERROR.test(line)) {
                        if (bracket && (/^ERROR: Estragon (style 'background_color':|length 'border_width':)/.test(line) || line === 'ERROR: Estragon style: Text/Rect/Button painters retain their local API until S02')) count++;
                        else unexpected.push(line);
                    }
                }
                if (bracket || count !== 18 || unexpected.length) {result.status = 'FAIL'; result.reason = 'Unexpected native rejection output: '+JSON.stringify({count, unexpected});}
            }
            results[name] = result;
            writeJSON(path.join(out, 'results.json'), results);
            process.stdout.write(log);
            if (result.status !== 'PASS') throw Error('S01 ' + name + ' failed');
        }
        const packed = packAddon(path.join(out, 'packed'), true);
        results.pack = {status: 'PASS', tarball_sha256: packed.manifest.tarball_sha256};
        fs.mkdirSync(box.project, {recursive: true});
        writeJSON(path.join(box.project, 'package.json'), {name: 's01-native-consumer', private: true, packageManager: 'yarn@1.22.22'});
        await run('install', ['corepack', 'yarn@1.22.22', 'add', '--offline', '--exact', '--ignore-scripts', '--non-interactive',
            '--cache-folder', path.join(box.workspace, 'yarn-cache'), 'file:' + packed.tarball], undefined, process.env);
        const addon = 'node_modules/@papercraftgames/estragon/addons/estragon';
        const installed = path.join(box.project, 'node_modules/@papercraftgames/estragon');
        const fixtures = path.join(box.project, 'tests/styling');
        copyTree(path.join(ROOT, 'tests/styling'), fixtures);
        for (const name of fs.readdirSync(fixtures).filter(n => n.endsWith('.gd'))) {
            const file = path.join(fixtures, name);
            fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replaceAll('res://addons/estragon', 'res://' + addon));
        }
        fs.mkdirSync(path.join(box.project, 'app'), {recursive: true});
        for (const name of ['StyleGallery', 'StyledSettings', 'StyledRose']) {
            fs.writeFileSync(path.join(box.project, 'app', name+'.gogo'),
                fs.readFileSync(path.join(ROOT, 'examples/styling',name+'.gogo'), 'utf8')
                    .replaceAll('../../../addons/estragon', path.posix.relative('app/generated', addon))
                    +(name==='StyleGallery'?'\nfunc _ready() -> void:\n\tif OS.get_environment("S01_EDITOR")=="1": _s01_game_probe.call_deferred()\n\nfunc _s01_game_probe() -> void:\n\tvar probe = preload("res://tests/styling/game.gd").new()\n\tawait probe.run(self)\n':''));
        }
        writeJSON(path.join(box.project, 'gogo.config.json'), {version: 1, source_roots: ['app']});
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="S01 native styling"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1152\nwindow/size/viewport_height=648\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        const args = [box.binary, '--audio-driver', 'Dummy', '--path', box.project];
        const graphics = ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3'];
        await run('build', [...args, '--headless', '--script', 'res://tests/styling/build.gd'], 'S01_BUILD_OK');
        if (!editorOnly) {
            await run('rejections', [...args, '--headless', '--script', 'res://tests/styling/rejections.gd'], 'S01_REJECTIONS_OK');
            await run('runtime', [...args, ...graphics, '--script', 'res://tests/styling/runtime.gd'], 'S01_RUNTIME_OK');
        }
        if (editor) {
            // Godot 4.7 reads GameView embedding preferences during READY,
            // before a test plugin can change EditorSettings. Seed only this
            // fresh consumer's project metadata so native window resizes are
            // not overridden by the embedded game workspace (fixed-size mode).
            fs.mkdirSync(path.join(box.project, '.godot/editor'), {recursive: true});
            fs.writeFileSync(path.join(box.project, '.godot/editor/project_metadata.cfg'),
                '[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
            box.env.S01_EDITOR = '1';
            fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://' + addon + '/editor/plugin.cfg", "res://tests/styling/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
            for (const name of ['editor', 'editor-restart']) {
                await run(name, [...args, ...graphics, '--editor'], 'S01_EDITOR_OK');
            }
            delete box.env.S01_EDITOR;
        }
        for (const [file, hash] of Object.entries(packed.manifest.files)) {
            if (sha256(path.join(installed, file)) !== hash) throw Error('Installed bytes/UID changed: ' + file);
        }
        writeJSON(path.join(out, 'consumer.json'), {source: gitHead(), profile: editorOnly ? 'S01-styling-editor' : 'S01-styling', direct_yarn: true,
            package_unchanged: true, canonical_uids: packed.manifest.canonical_uids, tarball_sha256: packed.manifest.tarball_sha256});
    } finally {
        if (fs.existsSync(box.project)) {
            for (const name of fs.readdirSync(box.project).filter(n => n.endsWith('.png') || n.endsWith('.json'))) {
                fs.copyFileSync(path.join(box.project, name), path.join(out, name));
            }
            for (const name of ['app/StyleGallery.tscn', '.godot/s01-game.json']) {
                const file = path.join(box.project, name);
                if (fs.existsSync(file)) fs.copyFileSync(file, path.join(out, path.basename(name) + '.txt'));
            }
        }
        writeJSON(path.join(out, 'results.json'), results);
        box.dispose();
    }
}
