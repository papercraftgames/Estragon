/** C01-H cache-free addon/examples and resource-pack distribution; no compiler toolchain. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, copyFile, copyTree, engineRecord, freshProject, indexProject, listGDScripts,
  newSandbox, parseCLI, reportMetadata, runCommand, sourceHashes, stageStatus,
  unavailable, writeJSON, sha256 } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";

export async function audit(selection: EngineSelection, output: string, graphics = false): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label);
  fs.mkdirSync(target);
  const record = engineRecord(selection, sandbox);
  const project = sandbox.project;
  const log = (name: string): string => path.join(target, name + ".log");
  try {
    freshProject(sandbox, true);
    const config = fs.readFileSync(path.join(project, "project.godot"), "utf8");
    const scenes = ["hello/Hello", "layout/Layout", "compiled/Compiled", "mixed/Mixed",
      "interactive/Interactive", "counter/Counter"];
    const uidFiles: Record<string, string> = {};
    const scripts = listGDScripts(path.join(project, "addons/estragon"));
    for (const file of [...scripts, ...listGDScripts(path.join(project, "examples"))]) {
      if (fs.existsSync(file + ".uid")) uidFiles[path.relative(project, file + ".uid")] = sha256(file + ".uid");
    }
    const sceneFormats = scenes.every(scene =>
      /^\[gd_scene [^\n]*format=3\]/.test(fs.readFileSync(path.join(project, "examples", scene + ".tscn"), "utf8")));
    record.stages.package_layout = {
      status: config.includes('config/features=PackedStringArray("4.0", "GL Compatibility")') && sceneFormats ? "PASS" : "FAIL",
      evidence: { scenes, uid_sidecars: uidFiles, cache_free: !fs.existsSync(path.join(project, ".godot")) },
    };
    record.stages.distribution_import = await indexProject(sandbox, project, log("distribution_import"));
    copyFile(path.join(ROOT, "tests/distribution/scenes.gd"), path.join(project, "tests/distribution/scenes.gd"));
    record.stages.distribution_scenes = await runCommand(
      [sandbox.binary, "--headless", "--path", project, "--script", "res://tests/distribution/scenes.gd"],
      sandbox.workspace, sandbox.env, log("distribution_scenes"), "C01_H_DISTRIBUTION_OK", { abortOnError: true });

    const original = fs.readFileSync(path.join(project, "project.godot"));
    const driver = path.join(project, "tests/distribution");
    copyFile(path.join(ROOT, "tests/distribution/editor.gd"), path.join(driver, "editor.gd"));
    fs.writeFileSync(path.join(driver, "plugin.cfg"),
      '[plugin]\nname="C01-H shipped script context"\ndescription="Test only"\nauthor="Estragon"\nversion="1"\nscript="editor.gd"\n');
    writeJSON(path.join(project, "shipped-scripts.json"), scripts.map(file =>
      "res://" + path.relative(project, file).split(path.sep).join("/")));
    fs.appendFileSync(path.join(project, "project.godot"),
      '\n[editor_plugins]\nenabled=PackedStringArray("res://tests/distribution/plugin.cfg")\n');
    try {
      record.stages.shipped_scripts_editor = await runCommand(
        [sandbox.binary, "--headless", "--editor", "--path", project], sandbox.workspace,
        sandbox.env, log("shipped_scripts_editor"), "C01_H_EDITOR_CONTEXT_OK", { timeout: 90000, abortOnError: true });
    } finally { fs.writeFileSync(path.join(project, "project.godot"), original); }
    fs.rmSync(path.join(driver, "plugin.cfg"));
    fs.rmSync(path.join(driver, "editor.gd"));

    // Resource-pack export uses built-in editor export support, not an executable
    // template. Runtime is launched from a separate empty directory below.
    fs.writeFileSync(path.join(project, "export_presets.cfg"),
      '[preset.0]\nname="C01 resource pack"\nplatform="macOS"\nrunnable=true\n' +
      'export_filter="resources"\nexport_files=PackedStringArray(' +
      [...scenes.map(scene => '"res://examples/' + scene + '.tscn"'),
        ...listGDScripts(path.join(project, "addons/estragon/runtime")).map(file =>
          '"res://' + path.relative(project, file).split(path.sep).join("/") + '"'),
        '"res://tests/distribution/scenes.gd"'].join(', ') + ')\ninclude_filter="*.json,*.gogo"\nexclude_filter=""\n' +
      'export_path=""\nscript_export_mode=1\n[preset.0.options]\napplication/bundle_identifier="org.estragon.c01h"\n');
    const pack = path.join(target, "examples.pck");
    record.stages.resource_pack_export = await runCommand(
      [sandbox.binary, "--headless", "--editor", "--path", project, "--export-pack", "C01 resource pack", pack],
      sandbox.workspace, sandbox.env, log("resource_pack_export"), undefined, { timeout: 90000 });
    if (!fs.existsSync(pack) || fs.statSync(pack).size === 0) record.stages.resource_pack_export.status = "FAIL";
    if (fs.existsSync(pack) && fs.statSync(pack).size > 0) {
      record.stages.resource_pack_export.evidence = { sha256: sha256(pack), bytes: fs.statSync(pack).size };
      const empty = path.join(sandbox.workspace, "empty-runtime");
      fs.mkdirSync(empty);
      record.stages.resource_pack_runtime = await runCommand(
        [sandbox.binary, "--headless", "--path", empty, "--main-pack", pack,
          "--script", "res://tests/distribution/scenes.gd", "--", "--pack"],
        empty, sandbox.env, log("resource_pack_runtime"), "C01_H_DISTRIBUTION_OK", { abortOnError: true });
    } else record.stages.resource_pack_runtime = unavailable("Pack export failed");
    const cold = path.join(sandbox.workspace, "cold-scene");
    copyTree(path.join(ROOT, "addons"), path.join(cold, "addons"));
    copyTree(path.join(ROOT, "examples"), path.join(cold, "examples"));
    copyFile(path.join(ROOT, "gogo.config.json"), path.join(cold, "gogo.config.json"));
    for (const name of ["compiled", "mixed", "counter"]) {
      fs.rmSync(path.join(cold, "examples", name, "generated"), { recursive: true });
    }
    fs.writeFileSync(path.join(cold, "project.godot"), config.replace(
      "res://examples/hello/Hello.tscn", "res://examples/counter/Counter.tscn") +
      '\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg")\n');
    record.stages.cold_scene_restore = await indexProject(sandbox, cold, log("cold_scene_restore"),
      ["res://examples/counter/Counter.tscn"]);
    copyFile(path.join(ROOT, "tests/distribution/build.gd"), path.join(cold, "build.gd"));
    record.stages.source_only_build = await runCommand(
      [sandbox.binary, "--headless", "--path", cold, "--script", "res://build.gd"],
      sandbox.workspace, sandbox.env, log("source_only_build"), "C01_H_SOURCE_ONLY_OK", { abortOnError: true });

    record.stages.native_graphics = unavailable("No graphical capture requested", "UNTESTED");
    if (graphics) {
      copyFile(path.join(ROOT, "tests/godot/native_counter.gd"), path.join(project, "native_counter.gd"));
      record.stages.native_graphics = await runCommand(
        [sandbox.binary, "--path", project, "--script", "res://native_counter.gd", "--", "--visual"],
        sandbox.workspace, sandbox.env, log("native_graphics"), "ESTRAGON_NATIVE_COUNTER_OK", { timeout: 90000, abortOnError: true });
      const images = [];
      for (const name of ["zero", "one", "reset-resized"]) {
        const image = path.join(project, "native-counter-" + name + ".png");
        if (!fs.existsSync(image)) { record.stages.native_graphics.status = "FAIL"; continue; }
        copyFile(image, path.join(target, path.basename(image)));
        const bytes = fs.readFileSync(image);
        const width = bytes.readUInt32BE(16), height = bytes.readUInt32BE(20);
        if (width !== (name === "reset-resized" ? 800 : 640) || height !== (name === "reset-resized" ? 400 : 360)) record.stages.native_graphics.status = "FAIL";
        images.push({ file: path.basename(image), sha256: sha256(image), width, height });
      }
      record.stages.native_graphics.evidence = { images, scope: process.platform + " native GPU Counter input/resize; visual review is separate" };
    }
    // Keep absence of executable templates/platform proof visible, not an invented PASS.
    record.stages.executable_export = unavailable("Resource-pack evidence does not verify standalone executable export", "UNTESTED");
    record.stages.other_platforms = unavailable("Only the executing OS/engine is exercised", "UNTESTED");
    return record;
  } finally {
    writeJSON(path.join(target, "report.json"), record);
    sandbox.dispose();
  }
}
async function main(): Promise<void> {
  const args = parseCLI(process.argv.slice(2), { collectOnly: true, graphics: true });
  fs.mkdirSync(args.output);
  const report = { ...reportMetadata(), source_hashes: sourceHashes([
    "tools/check-distribution.ts", "tools/compat-kit.ts", "project.godot",
    "tests/distribution/scenes.gd", "tests/distribution/editor.gd", "tests/distribution/build.gd",
    "tests/godot/native_counter.gd",
  ]), engines: [] as EngineRecord[] };
  for (const selection of args.engines) {
    report.engines.push(await audit(selection, args.output, args.graphics));
    console.log(selection.label, stageStatus(report.engines.at(-1)!));
  }
  writeJSON(path.join(args.output, "results.json"), report);
  if (!args.collectOnly && report.engines.some(row => Object.entries(row.stages)
    .some(([, stage]) => stage.status !== "PASS"))) {
    process.exitCode = 1;
  }
}
if (import.meta.url === "file://" + process.argv[1]) main().catch(error => { console.error(error); process.exitCode = 1; });
