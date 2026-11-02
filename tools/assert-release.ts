/** Assess matching current two-version artifacts without starting another engine. */
import * as path from "node:path";
import * as fs from "node:fs";
import { assessDevelopment } from "./development-policy.ts";
import type { DevelopmentAssessment } from "./development-policy.ts";
import { assessRelease } from "./release-policy.ts";
import { fail, readJSON, writeJSON } from "./compat-kit.ts";
import type { EngineRecord } from "./compat-kit.ts";
type Report = { source_commit: string; source_dirty: boolean; engines: EngineRecord[] };
export function assessFiles(files: Record<string, string>, mode: "release" | "development" = "release") {
  const names = ["core", "distribution", "lifecycle", "play"] as const;
  const reports = Object.fromEntries(names.map(name => [name, readJSON<Report>(files[name]!)])) as Record<typeof names[number], Report>;
  const core = reports.core;
  const labels = core.engines.map(engine => engine.label);
  if (!labels.length || labels.length > 2 || new Set(labels).size !== labels.length ||
      labels.some(label => !["4.0.4", "4.7"].includes(label))) fail("Invalid approved-engine set");
  for (const report of Object.values(reports)) {
    if (!report.source_commit || report.source_commit !== core.source_commit || report.source_dirty !== false || core.source_dirty !== false) {
      fail("Release evidence must have the same clean source commit");
    }
    const other = report.engines.map(engine => engine.label).sort();
    if (JSON.stringify(other) !== JSON.stringify([...labels].sort())) fail("Evidence engine sets differ");
    for (const engine of report.engines) {
      const reference = core.engines.find(row => row.label === engine.label)!;
      if (!engine.version || !engine.input_binary_sha256 || engine.version !== reference.version ||
          engine.input_binary_sha256 !== reference.input_binary_sha256) fail("Evidence engine identity differs");
      for (const stage of Object.values(engine.stages)) {
        if (!stage.command) continue;
        if (!stage.log || path.basename(stage.log) !== stage.log) fail("Missing or invalid stage log reference");
        const group = names.find(name => reports[name] === report)!;
        const log = path.join(path.dirname(files[group]!), engine.label, stage.log);
        if (!fs.existsSync(log)) fail("Missing execution evidence: " + log);
        // Known-failure matching must see all native errors, not merely the
        // collector's bounded diagnostic excerpt. Extra errors still regress.
        if (stage.status === "FAIL") {
          const errors = fs.readFileSync(log, "utf8").split(/\r?\n/)
            .filter(line => /^(SCRIPT ERROR:|ERROR:)/.test(line));
          const recorded = stage.diagnostics?.filter(line => /^(SCRIPT ERROR:|ERROR:)/.test(line));
          if (JSON.stringify(errors) !== JSON.stringify(recorded)) fail("Failure transcript differs from recorded diagnostics: " + log);
        }
      }
    }
  }
  return { verification_mode: mode, source_commit: core.source_commit, engines: labels.map(label => ({ label,
    ...assessRelease(Object.fromEntries(names.map(name => [name,
      reports[name].engines.find(engine => engine.label === label)!]))),
    ...(mode === "development" ? { development_check: assessDevelopment(Object.fromEntries(names.map(name => [name,
      reports[name].engines.find(engine => engine.label === label)!])), label) } : {}) })) };
}
function main(): void {
  const args = process.argv.slice(2);
  let mode: "release" | "development" = "release";
  if (args[0] === "--mode") {
    args.shift();
    const value = args.shift();
    if (value !== "release" && value !== "development") fail("Mode must be release or development");
    mode = value;
  }
  if (args.length !== 5 || args.some(file => !path.isAbsolute(file))) fail("Usage: assert-release.ts [--mode release|development] CORE DISTRIBUTION LIFECYCLE PLAY OUTPUT (absolute paths)");
  const [core, distribution, lifecycle, play, output] = args as [string, string, string, string, string];
  const result = assessFiles({ core, distribution, lifecycle, play }, mode);
  writeJSON(output, result);
  console.log(JSON.stringify(result, null, 2));
  if (result.engines.some(engine => mode === "release" ? engine.status !== "PASS" :
    (engine as typeof engine & { development_check: DevelopmentAssessment }).development_check.status !== "PASS")) process.exitCode = 1;
}
if (import.meta.url === "file://" + process.argv[1]) {
  try { main(); } catch (error) { console.error(error); process.exitCode = 1; }
}
