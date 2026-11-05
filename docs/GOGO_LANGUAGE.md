**F03 implementation:** [Child sequences and keyed lists](F03_LISTS.md) / [#96](https://github.com/resistdesign/Estragon/issues/96) extends merged F01/F02 with native for/map descriptions, nested Array flattening and sibling-scoped retained keys. Live issue/sole PR records verification and review; F04 cutover and F05/F06 remain future. Earlier stage-specific restrictions below describe their original boundaries.

**F02 implementation checkpoint:** [Conditional child/nested composition contract](F02_CONDITIONALS.md) / [#94](https://github.com/resistdesign/Estragon/issues/94) extends the merged F01 engine with stable nullable slots, branch replacement and parent-first nested ownership. Exact verification/review state is in the live issue/sole PR; F03 lists/keys and F04 cutover remain future work. Earlier F01-only shape restrictions below are historical.

**F01 implementation checkpoint:** [Native composition spike](F01_COMPOSITION.md) / [#92](https://github.com/resistdesign/Estragon/issues/92) supplies the bounded getter-read → description → retained static-shape path for review. Full ADR-0016/F02–F06 behavior is not claimed; exact verification and review state are in the live issue/sole PR.

# Gogo and GGX — shipped language and approved direction

Gogo is a GDScript-like language authored in `.gogo`; GGX is its namespace-free XML-like syntax for declaring native Godot Nodes. The bundled **Godot-native** compiler/editor generates ordinary typed GDScript and source maps; no Bun/Node/GDExtension/standalone compiler is needed to edit or Play.

**Important distinction:** what main supports today is documented below. The next-generation **[ADR-0016 reactive function composition](REACTIVE_COMPOSITION_ARCHITECTURE.md)** is accepted but *not yet implemented*. In that model GGX in a composition function produces virtual element descriptions, and generated bindable signals cause automatic function reruns with native Node-preserving reconciliation.

## Current syntax (merged C4, T09-A and T09-B)

- Declare a GDScript-like class with ordinary `extends`, typed vars, functions, constants and explicit `preload` aliases. GGX tags resolve to constructible native Godot `Node` types (built-in, registered script class or explicit script alias). Non-Node data/models may be attribute values, not hierarchy elements.
- Use `<EstragonVBox> ... </EstragonVBox>`, `<EstragonText text="..." />` and other resolved native Node tags in Gogo expressions. The existing compiler builds actual Nodes once by factories and attaches with inherited void `Node.add_child`; it does **not yet** produce virtual elements or support arbitrary expression children.
- Attributes use typed native Godot property/signal metadata. String/`StringName` use quoted literals, typed expressions use braces (`width={100.0}`). Events use ordinary named handler/`Callable` values. Unknown, duplicate or read-only attributes, wrong child types and invalid signals fail with diagnostics and source maps. Arbitrary inline anonymous handler declarations are unsupported.
- `@bindable var count: int = 0` is supported on explicitly typed instance properties in **authored Gogo only**; it generates typed native setters and `count_changed(previous, value)`. Code-only non-Node Gogo models are supported; native `.gd` cannot use a custom `@bindable` annotation. [Property contract](BINDABLE_PROPERTIES.md).
- Braced property expressions with a bounded explicit `self.<bindable>` path are **already reactive in T09-B**. Other expressions run once during construction. The current helper Node/signal implementation is [documented separately](REACTIVE_GGX.md). Existing Counter updates without manual `refresh()`.
- Current GGX supports explicit native `position` and the Node2D/Node3D entry/layout boundaries. Reactive transform/`x`/`y` authority is not decided; [#88](https://github.com/resistdesign/Estragon/issues/88) tracks it.

## Future ADR-0016 authoring contract (not currently valid Gogo)

- A normal Gogo function (`build_view` initially) returns **declarative desired tree descriptions**. It reruns **on relevant bindable signal changes**, not every frame, and authors never manually invalidate state.
- Its GGX children may include a native GDScript-style conditional expression, an array/list of element descriptions, and elements built in an ordinary loop or `Array.map`. A reserved optional sibling-scoped `key` enables retaining item Node identity on reorder; it is **not** a Node property or external metadata.
- A Gogo composition function is a repeatable description computation. Normal Godot lifecycle/event methods handle side effects. Generated bindable getter reads, including nested models and conditional paths, automatically determine which component is subscribed.
- Existing native Godot Nodes are preserved through reconciliation by type/position/key. Actual `Node.add_child`, `remove_child` and `move_child` remain the only hierarchy operations. Descriptors/identity records are kept **outside** Godot Nodes.
- A class-level Gogo-only `@bindable` annotation will eventually instrument eligible typed instance fields ([issue #90](https://github.com/resistdesign/Estragon/issues/90)). Optional observable collection mutation and two-way input bindings are staged later. No required `Repeater`, RemoteObject/AMF, React hook API, compiler pragma or immutable data hierarchy.
- The final language and generated output are deliberately allowed to **break pre-release GGX API compatibility** when transitioning to the single new pipeline. Compiler/runtime/editor examples and tests must cut over together, then obsolete factories and per-target binding helpers must be removed.

## Verification

Compile and Play using the normal native Godot editor. Current checks cover only official **Godot 4.0.4 and pinned 4.7.0 on Linux CI**; do not infer untested engine/platform certification. Compilation must preserve actual-path semantic validation and editor saved/unsaved Play rollback/recovery, source maps, generated script UIDs and Godot-native signal/lifecycle semantics. See [testing](TESTING.md), [architecture](ARCHITECTURE.md), [reactivity plan](REACTIVITY_PLAN.md), and current issue/PR for implementation evidence.
