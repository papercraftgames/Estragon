/** Independent TypeScript evidence-validator tests; no Godot process is launched. */
import assert from "node:assert/strict";
import * as path from "node:path";
import { test } from "node:test";
import { ROOT, readJSON } from "../../tools/compat-kit.ts";
import { validateNumeric, validateCallableMetadata } from "../../tools/compat-evidence.ts";

type Row = Record<string, any>;
test("numeric oracle, source mapping and native preservation reject corrupted evidence", () => {
  const fixture = readJSON<{ cases: Row[]; native_parser_limits: Row[]; rejected_cases: string[] }>(
    path.join(ROOT, "tests/compatibility/numeric_cases.json"));
  const format = (rows: Row[], prefix: string): string =>
    rows.map(row => prefix + JSON.stringify(row)).join("\n");
  const rows = (cases: Row[]) => [
    format(cases, "C01_NUMERIC_CASE "),
    format(fixture.native_parser_limits.map(item => ({
      ...item, model_bits: item.expected_bits, runtime_bits: item.expected_bits,
      raw_conversion_bits: item.expected_bits, direct_literal_bits: item.expected_bits,
      storage_bits: item.expected_bits, native_value_preserved: true,
      deterministic_and_mapped: true, status: "PASS",
    })), "C01_NUMERIC_NATIVE_LIMIT "),
    format(fixture.rejected_cases.map(source => ({
      source, rejected: true, no_output: true, source_located: true,
      finite_domain_diagnostic: true,
    })), "C01_NUMERIC_REJECTION "),
  ].join("\n");
  const good: Row[] = fixture.cases.map(item => ({
    ...item, model_bits: item.expected_bits, runtime_bits: item.expected_bits,
    storage_bits: item.expected_bits, deterministic_and_mapped: true, status: "PASS",
  }));
  assert.equal(validateNumeric(rows(good), fixture).cases.length, fixture.cases.length);
  const corrupt: Row[] = good.map(item => ({ ...item }));
  corrupt[0]!.storage_bits = "0000000000000000";
  if (corrupt[0]!.expected_bits === "0000000000000000") corrupt[0]!.storage_bits = "ffffffffffffffff";
  assert.throws(() => validateNumeric(rows(corrupt), fixture));
});
test("archived native callback metadata has consistent exact control observations", () => {
  const historical = readJSON<{ engines: Array<{
    version: string; callback_metadata: {
      observations: Row[]; expected_metadata_errors: number;
    }
  }> }>(path.join(ROOT, "tests/compatibility/c01-c-results.json"));
  assert.ok(historical.engines.length > 0);
  for (const engine of historical.engines) {
    const count = engine.callback_metadata.expected_metadata_errors;
    const log = [
      ...Array.from({ length: count },
        () => "ERROR: Can't get method on CallableCustom (lambda)"),
      ...engine.callback_metadata.observations.map(row =>
        "C01_CALLBACK_METADATA " + JSON.stringify(row)),
    ].join("\n");
    const minor = Number(engine.version.split(".")[1]);
    const result = validateCallableMetadata(log, minor);
    assert.equal(result.expected_metadata_errors, count);
    const wrong = engine.callback_metadata.observations.map(row => ({ ...row }));
    wrong[0]!.valid = !wrong[0]!.valid;
    const invalid = [
      ...Array.from({ length: count },
        () => "ERROR: Can't get method on CallableCustom (lambda)"),
      ...wrong.map(row => "C01_CALLBACK_METADATA " + JSON.stringify(row)),
    ].join("\n");
    assert.throws(() => validateCallableMetadata(invalid, minor));
  }
});
