# UX01 native authoring and scrolling evidence

[#183](https://github.com/papercraftgames/Estragon/issues/183) consolidates
#178/#180/#127/#179/#181. [Contract](../UX01.md), ADR-0026. Implementation source
`d002aa6ae34eb0fc7c046163269b89f9058a7944`, base owner-merged Wrap/Grid PR #177
`efea57dad3d0ea10d412ff07f20227ebed29f9bd`. Later evidence/status-only commits do
not change the tested addon. Review/owner merge remain required.

## Paired immutable consumer

Both official Linux engines tested the same reproducible read-only preview tar:
`9f1828d0a7b395744bf27fd5cc53c385c718be3ad5a77a9f19de6c672fe752e4`.
The staged version/tag are recorded only in the fixture manifests; overlay `estragon-tag-overlay-v1`, mode
`preview`; source metadata remains development-only. This is local compatibility
proof, not a release, registry/publication or release-certification claim.
Both actual direct-Yarn node_modules installs retain all71 canonical addon UIDs
and identical file hashes after editor shutdown. [Qualification](../../tests/ux01/evidence/source-qualification.json),
[4.0.4 manifest](../../tests/ux01/evidence/4.0.4/package-manifest.json),
[4.7 manifest](../../tests/ux01/evidence/4.7/package-manifest.json) include exact source/engine/package
provenance. Each engine's results contains16 PASS stages, no unexpected errors.

| Native acceptance | Official Linux4.0.4 | Pinned Linux4.7.0 |
| --- | --- | --- |
| A capacity/transpose/alignment/short natural/indefinite math | PASS89 | PASS89 |
| Exact owner six-Text source, preceding panels, resize/IDs/quiet | PASS40 | PASS40 |
| B typed bare Bool/body/String/Unicode/newlines/font/diagnostics | PASS29;2 intended runtime errors | PASS29;2 intended runtime errors |
| C maxima, floors, Stack/Wrap/Grid, visible paint/outside hit | PASS14 | PASS14 |
| D native ranges/independent max-only axes/pan/capture/native pack | PASS12 | PASS12 |
| Nested wheel/exhaustion/scrollbar/no underlying click/re-entry | PASS | PASS |
| Whole-view invalid/max removal/conditional/offset restoration | PASS18;10 intended errors | PASS18;10 intended errors |
| Combined gallery320x240/640x480/1000x800/back320, keyed/native input | PASS29 + pack/reload | PASS29 + pack/reload |
| Real Inspector/undo, both Play rejection/repair and actual games | PASS19 | PASS19 |
| Cold editor restart and actual game | PASS11 | PASS11 |

Gallery games produce8 native/custom activations, Toggle edits
`[true,false,true,false]`, twelve top/middle/end samples and no resize
recomposition/idle layout work. Offset-only changes translate without child
remeasurement. Content shrink clamps while retaining keyed Nodes. Read-only range,
invalid offsets/flags/maxima, zero/multiple/unbounded content and body conflicts
retain the last good tree. Authored offsets apply after geometry and clamp to the
new arranged range, independent of attribute order.

Inspected fresh captures on BOTH engines: gallery320/top,640/middle,1000/end and
owner reproduction640. They show the short auto-Wrap group changing lines,
ordinary blue child overflow beyond its180px owner, native clipped scrolling and
the six measured owner Text items on multiple rows. Selected images and complete
stage logs live beside each [4.0.4 result](../../tests/ux01/evidence/4.0.4/results.json) and
[4.7 result](../../tests/ux01/evidence/4.7/results.json). Green pixel450 and an actual outside-parent
activation independently prove visible overflow beyond a300px capped owner.

Manual interactive smoke: **UNTESTED**. Automated real native rendering, input,
focus and isolated editor/game checks ran. Physical keypress testing is not a gate.
Only these two Linux engine versions were launched. Touch-drag, virtualization,
focus management, other engines/platforms and3D scrolling are not implemented or
claimed. Godot4.0 optional isolated preflight/symlink introspection remain
unavailable; mandatory transactional actual-path validation passes.

## Exact commands and proportional regressions

Linux Docker `estragon-e04-local`, Xvfb/Openbox, Mesa llvmpipe compatibility
renderer; self-contained editor settings and a no-external-tools product PATH.
From `/repo`, with `XDG_RUNTIME_DIR=/tmp/e04-runtime` and `UX01_CANDIDATE_TAG` set to the recorded manifest overlay tag (concrete argv is preserved in provenance):

```sh
COREPACK_ENABLE_PROJECT_SPEC=0 corepack yarn@1.22.22 node --experimental-strip-types tools/check-ux01.ts --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --editor --candidate-tag "$UX01_CANDIDATE_TAG" --output /tmp/ux01-review-acceptance
bun install --frozen-lockfile
bun run check
```

Paired local acceptance PASS in223.74s. This heavier LOCAL run is not routine CI.
Frozen install unchanged; typecheck/policy30 PASS, [log](../../tests/ux01/evidence/static.log).
[265 unique script/UID pairs](../../tests/ux01/evidence/uid-audit.json); canonical source maps checked
by policy. Current addon file hashes independently match both package manifests.
Configured root actual-path builds also PASS on both engines after unique fixture
aliases/source-owned field metadata, at the preceding compiler source `cee90ee`:
[root4.0.4](../../tests/ux01/evidence/root-4.0.4.log), [root4.7](../../tests/ux01/evidence/root-4.7.log). Subsequent changes
only refine ScrollView runtime restoration/tests; final package Build stages
validate the runtime scripts on both engines.

The bounded prior4.7 regression commands were each run once, using the same engine
argument and new output `/tmp/ux01-regressions-1/NAME`:

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/check-lengths.ts --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /tmp/ux01-regressions-1/lengths
# Same invocation for check-styling.ts, check-spreads.ts, check-responsive.ts,
# check-node-runtime.ts, check-native-controls.ts and check-native-ui.ts.
# check-native-ui.ts additionally used --runtime-only.
```

All seven PASS: Length243 including foundation/distribution/minima/root Exit;
S01/S02 styling158; S03 frontend61/publication7/rejection93/runtime28;
Wrap/Grid math95/frontend21/runtime44/rendered; shared core18/native runtime and
2D/3D editor persistence; native Control/Exit/examples and Counter/native UI.
[Regression logs/provenance](../../tests/ux01/evidence/regressions/lengths-provenance.json) and qualification
record exact heads. Most ran clean at `9b53e97`, Controls/Counter at `bc52a71`.
Node-runtime records a dirty working tree while the scoped scrollbar fix was being
made; its actual source hashes are retained. These are source-qualified earlier
regressions, not misrepresented as reruns at the final head. Final paired tests
cover all later ScrollView/capture/restoration and compiler-field corrections.
No73-stage/full release suite, workflow dispatch, skip-CI or extra matrix ran.

## Retained failures and corrections

- Merged-main auto-Wrap failure was reproduced before the capacity fix; checkpoint
  A links the initial numeric/owner-render logs on #183.
- Raw native BaseButton can activate on release outside a clip. Position rewriting
  alone did not cancel its cached press. The scoped public scroll notification
  guard is proven on both engines; raw native behavior is not claimed fixed.
- [First paired failure](../../tests/ux01/evidence/first-paired-failure.log):4.0 nested scrollbar was
  incorrectly filtered by the outer custom picker rule. Native GUI now intersects
  actual clips; custom picking separately excludes bars. Permanent native click
  regression passes without activating content.
- [Orchestration failure](../../tests/ux01/evidence/source-change-orchestration-failure.log): a config
  commit during an earlier paired run correctly failed `Overlay source mismatch`.
  Final paired source stayed fixed/clean throughout.
- [Unchanged-main root failure](../../tests/ux01/evidence/baseline-root-failure.log): native4.7 rejected
  source-owned Gogo model/item fields as if declared on the native base. Preserve
  source-proven property metadata, then validate the real generated assignments.
  Fixture basename collisions were removed with unique files/explicit aliases.
- [Restoration failure](../../tests/ux01/evidence/restoration-before-fix.log): old viewport range600
  incorrectly clamped a new authored750 before a larger range800 was arranged.
  Commit order and the existing dirty/arranged core now preserve then clamp once.
  An earlier probe lacking an Entry was discarded as invalid layout evidence.
- Initial fixture type inference/count assertions and missing native private
  ancestry during pack/reload were caught/corrected; GitHub checkpoints retain
  their development qualification. Persistent native ancestry and generated
  owner-null cleanup now pass permanent tests on both engines.

Evidence log end-of-line whitespace is normalized for Git; numeric tag/version provenance stays in test fixtures, as required by P04. JSON/package hashes and PNGs are unchanged.

Routine CI remains unchanged and is independently checked on the sole review PR.
The live issue/PR handoff records its final head, required checks/timing and owner
next action. Nothing here authorizes merge, a release/tag or publication.
