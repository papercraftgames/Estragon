/**
 * Focused two-version C01 audit. Actual compiler/runtime authority is Godot.
 * Historical nine-engine logs are frozen; this runs only the two selected engines.
 */
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { typingErrorsAreExpected } from "./check-helper-calls.ts";
import { validateCallableMetadata, validateNumeric } from "./compat-evidence.ts";
import { ROOT, ERROR, copyFile, copyTree, engineRecord, freshProject, indexProject,
  newSandbox, parseCLI, readJSON, recordHasFailure, reportMetadata, runCommand,
  stageStatus, unavailable, writeJSON } from "./compat-kit.ts";
import type { EngineRecord, EngineSelection, Sandbox, Stage } from "./compat-kit.ts";

export function diagnosticLines(log: string): string[] {
  // Count engine emissions, not the validator's structured/mapped repetitions
  // containing the same words. Newer Logger engines produce both forms.
  return log.split(/\r?\n/).filter(line => /^(?:SCRIPT ERROR:|ERROR:)/.test(line));
}
export async function audit(selection: EngineSelection, output: string, editor: boolean): Promise<EngineRecord> {
  const sandbox = newSandbox(selection);
  const target = path.join(output, selection.label);
  fs.mkdirSync(target, { recursive: true });
  const record = engineRecord(selection, sandbox);
  const stages = record.stages;
  const minor = selection.label === "4.7" ? 7 : 0;
  const project = sandbox.project;
  const logPath = (name: string): string => path.join(target, name + ".log");
  const base = [sandbox.binary, "--headless", "--path", project];

  const run = async (name: string, args: string[], marker?: string,
    options: { expectedErrors?: boolean; timeout?: number } = {}): Promise<boolean> => {
    stages[name] = await runCommand([...base, ...args], sandbox.workspace, sandbox.env,
      logPath(name), marker, { ...options, abortOnError: Boolean(marker && !options.expectedErrors) });
    return stages[name]!.status === "PASS";
  };
  const runNative = async (name: string, script: string, marker: string,
    options: { expectedErrors?: boolean; timeout?: number } = {}): Promise<boolean> =>
    run(name, ["--script", "res://tests/godot/" + script + ".gd"], marker, options);

  try {
    freshProject(sandbox, true);
    stages["import"] = await indexProject(sandbox, project, logPath("import"));
    for (const name of ["godot", "fixtures"]) {
      copyTree(path.join(ROOT, "tests", name), path.join(project, "tests", name));
    }
    // native_semantics.gd reads this oracle during execution. Stage it before
    // generated import and all runtime probes, not after semantic_identity.
    copyFile(path.join(ROOT, "tests/compatibility/numeric_cases.json"),
      path.join(project, "numeric_cases.json"));
    // Native editor import is the class-registry authority; do not spawn 33
    // independent --check-only processes for an identical clean source tree.
    await run("frontend", ["--script", "res://tests/godot/native_frontend.gd",
      "--", "--require-no-bun"], "ESTRAGON_NATIVE_FRONTEND_OK");
    for (const name of ["compiled", "mixed", "counter"]) {
      fs.rmSync(path.join(project, "examples", name, "generated"), { recursive: true, force: true });
    }
    const emitted = await run("emission_maps", ["--script", "res://tests/godot/native_generation.gd",
      "--", "--require-no-bun"], "ESTRAGON_NATIVE_GENERATION_OK");
    if (emitted) {
      stages["generated_import"] = await indexProject(sandbox, project, logPath("generated_import"));
    } else stages["generated_import"] = unavailable("Native emission failed");

    for (const [name, script, marker] of [
      ["legacy_scene", "smoke", "ESTRAGON_SMOKE_OK"],
      ["components", "components", "ESTRAGON_COMPONENTS_OK"],
      ["layout", "layout", "ESTRAGON_LAYOUT_OK"],
      ["input_text", "interaction", "ESTRAGON_INTERACTION_OK"],
      ["cold_text", "cold_text", "ESTRAGON_COLD_TEXT_OK"],
    ]) await runNative(name!, script!, marker!);

    if (emitted) {
      for (const [name, script, marker] of [
        ["generated_layout", "generated_gogo", "ESTRAGON_GENERATED_GOGO_OK"],
        ["hybrid_runtime", "hybrid_gogo", "ESTRAGON_HYBRID_GOGO_OK"],
        ["generated_signals", "generated_signals", "ESTRAGON_SIGNALS_OK"],
        ["native_counter", "native_counter", "ESTRAGON_NATIVE_COUNTER_OK"],
        ["semantic_identity", "native_semantics", "ESTRAGON_NATIVE_SEMANTICS_OK"],
      ]) {
        const expected = name === "semantic_identity";
        await runNative(name!, script!, marker!, { expectedErrors: expected });
        if (expected) {
          const log = fs.readFileSync(logPath(name!), "utf8");
          const count = minor < 3 ? 18 : 20;
          if (diagnosticLines(log).length !== count ||
              !log.split(/\r?\n/).includes("EXPECTED_NATIVE_ERROR_COUNT " + count)) {
            stages[name!]!.status = "FAIL";
            stages[name!]!.reason = "Native semantic error transcript differs from expected";
          }
        }
      }
    } else {
      for (const name of ["generated_layout", "hybrid_runtime", "generated_signals",
        "native_counter", "semantic_identity"]) stages[name] = unavailable("Native emission failed");
    }

    // #61 has a raw-free execution gate independent of HybridEdges raw syntax.
    copyFile(path.join(ROOT, "tests/compatibility/helper_calls/driver.gd"), path.join(project, "tests/godot/helper_calls.gd"));
    await runNative("helper_calls", "helper_calls", "C61_HELPER_CALLS_OK");
    for (const mode of ["argument", "return"]) {
      const name = "helper_negative_" + mode;
      await run(name, ["--script", "res://tests/godot/helper_calls.gd", "--", mode],
        "C61_NEGATIVE_" + mode.toUpperCase() + "_OK", { expectedErrors: true });
      if (!typingErrorsAreExpected(fs.readFileSync(logPath(name), "utf8"), mode)) stages[name]!.status = "FAIL";
    }

    // Actual-path publication/cache checks run in isolated projects, independent
    // of unrelated hybrid fixture grammar. All modes retain native diagnostics.
    const publication = path.join(sandbox.workspace, "publication-template");
    copyTree(path.join(ROOT, "addons/estragon"), path.join(publication, "addons/estragon"));
    copyFile(path.join(ROOT, "tests/godot/native_publication.gd"), path.join(publication, "tests/godot/native_publication.gd"));
    copyFile(path.join(ROOT, "tests/compatibility/publication/Registered.gd"), path.join(publication, "ui/generated/Registered.gd"));
    fs.writeFileSync(path.join(publication, "project.godot"),
      'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
    stages["publication_import"] = await indexProject(sandbox, publication, logPath("publication_import"));
    for (const mode of ["registered", "positive", "rollback", "fresh_failure"]) {
      const candidate = path.join(sandbox.workspace, "publication-" + mode);
      fs.cpSync(publication, candidate, { recursive: true });
      const name = "native_publication_" + mode;
      const expected = mode === "rollback" || mode === "fresh_failure";
      stages[name] = await runCommand([sandbox.binary, "--headless", "--path", candidate,
        "--script", "res://tests/godot/native_publication.gd", "--", mode],
        sandbox.workspace, sandbox.env, logPath(name), "ESTRAGON_NATIVE_PUBLICATION_OK", { expectedErrors: expected });
      if (expected) {
        const errors = diagnosticLines(fs.readFileSync(logPath(name), "utf8"));
        const expectedText = mode === "rollback" ? 'return type is "int"' : "missing_publication_value";
        if (errors.length !== 1 || !errors[0]?.includes(expectedText)) stages[name]!.status = "FAIL";
      }
    }

    // Independent exact numeric oracle, checked against real native Godot.
    copyFile(path.join(ROOT, "tests/compatibility/numeric_literals.gd"), path.join(project, "numeric_literals.gd"));
    await run("numeric_literals", ["--script", "res://numeric_literals.gd"], "C01_NUMERIC_OK");
    try {
      const evidence = validateNumeric(fs.readFileSync(logPath("numeric_literals"), "utf8"),
        readJSON(path.join(project, "numeric_cases.json")));
      record["numeric_evidence"] = evidence;
      if (evidence.cases.some(row => row.status !== "PASS")) stages["numeric_literals"]!.status = "FAIL";
      const limitations = evidence.native_parser_limits;
      stages["numeric_native_preservation"] = { status:
        limitations.every(row => row.native_value_preserved === true) ? "PASS" : "FAIL" };
      stages["numeric_native_conversion"] = unavailable(
        "Godot native numeric conversion limits; original oracle retained",
        limitations.some(row => row.status === "BLOCKED") ? "BLOCKED" : "PASS");
    } catch (error) {
      stages["numeric_literals"]!.status = "FAIL";
      stages["numeric_literals"]!.reason = String(error);
      stages["numeric_native_preservation"] = unavailable("Invalid numeric observations", "FAIL");
      stages["numeric_native_conversion"] = unavailable("No validated conversion observations");
    }
    copyFile(path.join(ROOT, "tests/compatibility/callback_metadata.gd"), path.join(project, "callback_metadata.gd"));
    await run("callback_metadata_probe", ["--script", "res://callback_metadata.gd"],
      "C01_CALLBACK_METADATA_OK", { expectedErrors: true });
    try {
      record["callback_metadata"] = validateCallableMetadata(
        fs.readFileSync(logPath("callback_metadata_probe"), "utf8"), minor);
    } catch (error) {
      stages["callback_metadata_probe"]!.status = "FAIL";
      stages["callback_metadata_probe"]!.reason = String(error);
    }
    stages["callback_arity_api"] = minor < 3
      ? unavailable("Legacy native arity reflection unavailable; approved normal invocation fallback")
      : { status: "PASS" };

    // Exact semantic failure/recovery on actual executable, no fake PASS.
    for (const mode of ["valid", "invalid"]) {
      const name = "semantic_baseline_" + mode;
      await run(name, ["--script", "res://tests/godot/semantic_baseline.gd",
        "--quit-after", "120", "--", mode], "ESTRAGON_SEMANTIC_BASELINE_OK",
        { expectedErrors: mode === "invalid" });
      if (mode === "invalid") {
        const errors = diagnosticLines(fs.readFileSync(logPath(name), "utf8"));
        if (errors.length !== 1 || !errors[0]?.includes("missing_semantic_value")) {
          stages[name]!.status = "FAIL";
        }
      }
    }

    // Preserve measured data but do not rerun separate multi-engine research
    // and known accepted/unsupported capability probes in routine CI.
    stages["filtered_highlighting"] = unavailable(
      "Owner-accepted invisible never-associated tab limitation (#44)", "FAIL");
    stages["native_graphics"] = unavailable(
      "Headless runner cannot certify pixels; native capture is separate", "UNTESTED");
    if (editor) {
      // Editor startup and both Play modes are verified by dedicated native
      // lifecycle/Play runners in CI, without invoking an additional full sweep.
      stages["addon_startup"] = unavailable("Covered by dedicated lifecycle runner", "UNTESTED");
    }
    return record;
  } finally {
    writeJSON(path.join(target, "report.json"), record);
    sandbox.dispose();
  }
}

async function main(): Promise<void> {
  const args = parseCLI(process.argv.slice(2), { editor: true, collectOnly: true });
  fs.mkdirSync(args.output, { recursive: false });
  const report = { ...reportMetadata(), date: new Date().toISOString(),
    collect_only: args.collectOnly, engines: [] as EngineRecord[] };
  for (const engine of args.engines) {
    try {
      report.engines.push(await audit(engine, args.output, args.editor));
    } catch (error) {
      report.engines.push({ label: engine.label, stages:
        { infrastructure: unavailable(String(error), "FAIL") } });
    }
    writeJSON(path.join(args.output, "results.json"), report);
    const last = report.engines.at(-1)!;
    console.log(engine.label, stageStatus(last));
  }
  if (!args.collectOnly && recordHasFailure(report.engines)) process.exitCode = 1;
}
if (import.meta.url === "file://" + process.argv[1]) {
  main().catch(error => { console.error(error); process.exitCode = 1; });
}
