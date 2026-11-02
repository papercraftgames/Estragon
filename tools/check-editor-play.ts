/** Actual unsaved Gogo F5/F6 Godot editor/child-game regression. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, ERROR, copyFile, copyTree, engineRecord, newSandbox, parseCLI,
  reportMetadata, runCommand, sourceHashes, stageStatus, unavailable, writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";

export function unexpectedErrors(output: string): string[] {
  const lines = output.split(/\r?\n/);
  const native = /^SCRIPT ERROR: Parse Error: (?:Identifier "missing_handler" not declared|Cannot assign (?:a )?value of type)/;
  const mapped = /^ui\/Counter\.gogo:\d+:\d+: Parse Error: (?:Identifier "missing_handler" not declared|Cannot assign (?:a )?value of type)/;
  const unexpected: string[] = [];
  for (const [index, line] of lines.entries()) {
    if (!ERROR.test(line)) continue;
    if (native.test(line) && index + 1 < lines.length &&
        /at: GDScript::reload \(res:\/\/ui\/generated\/Counter\.gd:\d+\)/.test(lines[index + 1]!)) continue;
    if (mapped.test(line) || line === "ERROR: An EditorPlugin build callback failed." ||
        line === "ERROR: Cannot save text file 'res://ui/Counter.gogo'.") continue;
    unexpected.push(line);
  }
  return unexpected;
}
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
    const source = fs.readFileSync(path.join(ROOT, "examples/counter/Counter.gogo"), "utf8");
    const proof = fs.readFileSync(path.join(ROOT, "tests/editor/play/proof.gd.txt"), "utf8");
    put("ui/Counter.gogo", source + proof);
    put("ui/Background.gogo", "extends RefCounted\r\nfunc value() -> int: return 0\r\n");
    put("ui/Counter.tscn", fs.readFileSync(path.join(ROOT, "examples/counter/Counter.tscn"), "utf8")
      .replace("res://examples/counter/generated/Counter.gd", "res://ui/generated/Counter.gd"));
    put("ui/generated/Counter.gd", fs.readFileSync(
      path.join(ROOT, "examples/counter/generated/Counter.gd"), "utf8")
        .replace("var count: int = 0", "var count: int = -1"));
    copyFile(path.join(ROOT, "tests/editor/play/driver.gd"), path.join(project, "tests/play/driver.gd"));
    put("tests/play/plugin.cfg",
      '[plugin]\nname="C01-G Play driver"\ndescription="Test only"\nauthor="Estragon"\nversion="1"\nscript="driver.gd"\n');
    put("gogo.config.json", '{"version":1,"source_roots":["ui"]}\n');
    put("project.godot",
      'config_version=5\n[application]\nconfig/name="C01-G isolated Play"\n' +
      'run/main_scene="res://ui/Counter.tscn"\n' +
      'config/features=PackedStringArray("4.0", "GL Compatibility")\n' +
      '[editor]\nrun/main_run_args="--headless"\n' +
      '[rendering]\nrenderer/rendering_method="gl_compatibility"\n' +
      '[editor_plugins]\nenabled=PackedStringArray(' +
      '"res://tests/play/plugin.cfg", "res://addons/estragon/editor/plugin.cfg")\n');
    for (const phase of [1, 2]) {
      const name = "play_" + phase;
      record.stages[name] = await runCommand(
        [sandbox.binary, "--headless", "--editor", "--path", project],
        sandbox.workspace, sandbox.env, path.join(target, name + ".log"),
        "C01_G_PLAY_PHASE_" + phase + "_OK", { timeout: 240000, expectedErrors: true });
      const log = fs.readFileSync(path.join(target, name + ".log"), "utf8");
      const checks = [...log.matchAll(/^C01_G_CHECK (.*): (true|false)$/gm)];
      record.stages[name].checks_total = checks.length;
      record.stages[name].failed_checks = checks.filter(hit => hit[2] !== "true")
        .map(hit => hit[1]);
      const unexpected = unexpectedErrors(log);
      record.stages[name].unexpected_errors = unexpected;
      if (unexpected.length || checks.some(hit => hit[2] !== "true") || checks.length === 0) {
        record.stages[name].status = "FAIL";
        record.stages[name].reason = "Play assertions failed or unexpected native errors";
      }
      if (record.stages[name].status !== "PASS") {
        if (phase === 1) record.stages["play_2"] = unavailable("First Play phase failed");
        break;
      }
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
    "addons/estragon/editor/plugin.gd", "addons/estragon/editor/buffer_guard.gd",
    "tools/check-editor-play.ts", "tests/editor/play/driver.gd", "tests/editor/play/proof.gd.txt",
  ]), engines: [] as EngineRecord[] };
  for (const selection of args.engines) {
    report.engines.push(await audit(selection, args.output));
    const latest = report.engines.at(-1)!;
    console.log(latest.version, stageStatus(latest));
  }
  writeJSON(path.join(args.output, "results.json"), report);
  if (report.engines.some(row => Object.values(row.stages).some(stage => stage.status !== "PASS"))) process.exitCode = 1;
}
if (import.meta.url === "file://" + process.argv[1]) {
  main().catch(error => { console.error(error); process.exitCode = 1; });
}
