**T09-B current contract:** [REACTIVE_GGX](REACTIVE_GGX.md) defines implemented explicit self-path properties, nested null/replacement, weak native lifetime and deferred batching. The older full-system sketches below are historical direction; collections/keyed repeaters and two-way binding remain unimplemented.

**Current implementation:** T09-A #43 implements [observable typed Gogo properties/code-only models](BINDABLE_PROPERTIES.md); T09-B #86 adds the bounded explicit-self-path UI binding contract linked above. C4 is merged; the canonical runtime is native Node2D/Node3D with composed layout, and RefCounted data models are values, never UI hierarchy elements. The broader collection/two-way proposals below remain future T09-C/D. Historical surface/Box/no-Node statements are superseded by ADR-0015/C4.

# Bindable properties and reactivity

**Status: planned; owner-approved source boundary 2026-10-29.** Only `@bindable` (lowercase) in **authored `.gogo`** is an accepted annotation. Ordinary authored `.gd` remains normal GDScript; it must not contain a custom Estragon annotation. The prior `@Bindable`-in-`.gd` direction is superseded by [ADR-0013](DECISIONS.md). [R01 research](BINDABLE_FEASIBILITY.md) is retained as evidence explaining why native Godot 4.7 did not support the old proposal. The original full-system sketches below predate the bounded shipped property/binding stages; use the linked current contracts for executable syntax.

Read the [T09 implementation contract](REACTIVITY_PLAN.md) for accepted goals, staging and tests, and the [live umbrella issue #5](https://github.com/resistdesign/Estragon/issues/5) for work status. Source examples below are **proposed, not executable**.

**ADR-0015 amendment (2026-11-02):** Keep these data/binding requirements, but target retained Node2D/Node3D components with a composed layout core and native lifetime, not an independent RefCounted Box hierarchy. GGX is general-purpose Node composition; ordinary Nodes do not automatically join layout. See [migration gates](NODE_MIGRATION_PLAN.md). Older surface examples below illustrate binding intent, not a new Node entry API. C01 strict release stays BLOCKED.

## Gogo authoring

A model may be a **code-only `.gogo` module**, not just a visual component:

```gdscript
# Player.gogo (proposed)
class_name Player
extends RefCounted

@bindable var name: String = "World"
@bindable var score: int = 0

func add_point() -> void:
    score += 1
```

A UI Gogo module can bind to its own state and to model state:

```gdscript
# Counter.gogo (proposed binding behavior)
extends EstragonSurface

@bindable var count: int = 0

func increment() -> void:
    count += 1

func build_view() -> EstragonVBox:
    return <VBox>
        <Text text={"Count: %d" % count} />
        <Button text="+" pressed={increment} />
    </VBox>
```

T09-B defines explicit self-path dependency expressions. **Unrelated braced expressions are construction-time values**; annotation recognition alone does not make bare `{count}` reactive. The native compiler should emit typed accessors, property-change notifications, a dependency graph and scoped subscriptions; application code should not call `set_root(build_view())` or emit signals manually to make a bindable value refresh.

## Observable data and ArrayCollection-like semantics

- Support bindable properties on **non-Node data classes**, including typechecking, inheritance and suitable `RefCounted`/`Resource` behavior.
- Distinguish **collection reference replacement** (`@bindable var items`) from **mutation of its contents**. A raw `Array.append()` does not automatically become observable merely because the variable containing the Array is bindable.
- Provide an observable **EstragonArrayCollection-like** object publishing changes for addition, insertion, removal, replacement, movement, reset and changes to bindable item objects. Define event payloads, item identity and indexing, and subscription ownership.
- Repeated/list views should reconcile affected children with stable keys, preserve unaffected components and release observers automatically on removal/replacement. Sort/filter/view APIs can be staged but should be considered in event semantics.

## Layout and other dependent properties

Bindings should update **all supported typed component properties**, including text, color, enabled state, width/height, gap/fill flags and eventually position x/y, using correct layout vs paint invalidation. Current components do **not** expose x/y; design their semantics against parent-managed HBox/VBox layout, nested geometry and hit-testing before adding them. No per-frame polling, full-tree rebuild for every property change, duplicated signal hookups, or hand-disposed UI components.

### Future unit-to-pixel helpers (deferred)

The 2D core layout/spacing API accepts **numeric pixels**, not percentages or unit strings. Later, an ordinary helper such as `to_pixels(parent, child, 50, "%", "height")` (conceptual API, not implemented) may compute pixels from parent/child geometry and an explicit reference dimension; the preferred shorter `to_pixels(parent, child, 50, "%")` form requires unambiguous axis context. Standard Gogo property bindings will use the returned pixel number and react to observed geometry changes through the **normal dependency system**, with no special unit-binding subsystem. Optional markup syntactic sugar may be designed afterward; `height="50%"` remains unsupported now. The full owner-approved direction and unresolved measurement/axis/cycle requirements are recorded in [REACTIVITY_PLAN.md](REACTIVITY_PLAN.md#deferred-pixel-conversion-helpers-and-possible-syntactic-sugar-owner-decision-2026-10-30) and [#54](https://github.com/resistdesign/Estragon/issues/54).

## Engineering contracts and explicit boundaries

- Generate deterministic, valid GDScript and source maps from the bundled native Godot-only Gogo compiler. Invalid declarations fail closed in the editor before F5/F6.
- Define property initialization, equality suppression, custom setter composition, nested dependency replacement, null/re-entrant states, batched notification and cycle/feedback behavior with native Godot tests.
- Target Node2D/Node3D visual branches compose shared measure/arrange. Preserve the implemented RefCounted Stack contract until reviewed migration; the older RefCounted Box target is superseded by ADR-0015. Native scene ownership, transform authority, affected-branch invalidation and feedback guards require proof.
- E01 #40 is merged; preserve the accepted E01-F hidden-tab limitation and queued T09 dependencies.

**Do not** revive custom annotations in ordinary `.gd`, silently select `.bgd`, implement regex rewriting or require Bun/Node for user compilation. Use [R01 evidence](BINDABLE_FEASIBILITY.md) to explain the old parser limitation, not as a blocker to the accepted Gogo-only path.
