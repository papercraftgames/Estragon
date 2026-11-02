/** Budget and failure-detection controls that never start Godot. */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { test } from "node:test";
import { ROOT, classify, parseCLI } from "../../tools/compat-kit.ts";
import { unexpectedErrors } from "../../tools/check-editor-play.ts";

const scripts = [
  "check-compatibility.ts", "check-editor-lifecycle.ts", "check-editor-play.ts",
  "check-filtered-highlighting.ts", "check-script-context.ts",
];
test("never start Godot for extra or non-approved engine versions", () => {
  for (const script of scripts) {
    for (const selections of [
      ["4.0.4=/missing/godot", "4.7=/missing/godot", "4.4.1=/missing/godot"],
      ["4.4.1=/missing/godot"],
    ]) {
      const output = path.join(os.tmpdir(), "estragon-budget-" + script);
      const command = ["--experimental-strip-types", path.join(ROOT, "tools", script),
        ...selections.flatMap(selection => ["--engine", selection]), "--output", output];
      const result = spawnSync(process.execPath, command, { encoding: "utf8", timeout: 10000 });
      assert.notEqual(result.status, 0, script);
      assert.match(result.stderr, /approved|At most two|Unknown|Only/);
      assert.equal(fs.existsSync(output), false);
    }
  }
});
test("two-version parser accepts 4.0.4 and pinned 4.7 without launching Godot", () => {
  const options = parseCLI(["--engine", "4.0.4=/missing/godot",
    "--engine", "4.7=/missing/godot", "--output", "/tmp/unique-out-for-estragon"]);
  assert.deepEqual(options.engines.map(row => row.label), ["4.0.4", "4.7"]);
});
test("native errors and missing markers always reject exit-zero logs", () => {
  assert.equal(classify(0, "SCRIPT ERROR: invalid\nOK\n", "OK"), "FAIL");
  assert.equal(classify(0, "ERROR: invalid\nOK\n", "OK"), "FAIL");
  assert.equal(classify(0, "almost OK\n", "OK"), "FAIL");
  assert.equal(classify(1, "OK\n", "OK"), "FAIL");
  assert.equal(classify(0, "OK\n", "OK", true), "FAIL");
  assert.equal(classify(0, "OK\n", "OK"), "PASS");
});
test("unsaved Play's expected native errors are narrowly scoped", () => {
  const expected = [
    'SCRIPT ERROR: Parse Error: Identifier "missing_handler" not declared in the current scope.',
    '    at: GDScript::reload (res://ui/generated/Counter.gd:26)',
    'ERROR: An EditorPlugin build callback failed.',
    "ERROR: Cannot save text file 'res://ui/Counter.gogo'.",
  ].join("\n");
  assert.deepEqual(unexpectedErrors(expected), []);
  assert.deepEqual(unexpectedErrors(expected + "\nERROR: unrelated error"),
    ["ERROR: unrelated error"]);
});
