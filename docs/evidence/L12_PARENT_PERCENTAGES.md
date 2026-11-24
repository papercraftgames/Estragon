# L12 #219 + UI-04 #220 — combined native evidence

The owner explicitly authorized one PR for [layout #219](https://github.com/papercraftgames/Estragon/issues/219) and [neutral Input #220](https://github.com/papercraftgames/Estragon/issues/220). Base main **`fd87f7211d9d2f581c27cf4c6984660a4d8cee7f`** is owner-merged UI-03 PR218. UI-04's initial independent commit is **`4f635c9`**; L12's initial core/fixture commit is **`c49241a`**, followed by the measured nested-host propagation correction in **`7cb8399`**. Final clean tested source **`da03a4bf6470be9830a35585a324aebf0307f1fb`**; subsequent evidence/status edits change no addon/example/fixture/runner bytes. Owner review/merge remains required.

[Parent percentage contract](../PARENT_PERCENTAGES.md), [Input API](../INPUT.md), [stage results](l12/summary.json), [immutable source/package manifest](l12/package-manifest.json), [artifact hashes](l12/file-hashes.json).

## Measured before/after

Repository-owned fixtures, no edits to external GogoDemo. The baseline core and native scrolling were run before edits; Input before captures preserve the original blue host default. [Numeric log and runner](l12/before/numeric.log), [scroll log and runner](l12/before/scroll.log), [before captures](l12/before/4.7/input-palette-before.png).

| Case | Before | Verified result |
| --- | --- | --- |
| Row/column300, gap20, 25%/75% |75/225 at0/95, edge320 |70/210 at0/90, edge300 |
| Wrap with the same dimensions |75/225, two lines |75/225, two lines; unchanged |
| Default Grid300, two fraction columns, gap20 |75/225 floors overflow |70/210 floors/tracks; existing water-fill |
| Auto spanning Header |spans whole cell |300 including internal track gap |
| VBox row_gap20, two10px children |natural20, secondY10 |natural40, secondY30 |
| Body actual210, border5/padding20 each |ancestor/reference defect guarded by new tests |nested100%160; wrapped75% child120 |
| Fixed100 +75% +gap20 in300 |full-content percentage overflows |100+210+20=330; deliberate overflow |
| Padded/bordered Wrap outer400 |full-content rule retained |75% of350 =262.5 |
| Grid200/header30/scroll content300, implicit rows |rows30/300, viewport300/range0 |same intrinsic overflow; intentional |
| Same Grid with explicit auto/1fr rows |rows30/300, viewport300/range0 |rows30/170, viewport170/range130 |
| Empty grow in bounded170 viewport |zero when actual viewport authority lost |170, no double allocation; overflow has zero extra |
| Unstyled Input host/cache/pixels |blue `#252d38` |neutral `#383838`, matches imported Button |

L12 separates only child width/height percentage budgets from ordinary Length references. Insets, min/max, margins, offsets, gaps and Grid track percentages retain their domains. Explicit fixed/%/fr tracks and overconstraint remain honest; no normalize/shrink/viewport fallback. Hidden/null/plain/independent-Entry outputs do not create phantom gaps. Nested transparent roots forward both contexts once; change-triggered membership propagation fixes initial multi-host participation. Direct target setters and genuine changed GGX props apply; unchanged desired props preserve imperative overrides. Layout outputs never write target setters. Dirty callbacks queue one follow-up; arrangement-completion `layout_applied` meaning is retained.

The scroll-floor correction uses the existing Grid allocator only for an auto scrolling participant in an entirely fractional definite span: its real viewport floor replaces hidden content contribution, while native/authored/intrinsic/inset minima still win. Auto/fixed/percentage spans and unbounded fractions retain prior semantics. Allocated dimensions are not reused as an intrinsic grow basis. No second layout/reactivity system or new public dimension property.

## Final paired immutable direct-Yarn acceptance

Official Linux **4.0.4** `fc0b241c9` and pinned **4.7.0** `5b4e0cb0f` only. One reproducible development tarball SHA256 **`9fb713ac84685284a00ce1bca6a95699cce56b3873e2fe3cc7296efa1829387b`**, **178 installed files / 83 addon UIDs**, unchanged after native editor/Play/restart. No copy/symlink/ignore overlay in node_modules. Development-package proof is not release certification.

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Pure percentage/domain/track/Wrap/allocation/cache cases |36 PASS |36 PASS |
| Native layout/targets/transparent/borrowed/scroll/reentrant/idle |34 PASS |34 PASS |
| Native Input editing/binding plus GGX palette/override checks |52 PASS |52 PASS |
| Independent neutral Input color/cache/pixel/states/reentry |12 PASS |12 PASS |
| Compiler/String metadata/maps/strict negatives |22 PASS |22 PASS |
| Atomic rejection/repair, model lifecycle and pack/reload |19 PASS |19 PASS |
| Actual editor current/main stale-source rollback, repair and both games |8 PASS |8 PASS |
| Cold editor restart and both games |2 PASS |2 PASS |
| Build/import/current maps/canonical UIDs/installed immutable bytes |PASS |PASS |

Each repaired editor Play and restart runs both Input52 and L12 native34, not just compiler parsing. Generated source/maps/UID/timestamp/cache identity restore after invalid current/main buffers. Five bracketed runtime rejections, two build-callback rejections and the exact intentional Bool-as-String diagnostics are qualified by the collector; unexpected errors/leaks fail. Optional4.0 isolated preflight/logger precision remains unavailable; mandatory transactional actual-path validation succeeds. The4.0 native semantic fallback reports the authored file without precise token location, while4.7 maps the placeholder span.

## Native visual inspection

Input before: [4.0.4](l12/before/4.0.4/input-palette-before.png), [4.7.0](l12/before/4.7/input-palette-before.png). After, out of focus with editable value and a real imported Estragon Button: [4.0.4](l12/4.0.4/input-palette-after.png), [4.7.0](l12/4.7/input-palette-after.png). Pixel assertions compare both surfaces to native Color383838. [Focused/selected/read-only/invalid/disabled/override](l12/4.7/input-palette-states-after.png) preserves semantic hues; only default surface changes. Scene reentry reconstructs one endpoint and retains the neutral cache. GGX explicit override/imperative override/omission reset pass, including actual Play.

Layout captures: [4.0.4 /640](l12/4.0.4/proportions-640.png), [4.0.4 /900](l12/4.0.4/proportions-900.png), [4.7 /640](l12/4.7/proportions-640.png), [4.7 /900](l12/4.7/proportions-900.png). They show named spanning Header,25/75 Grid, inside Body border/padding, descendant Wrap, and the exact70/gap20/210 row. Input captures retain native selection/caret, focus/invalid outline and clip geometry. Captures were inspected separately from headless assertions.

**Manual interactive Godot4.7 smoke was not run. Actual OS IME composition/candidate interaction remains UNTESTED under Xvfb.** Native X11 capability and synthetic Unicode do not prove composition. No macOS/mobile/extra engines/platforms, physical-key gate or release-certification claim.

## Commands and regressions

Container `estragon-e04-local`: repository read-only `/repo`, host `/tmp/e04-local` mounted at `/evidence`. Isolated native projects/settings/plugin activation only; root checkout addon/preferences unchanged.

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types -e "import('./tools/audit-native-source.ts').then(m=>console.log(m.auditNativeSource()))"
COREPACK_ENABLE_PROJECT_SPEC=0 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a \
  corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-input.ts --proportions \
  --engine 4.0.4=/evidence/edit01-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/edit01-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/l12-acceptance-final-2
```

Frozen install/static **30 policies PASS**, native audit **336 paired unique scripts/UIDs PASS**, all **67** authored module/maps match native regeneration. [Static](l12/static.log), [audit](l12/audit.log), [generation](l12/generate.log). Existing outputs retain UIDs; new sidecars came only from isolated official4.7 import. No Python/workflow/version/release/publication/Assets/GogoDemo change.

Focused regressions (Linux4.7 only): lengths243 plus24 strict invalid-length cases/root-exit PASS; responsive frontend21/math95/runtime19/native graphics/input/pack PASS; inherited scrolling50 plus native clip/scroll/nested-bubbling cases PASS; CORE-01 frontend15/runtime11/integration65 PASS. [Qualified source/commands](l12/regressions/qualification.json), [lengths](l12/regressions/lengths/results.json), [responsive](l12/regressions/responsive/results.json), [scroll](l12/regressions/scroll/results.json), [core](l12/regressions/core/results.json). The responsive run preceded only the subsequent coordinator nested-host membership fix; final pair/lengths/core/scroll cover that fix. Exact source differences are recorded, not implied same-source proof. New tests do not expand routine CI. Actual required CI and its60-second execution-wall measurement belong on the sole live PR.

## Retained failures and boundaries

- Before palette assertions deliberately fail on the original blue default; getter/cache/pixel errors are expected evidence, not a baseline product pass.
- First lengths run exposed a missing native Button fixture resource in its retained consumer setup; fixed by copying the actual helper/UID. Next run exposed the real nested-host participation gap and three old full-content percentage expectations. [Retained regression failure](l12/development/lengths-regression-failure.log). The fix preserves DeepFlex600x400→600x600 with half descendants300x200→300x300; final243 pass. Expected inset/offset domain checks remain.
- First final4.0 editor attempt timed out its inherited readiness wait without native errors, after all headless/native games passed. [Log](l12/development/native40-readiness-failure.log), [failed result](l12/development/native40-readiness-results.json). The fixture now separately bounds startup at45s and prints the plugin report on failure; no validation bypass. Final run executes sequential editor proof.
- A broader historical UX01 run failed an unrelated interpolation evaluation-count assertion, before reaching scrolling. [Retained FAIL](l12/development/legacy-ux-syntax-failure.log). The same failure was independently reproduced against all tracked pre-task addon bytes ([baseline log](l12/development/legacy-ux-baseline-failure.log), [source/commands](l12/development/legacy-ux-baseline-provenance.json)); it is not introduced by this task. Default whole-suite behavior is unchanged. The existing runner's explicit `--scroll-only` selects native clipping/scroll/nested/inherited cases for this task; those pass, and CORE-01 independently verifies current function-cache semantics. This report does not call the broader UX suite green.
- Early disposable fixture errors included a native GDScript Button alias (use explicit UiButton in `.gd`, Gogo's authored import remains supported), project-global Base collision (unique local layout name), and an unanchored test Box outside an Entry. Corrected before acceptance. No demo-specific workaround or production compatibility shim.

Read actual PSVG updater/direction/box/expand sources via GitHub: updater coalesces but clears pending after callbacks, direction wrongly divides the percentage budget by percent-child count and subtracts fixed sizes, box/expand mix geometry with target attributes. Estragon retains pending-before-callback discipline and target/actual separation rather than importing those behaviors. [Updater](https://github.com/resistdesign/psvg/blob/master/lib/built-in-src/p/layout/updater.js), [direction](https://github.com/resistdesign/psvg/blob/master/lib/built-in-src/p/layout/direction.js), [box](https://github.com/resistdesign/psvg/blob/master/lib/built-in-src/p/layout/box.js), [expand](https://github.com/resistdesign/psvg/blob/master/lib/built-in-src/p/layout/expand.js).
