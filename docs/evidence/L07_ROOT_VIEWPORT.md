# L07 — independent 2D Entry viewport percentages

[#160](https://github.com/papercraftgames/Estragon/issues/160), base `aaf33a4`
(merged L07A #165). [ADR-0019](../DECISIONS.md#adr-0019--independent-2d-entry-percentage-containing-rectangle)
and [current length contract](../LENGTHS.md) supersede the former root-percent
restriction. The owner's root `100%` authoring is valid.

## Fix and boundaries

Only independent 2D Entry coordinators now supply their native visible Viewport
X/Y as the containing reference passed to the existing mathematical core.
Every eligible root relative length shares this context: width/height, insets,
margin, direction-aware gap and additive x/y. Root margin has no parent allocator
and does not move/shrink the root. Ordinary children still use their actual
immediate parent content after padding. An auto/cyclic axis remains indefinite;
pure/proof contexts and3D Entries gain no viewport fallback or inferred Z/plane.
The scalar resolver, StackPolicy growth, native tree, compiler and reconciler
are unchanged. Existing size_changed/deferred invalidation handles resize;
there is no polling, extra helper or repeated per-frame parsing/recomposition.

## Before / after numerical and rendered proof

An isolated copy of unchanged `aaf33a4` compiles and executes the exact owner
root100%/inner50%+grow/Texts/Settings/native Exit/Rose shape. At640×480 and1000×800,
root and spacer are0×0 and Hello starts atY0: the visible widgets sit at the top.
The former warning inaccurately calls this authoring unanchored. The original
source-qualified baseline, log and two renders are retained under `l07/baseline`.

With the root-context correction, both approved engines agree within0.01px:

| Viewport | Root | Natural footer total | Grow spacer height | Footer bottom | Inner100% height / following textY / overflow bottom |
| --- | --- | --- | --- | --- | --- |
| 640×480 | 640×480 | 115px | 365px | 480px | 480 /480 /595px |
| 1000×800 | 1000×800 | 115px | 685px | 800px | 800 /800 /915px |
| 320×240 | 320×240 | 115px | 125px | 240px | 240 /240 /355px |
| 640×480 again | 640×480 | 115px | 365px | 480px | 480 /480 /595px |

The50%-width spacer follows half the **actual containing Column content width**.
Switching the same retained Entry from100% to100vw/100vh and back yields identical
root/Column/spacer/text/native Button/Rose geometry at every size, without Gogo
recomposition. Root height50% is240px in480px;150% intentionally reaches720px.
A full inner100% consumes the whole parent content height and places subsequent
siblings after it; it never becomes remaining space or silently shrinks.
Actual native Exit signals succeed at every size, and a separate real click quits
the game on both engines. Renders of grow and full-height overflow were inspected.

Fractional root dimensions with viewport-relative padding/margins/gap/offsets,
ordinary padded child percentages, axis changes, offset delta/nonaccumulation,
nested independent Entry below a plain boundary, SubViewport resize/re-entry,
native project stretch versus OS window dimensions, cached identity/idle work,
nested Gogo intrinsic changes, borrowed native Controls and ordinary auto/proof/3D
boundaries are asserted. The existing unit parser/compiler/property validation,
rollback/repair and prior L07A slot/area regressions remain in the same runner.

## Verified outcomes

| Scoped group | Official4.0.4 | Pinned4.7.0 |
| --- | --- | --- |
| Direct-Yarn build / exact bounded setter negatives | PASS | PASS |
| Runtime/compiler/geometry/ownership/cache | 195 assertions PASS | 195 assertions PASS |
| Native Exit click actually quits | PASS | PASS |
| Real editor/CodeEdit/Inspector/main+current Play | 17 assertions PASS | 17 assertions PASS |
| Cold restart/main Play | 8 assertions PASS | 8 assertions PASS |
| Passing installed-consumer byte/UID audit | PASS,63 UIDs | PASS,63 UIDs |

[4.0 runtime/Exit and later rejected startup](l07/runtime40-and-startup/4.0.4/results.json),
[4.7 runtime/Exit](l07/runtime47/4.7/results.json),
[4.0 fresh editor/restart](l07/editor/4.0.4/results.json),
[4.7 editor/restart](l07/editor/4.7/results.json).
The4.0 first-phase results intentionally retain the later editor FAIL; runtime/Exit
PASS is not a claim that that entire phase passed. Final editor/restart proof
comes from the separate unchanged fresh consumer. No automatic retry/waiver was
added to the runner.

Proportional existing4.7 regressions: core18/runtime149, Box68, native Control57
plus actual Exit/runnable examples3, routine smoke PASS. Static30,194 unique paired
script UIDs and the authenticated migrated NativeHome map PASS. Those group
provenances preserve a694dfa as actually run; the addon tar matches final4ae51dd.

[Baseline640 render](l07/baseline/before-640.png),
[corrected640 render](l07/runtime40-and-startup/4.0.4/l07-root-grow-640.png),
[corrected1000 render](l07/runtime47/4.7/l07-root-grow-1000.png),
[small320 render](l07/runtime47/4.7/l07-root-grow-320.png),
[full-height overflow trace](l07/runtime47/4.7/l07-root-geometry.json),
[real4.7 editor-game result](l07/editor/4.7/l07-root-game.json.txt).
Original result/log/provenance files, package manifests and rendered captures
are indexed by [SHA-256](l07/artifact-index.json). Readable logs use .txt and trim
trailing whitespace; reports preserve their original .log names.

## Execution and provenance

Final product source is `4ae51dd` (the preceding `a694dfa` has identical addon
bytes; only the new native Exit fixture's coroutine cleanup changed).
Official Linux4.0.4 (`fc0b241c9`) and pinned Linux4.7.0 (`5b4e0cb0f`) only.
Fresh direct-Yarn node_modules consumers, native no-tools PATH, isolated
self-contained editor preferences, Xvfb/Openbox/Mesa software OpenGL. No shared
checkout preferences/addon enablement or owner GogoDemo files were changed.
All package-based phases use the same development tar SHA-256
`77759c3fd4a56478d918f65ca94e1a893e3777e596d3193709f7b13abb574244`
and63 canonical addon script UIDs. Passing consumer stages verify installed
package bytes/UIDs are unchanged. This is focused acceptance, not release
certification or a publication authorization.

The4.0 combined phase passes runtime/Exit, then fails native editor startup before
any fixture check. Its original results retain that FAIL. A fresh **unchanged**
editor-only run supplies editor/main/current/restart proof; no runtime/Exit tests
are silently relabeled or failure diagnostics suppressed. The4.7 runtime/Exit
phase is separate. Full provenance and per-stage return codes/timings are retained.

From `/tmp` in existing `estragon-e04-local`, repository read-only at `/repo`,
authenticated approved engines at `/engines`, host `/tmp/e04-local` at `/evidence`:

```sh
# Each native command is wrapped in xvfb-run -a, with Openbox for editors.
# XDG_RUNTIME_DIR=/tmp/e04-runtime; engine copies/settings remain isolated.
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --editor --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/l07-root-final
# Above stops after the4.0 editor-startup failure; it does not execute4.7.
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --editor-only --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/l07-root-editor
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/l07-root-runtime47
```

Proportional existing4.7 commands through the same entry point:
`check-node-runtime.ts --runtime-only` → `/evidence/l07-root-native`,
`check-box-model.ts` → `/evidence/l07-root-box`,
`check-native-controls.ts` → `/evidence/l07-root-controls`,
`check-routine-smoke.ts` → `/evidence/l07-root-routine`.
Contributor: `bun install --frozen-lockfile`, `bun run check` (30/30).
Read-only audit:194 paired/unique committed script UIDs, one migrated NativeHome
map with matching sourceContent and generatedHash. `git diff --check` passes.
Native compiler/editor checks continue to use actual-path validation/rollback;
4.0's unavailable isolated preflight/introspection stays honestly BLOCKED while
mandatory actual-path semantics pass.

## Failures and limits

The first native Exit fixture awaited another process_frame after the author
handler had successfully requested quit. That left a suspended test coroutine on
4.0.4, and the strict runner rejected its ObjectDB leak. Returning after asserting
synchronous native signal delivery fixes the fixture; no product lifecycle code
or leak exemption changed. Its failed log and focused repair run remain recorded.

The final4.0 combined run's editor failed before the test plugin ran, with native
RID/texture startup errors (`Initializing already initialized RID`, `!mem`,
`!texture`), matching the previously retained L02 startup signature. One fresh
unchanged editor-only attempt is reported separately. This is bounded evidence,
not a general upstream root-cause/fix claim or an allowed-error pattern.
Existing software-GL VSync/Blender-path/scalar-parse warnings remain visible;
deliberate setter negatives stay inside the unchanged exact diagnostic brackets.

Earlier L06/L07A artifacts retain their original zero-root contract and outcomes;
they are historical, not the current root-% specification. No general alignment,
Wrap/Grid, native Control inside-layout, units/parser,3D plane or release gate
changes. Manual interactive/physical-key/macOS/other platforms or engines,
full73, exhaustive package-layout/release-equivalent certification, registry,
release/tag/publishing and owner merge were not performed. Routine CI remains
bounded and release certification remains mandatory before any later publication.
