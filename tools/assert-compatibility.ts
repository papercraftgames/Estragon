/** Required C01 checks, distinct from accepted limitations and research-only probes. */
import * as path from "node:path";
import { readJSON, fail } from "./compat-kit.ts";
type Stage = { status: string; reason?: string };
type Report = { engines: Array<{ label: string; stages: Record<string, Stage> }> };
const required = [
  "engine_identity", "import", "frontend", "emission_maps",
  "generated_import", "components", "layout", "input_text", "cold_text",
  "numeric_literals", "numeric_native_preservation", "callback_metadata_probe",
  "semantic_baseline_valid", "semantic_baseline_invalid",
  "generated_signals", "native_counter", "semantic_identity",
  "helper_calls", "helper_negative_argument", "helper_negative_return",
];
function main(): void {
  const filename = process.argv[2];
  if (!filename || !path.isAbsolute(filename)) fail("Provide absolute results.json path");
  const report = readJSON<Report>(filename);
  if (report.engines.length !== 1 || !["4.0.4", "4.7"].includes(report.engines[0]!.label)) {
    fail("Expected exactly one of the owner-approved Godot engines");
  }
  const engine = report.engines[0]!;
  let failed = false;
  for (const name of required) {
    const stage = engine.stages[name];
    const status = stage?.status ?? "MISSING";
    console.log(name + ": " + status);
    if (status !== "PASS") failed = true;
  }
  // Non-release historical/owner-accepted stages stay reported as FAIL/BLOCKED.
  for (const name of ["filtered_highlighting", "numeric_native_conversion", "graphics_physical_keys"]) {
    const stage = engine.stages[name];
    if (stage) console.log(name + ": " + stage.status + " (reported, not promoted to PASS)");
  }
  if (failed) fail("Required C01 native stages failed on Godot " + engine.label);
}
if (import.meta.url === "file://" + process.argv[1]) {
  try { main(); } catch (error) { console.error(error); process.exitCode = 1; }
}
