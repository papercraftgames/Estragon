> Historical B2 proof contract. Its sizing flags are retired. Current public API: [unit lengths](LENGTHS.md).

# ADR-0015-B2: shared 2D/3D measure-arrange proof

**Scope:** [#73](https://github.com/resistdesign/Estragon/issues/73), following merged [B1 PR #72](https://github.com/resistdesign/Estragon/pull/72), [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) and [Node migration plan](NODE_MIGRATION_PLAN.md). B2 is a bounded proof for review. The default compiler/editor, RefCounted component runtime, Counter and legacy examples remain unchanged. No B3 native bounds adapters, general component/compiler migration, bindings, volumetric wrapping or release certification is included.

## Proposed proof contract, not universal product policy

Actual scripts are `addons/estragon/layout_proof/entry_2d.gd` (Node2D) and `entry_3d.gd` (Node3D). There is no shared visual Node superclass. Each composes a shared coordinator and one instance of the same pure mathematical `core.gd`. The same spatial script acts as a direct participant when its immediate parent is an active proof participant of the same dimension, and as an explicit independent entry otherwise. They have no `class_name`; the demo resolves explicit preloaded aliases through B1's opt-in compiler API.

The proposed defaults were recorded before implementation in [#73's plan](https://github.com/resistdesign/Estragon/issues/73#issuecomment-6605088015). Owner review of this proof is not a decision to apply these defaults to all future layout components.

- **Units:** 2D widths/heights/gaps are pixels; 3D widths/heights/depth/gaps are authored Godot world-unit lengths. The pure core represents extents with Vector3; 2D always passes Z=0. There is no implicit 2D↔3D coordinate or unit conversion.
- **Measurement:** requested lengths are finite nonnegative fixed extents, or exactly -1 for natural measurement. A row's natural X extent is the sum of participating direct-child widths plus gap*(child_count-1); Y/Z are child maxima, and empty natural extent is zero. Each fixed axis overrides only that measured axis. No stretching, fill, flex allocation, clipping, wrapping or geometric auto-measure of native children.
- **Arrangement:** native child order determines an X-axis row. Children retain their measured extents, Y/Z placement is zero, and X advances by child width + gap. Optional `center` starts at `(available_width-natural_row_width)/2`, including negative starts on overflow. Fixed/zero parent bounds do not shrink children. This is not a full overflow policy.
- **Exact fixtures:** widths 10/20, gap 2, available width 100 center at X=34/46, height=max(5,7)=7. Change first width to 14: X=32/48. World-unit sizes (1,2,3)/(2,1,4), gap .5 measure (3.5,2,4) and second X=1.5.
- **Authority:** parent layout writes only participating direct children's native local position and each participant's separate computed `layout_size`. Requested width/height/depth and arbitrary native transforms are not rewritten. Native rotation/scale are retained; measurement is in untransformed local units, so transformed visuals may overflow. Parent-controlled child-position edits are not observed or polled; explicitly call `invalidate_layout()` to restore layout authority if needed. Root position remains authored/native-owned.
- **Boundaries:** ordinary native Nodes (including Node2D/Node3D without a proof script) and opposite-dimensional participants do not join the parent's layout. Their children do not tunnel sizing or invalidation upward. Another explicit proof entry beneath one starts a separate layout root. A plain Node also breaks Godot spatial ancestry; an ordinary Node2D/Node3D may retain native spatial transforms while still being a layout boundary. There is no automatic overlay integration.
- **Viewport:** `viewport_width_scale` defaults to 0 (disabled). For an entry with no participating parent, positive scale allocates root X from its own viewport's visible pixel width times the explicit application scale. The 2D demo uses 1 pixel per pixel. The 3D demo explicitly chooses .0125 world units per viewport pixel; this is an opt-in demo mapping, not a global pixels-to-world rule. Resize affects root allocation/centering while child measurements remain cached. Descendants managed by a parent ignore their own viewport scale.
- **DPI:** native `Window.dpi_changed` availability is recorded in tests; emitting it alone does not imply a viewport resize or reflow. There is no inferred DPI/scaling policy. An application that changes layout inputs for DPI may change those inputs or explicitly invalidate. Viewport resizing remains a distinct tested input.
- **Validity:** setters retain the previous valid value for nonfinite/invalid negative lengths/gaps/scales. The pure core's configuration API returns ERR_INVALID_PARAMETER on invalid geometry; tree operations reject duplicate/cyclic or already-owned models. This proof does not define a general validation UI or runtime geometry diagnostic policy.

Open review questions remain future axes/layering/wrapping, richer sizing/overflow, transformed-bounds measurement and general world/viewport mapping. None is needed to evaluate these bounded numeric examples; do not treat implementation convenience as owner approval for those broader choices.

## Shared math and event scheduling

`core.gd` imports no scene, editor or renderer classes. It owns ordered model references, weak model-parent links, measurement caches, dirty flags and numeric results/counters. Both spatial branches call exactly this measure → arrange algorithm. Rendering and native tree discovery are outside it.

`coordinator.gd` is the shared native lifetime/event adapter. It scans only immediate children after native child events, selecting same-dimensional active participants through private weak metadata. Existing unchanged child lists are no-ops. Participant changes propagate dirty flags up their participating model branch. Only the entry queues a deferred flush, with repeated invalidations coalescing into one queued operation. Clean sibling measure/arrange results are retained; changed sibling positions can be applied without recomputing that sibling's internal layout. Placement and result signals deliver only changed/dirty work to native Nodes. There is no process/frame callback, virtual DOM, full-tree reconstruction, transform watcher or polling loop.

Godot 4.0.4 lacks `child_order_changed` and `NOTIFICATION_CHILD_ORDER_CHANGED`. The proof uses native child-entry/exit signals on both engines, a capability-checked named order signal on newer engines and 4.0's `NOTIFICATION_MOVED_IN_PARENT` (12) forwarded by participants for native reordering. Native `move_child`, add/remove, transfer and freeing are tested. This is a small native event bridge, not a private editor adapter or a global tree scan.

Each active participant subscribes to its own viewport; only independent entries with positive scale schedule work for resize. Exit disconnects viewport/native child hooks and releases model parent/children participation. Native remove/add can preserve the Node instance and signal subscriptions while transferring layout participation. Layout does not assign scene owners or free Nodes; Godot still owns those operations. Deferred flushes check live/active ownership before doing work.

The 2D participant draws a rectangle using native Node2D `_draw`; 3D owns a native BoxMesh/MeshInstance3D as its visual detail. Native visual children are not layout participants. A camera and directional light make the 3D demo visible. These are fixed proof visuals, not B3 wrappers that measure or take authority over arbitrary external native Nodes.

## Demos and native build

See [example instructions](../examples/layout_proof/README.md). Scenes: `res://examples/layout_proof/TwoD.tscn` and `res://examples/layout_proof/ThreeD.tscn`.

The authored hidden `.proof/Layout.gogo` uses the existing B1 compiler with explicit Entry2D/Entry3D aliases. The Godot-only builder reuses B1's actual-path semantic publication/rollback. It constructs real native Nodes via inherited void `Node.add_child`, with deterministic source maps. The hidden proof source is excluded from normal editor source discovery. No compiler cutover, extra tag protocol, external compiler or generated-script hand editing is needed.

Both scenes show a teal participating child and a purple/blue nested branch. An orange row under an ordinary native spatial Node is an independent reentry. Press Enter/Space to change the teal child's requested width; native property events update existing positions. Resize the window to change root allocation/centering. Automated tests invoke these operations without requiring physical keys. The camera projection can move screen pixels on resize even when an orange child's world position is unchanged; native tests separately assert the unaffected boundary's geometry and counters.

## Verification

From outside the historical Bun package-manager manifest:

```sh
cd /tmp
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/check-layout-proof.ts \
  --engine 4.0.4=/absolute/official/godot-4.0.4 \
  --engine 4.7=/absolute/official/godot-4.7.0 \
  --output /new/absolute/evidence-directory --graphics
```

Use only these two approved engines. `--core-only` provides a narrow pure-math development check. Output directories must be new. The TypeScript/Yarn runner reuses the established isolated binary/hash/version verification and empty executable PATH. It copies only needed addon/proof files, removes generated B2 output, compiles natively and verifies code/map determinism through runtime tests. Pure math/build are headless; the mesh-bearing runtime and visual test require actual graphics (Xvfb/software Mesa on Linux). Native errors, missing markers, assertions, timeouts and resource-leak warnings fail checks.

Focused 4.0.4 headless runtime initially emitted the existing dummy-renderer mesh error; it was not filtered or claimed PASS. Real graphics-backed runtime verification preserves 3D mutation/freeing evidence without depending on dummy rendering behavior. The 4.0.4 child-order API failures also remain observed development failures, corrected by the event bridge above rather than version skipping. No C01 release blocker is waived.

Native tests cover exact numerical 2D/3D layout, invalid configuration/cycles/empty/zero bounds, affected versus cached branches, zero idle counters, one coalesced reflow, native viewport resize versus DPI, transforms/authority/plain and spatial boundaries/opposite dimensions, retained IDs/signals, native move_child/reparent/owner/free and subscription cleanup. Graphics tests capture initial, changed-extent and resized states in both dimensions. Existing B1 and default runtime/editor regressions remain independently exercised by CI.

Measured snapshots: [4.0.4 provenance](../tests/compatibility/b2/4.0.4/provenance.json) / [results](../tests/compatibility/b2/4.0.4/results.json), [4.7.0 provenance](../tests/compatibility/b2/4.7.0/provenance.json) / [results](../tests/compatibility/b2/4.7.0/results.json), with adjacent native logs and six captures each. On both engines, 18 pure fixtures and 69 runtime assertions PASS, including unchanged idle counters `[1,1,1]`, one coalesced root flush and zero sibling measure/arrange deltas. Both native 2D/3D initial/changed/resized captures were visually inspected. Compiler output/maps match byte-for-byte across the engines.

Exact local command from `/tmp`: `corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-layout-proof.ts --engine 4.0.4=/Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot --engine 4.7=/Applications/Godot.app/Contents/MacOS/Godot --output /tmp/estragon-b2-final --graphics`. Provenance records actual official versions/binary hashes, per-source SHA and the pre-commit working-tree state. Existing `bun install --frozen-lockfile` / `bun run check` passed (202 tests, 671 expectations, strict types and generated IR/GDScript consistency). The full existing pinned regression `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bun run check:godot` also passed (project import, every-script parse, native frontend/runtime/layout/interaction/signals and mapped negative cases); see [existing-regression.log](../tests/compatibility/b2/4.7.0/existing-regression.log). Raw native log trailing whitespace is preserved; source/doc hygiene excludes `*.log`. No manual legacy Hello or physical-key smoke test was run. Working-tree evidence is not a clean-source release artifact. Historical evidence remains unchanged. No physical/manual key acceptance gate or owner-checkout plugin setting changes are introduced.

## Release and delivery boundary

Strict C01 release remains **BLOCKED**. Raw-syntax/hybrid findings, cold missing-generated restoration, #65 resource-pack export cleanup and standalone/platform certification remain separate. The explicit B2 builder runs before its scene loads, not as a claimed cold-scene fix. Rendering a 3D layout proof is not export/platform certification.

B1 is merged; B2 still requires owner review/merge. B3 native adapters, wider runtime/component/compiler migration, T09 and L01 follow their separate dependencies. **Do not merge automatically or start B3 from this PR.**
