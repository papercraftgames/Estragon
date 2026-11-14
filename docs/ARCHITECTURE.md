# Current Estragon architecture

Estragon is a native Godot addon. F01–F06 are merged through [PR #105](https://github.com/papercraftgames/Estragon/pull/105), `55156fb`. [ADR-0016](REACTIVE_COMPOSITION_ARCHITECTURE.md) defines signal-driven function composition, lightweight desired descriptions and retained native reconciliation. Approval of that broader design is distinct from the bounded implemented contracts below. [P01 packaging](PACKAGING.md) prepares distribution; actual public publication remains separately authorized.

## Language, compiler and editor

Gogo is GDScript-like source with GGX expression islands. The bundled lexical parser/model/validator/emitter produces deterministic typed native GDScript and source maps, independent of EditorInterface, drawing and a running SceneTree. Native semantics remain authoritative. The editor saves Gogo buffers before main/current Play, rejects invalid/unsavable source, validates actual paths, transactionally restores code/maps/timestamps/cache identity on failure and recovers after repair. End users need only Godot; no Bun/Node compiler process.

Every GGX expression returns an Element description, including helpers/lambdas. A typed `build_view() -> Element` with an explicit Element preload alias is the automatic host entry. Native class tags and ordinary explicit imports resolve normally; E07 also resolves unique project-authored Gogo tag names through the shared source scope and mapped private native Script imports. There is no reserved short-tag mapping or runtime change. Named handler/Callable attributes connect native signals; no inline anonymous event declarations. Every hierarchy item derives from Node and attaches through inherited void Node.add_child. Resources and RefCounted data models remain values, not an alternate UI hierarchy.

## One reactive manager

Typed Gogo `@bindable` setters publish native per-field signals. Class scope expands eligible owned fields through the same lowering; initialization, reference equality, inheritance and rejected accessor forms are documented in [BINDABLE_PROPERTIES](BINDABLE_PROPERTIES.md). Dynamic getter reads during composition determine weak subscriptions. Relevant signals coalesce affected function executions; no per-frame rerender or manual invalidation is required.

Desired lightweight descriptions carry type/properties/handlers/children and optional sibling keys. The external manager matches native Nodes by type/position/key, preserves compatible identities/state, applies changed declared props and minimum necessary structural operations. Nested scopes and parent-first scheduling cancel removed descendants. Ordinary GDScript conditionals/for/Array.map build null slots and sequences. Raw in-place collection mutation is unobserved without a separately scoped adapter.

All reconciliation identity/subscriptions live in external framework records, with no helper Node or bookkeeping metadata on user objects. Foreign children and native scene owners follow explicit rescue/lifetime rules. Managed output is transient; PackedScene persists authored hosts and reconstitutes views on mount. F04 removed replaced eager factories/static path binders rather than supporting a second API.

F05-B [bind:value](TWO_WAY_BINDINGS.md) supports typed Gogo bool lvalue paths and a real native Toggle user-edit signal. Programmatic projections are quiet; replacement/unmount/free disconnect stale callbacks. Text/IME/keyboard focus and broader input types remain future work.

## Native layout, drawing and input

L04 [native Control integration](NODE_UI.md#l04--native-control-auto-layout) adds an externally retained, weak-host Control adapter to the existing coordinator registry. It measures native combined minimums, defers/coalesces native signals and assigns compatible 2D outer rects through the same pure core. Native minimum floors constrain flex slots; native Container internals remain opaque and Godot-owned. Direct and borrowed native Controls share this path; no helper Node, authored metadata, second reconciler or polling is introduced. Godot still owns GUI rendering/input/focus. Plain native actors keep explicit size/position boundaries.

Canonical Node2D widgets are Rect/Text/Button/Toggle/HBox/VBox with Estragon class prefixes. Native Node2D/Node3D participants/adapters use the same composed mathematical core. Godot owns transforms, rendering, physics, platform events and SceneTree lifetime. Affected branches invalidate eventfully; idle trees do no avoidable layout work. Generic Nodes have no universal size; explicit entries cross plain-Node boundaries and adapters expose bounded geometry/authority. L03 registers spatial composition hosts through their external Computation and forwards only the managed participant root into the same layout core; explicit Entry/non-layout/cross-dimension roots retain zero parent footprint. See [NODE_UI](NODE_UI.md), [NODE_RUNTIME](NODE_RUNTIME.md).

F06 [profiling evidence](F06_PROFILING.md) keeps collection opt-in/off by default, replaces quadratic LIS discovery with binary search and reuses metadata only within one preflight tree. This is measured bounded work reduction, not a new compiler optimizer or promise of universal throughput. Native 4.0.4 large reorders remain costly.

## Boundaries and evidence

Target Godot 4.0+; fresh proof is only official Linux 4.0.4 and pinned 4.7.0. Real isolated editor/game, native pointer/graphics, metadata/UID/maps, cold source-only and pack runtime proofs remain mandatory. The accepted #44 highlighter limitation and documented older-engine optional diagnostic/introspection differences remain truthful.

Merged F01–F06 complete the reactive composition milestone, not the entire general UI framework. Broader layout/position authority (#88), richer inputs/focus/text/IME, styling/accessibility/themes, editor UX (#6), broader release readiness (#51), optional collections/serialization and more platforms remain separate tasks. Historical reports/ADRs preserve their original facts and old repository links through GitHub redirects; they are not supported executable paths.

L01 [Box contract](NODE_UI.md#l01--pixel-box-model) adds the native EstragonBox base for HBox/VBox and Entry2D, pixel content padding and outer 2D participant margins in the existing pure core. External composition bridges forward root margins once; retained layout/drawing/input/lifetime remain native. No percent grammar or second layout runtime is introduced. Live #55/sole PR controls implementation verification and review state.
