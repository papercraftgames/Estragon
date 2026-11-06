# F06 — measured native composition

Tracking: [#103](https://github.com/papercraftgames/Estragon/issues/103), sole implementation/evidence PR. Prerequisite F05-B #102 is merged as `52a3255`. This milestone measures and improves the existing reactive architecture; it does not declare the general UI framework complete. Exact final source/engine/artifact identities and verification status are recorded in the live issue/PR.

## Instrumentation boundary

The opt-in framework Resource `runtime/composition/profile.tres` defaults off. `set_enabled(true)`, `reset()` and `snapshot()` support isolated profiling without modifying application components. Production hooks query enable state; disabled hooks perform no counter dictionary mutations, clock reads or sample allocation. Enabled counters/timing necessarily add overhead. The hook is external to application Nodes/models, with no metadata, helper Node, per-frame process or extra composition pipeline. Timing arrays are capped at 4,096 samples per key between resets.

Counters cover scheduling/coalescing/drains/processed and canceled jobs, getter reads, view executions, subscription changes, Element construction/normalized snapshots, validation/preflight/reconcile visits, ordering comparisons, actual native create/free/move/reparent/property edits and declared handler/input-boundary connections. Existing native core measure/arrange and coordinator invalidate/flush hooks supply layout counts. Element totals include both authored descriptions and normalized snapshots; subtract `normalized_elements` for authored constructions. Getter counts include repeated reads within the same deduplicated subscription set. A near-no-op Array reference replacement correctly reruns its parent once; zero native edits does not mean zero desired-description work.

`Time.get_ticks_usec()` measures view, computation and manager drain wall microseconds. These nested timings overlap; do not sum them. Benchmark `mutation_drain_us` surrounds only the authored mutation and synchronous call to the existing manager's drain. Deferred layout/frame settling occurs afterward; layout counts are retained separately. Native drawing, renderer/GPU/physics/platform event cost and all engine allocations are not exhaustively measured. No claim of zero native drawing during idle is made.

`OS.get_static_memory_usage()` is approximate process-wide tracked allocator usage, not an application heap/GPU measure or total RSS. `Performance.OBJECT_COUNT` is a process-wide object count. Snapshots themselves and retained WeakRef probes affect these statistics. Weak-source release and empty manager records/queues are the deterministic lifetime proofs; memory figures are descriptive.

## Reproducible workload

Run the existing workflow's focused `profiling` mode with either approved engine, or under Xvfb/software Mesa:

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/check-profiling.ts --engine 4.7=/absolute/official/linux/godot --output /tmp/new-absolute-f06-output
```

The runner copies the addon/current Gogo examples into an isolated project, builds normally, imports with isolated settings, then runs a real graphics-window native benchmark. No user preferences/addon setting in this checkout changes. End users still need only Godot. Contributor automation is TypeScript/Yarn; existing Bun policy checks remain.

Two warmup operations, then **7 measured samples per timed case**, same inputs for both engines. Two settling frames follow each measured operation; six follow mounts and twelve measure idle. This revised bounded plan follows measured 4.0.4 timeout evidence (#103); the older 4-warmup/15-sample 4.7 run remains historical and is not used as a mismatched comparison. Raw samples are in `profile.json`; `summary.json` reports median/p95 and representative counters. Progress/raw evidence is persisted after each completed case, outside timed regions. The process limit is six minutes; it is a harness bound, not a performance threshold. Startup/import/download/CI package setup and frame waits are excluded from sampled mutation/drain times.

| Workload | Exact input / deterministic checks |
| --- | --- |
| Idle | Class-wide nested HUD, multi-level conditional and native 2D/3D scenes: 12 frames after six settling frames; zero composition/Element/native edit/layout counters |
| HUD | 32 revision writes before one drain: one observing view, 31 coalesced requests; same-value writes do nothing; unread class-wide note changes do not rerun; shared bool schedules exactly three interested components |
| Conditional | Existing deep optional branch/null slots, model replacement, stable sibling identity/measure cache; simultaneous parent removal and dirty child cancels exactly one stale job |
| Inventory | 8/64/128 real source-authored keyed rows; near-no-op Array snapshot, reverse, append/remove, prepend/remove and independent row state; retained native IDs/state, reverse exactly n−1 moves, only inserted row+caption created/freed |
| Native 2D/3D | Current source-authored dimensional demos; bounded width changes: one layout flush, retained ID/transform, no composition |
| Toggle | Actual primary pointer via Input.parse_input_event and native router/window, three interested projections/five necessary writes, model replacement rewires three boundaries exactly once |
| Lifetime | Twelve model-replacement/mount/branch-removal/free cycles; old weak models released, external records/dirty queue empty |

Correctness is asserted from logical counts and real native identity/lifetime; no median/p95 speed threshold gates acceptance. Existing conditional/list/toggle/native UI/editor/pack tests remain mandatory for additional reentrancy, foreign ownership, input, cache and source rollback cases.

## Baseline, measured changes and results

Complete matched baselines use source `2aad73fd214d67643153886a4469b5a3b39511fd`: [4.0.4 run 42165060806](https://github.com/papercraftgames/Estragon/actions/runs/42165060806), [4.7 run 42165232952](https://github.com/papercraftgames/Estragon/actions/runs/42165232952). Both build/import/runtime stages passed, 248 logical assertions each. These baselines and the optimization decision were published in #103 **before editing the optimization logic**.

After source `2819b715936a710dd72cff739ddf9e403f2ad1d1`: [4.0.4 run 42165474231](https://github.com/papercraftgames/Estragon/actions/runs/42165474231), [4.7 run 42165380928](https://github.com/papercraftgames/Estragon/actions/runs/42165380928). All focused stages and 248 assertions passed on each; exact same official binaries, inputs, warmup and sample counts. Full tables (including slower/noisy cases): [4.0.4](evidence/F06_4_0_4.md), [4.7](evidence/F06_4_7.md). Raw samples, source/engine provenance and execution/environment logs remain in each CI artifact. Reproduce the comparison with:

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/compare-profiling.ts /absolute/before/profiling/4.7 /absolute/after/profiling/4.7 /tmp/comparison.md
```

Exactly two bounded changes were retained:

1. **LIS discovery:** unique native child indices use binary-search minimal tails/predecessors, reducing discovery from quadratic to O(n log n). Existing right-to-left minimum-move commitment is unchanged. Different equally valid LIS choices are permitted; actual native order/IDs/state/minimal operation assertions remain authoritative. No-op 128-row ordering comparisons fall **8,794→694**; reverse **8,794→272**. No speculative author/compiler memoization.
2. **Tree-local preflight metadata:** collect native/script property/signal/constructor contracts once per type in one synchronous desired-tree validation. The dictionary is local, passed down that tree, and discarded; no cross-commit/editor-reload cache or invalidation infrastructure. All per-element value/signal/type/name/foreign-boundary checks still run. For 128-row no-op, **144 validation visits remain**, but metadata collections fall from one per visited node to **six types**. Native lifetime and pack behavior remain intact.

| Case | 4.0.4 before → after median µs | 4.7 before → after median µs |
| --- | ---: | ---: |
| HUD 32 writes | 8,150 → 3,544 | 7,392 → 3,205 |
| 8 row no-op | 14,614 → 3,965 | 12,874 → 3,134 |
| 64 row no-op | 54,577 → 7,656 | 44,588 → 6,094 |
| 128 row no-op | 101,261 → 15,051 | 84,420 → 11,463 |
| 128 row reverse | 4,955,581 → 3,612,289 | 169,646 → 86,329 |
| 128 append/remove | 216,133 → 36,165 | 183,809 → 28,003 |
| 128 prepend/remove | 375,723 → 149,079 | 185,022 → 27,330 |
| 128 row state | 843 → 618 | 735 → 532 |
| Native 2D layout (not changed) | 37 → 29 | 28 → 46 |

These are **instrumented debug-engine wall measurements**, not release-build CPU/throughput promises. Seven samples yield p95 equal to the observed maximum, not population confidence. Runner load, engine and instrumentation affect small timings: e.g. unchanged 4.7 native 2D layout regressed 28→46 µs while 3D stayed 29 µs; same-value microsecond changes are noise, not evidence of an optimization of those paths. No speed threshold gates correctness. 4.0.4 large reverse remains multi-second despite minimal 127 moves because native child-order/layout synchronization is substantial. That authority was deliberately not redesigned (#55/#88 remain separate).

All four idle cases measure zero own composition/Elements/native mutations/layout work after quiescence. Bursts coalesce; shared-model observers and one-row state remain selective. Model replacement rewires current inputs, parent-first removal cancels dirty children, native IDs/state and sibling measurement caches persist. Twelve repeated lifetimes release weak models and clear external records/queues. The measured object delta is +12 for twelve intentionally retained WeakRef probes; approximate static-memory deltas include process/benchmark storage. The final gate also asserts exactly that expected object delta. Connection counters count explicit operations, not every automatic native destruction cleanup. Engine drawing/GPU/physics work is unmeasured.

### Preserved failed/provisional evidence

The earlier 4-warmup/15-sample 4.7 run [42149909593](https://github.com/papercraftgames/Estragon/actions/runs/42149909593) passed 488 checks and exposed quadratic scaling up to 256 rows, but is not compared against different sample settings. The 4.0.4 256-row runs [42150114859](https://github.com/papercraftgames/Estragon/actions/runs/42150114859), [42150538900](https://github.com/papercraftgames/Estragon/actions/runs/42150538900) and [42151318972](https://github.com/papercraftgames/Estragon/actions/runs/42151318972) hit bounded process timeouts; preserved partial evidence has no logical failures, but the runs remain FAIL and no completed large-reverse number is invented. Final matched 8/64/128 inputs and smaller sampling were recorded before optimization, keeping all scenario/invariant categories and existing release suites.

Initial test harness Resource constant-property access failures were corrected with explicit enable/query methods and dynamic test Resource references; temporary diagnostic traces were removed. No actual-path compiler/editor or public author contract was weakened. Final strict existing addon acceptance plus profiling is required on both approved Linux engines; exact final head/source/artifacts/status are in #103/its sole PR. Manual interactive Godot 4.7 smoke status is reported there separately from automated graphics evidence.

## Remaining framework roadmap

F01–F06 establish one native signal-driven description/reconciliation architecture. They do not complete Estragon's product roadmap. Layout/padding/margins/position authority (#55/#88), richer editable inputs/text/IME/keyboard focus, styling/accessibility/themes, editor UX (#6), broader distribution/release readiness (#51), other-platform/minor certification and optional observable collections/serialization remain separately scoped. The existing owner-accepted #44 highlighter limitation and 4.0.4 diagnostic/introspection differences remain truthful. No new author hook, memo annotation, HIR/SSA optimizer or alternate backend is introduced by this effort.
