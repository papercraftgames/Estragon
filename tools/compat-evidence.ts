/** Independent oracle validation for native Godot GDScript evidence. */
export type EvidenceRow = Record<string, any>;
type NumericFixture = { cases: EvidenceRow[]; native_parser_limits: EvidenceRow[];
  rejected_cases: string[] };
export type NumericEvidence = { cases: EvidenceRow[]; native_parser_limits: EvidenceRow[];
  rejected_cases: EvidenceRow[] };

function linesWith(log: string, prefix: string): EvidenceRow[] {
  return log.split(/\r?\n/).filter(line => line.startsWith(prefix))
    .map(line => JSON.parse(line.slice(prefix.length)) as EvidenceRow);
}
function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
export function validateNumeric(log: string, fixture: NumericFixture): NumericEvidence {
  const cases = linesWith(log, "C01_NUMERIC_CASE ");
  const limits = linesWith(log, "C01_NUMERIC_NATIVE_LIMIT ");
  for (const [observed, expected, limitation] of [
    [cases, fixture.cases, false],
    [limits, fixture.native_parser_limits, true],
  ] as const) {
    const bySource = new Map(observed.map(row => [row.source as string, row]));
    assert(bySource.size === observed.length &&
      bySource.size === expected.length &&
      expected.every(row => bySource.has(row.source as string)),
      "Missing/duplicated/unexpected numeric observations");
    for (const item of expected) {
      const row = bySource.get(item.source as string)!;
      assert(row.expected_bits === item.expected_bits &&
        row.storage_bits === item.expected_bits &&
        row.deterministic_and_mapped === true,
        "Invalid oracle/source map: " + item.source);
      const equal = row.model_bits === item.expected_bits && row.runtime_bits === item.expected_bits;
      const wanted = equal ? "PASS" : limitation ? "BLOCKED" : "FAIL";
      if (limitation) {
        const preserved = row.model_bits === row.runtime_bits &&
          row.model_bits === row.raw_conversion_bits &&
          row.model_bits === row.direct_literal_bits;
        assert(preserved && row.native_value_preserved === true,
          "Emission altered native parsed value: " + item.source);
      }
      assert(row.status === wanted, "Numeric value/status mismatch: " + item.source);
    }
  }
  const rejections = linesWith(log, "C01_NUMERIC_REJECTION ");
  assert(rejections.length === fixture.rejected_cases.length &&
    new Set(rejections.map(row => row.source)).size === rejections.length &&
    fixture.rejected_cases.every(source => rejections.some(row => row.source === source)),
    "Missing/duplicate numeric rejections");
  for (const row of rejections) {
    for (const flag of ["rejected", "no_output", "source_located", "finite_domain_diagnostic"]) {
      assert(row[flag] === true, "Invalid rejection " + flag + " for " + row.source);
    }
  }
  return { cases, native_parser_limits: limits, rejected_cases: rejections };
}

export function validateCallableMetadata(log: string, minor: number): EvidenceRow {
  const rows = linesWith(log, "C01_CALLBACK_METADATA ");
  const byName = new Map(rows.map(row => [row.name as string, row]));
  assert(rows.length === 21 && byName.size === 21, "Expected 21 distinct callables");
  const errors = log.split(/\r?\n/).filter(line =>
    /SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed:/.test(line));
  const missing = rows.filter(row => row.valid && row.custom && !row.method).length;
  assert(errors.length === missing && errors.every(line =>
    line.includes("Can't get method on CallableCustom") && line.includes("lambda")),
    "Unexpected native callback diagnostics");
  for (const [left, right] of [
    ["lambda_zero", "lambda_required"], ["lambda_zero", "lambda_optional"],
    ["named_lambda_zero", "named_lambda_required"],
    ["returned_lambda_zero", "returned_lambda_required"],
  ]) {
    const omit = (row: EvidenceRow): string =>
      JSON.stringify(Object.fromEntries(Object.entries(row)
        .filter(([key]) => key !== "name" && key !== "native_count").sort()));
    assert(byName.has(left) && byName.has(right) &&
      omit(byName.get(left)!) === omit(byName.get(right)!),
      "Callable reflection changed: " + left);
  }
  for (const row of rows) {
    assert(!(row.valid && row.connect_error !== 0), "Unexpected connection: " + row.name);
  }
  for (const name of ["empty", "missing", "freed_target"]) {
    assert(byName.get(name)?.valid === false, "Invalid control accepted: " + name);
  }
  const counts: Record<string, number> = {
    method_zero: 0, method_required: 1, method_optional: 1,
    method_bound: 0, method_optional_bound: 0, method_unbound: 1,
    static_zero: 0, lambda_zero: 0, lambda_captureless: 0,
    lambda_required: 1, lambda_optional: 1, lambda_captured: 0,
    named_lambda_zero: 0, named_lambda_required: 1,
    returned_lambda_zero: 0, returned_lambda_required: 1,
    bound_lambda: 0, unbound_lambda: 1,
  };
  for (const [name, count] of Object.entries(counts)) {
    assert(byName.has(name) && byName.get(name)?.native_count === (minor >= 3 ? count : null),
      "Wrong native callback argument count: " + name);
  }
  return { observations: rows, expected_metadata_errors: missing,
    legacy_reflection_strategy: "BLOCKED",
    reason: "Opaque lambda required/optional arity is absent from legacy public reflection.",
    unchanged_native_count_guard: minor < 3 ? "UNAVAILABLE" : "AVAILABLE" };
}
