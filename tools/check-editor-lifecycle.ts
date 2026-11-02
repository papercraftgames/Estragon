/** Real Godot editor lifecycle/restart proof, with TypeScript orchestration. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, copyFile, copyTree, engineRecord, gitDirty, gitHead, newSandbox,
  parseCLI, reportMetadata, runCommand, sourceHashes, stageStatus, unavailable,
  writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";

export async function audit(selection: EngineSelection, output: string): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label);
  fs.mkdirSync(target);
  const record = engineRecord(selection, sandbox);
  const project = sandbox.project;
  const put = (file: string, text: string): void => {
    const destination = path.join(project, file);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, text);
  };
  try {
    copyTree(path.join(ROOT, "addons/estragon"), path.join(project, "addons/estragon"));
    copyFile(path.join(ROOT, "examples/counter/Counter.gogo"), path.join(project, "ui/Counter.gogo"));
    put("ui/Counter.tscn", fs.readFileSync(path.join(ROOT, "examples/counter/Counter.tscn"), "utf8")
      .replace("res://examples/counter/generated/Counter.gd", "res://ui/generated/Counter.gd"));
    put("ui/generated/Counter.gd",
      fs.readFileSync(path.join(ROOT, "examples/counter/generated/Counter.gd"), "utf8")
        .replace("var count: int = 0", "var count: int = -1"));
    copyFile(path.join(ROOT, "tests/editor/lifecycle/driver.gd"),
      path.join(project, "tests/lifecycle/driver.gd"));
    copyFile(path.join(ROOT, "tests/editor/lifecycle/runtime.gd"),
      path.join(project, "tests/lifecycle/runtime.gd"));
    put("tests/lifecycle/plugin.cfg",
      '[plugin]\nname="C01-F lifecycle driver"\ndescription="Test only"\nauthor="Estragon"\nversion="1"\nscript="driver.gd"\n');
    put("gogo.config.json", '{"version":1,"source_roots":["ui"]}\n');
    put("project.godot",
      'config_version=5\n[application]\nconfig/name="C01-F isolated lifecycle"\n' +
      'run/main_scene="res://ui/Counter.tscn"\n' +
      'config/features=PackedStringArray("4.0", "GL Compatibility")\n' +
      '[rendering]\nrenderer/rendering_method="gl_compatibility"\n' +
      '[editor_plugins]\nenabled=PackedStringArray(' +
      '"res://tests/lifecycle/plugin.cfg", "res://addons/estragon/editor/plugin.cfg")\n');
    for (const phase of [1, 2]) {
      const name = "lifecycle_" + phase;
      record.stages[name] = await runCommand(
        [sandbox.binary, "--headless", "--editor", "--path", project], sandbox.workspace,
        sandbox.env, path.join(target, name + ".log"),
        "C01_F_LIFECYCLE_PHASE_" + phase + "_OK", { timeout: 120000, abortOnError: true });
      if (record.stages[name].status !== "PASS") {
        if (phase === 1) record.stages["lifecycle_2"] = unavailable("First phase failed");
        break;
      }
      const runtime = "runtime_after_" + phase;
      record.stages[runtime] = await runCommand(
        [sandbox.binary, "--headless", "--path", project, "--script",
          "res://tests/lifecycle/runtime.gd"],
        sandbox.workspace, sandbox.env, path.join(target, runtime + ".log"),
        "C01_F_PUBLISHED_RUNTIME_OK", { abortOnError: true });
    }
    return record;
  } finally {
    writeJSON(path.join(target, "report.json"), record);
    sandbox.dispose();
  }
}

async function main(): Promise<void> {
  const args = parseCLI(process.argv.slice(2));
  fs.mkdirSync(args.output);
  const report = { ...reportMetadata(), source_hashes: sourceHashes([
    "addons/estragon/editor/plugin.gd", "tools/check-editor-lifecycle.ts",
    "tests/editor/lifecycle/driver.gd", "tests/editor/lifecycle/runtime.gd",
  ]), engines: [] as EngineRecord[] };
  for (const selection of args.engines) {
    report.engines.push(await audit(selection, args.output));
    const latest = report.engines.at(-1)!;
    console.log(latest.version, stageStatus(latest));
  }
  writeJSON(path.join(args.output, "results.json"), report);
  if (report.engines.some(row => Object.values(row.stages).some(stage => stage.status !== "PASS"))) {
    process.exitCode = 1;
  }
}
if (import.meta.url === "file://" + process.argv[1]) {
  main().catch(error => { console.error(error); process.exitCode = 1; });
}
