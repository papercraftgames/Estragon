# LAYOUT-01 #201 — constraint-aware native measurement evidence

Owner review candidate; not merged. Base is owner-merged CORE-02 PR #226, `5df9e084c54fc0971cfcec30655e4e7ccc5ed5db`. Final compiler/runtime/fixtures: `c6107822fc0c5062366e4d56c070a9f5da2b65ce` (clean); production core bytes are the same as `dc8a31e`. Delivery commits add docs/evidence only. [Contract](../RESPONSIVE_LAYOUT.md#layout-01--allocated-constraints-and-dependent-natural-dimensions), [gallery](../../examples/constraint_layout/Constraints.gogo), [raw evidence/hashes](../../tests/responsive/constraint_evidence/manifest.json).

## What was reproduced and changed

The original core already passed direct row/column wrapping, auto-height Grid width-dependent wrapping, L12 budgets, native minima and scrollbar geometry. It failed when a definite Grid outer dimension incorrectly made an auto track independently authoritative, when a fixed track inside an auto Grid supplied no authority, and when nested wrappers hid unbreakable floors/capacity. Removing a constraint could retain an allocated size as its own auto-track floor. Scroll-axis capacity could also cause unintended wrapping.

The final59-case native fixture run against byte-verified main core/Grid sources gives **42 PASS / 17 FAIL**. The same fixture passes59/59 with the implementation. `baseline/provenance.json` binds the original core/Grid hashes to main5df9e08 and names the current fixture source. Baseline logs are truthful failures, not exemptions or release evidence.

The fix stays in `layout_core.gd` and `grid_policy.gd`: distinguish actual wrapping capacity from independent percentage/grow authority; classify Grid tracks/spans; clear lost authority before natural measurement; forward relevant capacities and compose floors through existing stacks/transparent hosts; retain natural preferred contributions for auto tracks and unbreakable floors for fractional distribution. Existing bounded dependent measurement, dirty caches, native coordinator, Node identities and render caches remain authoritative. Child ownership indices live only in internal mathematical records, avoiding repeated sibling scans. No Gogo render invocation, authored width/height writeback, new solver, shrink engine or per-frame work.

## Exact final paired acceptance

Only official Linux4.0.4 and pinned Linux4.7.0. Docker/Xvfb, Mesa llvmpipe; `LIBGL_ALWAYS_SOFTWARE=1`, `LP_NUM_THREADS=2`. Engines:

| Engine | Identity | Binary SHA-256 |
| --- | --- | --- |
| 4.0.4 | `4.0.4.stable.official.fc0b241c9` | `e9a0db9798cf53385693898af39f98d0065552c0808b9e7eb82cfcb0da880ae9` |
| 4.7.0 | `4.7.stable.official.5b4e0cb0f` | `f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75` |

```sh
docker exec -e COREPACK_ENABLE_PROJECT_SPEC=0 -e LIBGL_ALWAYS_SOFTWARE=1 -e LP_NUM_THREADS=2 \
  estragon-e04-local xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types \
  /repo/tools/check-responsive.ts --constraints --editor \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /tmp/layout01-final-pair
```

Both summaries PASS; collector exits0 with `LAYOUT01_ACCEPTANCE_OK`. Identical reproducible development tarball SHA-256: **`8f7efd40aff0f4f45a1dea001ef014c9f5a1811b10320ff3539e4b23ecdc9f68`**.

| Final paired stage | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Responsive math | 95 PASS | 95 PASS |
| New actual native constraint matrix | 59 PASS | 59 PASS |
| L12 percentage/grow controls | 36 PASS | 36 PASS |
| U03 gutters / U04 chrome math | 40 / 28 PASS | 40 / 28 PASS |
| U04 native interaction/geometry/pack | 44 PASS | 44 PASS |
| CORE-02 compiler / runtime | 23 / 40 PASS | 23 / 40 PASS |
| Gogo gallery graphics/keyboard/pointer/focus/lifetime | 30 PASS | 30 PASS |
| Editor current/main failure/repair/Play | 18 PASS | 18 PASS |
| Editor restart | 3 PASS | 3 PASS |
| Installed bytes / maps / UIDs | PASS | PASS |

Cold editor stages took110.61s /54.70s and restart44.91s /31.98s respectively. These are opt-in isolated local acceptance stages, not routine CI. No routine workflow was expanded.

The one reproducible development Yarn tarball was installed directly under node_modules in both isolated consumers, never copied/symlinked or hidden by `.gdignore`. Package bytes and all88 addon UIDs remain unchanged after editor/game execution. Authored/generated source content, source names, generated hashes and canonical UIDs are verified for the gallery/data fixtures. Regression sources build/test first; the editor's live source_roots then contain only its actual five-source gallery, preventing unrelated regression examples from widening every Play compile. This is focused development acceptance, not release certification/publication.

## Numerical/native evidence

- Direct Wrap220→290→220 gives heights48→20→48; transposed column gives widths48→20→48. Native second-line offset is28. Fractional220.5 constraints,90.25×20.5 children and10.25/8.25 gaps give height49.25 and offset28.75 without rounding.
- A definite460×200 Grid with two fr columns/gap20 assigns220 to its Wrap and auto row48; width600 assigns290 and row20. Transposed definite rows/auto column behave identically. A fixed220 track in an auto Grid supplies220 authority; clearing it restores the natural290 preference. A100+100 span/gap20 supplies220, with correct dependent48.
- Asymmetric inside insets20 horizontal/24 vertical and outer margins10 yield actual210/natural72, with exact7/7 child origin. A cross max40 caps geometry while natural72 remains overflow; min45 wins a conflicting max. A wrapped fr cross floor48 is not shrunk into an available30.
- Body210 minus padding40 and vertical gutter12 gives immediate nested100% width158. Increasing gutter20 changes it to150. A tall300 Body in a200-high Grid after Header30 is auto300/range0 or definite-fr170/range130. A scrolling Wrap's main axis stays unbounded. Native500 floor plus sibling10/gap20 intentionally reaches530 beyond Grid460, with no hidden shrink.
- Real explicit multiline Text height matches the actual engine font; font-size changes update ancestors. Native Button custom minimum/theme changes use its true combined minimum. Native Label width-sensitive minimum follows actual allocated width through public native notifications; no universal Control height-for-width API is invented. Fixed/unaffected Text/Rect siblings keep measure caches.
- Native hide/show/empty/removal/reparent and Gogo conditional/keyed ArrayCollection insertion/removal/reorder update actual geometry while retaining live Nodes, native Input caret/selection/focus, handlers, clipped pointer/key targets and valid scroll offsets. Viewport resize alone leaves Gogo `build_view()` call counts unchanged. Pack/reopen restores source composition. Settled profiling reports zero render/measure/arrange work.

Screenshots at460×420 and600×420 were inspected. The gallery shows two wrapped header lines at460, one at600, a bounded post-gutter Body and native Input/rows. This is layout-group wrapping; EstragonText still supports explicit newline/font measurement. Automatic word wrapping/shaping/fallback/RTL remains TEXT-01 #205; there is no new general-purpose measurement hook.

## Additional regressions and honest limits

- `bun install --frozen-lockfile`; `bun run check`: typecheck and30/30 policy/tooling tests PASS at the final committed source. Diff/source maps/UID audit and evidence hashes are checked separately.
- Existing L12 native34 PASS on4.7 with final production core bytes, including exactly one reentrant follow-up, native transparent/grow/scroll/reference/target/idle controls. Exact command/result and source hashes retained in `l12-native/`.
- Existing native Control immutable direct-Yarn regression on4.7, clean `ed1a1c4`: runtime57, native exit and runnable-example checks PASS. Its package/core hashes identify the pre-optimization source; the later change only avoids repeated sibling scans in Grid authority checks. No fresh native-Control editor run is claimed. The final paired59-case matrix independently covers minimum/theme/Label behavior on both engines.
- Earlier harness attempts are retained as failed evidence: static variable injection unsupported on4.0; a dynamic invalid Grid expression correctly rejected at runtime but was unsuitable for a compile-before-Play test; the old15s cold-editor readiness bound expired without native diagnostics. The final fixture uses an invalid literal Length for authored compile rejection and bounded waits suitable for its real editor/game workload. No product error filter was relaxed to disguise those attempts.
- CORE-02's broader old composition descendant-count48/49 baseline failure remains archived in [its source-qualified evidence](CORE02_TYPED_DATA.md#regressions-and-precise-limitations) and raw comparison logs. It is not reclassified as a LAYOUT-01 regression or fixed here; no unrelated composition rewrite/assertion weakening was added.
- 4.0.4 retains mandatory actual-path semantic validation/rollback and its documented unavailable optional preflight/introspection distinction;4.7 isolated preflight passes. Inherited keep-state initialization limitations remain unchanged. No new minor/platform certification, release/tag/publish, merge or external GogoDemo changes.
- Manual interactive Godot smoke and OS IME composition: **UNTESTED**. Automated real native editor/game/graphics/pointer/key/focus tests ran; physical F5/F6 is not required.

Routine CI stays unchanged,≤60s. The sole review PR/issue handoff records the completed required CI link and measured execution wall time separately from queue time. The opt-in local editor acceptance is not a routine-CI budget expansion.
