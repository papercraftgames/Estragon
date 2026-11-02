/** E01-F native Godot filtered tab research; actual hidden FAIL stays FAIL. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, copyFile, engineRecord, newSandbox, parseCLI, reportMetadata,
  runCommand, sourceHashes, stageStatus, writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";

export async function audit(selection: EngineSelection, output: string): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label);
  fs.mkdirSync(target);
  const record = engineRecord(selection, sandbox);
  const project = sandbox.project;
  const put = (name: string, text: string): void => {
    const destination = path.join(project, name);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, text);
  };
  try {
    sandbox.env.ESTRAGON_EDITOR_TEST = "1";
    for (const name of ["highlighter.gd", "highlighter_association.gd"]) {
      copyFile(path.join(ROOT, "addons/estragon/editor", name),
        path.join(project, "addons/estragon/editor", name));
    }
    copyFile(path.join(ROOT, "tests/editor/filtered/driver.gd"), path.join(project, "addons/probe/driver.gd"));
    copyFile(path.join(ROOT, "tests/editor/seed_plain.gd"), path.join(project, "seed.gd"));
    for (const name of ["Counter.gogo", "Background.gogo", "Counter.gogo.txt"]) {
      copyFile(path.join(ROOT, "examples/counter/Counter.gogo"),
        path.join(project, "examples/counter", name));
    }
    put("addons/probe/plugin.cfg", '[plugin]\nname="E01-F research"\ndescription="Test only"\nauthor="Estragon"\nversion="1"\nscript="driver.gd"\n');
    put("project.godot", 'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n' +
      '[editor_plugins]\nenabled=PackedStringArray("res://addons/probe/plugin.cfg")\n');
    for (const phase of [1, 2]) {
      const name = "phase_" + phase;
      const stage = await runCommand(
        [sandbox.binary, "--headless", "--editor", "--path", project],
        sandbox.workspace, sandbox.env, path.join(target, name + ".log"),
        undefined, { timeout: 120000, abortOnError: true });
      const log = fs.readFileSync(path.join(target, name + ".log"), "utf8");
      const lines = log.split(/\r?\n/);
      const invariantOK = stage.status === "PASS" && log.includes("E01_F_RESULT ") &&
        lines.some(line => line.startsWith("E01_F_INVARIANTS ") && line.endsWith(" PASS")) &&
        !log.includes("SCRIPT ERROR:") && !log.includes("ERROR:");
      stage.status = invariantOK ? "PASS" : "FAIL";
      record.stages[name + "_invariants"] = stage;
      record.stages[name + "_hidden_acceptance"] = {
        status: invariantOK && log.includes("E01_F_RESULT PASS") ? "PASS" : "FAIL",
        identity: lines.filter(line => line.startsWith("E01_F_IDENTITY ")),
        observations: lines.filter(line => line.startsWith("E01_F_HIDDEN_ACCEPTANCE ") ||
          line.startsWith("E01_F_REVEALED_BEFORE_ACTIVATION ")),
      };
      if (!invariantOK) break;
      if (phase === 1) {
        const seed = await runCommand(
          [sandbox.binary, "--headless", "--path", project, "--script", "res://seed.gd"],
          sandbox.workspace, sandbox.env, path.join(target, "seed.log"),
          "ESTRAGON_SEEDED_PLAIN_RESTORE", { abortOnError: true });
        record.stages["seed"] = seed;
        if (seed.status !== "PASS") break;
      }
    }
    return record;
  } finally {
    writeJSON(path.join(target, "report.json"), record);
    sandbox.dispose();
  }
}
async function main(): Promise<void> {
  const args = parseCLI(process.argv.slice(2), { collectOnly: true });
  fs.mkdirSync(args.output);
  const report = { ...reportMetadata(), collect_only: args.collectOnly,
    source_hashes: sourceHashes([
      "tools/check-filtered-highlighting.ts", "tools/compat-kit.ts",
      "tests/editor/filtered/driver.gd", "tests/editor/seed_plain.gd",
      "addons/estragon/editor/highlighter.gd", "addons/estragon/editor/highlighter_association.gd",
    ]), engines: [] as EngineRecord[] };
  for (const selection of args.engines) {
    report.engines.push(await audit(selection, args.output));
    console.log(selection.label, stageStatus(report.engines.at(-1)!));
  }
  writeJSON(path.join(args.output, "results.json"), report);
  if (!args.collectOnly && report.engines.some(row =>
    Object.values(row.stages).some(stage => stage.status !== "PASS"))) process.exitCode = 1;
}
if (import.meta.url === "file://" + process.argv[1]) {
  main().catch(error => { console.error(error); process.exitCode = 1; });
}
