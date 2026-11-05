/** Fresh Godot addon install/source-only rebuild/resource-pack integration. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, freshProject, copyTree, indexProject, runCommand, writeJSON, gitHead, gitDirty, listGDScripts } from './compat-kit.ts';
import type { Stage } from './compat-kit.ts';
const options = parseCLI(process.argv.slice(2));
fs.mkdirSync(options.output, { recursive: true });
for (const selection of options.engines) {
    const box = newSandbox(selection), output = path.join(options.output, selection.label);
    fs.mkdirSync(output, { recursive: true });
    const stages: Record<string, Stage> = {};
    try {
        freshProject(box, true);
        copyTree(path.join(ROOT, 'tests/distribution'), path.join(box.project, 'tests/distribution'));
        writeJSON(path.join(output, 'provenance.json'), { sourceHead: gitHead(), sourceDirty: gitDirty(), version: box.version, original_binary_sha256: box.inputHash });
        const config = fs.readFileSync(path.join(box.project, 'project.godot'), 'utf8');
        stages.package_layout = { status: config.includes('config/features=PackedStringArray("4.0", "GL Compatibility")') && !fs.existsSync(path.join(box.project, '.godot')) ? 'PASS' : 'FAIL' };
        async function run(name: string, project: string, script: string, marker: string, extra: string[] = []) {
            const stage = await runCommand([box.binary, '--headless', '--audio-driver', 'Dummy', '--path', project, '--script', script, ...extra], box.workspace, box.env, path.join(output, name + '.log'), marker, { abortOnError: true });
            const log = fs.readFileSync(path.join(output, name + '.log'), 'utf8');
            if (/instances leaked|Resources still in use/.test(log))
                stage.status = 'FAIL';
            stages[name] = stage;
            process.stdout.write(log);
            writeJSON(path.join(output, 'results.json'), stages);
            if (stage.status !== 'PASS')
                throw Error('Addon distribution ' + name + ' failed');
        }
        stages.import = await indexProject(box, box.project, path.join(output, 'import.log'), ['--audio-driver', 'Dummy']);
        if (stages.import.status !== 'PASS')
            throw Error('Native addon install import failed');
        await run('scenes', box.project, 'res://tests/distribution/scenes.gd', 'ADDON_DISTRIBUTION_OK');
        const cold = path.join(box.workspace, 'cold');
        fs.cpSync(box.project, cold, { recursive: true });
        fs.rmSync(path.join(cold, '.godot'), { recursive: true, force: true });
        for (const name of ['counter', 'ggx', 'bindable', 'reactive', 'composition'])
            fs.rmSync(path.join(cold, 'examples', name, 'generated'), { recursive: true, force: true });
        await run('cold_build', cold, 'res://tests/distribution/build.gd', 'ADDON_COLD_BUILD_OK');
        await run('cold_scenes', cold, 'res://tests/distribution/scenes.gd', 'ADDON_DISTRIBUTION_OK');
        const coldEditor = path.join(box.workspace, 'cold-editor');
        fs.cpSync(cold, coldEditor, { recursive: true });
        fs.rmSync(path.join(coldEditor, '.godot'), { recursive: true, force: true });
        for (const name of ['counter', 'ggx', 'bindable', 'reactive', 'composition'])
            fs.rmSync(path.join(coldEditor, 'examples', name, 'generated'), { recursive: true, force: true });
        fs.appendFileSync(path.join(coldEditor, 'project.godot'), '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg")\n');
        stages.cold_editor = await indexProject(box, coldEditor, path.join(output, 'cold_editor.log'), ['--audio-driver', 'Dummy', 'res://examples/counter/Counter.tscn']);
        if (stages.cold_editor.status !== 'PASS')
            throw Error('Native cold editor scene restoration failed');
        const resources = ['examples/counter/Counter.tscn', 'examples/ggx/TwoD.tscn', 'examples/ggx/ThreeD.tscn', 'examples/bindable/Demo.tscn', 'examples/reactive/Demo.tscn', 'examples/composition/Counter.tscn', 'tests/distribution/scenes.gd', ...[...listGDScripts(path.join(box.project, 'addons/estragon/runtime')), ...listGDScripts(path.join(box.project, 'examples'))].map(f => path.relative(box.project, f))];
        fs.writeFileSync(path.join(box.project, 'export_presets.cfg'), '[preset.0]\nname="Native addon runtime"\nplatform="Linux/X11"\nrunnable=true\nexport_filter="resources"\nexport_files=PackedStringArray(' + resources.map(p => '"res://' + p + '"').join(',') + ')\ninclude_filter="*.gogo,*.json"\nexclude_filter=""\nexport_path=""\nscript_export_mode=1\n[preset.0.options]\nbinary_format/architecture="x86_64"\n');
        const pack = path.join(output, 'addon.pck');
        // Let the engine finish cleanup so diagnostics identify retained resources;
        // runCommand still rejects every native error/leak even with exit zero.
        stages.pack_export = await runCommand([box.binary, '--headless', '--verbose', '--audio-driver', 'Dummy', '--editor', '--path', box.project, '--export-pack', 'Native addon runtime', pack], box.workspace, box.env, path.join(output, 'pack_export.log'), undefined, { timeout: 90000 });
        process.stdout.write(fs.readFileSync(path.join(output, 'pack_export.log'), 'utf8'));
        if (!fs.existsSync(pack) || fs.statSync(pack).size === 0 || stages.pack_export.status !== 'PASS')
            throw Error('Native addon consumer editor pack export failed');
        const bare = path.join(box.workspace, 'pack-runtime');
        fs.mkdirSync(bare);
        const stage = await runCommand([box.binary, '--headless', '--audio-driver', 'Dummy', '--path', bare, '--main-pack', pack, '--script', 'res://tests/distribution/scenes.gd'], box.workspace, box.env, path.join(output, 'pack_runtime.log'), 'ADDON_DISTRIBUTION_OK', { abortOnError: true });
        stages.pack_runtime = stage;
        process.stdout.write(fs.readFileSync(path.join(output, 'pack_runtime.log'), 'utf8'));
        if (stage.status !== 'PASS')
            throw Error('Native addon pack runtime failed');
    }
    finally {
        writeJSON(path.join(output, 'results.json'), stages);
        box.dispose();
    }
}
