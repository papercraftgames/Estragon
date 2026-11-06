> Historical 2026-11-02 design record: the native/description architecture has since shipped through F01–F06; [current implemented contracts](ARCHITECTURE.md) and [remaining roadmap](F06_PROFILING.md#remaining-framework-roadmap) supersede the implementation-status wording below. Preserve this record as design history.

# Estragon design direction: Gogo, GGX and native layout

**Owner-approved target, 2026-11-02; not implemented.** [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) formalizes [#68](https://github.com/resistdesign/Estragon/issues/68); [#69](https://github.com/resistdesign/Estragon/issues/69) is documentation/planning only. [ARCHITECTURE](ARCHITECTURE.md) separates this target from current code; [NODE_MIGRATION_PLAN](NODE_MIGRATION_PLAN.md) supplies serial successor tasks and unresolved decisions.

## Language and native execution

**Gogo** is the GDScript-like language in `.gogo`. **GGX** names its embedded XML-like syntax, in the role of JSX/TSX, for general-purpose Godot **Node composition**. It is not limited to Estragon UI. Preserve GDScript declarations/functions interleaved with expression-position, unprefixed tags and braces containing GDScript. No mandatory namespaces, code-behind, script blocks, JSX/GGX pragmas or runtime XML/JSON interpreter.

The bundled native compiler produces deterministic typed GDScript plus original-source maps. Godot remains the GDScript semantic authority. Native parsing/model/codegen stay separate from editor UI, rendering and a running SceneTree. The existing editor's transactional publication, actual-path semantic validation, cached Script identity, unsaved-buffer checks and fail-closed Play/recovery remain mandatory. End users need only Godot and the addon; no external compiler or Bun/Node fallback.

GGX hierarchy items must derive from Node. **Inherited Node.add_child(Node) is the only attachment API**, for all parent types; it returns void. No type-specific/configurable child-adder protocols. Resources, materials, meshes, shapes and models can be property/expression values; non-Node Objects cannot be hierarchy children. Typed native properties and native signal connections apply to ordinary Nodes too. A referenced non-Node Object can also supply a signal.

Event-handler attributes reference named handlers/Callable values; do not introduce inline anonymous function declarations there. Ordinary GDScript functions may contain GGX expressions; function-valued children are not required for repetition. The current T07 compiler accepts zero-argument lambdas as Callable expressions; a reviewed transition must account for that existing behavior rather than silently removing support in a planning PR.

Tag imports/resolution, native metadata validation, binding syntax, named references and migration from the current five built-ins require scoped design/proof. Native Node.add_child semantics cannot reuse the Error-returning EstragonContainer protocol mechanically. Parentage is separate from PackedScene owner persistence and native signal/freeing behavior.

## Layout-first 2D and 3D

Estragon supplies a Flex-inspired 2D UI suite replacing Godot Control UI for its intended uses, and extends measurement/layout/sizing/positioning/reactive composition to 3D. It is not a competing renderer or virtual DOM. Godot retains native SceneTree, lifetime, transforms, physics, rendering and platform/window events. Visual presentation is implemented by the respective native components/backends.

Visual 2D components inherit Node2D; 3D participants inherit Node3D. A mathematical measure → arrange core is shared **through composition**. A plain shared Node visual superclass is not intended. Explicit entries have working names Estragon2D/Estragon3D, exact names TBD.

Ordinary Nodes can appear anywhere in GGX and retain native behavior, but are not automatic layout participants. Add a new explicit entry to re-enter Estragon below an ordinary Node; never tunnel sizing through arbitrary boundaries. Plain Nodes can interrupt spatial ancestry, and 2D/3D transforms differ. Local/native coordinate conversion and any 2D overlay in 3D need explicit supported contracts.

2D pixel-unit decisions remain. 3D introduces width/height/depth and native spatial placement. Volumetric RowBox/ColBox filling two axes and layering along the third is accepted as a model; axes, wrap order, spacing, world units, size constraints and overflow remain a focused specification. Pixels are not assumed to be world units.

## Native adapters, identity and invalidation

Working Native2D/Native3D wrappers expose explicit size/position to layout and optionally measure/observe a native child. Appropriate providers may use authored size, geometry/rect bounds or mesh AABB. A generic Node/Node3D has no universal size. Children keep native rendering and behavior.

Specify which geometry is layout-controlled versus native-controlled, cache measurements, invalidate affected branches and batch/coalesce updates. Guard transform/bounds notifications caused by Estragon's own writes against feedback. Animated geometry may use fixed/deferred snapshots or explicit opt-in observation, with no compulsory per-frame polling or full-layout transform cascade.

Keep Node identity and subscriptions across layout. Events include property/collection changes, native signals, tree/child changes, explicit adapter invalidation and viewport resize. Handle relevant Window DPI/scaling events separately; they do not always imply viewport resize. Observable/bound theme data drives theme updates. Retained keyed Nodes support incremental repeated content without full-tree reconciliation or function-valued children.

## Reactive data and authoring

Preserve **exact lowercase `@bindable`, Gogo-only**, including code-only typed non-Node model modules. Generated `.gd` uses ordinary typed accessors/notifications; no native authored `.gd` annotation, `.bgd`, engine fork or manual setter boilerplate. Plain assignments should update subscribed visual/layout properties without manual root reconstruction. Dependency-aware nested replacement, collection structural/item changes, cycle guards and cleanup remain required. These features are **planned**, not executable today; see [REACTIVITY_PLAN](REACTIVITY_PLAN.md).

The native editor already supports highlighting, build diagnostics and compile-before-Play. Completion/navigation, debugger remapping and live preview remain future work. A future preview must show actual native components/layout rather than substituting stock Control semantics for Estragon UI. Editor Controls remain appropriate for tooling. Preserve user preferences and isolated real-editor verification; no physical keyboard gate.

## Present implementation and remaining direction

C1–C3 are merged. C4 #83 / PR #84 removes the obsolete RefCounted/RenderingServer UI, stage-0 JSON/reference compiler and temporary proof/shim paths. The current native compiler/editor, canonical Node2D widgets, retained Counter, 2D/3D participants/adapters and composed core are documented in [ARCHITECTURE](ARCHITECTURE.md), [GOGO_LANGUAGE](GOGO_LANGUAGE.md) and [NODE_UI](NODE_UI.md). Bindings/repeaters, broader widgets/style/focus/accessibility and general 3D wrapping remain future work. C4 is not Done until owner review/merge.

Current release scope is the Godot addon (#83), with native source/maps/semantic rollback, real editor Play/repair, runtime/graphics/metadata, fresh/source-only install and real pack export/runtime gates. Old C01 standalone/legacy tests are discontinued requirements; their historical failures remain unchanged. The sample uses the documented text-resource export bridge for the 4.0 scene conversion leak. Actual current failures still block; no automatic publishing or untested-platform/minor claims. Only official 4.0.4 and pinned 4.7.0 Linux are routine acceptance; TypeScript/Yarn automation, no Python.
