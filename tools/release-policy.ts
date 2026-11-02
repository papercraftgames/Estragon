/** C01-H release requirements. Observed outcomes and owner dispositions are separate. */
import type { EngineRecord, Stage } from "./compat-kit.ts";

export const CORE_REQUIRED = [
  "engine_identity", "import", "frontend", "emission_maps", "generated_import",
  "legacy_scene", "components", "layout", "input_text", "cold_text", "generated_layout",
  "hybrid_runtime", "generated_signals", "native_counter", "semantic_identity",
  "numeric_literals", "numeric_native_preservation", "callback_metadata_probe",
  "semantic_baseline_valid", "semantic_baseline_invalid",
  "publication_import", "native_publication_registered", "native_publication_positive",
  "native_publication_rollback", "native_publication_fresh_failure",
] as const;
export const DISTRIBUTION_REQUIRED = ["engine_identity", "package_layout", "distribution_import",
  "distribution_scenes", "shipped_scripts_editor", "resource_pack_export", "resource_pack_runtime", "source_only_build"] as const;
export const LIFECYCLE_REQUIRED = ["engine_identity", "lifecycle_1", "runtime_after_1",
  "lifecycle_2", "runtime_after_2"] as const;
export const PLAY_REQUIRED = ["engine_identity", "play_1", "play_2"] as const;

export type Reports = { core?: EngineRecord; distribution?: EngineRecord; lifecycle?: EngineRecord; play?: EngineRecord };
export type ReleaseAssessment = { status: "PASS" | "BLOCKED"; requirements: Array<{
  name: string; observed: string; required: boolean; disposition: string; reason?: string }>; };
export function assessRelease(reports: Reports): ReleaseAssessment {
  const requirements: ReleaseAssessment["requirements"] = [];
  const require = (name: string, stage: Stage | undefined): void => {
    requirements.push({ name, observed: stage?.status ?? "MISSING", required: true,
      disposition: stage?.status === "PASS" ? "SATISFIED" : "RELEASE BLOCKER",
      ...(stage?.reason ? { reason: stage.reason } : {}) });
  };
  for (const [group, names] of [
    ["core", CORE_REQUIRED], ["distribution", DISTRIBUTION_REQUIRED],
    ["lifecycle", LIFECYCLE_REQUIRED], ["play", PLAY_REQUIRED],
  ] as const) for (const name of names) require(group + "." + name, reports[group]?.stages[name]);
  // Release decisions not satisfied by headless/compiler passes. Retain these
  // until measured evidence or explicit owner-supported distribution scope exists.
  require("native_graphics", reports.distribution?.stages.native_graphics);
  require("cold_scene_restore", reports.distribution?.stages.cold_scene_restore);
  require("executable_export", reports.distribution?.stages.executable_export);
  for (const [group, report] of Object.entries(reports)) {
    for (const [name, stage] of Object.entries(report?.stages ?? {})) {
      const approved = (group === "core" && ["filtered_highlighting", "numeric_native_conversion", "callback_arity_api", "native_graphics", "graphics_physical_keys"].includes(name)) ||
        (group === "distribution" && name === "other_platforms");
      const alreadyRequired = requirements.some(row => row.name === group + "." + name ||
        group === "distribution" && row.name === name && row.required);
      if ((!approved && stage.status !== "PASS" || stage.status === "FAIL" && name !== "filtered_highlighting") &&
          !alreadyRequired) require(group + "." + name, stage);
    }
  }
  const filtered = reports.core?.stages.filtered_highlighting;
  requirements.push({ name: "filtered_highlighting", observed: filtered?.status ?? "MISSING", required: false,
    disposition: "OWNER-ACCEPTED EXCEPTION: unknown hidden tab waits for reveal AND activation (#44)",
    ...(filtered?.reason ? { reason: filtered.reason } : {}) });
  for (const name of ["numeric_native_conversion", "callback_arity_api"]) {
    const stage = reports.core?.stages[name];
    requirements.push({ name, observed: stage?.status ?? "MISSING", required: false,
      disposition: "OWNER-APPROVED CAPABILITY DIFFERENCE; mandatory preservation/guards remain required" });
  }
  return { status: requirements.some(row => row.required && row.observed !== "PASS") ? "BLOCKED" : "PASS", requirements };
}
