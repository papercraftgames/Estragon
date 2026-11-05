# Estragon

A layout-first **Godot addon** with native Node2D UI, bounded 2D/3D layout and **Gogo**: a GDScript-like language with embedded **GGX** Node composition.

Open `project.godot` in Godot, enable Estragon, and run the [Gogo Counter](examples/counter/Counter.gogo): click **+** / **Reset** and resize. Open `examples/ggx/TwoD.tscn` or `ThreeD.tscn` for dimensional demos, or `examples/reactive/Demo.tscn` for model-driven text, style and layout. Godot plus the bundled addon is enough for end-user authoring and Play; no external compiler.

Canonical native widgets are `EstragonRect`, `EstragonText`, `EstragonButton`, `EstragonHBox` and `EstragonVBox`. They derive from Node2D and share a composed core with 3D participants. Godot retains native SceneTree lifetime, transforms, rendering, physics and input.

## The next architecture: React-like composition × Flex-like binding

**[ADR-0016 — Reactive Composition Architecture](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md)** is the accepted *future* design: ordinary Gogo functions describe desired GGX; normal `@bindable` state assignments automatically signal affected components to recompose, **without React hooks or manual invalidation**. A **real, lightweight Virtual DOM** reconciles desired descriptions with existing real Godot Nodes, preserving unchanged identities, game state and animations. No per-frame component rerender, no forced immutable state, and **no reconciliation metadata attached to game Nodes, Resources or model objects**.

That next-generation composition engine is **not shipped yet**. The current merged code includes:
- **T09-A [PR #85](https://github.com/resistdesign/Estragon/pull/85):** typed Gogo-only `@bindable` properties and RefCounted data-model signals.
- **T09-B [PR #87](https://github.com/resistdesign/Estragon/pull/87):** automatic updates to existing GGX component properties/layout, including a refresh-free Counter.

Dynamic conditional children, mapped keyed lists, automatic function recomposition, class-level `@bindable`, and two-way bindings are planned in [the implementation roadmap](docs/REACTIVITY_PLAN.md) and [design issue #89](https://github.com/resistdesign/Estragon/issues/89). Class-level `@bindable` is separately tracked in [#90](https://github.com/resistdesign/Estragon/issues/90). Estragon has **not released**; obsolete internal APIs and implementations will be replaced and removed, not kept indefinitely for compatibility.

## Documentation

- [Complete future composition and binding design](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md), [ADRs](docs/DECISIONS.md)
- [Current architecture](docs/ARCHITECTURE.md), [runtime/adapters](docs/NODE_RUNTIME.md), [UI API](docs/NODE_UI.md)
- [Gogo/GGX source language](docs/GOGO_LANGUAGE.md), [editor](docs/EDITOR.md), [current binding behavior](docs/REACTIVE_GGX.md)
- [Work status](docs/WORK_STATUS.md), [execution plan](docs/EXECUTION_PLAN.md), [contributing](CONTRIBUTING.md), [testing/release evidence](docs/TESTING.md)

**Godot 4.0+ is the target; verification currently covers only official 4.0.4 and pinned 4.7.0 on Linux CI.** No untested minor/platform support is implied. The addon is not a standalone application.

[F01 native composition spike](docs/F01_COMPOSITION.md) runs `examples/composition/Counter.tscn`: Gogo bindable getter reads schedule function reruns, lightweight descriptions reconcile with retained real Nodes, without hooks or per-target binder Nodes. Static shape only; F02–F04 dynamic composition/cutover remain future work. Live #92/PR records exact review and engine evidence.
