# L07A — parent-owned layout foundation

> Historical root-% contract: [L07 #160](https://github.com/papercraftgames/Estragon/issues/160) supersedes the root-zero reference tested here. Independent 2D Entries now use their visible viewport as the percentage containing rectangle. These original measurements, logs and outcomes remain unchanged; see the [current contract](../LENGTHS.md).


Issue [#164](https://github.com/papercraftgames/Estragon/issues/164), base
`5588095` (merged P05 #159). [Contract](../LAYOUT_FOUNDATION.md) and
[ADR-0018](../DECISIONS.md#adr-0018--parent-owned-policies-and-measured-slots).
This is focused implementation evidence, not release certification. Owner review
and merge remain required; #160 stays open for post-merge reconciliation.

## Delivered slice

One pure StackPolicy assigns border-box slots from preferred/minimum extents,
parent content and placement data. The existing Core still measures, caches,
invalidates and applies slots through the native coordinator. HBox/VBox share
axis-transposed arrangement. Canonical `grow` replaces beta `flex` without an
alias; Spacer is a zero-natural standard participant. Box selects row/column
and physical horizontal/vertical start/center/end or cross-axis stretch.
Natural growth adds weighted free space without shrink; native Control minimum
water-filling remains intact. Pure GridDefinition validates tracks, rectangular
areas and normalized placements, independently of rendering.

Full distribution vocabulary, Wrap, rendered Grid, automatic placement and compact
template parsing remain #161/#162/#163. Future area metadata belongs to the
parent/Element record, not properties injected into native Nodes. No owner demo,
Assets, workflow, release/version/tag/publication or native Control internals changed.

## Provenance and retained evidence

Final runtime source is clean `30b5826569c8823b016145c62e94f4f8360748be`;
final editor source is clean `7b1bdeb` (only harness startup/observability and docs
changed). Addon bytes are identical across these phases and all package-based
regressions: development tar SHA-256
`c6964e957e1741791d142a26885ca538a880042bc3fbf4de37e5f7cb660e068c`.
Both engines install directly with Yarn into node_modules and preserve all
**63 addon script UIDs and installed file hashes** after execution.
Source/engine identity, exact stage argument arrays, timings, return codes,
package manifests, geometry and original expected/unexpected diagnostics are
retained under [indexed evidence](l07a/artifact-index.json).

Official Linux4.0.4 (`fc0b241c9`) and pinned Linux4.7.0 (`5b4e0cb0f`) only,
Xvfb/Openbox/Mesa software OpenGL, isolated self-contained settings and native
no-tools PATH. No shared checkout addon enablement or user preference changed.
The 4.7 GameView caches embedding configuration at READY; the focused runner
seeds only the fresh consumer's project metadata before startup to disable
fixed-size embedding ([official GameView startup implementation](https://github.com/godotengine/godot/blob/4.7-stable/editor/run/game_view_plugin.cpp)). The strict editor assertions then test actual requested
native viewport sizes, not a claim inferred from successful Window.size writes.

## Final results

| Group | Godot4.0.4 | Godot4.7.0 |
| --- | --- | --- |
| Direct-Yarn build / five bounded native setter negatives | PASS | PASS |
| Runtime / compiler / geometry / native input | 157 assertions PASS | 157 assertions PASS |
| Real editor / completion / Inspector / main+current Play | 15 assertions PASS | 15 assertions PASS |
| Cold restart / main Play | 7 assertions PASS | 7 assertions PASS |
| Installed package byte / UID integrity | PASS,63 UIDs | PASS,63 UIDs |

[4.0 runtime stages](l07a/runtime40/4.0.4/results.json),
[4.7 runtime stages](l07a/runtime47/4.7/results.json),
[4.0 editor stages](l07a/editor/4.0.4/results.json),
[4.7 editor stages](l07a/editor/4.7/results.json).
The editor game summaries explicitly record actual viewport480/800, bottom480/800,
spacer293/613 and two native clicks per game on both versions.

Proportional4.7 regressions pass: shared core18/native runtime149, Box68, native
Control57 plus actual Exit/runnable examples3, compiler frontend70 and all actual-path
publication/rollback/fresh-failure stages, routine smoke. Frozen install/static
**30/30** policy tests pass;192 unique paired UIDs and5 migrated source maps pass
the read-only audit. Group provenance preserves4f5e7f4 or d69963d as actually run;
addon bytes match the final tar. No full suite was repeated as an incidental gate.

## Geometry and behavior

Both engine traces agree within0.01px:

| Native viewport | Preferred siblings + gaps | Spacer width / height | Last native Button bottom |
| --- | --- | --- | --- |
| 640×480 | 187px | 320 / 293px | 480px |
| 1000×800 | 187px | 500 / 613px | 800px |

The spacer keeps its authored immediate-parent50% width, and takes exactly the
remaining height. Following Text, Settings, Rose and borrowed native Button slots
remain sequential. Real native clicks succeed at both sizes. Nested intrinsic
text changes reclaim spacer space without parent recomposition; idle frames do
no parsing/layout/recomposition. X/Y1:2 growth subtracts padding, gaps and margins
once. Zero growth stays natural; natural growing bases persist under a too-small
parent; explicit lengths never shrink. Parent end/center policies move unequal
real children with a nonzero gap; reactive direction/alignment commits retain
native identities. Native Controls, keyed/borrowed/nested ownership, existing
2D/3D units, SubViewport resize/re-entry, cleanup and unit rollback/repair remain
covered.

[640px render](l07a/runtime47/4.7/l07a-bottom-640.png),
[1000px render](l07a/runtime47/4.7/l07a-bottom-1000.png),
[4.0 geometry](l07a/runtime40/4.0.4/l07a-geometry.json),
[4.7 geometry](l07a/runtime47/4.7/l07a-geometry.json).
Both engines' before/after images were visually inspected. The root-percent
misconfiguration resolves to zero and suggests100vw/100vh. Fixing only the root
leaves a100%-height child consuming all content, with later siblings below the
viewport and an explanatory warning. This is preserved as a failed authoring
configuration, never silently converted to remaining-space growth.

Pure Grid normalization proves the2×2 header/sidebar/main bounds; rejects both
orientations of nonrectangular areas, uneven rows, unknown areas, duplicate child
conflicts, excessive spans and invalid track weights/units. `fr` remains a
track-share weight, rejected as an ordinary width/height unit.

## Exact commands

Existing Docker `estragon-e04-local` mounts this checkout read-only at `/repo`,
authenticated engines at `/engines`, host `/tmp/e04-local` at `/evidence`.
Commands run from `/tmp`, with `XDG_RUNTIME_DIR=/tmp/e04-runtime`:

```sh
# Each native execution wrapped with xvfb-run -a; editor has Openbox.
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --output /evidence/l07-runtime40-final
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --output /evidence/l07-runtime47-final
corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-lengths.ts \
  --editor-only --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 \
  --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 \
  --output /evidence/l07-editor-sized
```

Focused4.7 regressions use that same entry point:
`check-node-runtime.ts --runtime-only` → `/evidence/l07-runtime`,
`check-box-model.ts` → `/evidence/l07-box`,
`check-native-controls.ts` → `/evidence/l07-controls-final`,
`check-compatibility.ts` → `/evidence/l07-compiler`,
`check-routine-smoke.ts` → `/evidence/l07-routine`.
Contributor checks: `bun install --frozen-lockfile`, `bun run check`.
A read-only Node audit checks192 unique paired committed script UIDs and all5
migrated source-map sourceContent/generatedHash pairs. `git diff --check` is clean.

## Development failures and limits

Earlier attempts retain their actual outcomes under `l07a/development`:
new test helper inference/preload errors, unavailable4.0 Vector3.max replaced by
per-axis maxf, and a temporary RefCounted coroutine helper not retained across
await. The new PackedScene fixture initially omitted a root name; this was fixed.
The experimental in-editor scene-switch orchestration hit native4.0 coroutine
invalidation; that harness was replaced by a footer phase inside each main/current
game. This does not claim a general scene-switch defect was fixed. Late-set4.7
embedding preferences left a fixed1152×648 viewport, correctly failing the strict
new editor assertion; startup-only isolated metadata repairs the harness without
relaxing assertions.

An existing L04 minimum-floor fixture lacked cross-axis stretch after its L06
migration. The unchanged `origin/main` reproduction returned VBox height80,
children70/10, not the expected70/30. Adding explicit cross stretch gives the
intended definite100px Y; the strict70/30 assertion is unchanged. This was a stale
test allocation request, not a new native minimum algorithm exemption.
[Baseline output](l07a/development/main-native-floor.txt).

Readable `.txt` logs trim trailing whitespace; JSON stage reports retain their
original `.log` names. The artifact index authenticates committed evidence bytes.
Known software-GL VSync, Blender-path and older-engine scalar-parse warnings stay
visible. Exact deliberate native setter/compiler rejection errors remain bounded
by existing harnesses; no new error exemption or weakened release gate.

Manual interactive/physical-key testing, macOS/other platforms/engines, full73,
release-equivalent seven-stage certification, relocation/standard package matrix,
registry/release/publication and owner merge were not performed for this task.
The older hidden-tab highlighter and inherited-relative-class Inspector limitations
remain unchanged. This focused proof does not certify untested platforms/minors.
