/** The release gate must expose missing evidence and genuine product failures. */
import assert from "node:assert/strict";
import { test } from "node:test";
import { assessRelease, CORE_REQUIRED, DISTRIBUTION_REQUIRED, LIFECYCLE_REQUIRED, PLAY_REQUIRED } from "../../tools/release-policy.ts";
import type { EngineRecord } from "../../tools/compat-kit.ts";
function complete() {
  const engine = (names: readonly string[]): EngineRecord => ({ label: "4.0.4",
    stages: Object.fromEntries(names.map(name => [name, { status: "PASS" }])) });
  return { core: engine(CORE_REQUIRED),
    distribution: engine([...DISTRIBUTION_REQUIRED, "cold_scene_restore", "executable_export", "native_graphics"]),
    lifecycle: engine(LIFECYCLE_REQUIRED), play: engine(PLAY_REQUIRED) };
}
test("empty and partially scoped evidence cannot certify release", () => {
  assert.equal(assessRelease({}).status, "BLOCKED");
  const reports = complete();
  delete reports.core.stages.hybrid_runtime;
  const result = assessRelease(reports);
  assert.equal(result.status, "BLOCKED");
  assert.equal(result.requirements.find(row => row.name === "core.hybrid_runtime")?.observed, "MISSING");
});
test("#61 remains blocking even when every earlier scoped check passes", () => {
  const reports = complete();
  reports.core.stages.hybrid_runtime = { status: "FAIL", reason: "native raw/lambda (#61)" };
  assert.equal(assessRelease(reports).status, "BLOCKED");
});
test("approved exception stays observed FAIL and never waives normal behavior", () => {
  const reports = complete();
  reports.core.stages.filtered_highlighting = { status: "FAIL" };
  reports.core.stages.numeric_native_conversion = { status: "BLOCKED" };
  reports.core.stages.callback_arity_api = { status: "BLOCKED" };
  const result = assessRelease(reports);
  assert.equal(result.status, "PASS");
  const exception = result.requirements.find(row => row.name === "filtered_highlighting")!;
  assert.equal(exception.observed, "FAIL");
  assert.match(exception.disposition, /OWNER-ACCEPTED EXCEPTION/);
  reports.lifecycle.stages.lifecycle_1 = { status: "FAIL" };
  assert.equal(assessRelease(reports).status, "BLOCKED");
});
test("unrecognized failures and unsupported distribution evidence block release", () => {
  const reports = complete();
  reports.core.stages.new_regression = { status: "FAIL" };
  assert.equal(assessRelease(reports).status, "BLOCKED");
  delete reports.core.stages.new_regression;
  reports.distribution.stages.executable_export = { status: "UNTESTED" };
  assert.equal(assessRelease(reports).status, "BLOCKED");
});
test("physical keypress absence is not a release requirement", () => {
  const reports = complete();
  reports.core.stages.graphics_physical_keys = { status: "UNTESTED" };
  assert.equal(assessRelease(reports).status, "PASS");
  delete reports.distribution.stages.native_graphics;
  assert.equal(assessRelease(reports).status, "BLOCKED");
});

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { assessFiles } from "../../tools/assert-release.ts";
test("mismatched or dirty artifact provenance cannot authorize release", () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "estragon-release-policy-"));
  const files: Record<string, string> = {};
  const reports = complete();
  try {
    for (const [name, engine] of Object.entries(reports)) {
      engine.version = "4.0.4.stable.official.fc0b241c9";
      engine.input_binary_sha256 = "input-binary";
      files[name] = path.join(temp, name + ".json");
      fs.writeFileSync(files[name]!, JSON.stringify({ source_commit: "same", source_dirty: false, engines: [engine] }));
    }
    assert.doesNotThrow(() => assessFiles(files));
    const filename = files.play!;
    const value = JSON.parse(fs.readFileSync(filename, "utf8"));
    value.source_commit = "old";
    fs.writeFileSync(filename, JSON.stringify(value));
    assert.throws(() => assessFiles(files), /same clean source/);
    value.source_commit = "same";
    value.source_dirty = true;
    fs.writeFileSync(filename, JSON.stringify(value));
    assert.throws(() => assessFiles(files), /same clean source/);
    value.source_dirty = false;
    value.engines[0].input_binary_sha256 = "different";
    fs.writeFileSync(filename, JSON.stringify(value));
    assert.throws(() => assessFiles(files), /identity differs/);
    value.engines = [];
    fs.writeFileSync(filename, JSON.stringify(value));
    assert.throws(() => assessFiles(files), /sets differ/);
  } finally { fs.rmSync(temp, { recursive: true, force: true }); }
});

import { diagnosticLines } from "../../tools/check-compatibility.ts";
test("semantic error counts do not double-count mapped Logger diagnostics", () => {
  const native = 'SCRIPT ERROR: Parse Error: Identifier "missing_semantic_value" not declared.';
  const transcript = native + '\nSEMANTIC_BASELINE_DIAGNOSTIC Invalid.gogo:3:1: Parse Error: Identifier "missing_semantic_value" not declared.\n';
  assert.deepEqual(diagnosticLines(transcript), [native]);
  assert.deepEqual(diagnosticLines(transcript + 'ERROR: unrelated\n'), [native, 'ERROR: unrelated']);
});

test("CI visual probe needs no host audio device", () => {
  const collector = fs.readFileSync(new URL("../../tools/check-distribution.ts", import.meta.url), "utf8");
  assert.match(collector, /sandbox\.binary, "--audio-driver", "Dummy", "--path"/);
});

import { assessDevelopment } from "../../tools/development-policy.ts";
function knownDevelopment() {
  const reports = complete();
  reports.core.stages.filtered_highlighting = { status: "FAIL" };
  reports.core.stages.numeric_native_conversion = { status: "BLOCKED" };
  reports.core.stages.callback_arity_api = { status: "BLOCKED" };
  reports.core.stages.hybrid_runtime = { status: "FAIL", exit_code: null, timeout: false,
    aborted_on_error: true, diagnostics: ["SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.",
      "          at: _run (res://tests/godot/hybrid_gogo.gd:54)"] };
  reports.distribution.stages.resource_pack_export = { status: "FAIL", exit_code: 0, timeout: false,
    aborted_on_error: false, diagnostics: ['ERROR: Condition "_first != nullptr" is true.',
      "ERROR: Resources still in use at exit (run with --verbose for details)."] };
  reports.distribution.stages.cold_scene_restore = { status: "FAIL", exit_code: 0, timeout: false,
    aborted_on_error: false, diagnostics: ["ERROR: Attempt to open script 'res://examples/counter/generated/Counter.gd' resulted in error 'File not found'."] };
  reports.distribution.stages.executable_export = { status: "UNTESTED",
    reason: "Resource-pack evidence does not verify standalone executable export" };
  return reports;
}
test("known release blockers permit development while release remains BLOCKED", () => {
  const reports = knownDevelopment();
  assert.equal(assessDevelopment(reports, "4.0.4").status, "PASS");
  assert.equal(assessRelease(reports).status, "BLOCKED");
  assert.equal(reports.core.stages.hybrid_runtime?.status, "FAIL");
  assert.equal(assessDevelopment(reports, "4.7").status, "FAIL", "4.0-only failures cannot leak to 4.7");
});
test("new failures, changed known diagnostics, timeout and missing evidence reject development", () => {
  for (const mutate of [
    (r: ReturnType<typeof knownDevelopment>) => { r.core.stages.frontend = { status: "FAIL" }; },
    (r: ReturnType<typeof knownDevelopment>) => { delete r.distribution.stages.cold_scene_restore; },
    (r: ReturnType<typeof knownDevelopment>) => { r.core.stages.hybrid_runtime!.timeout = true; },
    (r: ReturnType<typeof knownDevelopment>) => { r.distribution.stages.resource_pack_export!.diagnostics!.push("ERROR: unrelated"); },
    (r: ReturnType<typeof knownDevelopment>) => { r.core.stages.hybrid_runtime!.diagnostics = ["SCRIPT ERROR: another error"]; },
    (r: ReturnType<typeof knownDevelopment>) => { r.distribution.stages.executable_export = { status: "BLOCKED" }; },
    (r: ReturnType<typeof knownDevelopment>) => { r.core.stages.new_probe = { status: "UNTESTED" }; },
  ]) {
    const reports = knownDevelopment(); mutate(reports);
    assert.equal(assessDevelopment(reports, "4.0.4").status, "FAIL");
    assert.equal(assessRelease(reports).status, "BLOCKED");
  }
});
test("fixed blockers and fully passing release requirements pass both policies", () => {
  const reports = knownDevelopment();
  for (const name of ["hybrid_runtime"]) reports.core.stages[name] = { status: "PASS" };
  for (const name of ["resource_pack_export", "cold_scene_restore", "executable_export"]) reports.distribution.stages[name] = { status: "PASS" };
  assert.equal(assessDevelopment(reports, "4.0.4").status, "PASS");
  assert.equal(assessRelease(reports).status, "PASS");
});

import { spawnSync } from "node:child_process";
test("CLI development/release exits stay separate and reject bad artifacts in both modes", () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "estragon-cli-release-"));
  const files = ["core", "distribution", "lifecycle", "play"].map(name => path.join(temp, name + ".json"));
  const save = (reports: ReturnType<typeof complete>) => {
    Object.values(reports).forEach((engine, i) => {
      engine.version = "4.0.4.stable.official.fc0b241c9";
      engine.input_binary_sha256 = "same-input";
      // These synthetic policy fixtures have no executed command/log claims.
      fs.writeFileSync(files[i]!, JSON.stringify({ source_commit: "same", source_dirty: false, engines: [engine] }));
    });
  };
  const run = (mode?: string) => spawnSync(process.execPath, ["--experimental-strip-types",
    path.resolve("tools/assert-release.ts"), ...(mode ? ["--mode", mode] : []),
    ...files, path.join(temp, "assessment.json")], { encoding: "utf8", timeout: 10000 });
  try {
    save(knownDevelopment());
    assert.equal(run("development").status, 0);
    const report = JSON.parse(fs.readFileSync(path.join(temp, "assessment.json"), "utf8"));
    assert.equal(report.engines[0].status, "BLOCKED");
    assert.equal(report.engines[0].development_check.status, "PASS");
    assert.equal(run().status, 1, "strict release is the default");
    assert.equal(run("release").status, 1);
    const passing = complete();
    passing.core.stages.filtered_highlighting = { status: "FAIL" };
    passing.core.stages.numeric_native_conversion = { status: "PASS" };
    passing.core.stages.callback_arity_api = { status: "PASS" };
    save(passing);
    assert.equal(run("development").status, 0);
    assert.equal(run().status, 0);
    for (const mode of ["development", "release"]) {
      save(knownDevelopment());
      const value = JSON.parse(fs.readFileSync(files[3]!, "utf8"));
      value.source_commit = "different";
      fs.writeFileSync(files[3]!, JSON.stringify(value));
      assert.equal(run(mode).status, 1);
      save(knownDevelopment());
      const broken = knownDevelopment();
      broken.core.stages.frontend = { status: "FAIL" };
      save(broken);
      assert.equal(run(mode).status, 1);
      save(knownDevelopment());
      fs.rmSync(files[3]!);
      assert.equal(run(mode).status, 1);
      save(passing);
      passing.core.stages.frontend = { status: "PASS", command: ["godot"], log: "absent.log" };
      save(passing);
      assert.equal(run(mode).status, 1, "missing executed log fails even when status claims PASS");
      delete passing.core.stages.frontend!.command;
      delete passing.core.stages.frontend!.log;
    }
  } finally { fs.rmSync(temp, { recursive: true, force: true }); }
});

test("non-FAIL unexpected required outcomes still block development", () => {
  for (const status of ["BLOCKED", "UNTESTED"] as const) {
    const reports = knownDevelopment();
    reports.core.stages.frontend = { status };
    assert.equal(assessDevelopment(reports, "4.0.4").status, "FAIL");
    assert.equal(assessRelease(reports).status, "BLOCKED");
  }
});
