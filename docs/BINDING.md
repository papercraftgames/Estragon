# Gogo data binding and automatic recomposition

**Canonical target:** [ADR-0016 Reactive Composition Architecture](REACTIVE_COMPOSITION_ARCHITECTURE.md). **Plan:** [REACTIVITY_PLAN](REACTIVITY_PLAN.md), [design task #89](https://github.com/resistdesign/Estragon/issues/89), [umbrella #5](https://github.com/resistdesign/Estragon/issues/5).

## User-facing model

**There is no `setState`, `useEffect`, manual `refresh()` or state invalidation hook.** A Gogo component is a normal Node with typed fields, ordinary methods and a `build_view` function that describes its desired children in GGX. A model may be a non-Node `RefCounted`/`Resource`. Gogo-generated `@bindable` getters/setters and native signals automate tracking and updates; component composition functions are rerun as needed and reconciled against existing Godot Nodes.

```gdscript
# Current shipped state declaration
@bindable var count: int = 0

func increment() -> void:
    count += 1  # Generated count_changed signal

# Proposed ADR-0016 view function, not yet runnable:
func build_view():
    return <EstragonVBox>
        <EstragonText text={"Count: %d" % self.count} />
        {<EstragonButton text="Reset" /> if self.count > 0 else null}
    </EstragonVBox>
```

### What is shipped today

**T09-A / PR #85:** per-property lowercase `@bindable` in authored `.gogo` only; generated typed properties and `<name>_changed(previous, value)` signals. Works for code-only non-Node data models. Initialization is quiet, normal assignment and `+=` notify, and `is_same` defines the current value/reference equality policy. See [BINDABLE_PROPERTIES](BINDABLE_PROPERTIES.md).

**T09-B / PR #87:** explicit supported `self.<bindable>` GGX **property** expressions subscribe to typed signals and update existing native Nodes and layout without manual refresh. Its current static-path and target-owned helper-Node implementation is transitional; no expression child/structural view rerender exists yet. See [REACTIVE_GGX](REACTIVE_GGX.md).

### What ADR-0016 adds

**Composition:** when a Gogo-generated getter is read during a component view execution, a framework-owned computation context records the source property and subscribes to its change signal. Only relevant component functions rerun; their GGX compiles to *virtual element descriptions*, not new native Nodes. A minimal reconciler updates declared props/handlers and changes actual native children only when necessary. Key/identity records exist **outside** Godot Nodes; no metadata or binder Nodes are injected into components. A frame being drawn does not rerun a view function.

**Nested paths:** `self.model.player.name` observes all Gogo-bindable segments *actually read* during the view execution. Replacing the player/model or changing conditional branches automatically refreshes the dependency set after rerender. Non-bindable external fields cannot generate notifications on their own; users may use a real external signal adapter where necessary. A plain Dictionary/Array write is not automatically observable.

**Class-level bindability (planned, [#90](https://github.com/resistdesign/Estragon/issues/90)):** allow a lowercase Gogo-only `@bindable` class annotation to instrument all eligible typed instance properties without listing each one. Use the **same** generated signals and getter tracking as per-property annotations. Do not introduce a new observable object hierarchy, custom Godot `.gd` annotations, or automatic proxy wrappers. The class-level syntax, inheritance and accessor restrictions are settled during its focused implementation.

**Lists:** normal GDScript for/`Array.map` can compose arrays of desired element descriptions. A `key` helps preserve actual native child state on reorder. Replacing an `@bindable` array reference rerenders the owning view; in-place `append/remove` requires an observable collection adapter if that notification behavior is wanted. No mandatory Repeater or separate list reconciliation engine.

## Two-way binding: planned T09-D

A future assignable GGX attribute (illustratively `bind:value={self.player.name}`) can express:
1. **Model → View:** view declarative value follows the bindable model property.
2. **View → Model:** a validated native input change signal assigns back through the ordinary model setter.
3. **Feedback guards:** equal-value suppression and explicit event-origin/lifecycle management prevent ping-pong, suppress edits from removed views and safely rewire nullable/replaced models.

The model remains the source of truth; do not create a second state store on the UI or use React hooks. The exact input component, event mapping and attribute grammar are *not implemented or finalized*. Native Godot event handlers remain normal named `Callable` connections.

## Model sources, persistence and limits

- A raw JSON object or Godot `Dictionary`/`Array` may be stored/serialized normally, without becoming automatically observable. Convert only portions needing in-place observation to typed bindable models or an explicit collection adapter; optionally use conventional `to_dict/from_dict` and `Resource` serialization.
- `Resource.changed` is not emitted automatically for custom script fields in Godot; actual generated setters or a manual external signal adapter remain necessary.
- Do not require a RemoteObject/AMF protocol, universal observable graph/proxies, mandatory hydration of all nested values, or serialization per render.
- No per-frame data scanning, global virtual DOM diff, full-scene reconstruction or forced immutable physics/game model.
- Render descriptions should be repeatable. Keep mutating game state, network actions, spawning and native scene edits in normal lifecycle/event code, not inside rerunnable `build_view`.
- Visible UI changes may be deferred/coalesced, while data setters and their signals remain synchronous. Native layout/physics safety and parent-first nested cancellation are required.

**Implementation gating:** [F01–F06 migration and acceptance](REACTIVE_COMPOSITION_ARCHITECTURE.md#11-delivery-plan-and-migration-gates). Existing exact T09-A/T09-B code/tests remain real until the single-runtime migration replaces their old implementation; the target is not claimed shipped by its presence in a document. No pre-release backwards compatibility or dual runtime is required.
