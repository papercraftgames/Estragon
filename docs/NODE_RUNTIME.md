**Current C4 note:** the native C1 API below remains the production runtime. C4 #83 removes its old B2/B3 forwarders/proof duplicates and the separate RefCounted UI. Canonical 2D widgets and current Counter paths are in [NODE_UI](NODE_UI.md). C1/B2/B3 evidence paths/commands below are historical, not live compatibility requirements; use [TESTING](TESTING.md) for current acceptance.

# C1 Node-native runtime foundation

[ADR-0015-C1 #77](https://github.com/resistdesign/Estragon/issues/77) implements
an opt-in native runtime foundation in `addons/estragon/runtime/node`, alongside
the unchanged legacy RefCounted runtime. This is usable GDScript/native-scene
runtime code; B1–B3 remain separately selected experimental fixtures. The general
GGX/default compiler/editor migration is C2, and Text/Button/Rect/stack widget
parity is C3. No old hierarchy was renamed or retired. Strict C01 release remains
**BLOCKED**; this foundation does not certify every Godot minor/platform.

The bounded lifecycle/coordinate proposal was recorded on #77 before code.
This PR reviews that concrete C1 API and its limits, without settling universal
3D units/wrapping/overlays or animated geometry observation.

## Public C1 API

Preload the corresponding file, or use its registered native-script class name:

| Runtime file | Class / responsibility |
| --- | --- |
| `estragon_2d.gd`, `estragon_3d.gd` | `Estragon2D`, `Estragon3D`: explicit independent layout entry, inheriting the participant properties |
| `component_2d.gd`, `component_3d.gd` | `EstragonComponent2D`, `EstragonComponent3D`: layout-only Node2D/Node3D participant; no widget drawing or generated visual child |
| `native_2d.gd`, `native_3d.gd` | `EstragonNative2D`, `EstragonNative3D`: bounded participant around one direct Polygon2D / MeshInstance3D, reusing the B3 bounds bridge |

Participant properties are `width`, `height`, 3D `depth`, `gap`, and `center`.
An extent of -1 uses the children's natural row extent, or the native adapter's
cached geometry extent; a finite value >= 0 fixes that allocation. Gaps are finite
and nonnegative. Invalid individual writes retain the prior valid value. Equal
writes are no-ops. `set_extent(Vector2/Vector3) -> Error` checks all axes before
changing anything and returns `ERR_INVALID_PARAMETER` without partial changes.

`layout_size` is a computed output, with `layout_applied(size)` emitted on
arrangement. `invalidate_layout()` requests affected-branch remeasurement and
restores parent-controlled translation after an external edit. `get_layout_root()`
returns the explicit active entry or null; `get_layout_stats()` returns a snapshot
with `active`, `measure`, `arrange`, and `flush` counters for diagnostics. No
per-frame call is required. Inherited Node `add_child`, `remove_child`,
`move_child`, `queue_free`/`free` and native detach/add reparenting are the only
native lifetime/attachment operations; there is no Error-returning custom adder,
dispose, virtual DOM or manual ownership manager.

Entries additionally export `viewport_width_scale` (default 0, disabled). A
positive finite scale allocates that entry's X extent from its own viewport's
visible pixel width. The application chooses any 3D scale explicitly; C1 imposes
no pixel-to-world conversion. Entry resize invalidation does not remeasure clean
sibling branches. DPI alone is not treated as resize.

Native adapters additionally export `observe_native` (default false), and expose
`invalidate_native()`, `get_native_bounds()` (Rect2/AABB in parent axes before
adapter translation) and `get_native_bounds_status() -> Error`. Initial status is
`ERR_UNCONFIGURED`; deferred measurement produces OK or `ERR_INVALID_PARAMETER`
for missing/multiple/unsupported/empty/non-finite providers. Invalid measured
bounds become zero, with explicit fixed allocation still respected. Generic
Nodes have no inferred size. The `layout`, `bounds`, coordinator/model fields and
placement/measurement hooks are internal implementation details, not the stable
authoring API. Future provider/widget extension interfaces are not defined here.

## Scope, coordinates and authority

A component joins layout only along immediate, same-dimensional C1 participants
leading to an explicit entry. Ordinary Nodes (including unadapted Node2D/Node3D),
opposite-dimensional participants and experimental proof participants are not
silently admitted. A component below such a boundary has no active root and
performs no layout. Nest a new entry to re-enter. An entry always starts a new
independent scope, even directly beneath another entry/participant; outer layout
does not size, place or receive invalidation from that nested entry. This differs
intentionally from B2's single proof class serving both entry/participant roles.

Both dimensions use the same composed B2 mathematical X-row measure→arrange core.
Natural width sums children plus gaps; Y/Z use maximum child extent. Optional
centering offsets the row within allocation. Fixed allocation does not shrink,
stretch or clip native geometry; overflow is permitted. Local 2D coordinates use
pixels; 3D coordinates use explicitly authored Godot world units. No wrapping,
constraint solver, implicit overlay or universal volumetric policy is included.

For a basic participant, the parent owns local translation and computed allocation.
Native rotation/scale are retained, and measurement uses authored local extent;
transformed basic-component visuals may overflow. Entry translation and ordinary
Node transforms stay authored. A plain Node can break Godot spatial ancestry;
a spatial ordinary Node can preserve spatial transforms while still breaking
layout. These boundaries are independently tested.

The bounded native adapters preserve B3 semantics: polygon vertices plus offset,
or eight mesh AABB corners, transformed by the native child transform and adapter
basis into immediate-parent axes. Layout places the adapter at row offset minus
cached minimum, normalizing negative/transformed origins without changing the
native child's position/rotation/scale/mesh/material. This normalization applies
only when an entry places the participant. Explicit allocation never resizes its
native geometry or physics. Skinning, shader displacement and generic/animated
provider contracts remain outside this provider set.

Snapshots are deferred and coalesced. `observe_native` subscribes to Mesh.changed
or CanvasItem.item_rect_changed; Polygon2D geometry/transform edits do not reliably
emit that signal on both engines and require explicit `invalidate_native()`.
Mesh replacement also requires resnapshot to rebind. Fixed snapshots are suitable
for opting out of animated changes. Bounds observation reads child/resource inputs,
whereas layout writes only wrapper translation, excluded from measured basis:
there is no transform feedback subscription or compulsory polling. An origin-only
change still reapplies placement with unchanged extent. Initial/dependent native
snapshots can schedule a bounded follow-up arrangement; this is not a guarantee
that mixed asynchronous provider/property events always produce one callback.

## Native lifetime and persistence

Layout scope ownership is unrelated to Godot parentage or scene `owner`.
`add_child` never assigns `owner`. Native removal preserves the Node and authored
signal connections; it is not legacy disposal. Native reparenting can clear an
owner that is no longer an ancestor. Runtime layout does not restore that owner
or claim external nodes for persistence. Assign valid owners explicitly when
packing a scene; unowned runtime children are intentionally absent after reload.

Each participant scopes native child/order connections to enter/exit. Only entries
subscribe to viewport resize. Exit disconnects and releases model membership;
re-entry discovers the existing native children again. Pending deferred work checks
active lifetime and queued deletion before applying anything. Runtime membership
resolves the live participant script field, so no coordinator WeakRef is stored
in serialized Node metadata. PackedScene restores metadata after construction;
the preserved proof-only registry is refreshed at enter-tree for that old API. Native free cleans
up Nodes/signals. Node identity and authored connections survive reflow/removal/
reparenting according to normal Godot rules. The proof's 4.0 moved-in-parent
notification bridge remains capability-isolated from newer child-order signals.

## Shared internals and migration boundary

`runtime/node/internal/layout_core.gd` is the single mathematical implementation;
it imports no Node, SceneTree, renderer or editor. `coordinator.gd` supplies native
membership/lifetime/scheduling and distinguishes C1 scopes from the proof mode.
`native_bounds.gd` is the single B3/C1 snapshot/observation bridge. The old B2 core/
coordinator and B3 bounds files now forward to these implementations while
preserving their file paths and UID sidecars. Proof behavior and all B1/B2/B3
examples remain exercised by their original checks. C1 product files import no
proof or example path; its isolated acceptance runner copies only runtime files,
its demos and its native tests. This is not a second per-dimension math library.

Legacy `EstragonDisplayObject`/`EstragonContainer`/`EstragonSurface`, generated
Counter/Mixed/Compiled scripts, the default native Gogo compiler/editor and B1's
opt-in compiler retain their own APIs. No `.gogo` source discovery, grammar,
emission or default tag resolution was changed. C2 needs a separately selected
issue after C1 review/merge; do not start it from this PR.

## Demos and verification

Runnable scenes and exact interactions: [examples/node_runtime/README.md](../examples/node_runtime/README.md).
Both demos show native teal/purple visuals through real C1 adapters and an orange
layout-only component under an explicit reentry boundary. They run with Godot
alone; native authored script/scene composition is intentional until C2.

`tools/check-node-runtime.ts` uses TypeScript/Yarn orchestration, isolated
self-contained editor settings, empty child PATH and verified official binaries.
It runs numeric/native lifecycle tests, native owner-aware packing/reload, two
real-editor save/reopen sessions and native graphics captures. Runtime/graphics
use a real renderer (software Mesa/Xvfb in Linux CI); headless parsing is separate.
Native errors, failed markers/assertions, timeouts and leak warnings fail the run.
Only official 4.0.4 and pinned 4.7.0 are tested. No physical keypress acceptance
is required; automated tests call the same demo interactions.

Exact commands, engine/source provenance, results and inspected captures are in
`tests/compatibility/c1/README.md`. Metadata uses the established audit, with
new native UIDs generated at canonical source paths, no broad ignores and only
an audited evidence-only C1 `.gdignore`. Existing 4.0 full-checkout Logger research
FAIL diagnostics and first-import asset-setting normalization remain documented
in the B3 metadata contract; this task neither suppresses them nor repairs C01.
