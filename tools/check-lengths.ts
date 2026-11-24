/** L06 focused direct-Yarn native unit-length layout compiler/editor/render/input proof. */
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
            const negative = name === 'rejections', editorStage = name.startsWith('editor');
            const result = await runCommand(args, name === 'install' ? box.project : box.workspace,
                env, logFile, marker, {abortOnError: !negative && !editorStage, expectedErrors: negative || editorStage, timeout: name.startsWith('editor') ? 120000 : 60000});
            const log = fs.readFileSync(logFile, 'utf8');
            if (negative) {
                let bracket = false, count = 0;
                const unexpected: string[] = [];
                for (const line of log.split(/\r?\n/)) {
                    if (line === 'L06_EXPECTED_REJECTION_BEGIN') bracket = true;
                    else if (line === 'L06_EXPECTED_REJECTION_END') bracket = false;
                    else if (ERROR.test(line)) {
                        if (bracket && (/^ERROR: Estragon length '(width|min_width|min_height)': (Invalid length:|Expected a finite nonnegative length|Length requires int, float or a unit string|Length is negative, nonfinite or outside the supported range)/.test(line) || /^ERROR: (?:res:\/\/)?app\/MinimumGallery\.gogo:\d+:\d+: invalid length 'min_width': Invalid length:/.test(line))) count++;
                        else unexpected.push(line);
                    }
                }
                if (bracket || count !== 24 || unexpected.length) {result.status = 'FAIL'; result.reason = 'Unexpected native rejection output: '+JSON.stringify({count, unexpected});}
            }
            if (editorStage) {
                let bracket=false,count=0,starts=0;const unexpected:string[]=[];
                for (const line of log.split(/\r?\n/)) {
                    if (line==='L11_EXPECTED_PLAY_REJECTION_BEGIN') {bracket=true;starts++;}
                    else if (line==='L11_EXPECTED_PLAY_REJECTION_END') bracket=false;
                    else if (ERROR.test(line)) {
                        if (bracket && line==='ERROR: An EditorPlugin build callback failed.') count++;
                        else unexpected.push(line);
                    }
                }
                if (bracket || count!==starts || starts>1 || unexpected.length) {result.status='FAIL';result.reason='Unexpected editor diagnostics '+JSON.stringify({starts,count,unexpected});}
            }
            results[name] = result;
            writeJSON(path.join(out, 'results.json'), results);
            process.stdout.write(log);
            if (result.status !== 'PASS') throw Error('L06 ' + name + ' failed');
        }
        const packed = packAddon(path.join(out, 'packed'), true);
        results.pack = {status: 'PASS', tarball_sha256: packed.manifest.tarball_sha256};
        fs.mkdirSync(box.project, {recursive: true});
        writeJSON(path.join(box.project, 'package.json'), {name: 'l06-native-consumer', private: true, packageManager: 'yarn@1.22.22'});
        await run('install', ['corepack', 'yarn@1.22.22', 'add', '--offline', '--exact', '--ignore-scripts', '--non-interactive',
            '--cache-folder', path.join(box.workspace, 'yarn-cache'), 'file:' + packed.tarball], undefined, process.env);
        const addon = 'node_modules/@papercraftgames/estragon/addons/estragon';
        const installed = path.join(box.project, 'node_modules/@papercraftgames/estragon');
        const fixtures = path.join(box.project, 'tests/lengths');
        copyTree(path.join(ROOT, 'tests/lengths'), fixtures);
        for (const name of fs.readdirSync(fixtures).filter(n => n.endsWith('.gd'))) {
            const file = path.join(fixtures, name);
            fs.writeFileSync(file, fs.readFileSync(file, 'utf8').replaceAll('res://addons/estragon', 'res://' + addon));
        }
        for(const suffix of ['.gd','.gd.uid'])fs.copyFileSync(path.join(ROOT,'examples/godot_button'+suffix),path.join(box.project,'godot_button'+suffix));
        fs.mkdirSync(path.join(box.project, 'app'), {recursive: true});
        fs.writeFileSync(path.join(box.project, 'app/Counter.gogo'),
            fs.readFileSync(path.join(ROOT, 'examples/counter/Counter.gogo'), 'utf8')
                .replaceAll('../../../addons/estragon', path.posix.relative('app/generated', addon)));
        for (const name of ['MinimumGallery','MinimumPanel']) {
            fs.writeFileSync(path.join(box.project,'app',name+'.gogo'),fs.readFileSync(path.join(ROOT,'examples/lengths',name+'.gogo'),'utf8')
                .replaceAll('../../../addons/estragon',path.posix.relative('app/generated',addon))
                +(name==='MinimumGallery'?'\nfunc _ready() -> void:\n    if OS.get_environment("L06_EDITOR")=="1": _l11_probe.call_deferred()\nfunc _l11_probe() -> void:\n    var probe = preload("res://tests/lengths/minimum_game.gd").new()\n    await probe.run(self)\n':''));
        }
        writeJSON(path.join(box.project, 'gogo.config.json'), {version: 1, source_roots: ['app']});
        fs.writeFileSync(path.join(box.project, 'project.godot'), 'config_version=5\n[application]\nconfig/name="L06 unit lengths"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1152\nwindow/size/viewport_height=648\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
        const args = [box.binary, '--audio-driver', 'Dummy', '--path', box.project];
        const graphics = ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3'];
        await run('build', [...args, '--headless', '--script', 'res://tests/lengths/build.gd'], 'L06_BUILD_OK');
        if (!editorOnly) {
            await run('rejections', [...args, '--headless', '--script', 'res://tests/lengths/rejections.gd'], 'L06_REJECTIONS_OK');
            await run('runtime', [...args, ...graphics, '--script', 'res://tests/lengths/runtime.gd'], 'L06_RUNTIME_OK');
            await run('root-exit', [...args, ...graphics, '--script', 'res://tests/lengths/root_exit.gd'], 'L07_ROOT_EXIT_OK', {...box.env, L07_EXIT: '1'});
        }
        if (editor) {
            // Godot 4.7 reads GameView embedding preferences during READY,
            // before a test plugin can change EditorSettings. Seed only this
            // fresh consumer's project metadata so native window resizes are
            // not overridden by the embedded game workspace (fixed-size mode).
            fs.mkdirSync(path.join(box.project, '.godot/editor'), {recursive: true});
            fs.writeFileSync(path.join(box.project, '.godot/editor/project_metadata.cfg'),
                '[game_view]\nembed_on_play=false\nmake_floating_on_play=false\n');
            box.env.L06_EDITOR = '1';
            fs.appendFileSync(path.join(box.project, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://' + addon + '/editor/plugin.cfg", "res://tests/lengths/plugin.cfg")\n[editor]\nrun/main_run_args="--audio-driver Dummy --rendering-method gl_compatibility --rendering-driver opengl3"\n');
            for (const name of ['editor', 'editor-restart']) {
                await run(name, [...args, ...graphics, '--editor'], 'L06_EDITOR_OK');
            }
            delete box.env.L06_EDITOR;
        }
        for (const [file, hash] of Object.entries(packed.manifest.files)) {
            if (sha256(path.join(installed, file)) !== hash) throw Error('Installed bytes/UID changed: ' + file);
        }
        writeJSON(path.join(out, 'consumer.json'), {source: gitHead(), profile: editorOnly ? 'L06-lengths-editor' : 'L06-lengths', direct_yarn: true,
            package_unchanged: true, canonical_uids: packed.manifest.canonical_uids, tarball_sha256: packed.manifest.tarball_sha256});
    } finally {
        if (fs.existsSync(box.project)) {
            for (const name of fs.readdirSync(box.project).filter(n => n.endsWith('.png') || n.endsWith('.json'))) {
                fs.copyFileSync(path.join(box.project, name), path.join(out, name));
            }
            for (const name of ['app/Home.tscn', '.godot/l06-game.json', '.godot/l07-game.json', '.godot/l07-root-game.json', '.godot/l11-game.json']) {
                const file = path.join(box.project, name);
                if (fs.existsSync(file)) fs.copyFileSync(file, path.join(out, path.basename(name) + '.txt'));
            }
        }
        writeJSON(path.join(out, 'results.json'), results);
        box.dispose();
    }
}
