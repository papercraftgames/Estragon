# Estragon

A layout-first **Godot addon** with native Node2D UI, bounded 2D/3D layout and **Gogo**: a GDScript-like language with embedded **GGX** Node composition.

Open `project.godot` in Godot, enable Estragon, and run the [Gogo Counter](examples/counter/Counter.gogo): click **+** / **Reset** and resize. Open `examples/ggx/TwoD.tscn` or `ThreeD.tscn` for dimensional demos, or `examples/reactive/Demo.tscn` for model-driven text, style and layout. Godot plus the bundled addon is enough for end-user authoring and Play; no external compiler.

Canonical native widgets are `EstragonRect`, `EstragonText`, `EstragonButton`, `EstragonHBox` and `EstragonVBox`. They derive from Node2D and share a composed core with 3D participants. Godot retains native SceneTree lifetime, transforms, rendering, physics and input.

## React-like composition with Gogo signals

[ADR-0016](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md) uses ordinary Gogo functions and typed `@bindable` state: signals rerun affected functions, descriptions reconcile retained real native Nodes. No hooks, manual refresh, per-frame rerender or bookkeeping on application Nodes/models/Resources.

F01–F03 merged dynamic getter observation, conditional/nested ownership and mapped keyed lists. [F04 #98](https://github.com/resistdesign/Estragon/issues/98) cuts all GGX over to one description compiler/runtime and removes eager factories and target-owned binding helpers; [contract/removal/parity report](docs/F04_CUTOVER.md). All active Counter/2D/3D/model/conditional/inventory scenes use this path. Review/verification state lives in the issue and sole PR.

Every GGX expression returns an Element, including ordinary helpers/lambdas. Typed `build_view() -> Element` is the automatic host entry. Run `examples/conditional/Counter.tscn` for branches/nested scopes, or `examples/inventory/Inventory.tscn` for retained keyed rows and for/map lists. Raw collection mutations do not notify; bindable Array reference replacement does.

F05 class-level `@bindable` ([#90](https://github.com/resistdesign/Estragon/issues/90))/two-way inputs and F06 measured optimization remain future. Estragon is unreleased; replaced implementations are removed, not maintained as a second API.

## Documentation

- [Composition and future binding design](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md), [ADRs](docs/DECISIONS.md)
- [Current architecture](docs/ARCHITECTURE.md), [runtime/adapters](docs/NODE_RUNTIME.md), [UI API](docs/NODE_UI.md)
- [Gogo/GGX source language](docs/GOGO_LANGUAGE.md), [editor](docs/EDITOR.md), [current binding behavior](docs/REACTIVE_GGX.md)
- [Work status](docs/WORK_STATUS.md), [execution plan](docs/EXECUTION_PLAN.md), [contributing](CONTRIBUTING.md), [testing/release evidence](docs/TESTING.md)

**Godot 4.0+ is the target; verification currently covers only official 4.0.4 and pinned 4.7.0 on Linux CI.** No untested minor/platform support is implied. The addon is not a standalone application.
