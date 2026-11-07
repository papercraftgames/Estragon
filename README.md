# Estragon

A layout-first **Godot addon** with native Node2D UI, bounded Node3D layout/adapters and **Gogo**: a GDScript-like language with embedded **GGX** Node composition. Canonical repository: [papercraftgames/Estragon](https://github.com/papercraftgames/Estragon).

Godot plus the bundled addon is enough for authoring and Play; there is no external compiler. In this checkout, open `project.godot`, enable Estragon at `addons/estragon/editor/plugin.cfg`, and run the [Gogo Counter](examples/counter/Counter.gogo). Click **+** / **Reset** and resize. The [live example inventory](docs/PACKAGING.md#retained-live-scene-inventory) lists all supported demos and their verification paths.

## Install in another Godot project

Estragon's public beta is available on [npm](https://www.npmjs.com/package/@papercraftgames/estragon). Install the current beta with `yarn add --exact --ignore-scripts @papercraftgames/estragon@beta`, keep the addon in `node_modules`, and enable its full `plugin.cfg` path in `editor_plugins/enabled`. P02 direct installation is pending an owner-published release; an earlier published beta may not contain this fix. Yarn alone does not register the plugin. The **only committed package release version** is the one in `addons/estragon/editor/plugin.cfg`; npm packaging generates its manifest version from that source. Root `estragon-tooling` remains private contributor tooling. See the [install/release contract](docs/PACKAGING.md), [package README](packages/estragon/README.md) and [P01 tracking #104](https://github.com/papercraftgames/Estragon/issues/104).

## React-like composition with Gogo signals

Merged F01–F06 provide ordinary typed `build_view() -> Element` functions, signal-driven getter observation, descriptions reconciled with retained real Nodes, nested conditionals and keyed lists. F04 removed the eager/static binder path; F05 adds class-wide typed Gogo `@bindable` and a bounded native boolean `bind:value`; F06 adds opt-in profiling and measured LIS/preflight improvements. No hooks, manual refresh, per-frame rerender or reconciliation metadata on application objects.

Canonical widgets are `EstragonRect`, `EstragonText`, `EstragonButton`, `EstragonToggle`, `EstragonHBox` and `EstragonVBox`. They derive from Node2D and share a composed layout core with bounded 3D participants. Godot retains SceneTree lifetime, transforms, rendering, physics and input. Raw Array/Dictionary mutations do not notify; bindable reference replacement does.

Try [conditional/nested composition](examples/conditional/Counter.tscn), [keyed inventory](examples/inventory/Inventory.tscn), [class-wide models](examples/bindable/Demo.tscn), [controlled boolean input](examples/twoway/Demo.tscn), [reactive style/layout](examples/reactive/Demo.tscn), or [2D](examples/ggx/TwoD.tscn)/[3D](examples/ggx/ThreeD.tscn). These are bounded working slices; richer inputs/text/IME/focus, themes/accessibility, broader layout/editor UX and release readiness remain separately scoped. Estragon is pre-1.0, not a complete mature widget suite.

## Documentation

- [Current architecture](docs/ARCHITECTURE.md), [ADRs](docs/DECISIONS.md), [composition design](docs/REACTIVE_COMPOSITION_ARCHITECTURE.md)
- [Gogo/GGX language](docs/GOGO_LANGUAGE.md), [editor](docs/EDITOR.md), [native UI](docs/NODE_UI.md), [runtime/adapters](docs/NODE_RUNTIME.md)
- [Bindable models](docs/BINDABLE_PROPERTIES.md), [two-way bool contract](docs/TWO_WAY_BINDINGS.md), [F06 measurements](docs/F06_PROFILING.md)
- [Packaging/release preparation](docs/PACKAGING.md), [work status](docs/WORK_STATUS.md), [execution plan](docs/EXECUTION_PLAN.md), [contributing](CONTRIBUTING.md), [testing/evidence](docs/TESTING.md)

**Godot 4.0+ is the target; fresh proof covers only official 4.0.4 and pinned 4.7.0 on Linux.** No untested minor/platform certification or standalone application export requirement. The MIT license and original attribution are retained; repository transfer does not change historical copyright.
