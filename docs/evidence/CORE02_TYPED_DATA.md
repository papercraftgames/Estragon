# CORE-02 #200 — native typed collections and data evidence

Review candidate; owner merge pending. Base: owner-merged U04 PR #225, `1813fa7ac7b887dce69a20db15a7a16639f8947e`. Final production compiler/runtime and focused fixture source: **`8a138617fb4a031d934f2a6db6f322156cee6087`**, clean. Subsequent delivery files add only evidence/docs and the Gallery scene already synthesized and tested by the collector. [Authoring contract](../TYPED_DATA.md). [Raw evidence and hashes](../../tests/data/evidence/manifest.json).

## Exact acceptance

Linux Docker, Xvfb, Mesa llvmpipe, `LIBGL_ALWAYS_SOFTWARE=1`, `LP_NUM_THREADS=2`. Only the two owner-approved official binaries ran:

| Engine | Official identity | SHA-256 |
| --- | --- | --- |
| 4.0.4 | `4.0.4.stable.official.fc0b241c9` | `e9a0db9798cf53385693898af39f98d0065552c0808b9e7eb82cfcb0da880ae9` |
| pinned 4.7.0 | `4.7.stable.official.5b4e0cb0f` | `f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75` |

```sh
docker exec -e COREPACK_ENABLE_PROJECT_SPEC=0 -e LIBGL_ALWAYS_SOFTWARE=1 -e LP_NUM_THREADS=2 \
  estragon-e04-local xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types \
  /repo/tools/check-data.ts --editor \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /tmp/core02-review-acceptance
```

Both engine summaries PASS; collector exits 0 with `CORE02_ACCEPTANCE_OK`. The package was created once from clean source, installed directly by Yarn in both consumers, and rehashed after editor/game execution. No copying/symlinking or `.gdignore` over the installed package. All **88 addon script UIDs**, installed files and source/generated map/UID checks remain unchanged. Reproducible development tarball SHA-256: **`0ab310ea1102bcc46130151f5a4c2489fcf1aeb1f5a468bc9e40710c449128dd`**. This is a development package, not a release certification/publication.

| Evidence per engine | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Native frontend/compiler cases | 23 PASS | 23 PASS |
| Runtime/hydration/selective GGX | 40 PASS | 40 PASS |
| Native keyboard/pointer/focus, 640×360 and 900×520 | 6 PASS | 6 PASS |
| Installed native editor rejection/rollback/repair/current + main Play | 18 PASS | 18 PASS |
| Editor restart and actual game | 3 PASS | 3 PASS |
| Installed bytes, maps and UIDs | PASS | PASS |

Runtime includes native and declared defaults, real parsed JSON, recursive/nested collections, round trip, unknown fields, wrong types, cycles, malformed input, optional nulls, atomic failed replacement, deep-grandchild bubbling, duplicate membership, shared-child diamonds, reentrancy, last-membership removal/replacement/GC, structural batching, raw mutable-container controls, bound same-identity helper invalidation, selective keyed rows, burst coalescing, duplicate-key rejection/repair, stable native identity and unmount cleanup. Compiler cases include multiline values, typed locals/parameters, lexical shadowing, self/member assignments, native typed Arrays, inheritance, notification preservation, collision diagnostics and native semantic proof of member writes. A real repo-owned Inventory/Item/Details/Gallery vertical slice supplies the native editor/game proof.

The baseline probe at main `1813fa7` successfully loads an ordinary bindable model and confirms no `to_data`, no upward data signal and no ArrayCollection implementation. Its raw log is retained.

## Regressions and precise limitations

- `bun install --frozen-lockfile`; `bun run check`: typecheck and **30/30 policy/tooling tests PASS**. One earlier tooling run overlapped a local commit and correctly rejected its changing source-head provenance; the stable-head rerun passes.
- Existing native compiler regression: frontend70 plus transactional publication/repair cases PASS on both approved engines. Existing bindable runtime95 and isolated editor61 PASS on both engines. Commands used `tools/check-native-addon.ts --suites=compiler,bindable` (4.0.4 was the completed prefix of the broader run; 4.7 had its own focused run). Logs/results/provenance retained: 4.0.4 at clean `e7ccdcc` (before the self-qualified iteration-only fix), 4.7 at clean `8a13861`; the final CORE-02 paired run covers that fix on both engines.
- CORE-01 immutable direct-Yarn regression on 4.7: frontend15/runtime11/integration65 PASS, including 128/256 keyed rows, ordinary `.gd`, inherited/super calls, same-identity observable arguments, raw Arrays, rejected desired trees, cleanup and idle counters. Command: `tools/check-core-reactivity.ts --engine 4.7=... --output /tmp/core02-core01-regression` under the same Linux/Xvfb environment. No claim of a new CORE-01 editor run.
- The broad older composition collector timed out at its 60s build limit, without native diagnostics. A smaller isolated project with source roots `examples/composition`, `counter`, `bindable`, `reactive`, `ggx` builds successfully. Its runtime reports **48/49**, failing the old `descriptions allocate actual subtree once and no binder Nodes` descendant-count assertion. The same isolated probe with unmodified main `1813fa7` compiler/runtime fails **the identical assertion**, also 48/49. This is a preserved baseline failure, not a PASS. Its visual fixture passes. Exact current/baseline runtime logs and broad timeout results are retained under `composition/`; no unrelated fixture or input/layout behavior was changed to hide it.
- An initial regression collection hit host shared-volume `EACCES` while copying a generated UID after its native build passed. Container-local output removed that infrastructure problem; raw product verification above does not depend on it.
- Godot 4.0.4 uses mandatory actual-path transactional validation; unavailable optional isolated preflight/symlink introspection remains explicitly capability-limited. On 4.7 isolated preflight passes. Inherited live-instance initialization remains the previously documented native limitation. Neither limitation is claimed fixed here.
- Captures at both sizes were visually inspected, including [4.7 at 900px](../../tests/data/evidence/4.7/data-game-900.png). Automated native input, focus and geometry ran. **Manual interactive Godot smoke and OS IME composition: UNTESTED.** No physical F5/F6 requirement, other Godot versions, platforms, release/tag/publish or automatic merge.

Routine CI remains unchanged and capped at 60s. The live review PR records its required checks, measured execution wall time and owner handoff; the full opt-in editor acceptance is separate from routine CI.
