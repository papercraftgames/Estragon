**F03 implementation:** [Child sequences and keyed lists](F03_LISTS.md) / [#96](https://github.com/resistdesign/Estragon/issues/96) extends merged F01/F02 with native for/map descriptions, nested Array flattening and sibling-scoped retained keys. Live issue/sole PR records verification and review; F04 cutover and F05/F06 remain future. Earlier stage-specific restrictions below describe their original boundaries.

**F02 implementation checkpoint:** [Conditional child/nested composition contract](F02_CONDITIONALS.md) / [#94](https://github.com/resistdesign/Estragon/issues/94) extends the merged F01 engine with stable nullable slots, branch replacement and parent-first nested ownership. Exact verification/review state is in the live issue/sole PR; F03 lists/keys and F04 cutover remain future work. Earlier F01-only shape restrictions below are historical.

**F01 implementation checkpoint:** [Native composition spike](F01_COMPOSITION.md) / [#92](https://github.com/resistdesign/Estragon/issues/92) supplies the bounded getter-read → description → retained static-shape path for review. Full ADR-0016/F02–F06 behavior is not claimed; exact verification and review state are in the live issue/sole PR.

# Estragon architecture: shipped native core and accepted next generation

**The canonical product design is [ADR-0016](REACTIVE_COMPOSITION_ARCHITECTURE.md): signal-driven React-like function recomposition, Flex-like Gogo bindable properties, a small honest Virtual DOM and native Godot Node reconciliation.** ADR-0016 is *approved for future implementation*; its source syntax/runtime are not shipped simply because this document exists. [T09 implementation plan](REACTIVITY_PLAN.md), [decisions](DECISIONS.md), [issue #89](https://github.com/resistdesign/Estragon/issues/89).

## Production today (through merged T09-B / PR #87)

Estragon is a **Godot addon**. Godot owns SceneTree lifetime, Node2D/Node3D transforms, rendering, physics and platform/window events. Estragon provides native UI widgets, composed 2D/3D layout, Gogo/GGX compilation and editor integration.

- **Compiler:** native GDScript lexes/parses Gogo and GGX, validates against Godot types and explicit script imports without constructing authored Nodes during compilation, and emits deterministic GDScript with original-source range maps. Godot supplies final native semantic/type validation. The editor saves active source, builds, validates actual paths, and transactionally publishes/reverts code/maps/UIDs/cache state before main/current Play.
- **UI:** EstragonRect/Text/Button/HBox/VBox derive from Node2D. Ordinary GGX children are Godot Nodes. Explicit Estragon2D/3D entry scopes and adapters share one mathematical layout core, with event-driven affected-branch measure/arrange and native rendering/input. Plain Node boundaries interrupt Estragon layout unless another entry reopens it.
- **Signals/models:** T09-A compiles typed per-property Gogo-only `@bindable` into native setter/storage and `<name>_changed` signals, including RefCounted *data* models. T09-B compiles bounded explicit self-path GGX property bindings, with target-owned helper Nodes, weak native source subscriptions and deferred/coalesced property updates. The native Counter no longer calls `refresh`.
- **Distribution:** native compiler/editor works with Godot alone. Linux release/development proofs cover only official 4.0.4 and pinned 4.7.0, with real saved/unsaved editor Play, graphics, clean imports, source-only cold restore and addon export/runtime. Current strict addon evidence applies to the code actually shipped, not future ADR-0016 capabilities.

**Not currently shipped:** rerunnable declarative GGX view functions, virtual element descriptions/reconciliation, conditional child expressions, keyed iteration, class-level bindable annotation, two-way binding or generic observable collection mutation.

## ADR-0016 target

Gogo source remains a **readable function describing the desired child tree**. A change to a generated bindable value emits its native signal and automatically schedules only affected component functions. The function computes *lightweight virtual element descriptions*, not actual newly constructed Nodes. The framework reconciles desired vs previous declared elements, preserving compatible **real Godot Node** identity/type/key/position and native state while applying only necessary prop, signal and child changes. No per-frame GGX rerender.

This **is a Virtual DOM** (a small descriptor/reconciliation layer); it is not a second Godot scene or a requirement that game data be immutable. All keys, previous declaration snapshots and subscription/reconciliation records are stored by the runtime manager, **never injected onto user Nodes, models or Resources**. No `set_meta`, virtual-fiber field on Nodes or binder helper Node on every property.

**Dynamic observation:** compiled bindable getters collect actual reads during the affected composition function; native signals schedule rerender and update the subscriber set, including nested paths and conditionals. The first implementation phase must prove this on both approved Godot versions, then provide a small native fallback if their GDScript behavior genuinely requires it. A model can also be a normal non-Node RefCounted/Resource. Native properties/arrays/dictionaries without generated observable signals do not automatically notify.

**Deep hierarchy:** nested component scope records let parents cancel queued work and subscriptions when replacing/removing branches. Evented, coalesced and SceneTree-safe commit; preserve unrelated game Nodes, Godot scene owner and layout authority. Only declared GGX-managed children belong to the reconciler.

**Lists:** ordinary GDScript loops or `Array.map` produce descriptions. Optional sibling-scoped keys preserve native item identity on insert/reorder. A bindable array *reference* update schedules composition; in-place native Array/Dictionary writes are not observable without an opt-in collection adapter. No required special Repeater or separate list diff.

**Two-way:** later typed input event adapters synchronize from UI back to bindable models with feedback guards. Class-level Gogo-only `@bindable` is separately tracked by [#90](https://github.com/resistdesign/Estragon/issues/90). Plain JSON/dictionaries remain valid transport; convert to observable models only when needed, not universally.

## Cutover without compatibility baggage

Estragon is unreleased. Once ADR-0016 behavior is proved, **remove** superseded eager GGX factory generation, the T09-B per-property helper-Node subscription path, obsolete output/fixtures/tests and old docs that assume a permanently static tree. Preserve actual native Node/layout/compiler/editor capabilities, not their previous implementation strategy or a dual API. Changes are serial reviewed PRs: [F01–F06](REACTIVE_COMPOSITION_ARCHITECTURE.md#11-delivery-plan-and-migration-gates). Do not auto-merge, run a larger OS/engine matrix, introduce Python, or require external compilation for Gogo users.

**Historical decisions:** ADR-0015 replaced the old RefCounted display/surface and custom child-adder architecture. ADR-0016 supersedes ADR-0015's *no Virtual DOM* rule while preserving the native Node/Node2D/Node3D lifecycle and shared layout invariants. The old RefCounted UI will not be reintroduced; ordinary RefCounted *models* remain supported.
