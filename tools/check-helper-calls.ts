/** #61 raw-free native Gogo callback execution on the two approved engines. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, copyFile, copyTree, engineRecord, indexProject, newSandbox, parseCLI,
  reportMetadata, runCommand, sourceHashes, stageStatus, writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";
export function typingErrorsAreExpected(log: string, mode: string): boolean {
  const errors = log.split(/\r?\n/).filter(line => /^(SCRIPT ERROR:|ERROR:)/.test(line));
  return errors.length === (mode === "argument" ? 2 : 1) && errors.every(line =>
    line.startsWith("SCRIPT ERROR: Parse Error:") && (mode === "argument" ?
      /String/.test(line) && /float/.test(line) : /Cannot return value of type "EstragonRect"/.test(line) && /"int"/.test(line)));
}
async function audit(selection: EngineSelection, output: string): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label); fs.mkdirSync(target);
  const record = engineRecord(selection, sandbox);
  try {
    copyTree(path.join(ROOT, "addons/estragon"), path.join(sandbox.project, "addons/estragon"));
    copyFile(path.join(ROOT, "tests/fixtures/helper-calls.gogo"), path.join(sandbox.project, "tests/fixtures/helper-calls.gogo"));
    copyFile(path.join(ROOT, "tests/compatibility/helper_calls/driver.gd"), path.join(sandbox.project, "driver.gd"));
    fs.writeFileSync(path.join(sandbox.project, "project.godot"), 'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
    record.stages.import = await indexProject(sandbox, sandbox.project, path.join(target, "import.log"));
    record.stages.helper_calls = await runCommand([sandbox.binary, "--headless", "--path", sandbox.project,
      "--script", "res://driver.gd"], sandbox.workspace, sandbox.env, path.join(target, "helper_calls.log"),
      "C61_HELPER_CALLS_OK", { abortOnError: true });
    for (const mode of ["argument", "return"]) {
      const logfile = path.join(target, "negative_" + mode + ".log");
      const stage = await runCommand([sandbox.binary, "--headless", "--path", sandbox.project,
        "--script", "res://driver.gd", "--", mode], sandbox.workspace, sandbox.env, logfile,
        "C61_NEGATIVE_" + mode.toUpperCase() + "_OK", { expectedErrors: true });
      const errors = fs.readFileSync(logfile, "utf8").split(/\r?\n/).filter(line => /^(SCRIPT ERROR:|ERROR:)/.test(line));
      stage.native_errors = errors;
      if (!typingErrorsAreExpected(fs.readFileSync(logfile, "utf8"), mode)) stage.status = "FAIL";
      record.stages["negative_" + mode] = stage;
    }
    return record;
  } finally { writeJSON(path.join(target, "report.json"), record); sandbox.dispose(); }
}
async function main(): Promise<void> {
  const args = parseCLI(process.argv.slice(2), { collectOnly: true }); fs.mkdirSync(args.output);
  const report = { ...reportMetadata(), source_hashes: sourceHashes([
    "addons/estragon/compiler/emitter.gd", "tests/fixtures/helper-calls.gogo",
    "tests/compatibility/helper_calls/driver.gd", "tools/check-helper-calls.ts",
  ]), engines: [] as EngineRecord[] };
  for (const engine of args.engines) { report.engines.push(await audit(engine, args.output)); console.log(engine.label, stageStatus(report.engines.at(-1)!)); }
  writeJSON(path.join(args.output, "results.json"), report);
  if (!args.collectOnly && report.engines.some(e => Object.values(e.stages).some(s => s.status !== "PASS"))) process.exitCode = 1;
}
if (import.meta.url === "file://" + process.argv[1]) main().catch(error => { console.error(error); process.exitCode = 1; });
