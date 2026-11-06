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

Two warmup operations, then **7 measured samples per timed case**, same inputs for both engines. Two settling frames follow each measured operation; six follow mounts and twelve measure idle. This revised bounded plan follows measured 4.0.4 timeout evidence (#103); the older 4-warmup/15-sample 4.7 run below remains historical and is not used as a mismatched comparison. Raw samples are in `profile.json`; `summary.json` reports median/p95 and representative counters. Progress/raw evidence is persisted after each completed case, outside timed regions. The process limit is six minutes; it is a harness bound, not a performance threshold. Startup/import/download/CI package setup and frame waits are excluded from sampled mutation/drain times.

| Workload | Exact input / deterministic checks |
| --- | --- |
| Idle | Class-wide nested HUD, multi-level conditional and native 2D/3D scenes: 12 frames after six settling frames; zero composition/Element/native edit/layout counters |
| HUD | 32 revision writes before one drain: one observing view, 31 coalesced requests; same-value writes do nothing; unread class-wide note changes do not rerun; shared bool schedules exactly three interested components |
| Conditional | Existing deep optional branch/null slots, model replacement, stable sibling identity/measure cache; simultaneous parent removal and dirty child cancels exactly one stale job |
| Inventory | 8/64/256 real source-authored keyed rows; near-no-op Array snapshot, reverse, append/remove, prepend/remove and independent row state; retained native IDs/state, reverse exactly n−1 moves, only inserted row+caption created/freed |
| Native 2D/3D | Current source-authored dimensional demos; bounded width changes: one layout flush, retained ID/transform, no composition |
| Toggle | Actual primary pointer via Input.parse_input_event and native router/window, three interested projections/five necessary writes, model replacement rewires three boundaries exactly once |
| Lifetime | Twelve model-replacement/mount/branch-removal/free cycles; old weak models released, external records/dirty queue empty |

Correctness is asserted from logical counts and real native identity/lifetime; no median/p95 speed threshold gates acceptance. Existing conditional/list/toggle/native UI/editor/pack tests remain mandatory for additional reentrancy, foreign ownership, input, cache and source rollback cases.

## Baseline and optimization decision

The unoptimized 4.7 baseline is [run 42149909593](https://github.com/papercraftgames/Estragon/actions/runs/42149909593), source `b4bec05`, official Linux 4.7 under Xvfb/Mesa26.0.8 llvmpipe. Native build/import/runtime and 488 bounded checks passed. An initial 4.0.4 attempt hit the former 180-second harness bound without native diagnostics; its FAIL remains recorded in #103. The retry keeps sampling/input identical with the six-minute bound and per-case persistence.

| Baseline 4.7 case | median / p95 µs | Order comparisons |
| --- | ---: | ---: |
| HUD 32 writes | 7,281 / 7,665 | 45 |
| 8 row no-op | 12,824 / 13,118 | 94 |
| 64 row no-op | 43,409 / 45,371 | 2,362 |
| 256 row no-op | 191,981 / 198,432 | 33,946 |
| 256 row reverse | 677,686 / 712,894 | 33,946 |
| 256 append/remove | 401,684 / 413,903 | 68,153 |
| 256 row-owned state | 915 / 1,114 | 0 |

These are **instrumented debug-engine wall measurements**, not release-build throughput promises. Runner load, instrumentation, engine version and software graphics affect timing; algorithmic operation-count differences are stronger evidence than one noisy sample distribution. Individual runs expose median and p95, not a confidence interval across machines. Before/after source/run evidence and the final selected optimization are recorded below and in #103 before review delivery.

## Remaining framework roadmap

F01–F06 establish one native signal-driven description/reconciliation architecture. They do not complete Estragon's product roadmap. Layout/padding/margins/position authority (#55/#88), richer editable inputs/text/IME/keyboard focus, styling/accessibility/themes, editor UX (#6), broader distribution/release readiness (#51), other-platform/minor certification and optional observable collections/serialization remain separately scoped. The existing owner-accepted #44 highlighter limitation and 4.0.4 diagnostic/introspection differences remain truthful. No new author hook, memo annotation, HIR/SSA optimizer or alternate backend is introduced by this effort.
