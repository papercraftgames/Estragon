# CORE-01 — native function memoization evidence

Issue [#195](https://github.com/papercraftgames/Estragon/issues/195), base `9f0493517e3b12398b6f2cdebe66a72f529a68d3` (merged ADR-0031 PR212). Final tested implementation is clean `e5ecf77130c03b7d8e3b38bdf909274bafb389b1`; subsequent evidence/status edits change no addon, authored/generated fixture or test-tool bytes. The live sole PR carries the review head and routine CI. **Owner review/merge remains required.** [Contract](../CORE01_REACTIVITY.md).

## Final acceptance — 2026-11-20

Only official Linux Godot **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f`. Every final collector stage passes on each engine, with exact expected diagnostics and no unexpected errors or shutdown leaks:

| Group | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Native frontend, inference/maps/determinism/semantic rejection | 15 PASS | 15 PASS |
| Real compiled render runtime, including native void statements | 11 PASS | 11 PASS |
| Integrated signals/cache/identity/input/lifetime/profiling | 65 PASS | 65 PASS |
| Isolated real editor, undo/redo, current/main rejection/repair/Play | 18 PASS | 18 PASS |
| Cold editor restart and actual rendered Play | 3 PASS | 3 PASS |
| Build/import/direct Yarn/installed bytes/UIDs/maps | PASS | PASS |

The collector permits exactly two bracketed frontend native type errors, four bracketed invalid desired-width errors, and the precisely bounded editor rejection diagnostics. All other native errors/leaks fail. [Raw results, logs, profiles, images and file hashes](core01/summary.json), [artifact index](core01/file-hashes.json).

One reproducible development tarball was installed directly under `node_modules`, with no package copy/symlink/ignore overlay: SHA256 `06b1a3e6b4b940ed6d8327ff4314dcc416ea46a187861bbb454dc8ee67d94b46`. All **159 addon files / 76 canonical addon UIDs** remain unchanged after editor repair/restart; total staged package has 163 files. [Exact source/package manifest](core01/package-manifest.json). Repository audit passes **313 paired, unique script UIDs and 60 authenticated example maps**. This is development acceptance, not versioned release certification or publication.

Both final editor captures at640/1000 were inspected for each engine: [4.0.4 640](core01/4.0.4/core01-game-640.png), [1000](core01/4.0.4/core01-game-1000.png), [4.7.0 640](core01/4.7/core01-game-640.png), [1000](core01/4.7/core01-game-1000.png). Actual native clicks, geometry and retained IDs are asserted by the game and integrated runner. **Manual interactive Godot4.7 smoke was not run.** Physical keypresses are not acceptance requirements.

## Behavior and measured work

Ordinary functions cache explicit arguments; hidden reads, including through ordinary wrappers/manual Elements, stay opaque. Authored GGX marks reactive functions, including locals/branches and locally declared lambdas. Independent sites, keyed zero-argument occurrences, nested dependencies, imported Script/static methods, Callable calls and inherited/super calls are exercised. The Counter migrates its ordinary heading helper to an explicit title argument. No per-property recipes, additional scheduler, user bookkeeping fields or helper Nodes are introduced.

Native tests prove sibling/shared-source isolation, 100 synchronous writes coalesced to one view, same-value quietness, conditional dependency replacement, model null/replacement/weak release, native source disposal, bounded reentrancy, parent-first descendant cancellation, failed preflight retaining native output, repair solely through a new source, repeated failed-attempt subscription pruning, suspend/reentry/free and idle-zero work. One cached controlled description mounts twice with independent edit connections; actual input on either works, and removing one preserves the other's connection. Raw Array identity and a real Resource `changed` signal protocol are tested without implementing CORE-02 collections/hydration.

For both row sizes, one dirty row executes **one row helper**, retains every row Node ID, leaves unrelated nested helpers/components quiet and produces **one owner job, one property write and two cache misses** (root + row). Cache hits are143/271 for128/256 rows. The128-row test reverses keys and removes the branches;256 tests same-order reference replacement and host suspend/reentry/free. Idle counts and timing arrays are empty on both engines.

| Engine / rows | View body µs | Whole computation µs | Including settle frames µs |
| --- | ---: | ---: | ---: |
| 4.0.4 / 128 | 11,596 | 637,685 | 672,807 |
| 4.0.4 / 256 | 28,698 | 1,290,259 | 1,329,945 |
| 4.7.0 / 128 | 10,713 | 538,460 | 579,929 |
| 4.7.0 / 256 | 27,757 | 1,034,131 | 1,079,217 |

These are software-rendered fixture measurements, not throughput guarantees. Clean function bodies are skipped; normalization/preflight/reconciliation still visit the owning desired tree (674/1314 preflights). Large native4.0 operations remain expensive. [Exact profiler output](core01/4.0.4/profile.json), [4.7 output](core01/4.7/profile.json).

Final-source4.7 regressions also pass with **no native errors/leaks**: composition49, conditionals45, lists56, reactive31, two-way50. [Source qualification and logs](core01/regressions/provenance.json). Frozen install and `bun run check` pass all30 policy tests and TypeScript checking. Earlier source-qualified development checks included native frontend70, shared native core18/runtime149, Counter runtime32, EL02 frontend69/runtime30 and GGX runtime55/editor89; those are supporting development results, not relabelled final-source full-suite evidence.

## Commands and provenance

Linux container `estragon-e04-local` mounts the repository read-only at `/repo` and host `/tmp/e04-local` at `/evidence`. Engines were authenticated by the existing pinned/hash-verifying `tools/download-compat-engine.ts`; no other engines were downloaded or launched.

```sh
bun install --frozen-lockfile
bun run check
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types tools/check-core-reactivity.ts \
  --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/core01-acceptance-e5ecf77 --editor
```

Final runtime regressions use an isolated copy of the clean source at `/evidence/core01-regressions-e5ecf77`, with the approved4.7 binary, `--headless --audio-driver Dummy --path <sandbox> --script res://tests/<composition|conditional|lists|reactive|twoway>/runtime.gd`. Their exact source qualification, stdout and diagnostics are retained. All paired collector command arrays and original engine hashes are in each engine's `results.json` / `provenance.json`.

## Retained failures and boundaries

- Earlier4.0 static Script dispatch and custom Callable API differences are fixed using public Callable/instance-ID APIs. The failed [static dispatch run](core01/development/static-script40-failure.log) remains a failure.
- [Repeated rejected renders](core01/development/repair-subscriptions-before.log) retained `[1,1,1,1]` source connections. Retaining committed reads plus only the latest repair reads yields `[0,0,0,1]` on both engines; permanent final integration exercises this.
- Earlier lists/two-way assertion totals were green **but logs contained native void-return errors**. Those runs are FAIL, not passes. [Retained error log](core01/development/void-adapter-lists-failure.log). Ignored native statement results now remain ignored; executable multiline/inline Array.append tests and the final diagnostic-clean regressions prove the correction.
- Cached controlled descriptions previously had edit connections `[1,0]`, making the second control inert. [Before](core01/development/shared-binding-before.log), [after4.0](core01/development/shared-binding-after40.log), [after4.7](core01/development/shared-binding-after47.log). Data-only linkage snapshots now give each mount its own mutable connection, without getter reads during normalization.
- The first clean editor run found a4.0 harness parse error for JSON `.static`; [retained failure](core01/development/editor40-reserved-keyword.log), fixed bracket access. A later4.0 editor attempt hit native RID/texture startup faults **before fixture assertions**: [retained FAIL](core01/development/editor40-native-startup-rid.log). Final fresh exact-source editor/restart runs pass on both engines. No claim that the engine startup fault or historical#148 is fixed.
- Development256-row reversal and in-place large native subtree removal timed out on4.0; [incomplete run](core01/development/large-removal40-incomplete.log) is not a pass. Final bounds are stated above, not silently expanded. Overnight environment cleanup also removed the approved binaries; the firstce0 invocation could not start. Both exact official binaries were restored and the fresh run was separately recorded.

CORE-02 observable collections/typed conversion and implicit two-way controls remain separate. No extra minor/platform, exhaustive release suite, manual interactive smoke, release/tag/version/publication action, automatic merge or successor implementation is claimed.
