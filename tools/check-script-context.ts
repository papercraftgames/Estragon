/** Archived C01-E capability research, runnable on two owner-approved engines only. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, copyTree, engineRecord, indexProject, newSandbox, parseCLI,
  readJSON, reportMetadata, runCommand, stageStatus, writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection } from "./compat-kit.ts";

async function collect(selection: EngineSelection, output: string): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label);
  fs.mkdirSync(target);
  const record = engineRecord(selection, sandbox);
  const project = sandbox.project;
  try {
    copyTree(path.join(ROOT, "tests/compatibility/script_context"), project);
    fs.writeFileSync(path.join(project, "project.godot"),
      'config_version=5\n[application]\nconfig/name="C01-E context probe"\n');
    record.stages["import"] = await indexProject(sandbox, project, path.join(target, "import.log"));
    for (const mode of ["cache", "paired", "collision", "alias", "ignore", "fresh"]) {
      const file = path.join(target, mode + ".log");
      const stage = await runCommand(
        [sandbox.binary, "--headless", "--path", project,
          "--script", "res://probe.gd", "--", mode],
        sandbox.workspace, sandbox.env, file);
      const observations = fs.readFileSync(file, "utf8").split(/\r?\n/)
        .filter(line => line.startsWith("ESTRAGON_CONTEXT_EVIDENCE "))
        .map(line => JSON.parse(line.slice("ESTRAGON_CONTEXT_EVIDENCE ".length)) as
          { status: "PASS" | "FAIL" | "BLOCKED" | "UNTESTED" });
      if (observations.length !== 1) stage.status = "FAIL";
      else {
        stage.evidence = observations[0];
        if (stage.status === "PASS") stage.status = observations[0]!.status;
      }
      record.stages[mode] = stage;
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
  const report = { ...reportMetadata(), scope: "research only; not compatibility certification",
    engines: [] as EngineRecord[] };
  for (const selection of args.engines) {
    report.engines.push(await collect(selection, args.output));
    console.log(selection.label, stageStatus(report.engines.at(-1)!));
  }
  writeJSON(path.join(args.output, "results.json"), report);
}
if (import.meta.url === "file://" + process.argv[1]) {
  main().catch(error => { console.error(error); process.exitCode = 1; });
}
