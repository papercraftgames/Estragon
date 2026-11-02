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
