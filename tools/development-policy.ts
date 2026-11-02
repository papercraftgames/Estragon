/** Development expectations are not waivers of the strict release requirements. */
import { assessRelease } from "./release-policy.ts";
import type { Reports } from "./release-policy.ts";
import type { Stage } from "./compat-kit.ts";

export type DevelopmentAssessment = { status: "PASS" | "FAIL"; problems: string[]; known_blockers: string[] };
const exportReason = "Resource-pack evidence does not verify standalone executable export";

function knownFailure(name: string, stage: Stage): boolean {
  if (stage.status !== "FAIL" || stage.timeout !== false || !Array.isArray(stage.diagnostics)) return false;
  const errors = stage.diagnostics.filter(line => /^(SCRIPT ERROR:|ERROR:)/.test(line));
  if (name === "core.hybrid_runtime") {
    return stage.aborted_on_error === true && stage.exit_code === null && errors.length === 1 &&
      errors[0] === "SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'." &&
      stage.diagnostics.some(line => /at: _run \(res:\/\/tests\/godot\/hybrid_gogo.gd:54\)/.test(line));
  }
  if (name === "distribution.resource_pack_export") {
    return stage.exit_code === 0 && stage.aborted_on_error === false && errors.length === 2 &&
      errors.includes('ERROR: Condition "_first != nullptr" is true.') &&
      errors.includes("ERROR: Resources still in use at exit (run with --verbose for details).");
  }
  if (name === "cold_scene_restore" || name === "distribution.cold_scene_restore") {
    return stage.exit_code === 0 && stage.aborted_on_error === false && errors.length === 1 &&
      errors[0] === "ERROR: Attempt to open script 'res://examples/counter/generated/Counter.gd' resulted in error 'File not found'.";
  }
  return false;
}

export function assessDevelopment(reports: Reports, label: string): DevelopmentAssessment {
  const release = assessRelease(reports);
  const problems: string[] = [];
  const known: string[] = [];
  if (!["4.0.4", "4.7"].includes(label)) problems.push("Unapproved engine");
  for (const row of release.requirements) {
    if (!row.required || row.observed === "PASS") continue;
    const [group, key] = row.name.split(".");
    const stage = row.name === "cold_scene_restore" ? reports.distribution?.stages.cold_scene_restore :
      row.name === "executable_export" ? reports.distribution?.stages.executable_export :
      row.name === "native_graphics" ? reports.distribution?.stages.native_graphics :
      reports[group as keyof Reports]?.stages[key!];
    if (row.name === "executable_export" && stage?.status === "UNTESTED" && stage.reason === exportReason) {
      known.push(row.name);
    } else if (label === "4.0.4" && stage && knownFailure(row.name, stage)) {
      known.push(row.name);
    } else problems.push(row.name + ": unexpected " + row.observed);
  }
  // These observations are explicitly outside required release behavior, but
  // their evidence cannot disappear or acquire arbitrary outcomes unnoticed.
  for (const [name, allowed] of [
    ["filtered_highlighting", ["FAIL", "PASS"]],
    ["numeric_native_conversion", ["BLOCKED", "PASS"]],
    ["callback_arity_api", label === "4.0.4" ? ["BLOCKED", "PASS"] : ["PASS"]],
  ] as const) {
    const stage = reports.core?.stages[name];
    if (!stage || !(allowed as readonly string[]).includes(stage.status)) problems.push(name + ": missing or invalid capability observation");
  }
  return { status: problems.length ? "FAIL" : "PASS", problems, known_blockers: known };
}
