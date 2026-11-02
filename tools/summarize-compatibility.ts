/** Compact reports from current one- or two-engine Godot native results. */
import * as fs from "node:fs";
import * as path from "node:path";
import { ROOT, fail, readJSON, sha256, writeJSON } from "./compat-kit.ts";

type ResultStage = { status: "PASS" | "FAIL" | "BLOCKED" | "UNTESTED";
  log?: string; diagnostics?: string[]; scripts?: Array<Record<string, unknown>>;
  [key: string]: unknown };
type Engine = { label: string; version: string; input_binary_sha256: string;
  api?: unknown; numeric_evidence?: unknown; stages: Record<string, ResultStage> };
type Report = { schema_version: number; date?: string; platform: string;
  source_commit: string; source_dirty: boolean; collect_only?: boolean; engines: Engine[] };

function main(): void {
  const files: string[] = [];
  let output = "";
  let scope = "C01 selected engine audit, not full-version certification";
  const args = process.argv.slice(2);
  for (let i = 0; i < args.length; ++i) {
    if (args[i] === "--report") files.push(args[++i] || "");
    else if (args[i] === "--output") output = args[++i] || "";
    else if (args[i] === "--scope") scope = args[++i] || "";
    else fail("Unknown summarize option: " + args[i]);
  }
  if (!files.length || !output) fail("Provide at least one --report and --output");
  const snapshot = { schema_version: 1, scope, raw_reports: [] as unknown[],
    engines: [] as unknown[] };
  const versions = new Set<string>();
  for (const filename of files) {
    const report = readJSON<Report>(filename);
    if (report.schema_version !== 1) fail("Unknown report schema");
    snapshot.raw_reports.push({ date: report.date, platform: report.platform,
      source_commit: report.source_commit, source_dirty: report.source_dirty,
      collect_only: report.collect_only, sha256: sha256(filename) });
    for (const engine of report.engines) {
      if (versions.has(engine.version)) fail("Duplicate engine: " + engine.version);
      versions.add(engine.version);
      const result: Record<string, unknown> = {
        label: engine.label, version: engine.version,
        input_binary_sha256: engine.input_binary_sha256, api: engine.api,
        numeric_evidence: engine.numeric_evidence, stages: {} as Record<string, unknown>,
      };
      const stages = result.stages as Record<string, unknown>;
      for (const [name, stage] of Object.entries(engine.stages)) {
        if (!["PASS", "FAIL", "BLOCKED", "UNTESTED"].includes(stage.status)) fail("Invalid stage: " + name);
        const compact: Record<string, unknown> = {};
        for (const key of ["status", "reason", "exit_code", "timeout", "aborted_on_error", "log", "evidence"]) {
          if (key in stage) compact[key] = stage[key];
        }
        if (stage.log) {
          const log = path.join(path.dirname(filename), engine.label, stage.log);
          compact.log_sha256 = sha256(log);
          if (stage.status === "FAIL") {
            compact.diagnostics = (stage.diagnostics || []).slice(0, 8);
            compact.log_tail = fs.readFileSync(log, "utf8").split(/\r?\n/).slice(-16);
          }
        }
        if (stage.scripts) {
          compact.total = stage.scripts.length;
          compact.passed = stage.scripts.filter(row => row.status === "PASS").length;
          compact.scripts = stage.scripts.map(row => ({
            source: row.source, status: row.status, log: row.log,
          }));
        }
        stages[name] = compact;
      }
      snapshot.engines.push(result);
    }
  }
  const manifest = readJSON<Array<{ version: string }>>(path.join(ROOT, "tests/compatibility/engines.json"));
  const allowed = new Set(manifest.filter(row => row.version.startsWith("4.0.4.stable.") ||
    row.version.startsWith("4.7.stable.")).map(row => row.version));
  if (!versions.size || versions.size > 2 || [...versions].some(version => !allowed.has(version))) {
    fail("New snapshots must contain only 4.0.4 and/or pinned 4.7.0");
  }
  snapshot.engines.sort((a, b) => (a as Engine).version.localeCompare((b as Engine).version, undefined, { numeric: true }));
  writeJSON(output, snapshot);
  console.log("Wrote", versions.size, "engine records to", output);
}
if (import.meta.url === "file://" + process.argv[1]) {
  try { main(); } catch (error) { console.error(error); process.exitCode = 1; }
}
