# B3 native adapter proof

ADR-0015-B3 [#75](https://github.com/resistdesign/Estragon/issues/75), after
B2 / merged PR #74 (`5921e96`). This is an isolated experiment under
`addons/estragon/adapter_proof`, not the default runtime/compiler migration.
The bounded proposal was recorded in #75 before implementation. Owner review
of this PR is the review of these proof defaults; universal adapter rules remain
open. No C1 implementation or release approval is included.

## Bounded bounds and authority contract

`native_2d.gd` and `native_3d.gd` extend B2's Node2D/Node3D entries respectively,
composing the same mathematical core and native coordinator. They suppress B2's
placeholder drawing/mesh; one authored native child supplies all rendering.
Exactly one direct Polygon2D / MeshInstance3D with a Mesh is accepted. The bounds
bridge reports `ERR_INVALID_PARAMETER` for missing, multiple, unsupported,
non-finite or empty providers. This is a validation result, not a swallowed engine
error. Generic Nodes never gain inferred dimensions.

Polygon vertices plus Polygon2D.offset, or the eight Mesh AABB corners, are
transformed by the native child's full local transform and the adapter's basis
(rotation/scale/skew where applicable). Cached minimum/extent are axis-aligned in
the immediate parent's coordinate axes. Layout owns adapter translation:
`position = allocated_offset - cached_minimum`. This aligns the transformed
visual minimum with the row allocation, including negative origins and rotated
or scaled geometry. No inversion of a singular transform is needed. Ancestor
transforms remain native, as in B2; ordinary Node boundaries do not tunnel layout.
An adapter used as an independent entry retains its authored translation; minimum
normalization is defined only when a same-dimension layout parent places it.

Width/height/depth >= 0 override allocation per axis; -1 uses cached native
extent. Fixed allocation never stretches the visual, so overflow is permitted.
Godot owns the child's position, rotation, scale, geometry, mesh, material,
rendering and physics. Layout never writes those fields. Adapter rotation/scale
also remain authored, but edits require explicit resnapshot. Units remain B2's
2D pixels and proof-only 3D world units; this defines no general wrapping,
constraint, clipping, physics resize or pixel/world conversion system.

`invalidate_native()` defers/coalesces bounds snapshots; layout remeasures the
affected branch through B2. There is no `_process`, transform observer cascade,
per-frame measurement or reconstruction. `observe_native=false` (default) is a
fixed snapshot policy for animated geometry. With observation enabled, the bridge
subscribes to Mesh.changed or CanvasItem.item_rect_changed. Mesh geometry changes
emit the native signal in the test. Polygon2D geometry/transform setters do not
reliably emit item_rect_changed on both engines: explicitly invalidate after
those edits; the test separately emits that native signal to verify subscription
and batching. Replacing a mesh also requires explicit invalidation to rebind.

Feedback is prevented by separating observed inputs from outputs: subscriptions
are on the native child/resource, while layout writes only adapter translation;
translation is excluded from measured basis. Tests assert notifications stop and
idle snapshot/measure/arrange/flush counters remain unchanged. An origin-only edit
forces placement even when extent/row offset are unchanged. Three invalidations
coalesce into one snapshot and one root flush; sibling measurement stays cached.

Native lifetime is unchanged. Tree exit/removal disconnects subscriptions;
re-entry resubscribes, deferred work checks active lifetime, reparenting transfers
participation, freeing destroys the child. Instance identity survives reflow and
reparenting. Scene `owner` is explicit: the demo recursively owns authored native
nodes under its scene root. PackedScene pack/save/load and two real editor sessions
verify both dimensions, owners, native transforms and absence of duplicate visuals.
The runtime never assigns scene ownership implicitly.

## Metadata policy and audit

The starting checkout had three disposable native-generated outputs, 51 new script
UID sidecars and 30 screenshot import sidecars. The outputs were restored; valid
unique script UIDs were preserved. New B3 UIDs were obtained from the pinned native
editor at the corresponding canonical project paths, never temporary drivers.
Every committed GDScript has a stable sidecar; uniqueness is checked against all
script UID and asset import UID values. All five existing `Assets/*.import`
settings remain versioned. No global suffix ignore was added.

Resource/reference audit found no live resources beneath B1, B2, B3 and C01-H
evidence roots, so they each receive `.gdignore`. Only C61's `editor/` capture
folder is excluded: its archived `.gogo` outside that folder remains visible.
The 30 classified untracked screenshot `.png.import` files were removed; old
logs, results, screenshots and the preserved Codex stash remain unchanged.
Godot's [UID rationale](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
and [directory exclusion guidance](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html#ignoring-specific-folders)
explain the distinction between identity/settings and disposable cache/evidence.

`tools/check-godot-metadata.ts` copies indexed repository files to clean isolated
projects, imports twice with the addon plugin disabled to isolate metadata from
intentional compile-on-open output changes, and checks unchanged sidecar hashes,
no unexpected `.uid`/`.import`, native cached/path/UID script identity and actual
PNG/font imports. Self-contained editor settings and empty PATH protect user
preferences and prove no external compiler is involved. 4.0.4 uses path identity;
4.7 additionally resolves UID paths to the identical loaded script.

Known full-checkout editor limitation: R01 research `tests/research/bindable`
uses 4.7 Logger APIs and produces parse diagnostics on 4.0.4. The metadata runner
retains those actual editor stages as **FAIL** with exact raw diagnostics and a
named limitation; only the measured diagnostic set is accepted for this metadata
check. Any other error, timeout, UID/settings change or unexpected sidecar fails.
This does not certify the complete repository/editor on 4.0.4 and is not a C01
repair. Live research fixtures were not hidden. Normal addon compile-on-open can
still update checked generated code/maps; this is independent of sidecar hygiene.

## Verification and complete proof boundary

Acceptance evidence is collected with `tools/check-adapter-proof.ts --graphics`
and `tools/check-godot-metadata.ts`, official 4.0.4 and pinned 4.7.0 only. Exact
commands, engine hashes, source hashes and dirty/commit provenance live alongside
raw logs in `tests/compatibility/b3`. Graphics are real native captures, separate
from numeric/runtime assertions; editor automation uses isolated real editor
save/reopen, not physical F5/F6 keypresses. See that evidence README for outcomes.

| Proof | Evidence / retained limits |
| --- | --- |
| B1 composition | PR #72: typed native GGX, Node-only child contract, named/Object signals, lifetime, transforms, native pack/editor persistence; bounded opt-in compiler |
| B2 shared layout | PR #74: composed pure math, explicit entries/boundaries, cached affected branches, coalescing, native identities and graphics in both dimensions |
| B3 adapters | This review: transformed bounds, fixed/native allocation, snapshot/opt-in invalidation, feedback termination, lifetime/owners/editor persistence and graphics |

Together these are the minimal bounded proof **after B3 review/merge**, not a
migrated framework. Default RefCounted runtime/editor compiler and existing
Counter remain preserved. General adapter catalog, animated observers, universal
3D units/wrapping, general GGX resolution, widgets, bindings and legacy retirement
remain unimplemented. C01 strict release remains **BLOCKED** with unchanged
fingerprints. C1 needs a separately selected scoped issue and reviewed lifecycle/
coordinate contract; do not start it while this review PR is open.
