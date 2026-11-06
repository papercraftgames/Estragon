# CI01 — proportionate PR checks and measured native acceptance

Work ID CI01, [issue #109](https://github.com/papercraftgames/Estragon/issues/109). Baseline is merged #108's run [42292691481](https://github.com/papercraftgames/Estragon/actions/runs/42292691481); before/after execution evidence and final handoff live in that issue and the single review PR. This changes contributor CI and isolated fixtures, not addon/runtime/package version or bytes.

## Check policy

Every PR runs frozen install/typechecking/policy tests and reports the existing `tooling`, `addon (4.0.4)` and `addon (4.7)` check names. No workflow-level path filter or draft bypass leaves required statuses Pending. The 4.0.4 PR status explicitly records that release certification runs on main; native PR checks use pinned Linux 4.7. Documentation-only Markdown/license changes run no Godot. `tools/ci-plan.ts` uses the exact PR base/head diff, including both sides of renames; missing diff fails closed.

Native PR selection conservatively maps affected fixtures/examples/tools to suites, unions multiple areas, and adds representative vertical tests for compiler, editor, composition and native runtime changes. Shared/unknown files select all suites on 4.7; infrastructure has policy tests plus compiler/UI/package proof. The decision is printed in tooling logs. The policy is deliberately conservative; future reductions require evidence and regression tests. It is a review feedback path, never release certification.

Pushes to main always retain **all 73 stages on each official Linux Godot 4.0.4 and pinned 4.7.0**. Full workflow_dispatch acceptance remains available for pre-review verification. Existing focused flags remain development-only. `--suites=...` validates names/duplicates and always exits before generating `addon-evidence.json`, even if all suites are selected: focused evidence cannot claim release certification. The release workflow continues requiring exact-source successful main-push CI, strict hash/error/provenance/engine identity and identical reproducible allowlisted packages. Both post-publication registry consumers are unchanged.

## Waits, isolation and cache

Nine isolated editor harnesses now wait on dock selection, authored text/highlighter readiness, requested scene readiness and stopped Play/filesystem idle, bounded by a 15-second monotonic deadline. They retain all original success/rejection/unsavable/rollback/repair assertions, both entrypoints and the 0.8-second negative observation guard. That guard is intentional: an immediately false `is_playing_scene` alone does not prove no deferred stale child will launch. No shared mutable editor state/cold project cache or product diagnostic weakening is introduced. Startup and stop sleeps are removed, not successful assertions or distinct feature cases.

Only immutable verified Linux engine binaries are cached, by OS/architecture/approved label/pinned binary checksum, without broad restore keys. The downloader rechecks regular-file type, SHA256 **before execution** and exact engine version on every hit. Corrupt or wrong-version entries fail; missing binaries take the original authenticated archive/checksum path. No editor preferences, project imports or test sandboxes are cached. The graphics setup still proves llvmpipe/Vulkan; it skips apt only if the required installed tools and driver manifest already exist, otherwise installs and verifies as before. Binary caching is a modest saving, not the main latency claim.

## Measurements

Baseline #108: 4.7 native step 360.58s (361s rounded Actions step), job384s; 4.0.4 native503s, job1046s, of which graphics setup525s. 4.7 graphics setup8s, engine authentication2s. Apt variance must not be credited to test optimization. Baseline editor stages include composition33.77s, conditionals32.94s, lists35.84s, two-way33.69s, native UI18.15s and package18.15s. Artifact logs contain repeated copied subprocess output; the issue's116 console banners and the collector's130 per-stage log banners have different scopes, neither is a unique process count. Baseline has68 directly orchestrated Godot stage commands per engine (not version probes or nested games/semantic validators).

The orchestrator writes `ci-performance.json` after each suite, including failures, and prints `CI_SUITE_TIMING` plus a job summary. Stage durations use `performance.now()`; native command records retain actual directly spawned PIDs. Editor fixtures print `CI_EDITOR_TIMING` for each success/rejection scenario. Summary fields distinguish directly orchestrated Godot commands/PIDs from observed startup banners; nested games and compiler validation subprocesses are **not claimed counted uniquely**. Instrumentation performs no extra Godot launches. Timings remain associated with existing hashed results/log evidence; additional telemetry does not change the73-stage gate.

To inspect historic per-stage logs using the same collector without rerunning Godot:

```sh
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/ci-metrics.ts /absolute/native-addon/4.7 /tmp/baseline-ci-metrics.json
```

Compare suite totals, editor timings and native launch counts separately from queue/setup/upload times. Final issue/PR evidence reports actual measured PR/full runs and cache behavior, not an arbitrary speed threshold. No new certification for other versions/platforms. Manual interactive 4.7 smoke status is separate; physical keypresses are not a gate.
