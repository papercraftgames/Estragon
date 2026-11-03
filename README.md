# Estragon

**A Flex-inspired, layout-first 2D/3D component framework for Godot.**

*No more waiting for Godot. Gogo!*

**Accepted target, not implemented:** [ADR-0015](docs/DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) defines **Gogo** as the GDScript-like language in `.gogo` and **GGX** as its embedded XML-like general-purpose Node composition syntax. GGX uses inherited Node.add_child as the sole child rule, native typed properties and named-handler/Callable signals. Estragon's intended UI suite replaces Godot Control UI for its uses, with Node2D/Node3D visual branches composing shared measure/arrange. Godot retains SceneTree, lifetime, transforms, physics and rendering. Explicit entries/native adapters define layout participation; ordinary Nodes are not automatically laid out.

**Today:** the runtime still uses RefCounted components, a private child list and a RenderingServer surface. The bundled native Gogo compiler/editor, minimal stack layout, text/buttons and generated pressed connections work; Node-native GGX, 3D layout, native layout adapters and reactivity remain planned. Preserve current examples and evidence during [staged proof/migration](docs/NODE_MIGRATION_PLAN.md). Strict C01 release certification remains **BLOCKED**; Godot 4.0+ is the target, not a newly verified claim.

Lowercase `@bindable` in Gogo only, including code-only non-Node models, is accepted but not implemented. Native Gogo editing/build/Play needs only Godot and the addon; no external compiler. See [design direction](docs/DESIGN_DIRECTION.md) and the [supported language subset](docs/GOGO_LANGUAGE.md).

## Godot-only authoring

Copy `addons/estragon` into Godot 4.7 and enable **Estragon (experimental)**.
Open/edit Gogo in the native Script Editor, then press Play. The bundled native
compiler builds saved or modified buffers and blocks stale execution on errors.
No Bun, Node, TypeScript, executable configuration or manual compiler command
is needed. Fresh projects need no compiler config file; explicit source-root
configuration remains supported. See [editor setup](docs/EDITOR.md).

N01–N03 implement the native compiler/editor migration under
[ADR-0012](docs/DECISIONS.md). Bun/TypeScript remains optional contributor/CI
reference tooling. Bindings and legacy retirement remain separate work.

## Status: experimental vertical slices

T04 compiles a minimal namespace-free `VBox`/`HBox`/`Rect` markup subset to ordinary
GDScript constructing Estragon's independent components. The runtime supports
nested auto/fixed/fill stack layout, rectangle drawing and automatic lifecycle
through a single surface host. T05 adds GDScript-first hybrid modules with helper methods, nested markup,
braced construction-time expressions and range source maps. T06 adds text drawing, buttons and primary-mouse input through ordinary GDScript.
T07 adds Text/Button markup, generated pressed connections and an interactive Counter.gogo.
T08 adds optional native Gogo highlighting and automatic compilation before Play.
Bindings and broader editor services remain future work. See the [supported subset](docs/GOGO_LANGUAGE.md).

The earlier namespaced XML → JSON rectangle demo is preserved separately and
remains the configured main scene. It is temporary compatibility scaffolding,
not the new compiler's runtime format.

`RenderingServer` is the current low-level adapter. ADR-0015 delegates native rendering to the respective components; a competing renderer is not a migration requirement.

## Try the Gogo-to-GDScript slice

Requires Godot 4.7 and the enabled Estragon plugin.

Open `examples/compiled/Compiled.tscn` in Godot and run that scene. Edit `.gogo`
and press Play; do not edit generated `.gd`. The optional editor plugin compiles on save and before Play; see EDITOR for setup.
Generated code mounts components on an EstragonSurface; cleanup is automatic.

## Try hybrid GDScript/Gogo

Run `examples/mixed/Mixed.tscn`. The authored source contains typed GDScript
members, ordinary helper/build methods, nested markup and computed properties.
It mounts explicitly with `set_root(build_view())`; rebuild is explicit and
cleanup automatic. Generated `.gd.map.json` supports source tracing. This is
construction-time composition, not reactive binding; Godot checks GDScript types.

## Try interactive components

Run `examples/interactive/Interactive.tscn` in Godot 4.7. Add one and Reset update
visible text through ordinary GDScript handlers. Hover/hold for visual states,
release outside to cancel, and resize to see the button row follow the viewport.
No component Nodes, Godot Controls or manual component disposal are required.
For compiler-generated connections, run the Gogo Counter below. See the
[interactive test procedure](docs/TESTING.md#interactive-components-visual-check-t06).

## Try interactive Gogo

Run `examples/counter/Counter.tscn`. Click `+` to increment and Reset to return
to zero. The authored `.gogo` contains GDScript state/handlers and Text/Button
markup with `pressed={increment}`; Gogo generates all signal connections. Explicit
root rebuilding refreshes text/disabled state and automatically disconnects old
handlers. The optional plugin builds natively on save and Play; no bindings are implied. See the
[signal contract](docs/GOGO_LANGUAGE.md#t07-generated-signals-and-interactive-gogo-implemented).

## Try the initial slice

Requires **Bun 1.4.4** for compiling/testing and a compatible **Godot 4.x** editor/runtime to run the demo.

```sh
bun install --frozen-lockfile
bun run gogo examples/hello/Main.gogo --output examples/hello/generated/Main.gogo.json
bun run check
```

Open this directory as a Godot project (`project.godot`) and run the main scene. `examples/hello/Hello.tscn` contains **one host `Node`**, which reads the checked-in generated IR and draws rectangles directly using `RenderingServer.canvas_item_add_rect()`. The checked-in output lets the scene run without requiring Bun in the Godot process or at application runtime.

Enable **Estragon (experimental)** in Godot's Plugins settings for normal Gogo
authoring: mixed syntax highlighting, automatic saved-source builds and checked
compilation before F5/F6. No external tools or compiler commands are
required during normal development. The plugin preserves existing editor
extension settings. See [editor setup and verified limits](docs/EDITOR.md).

## Read the design

- [Codex execution plan (sequenced PRs and acceptance gates)](docs/EXECUTION_PLAN.md)
- [Work status and cross-session handoffs](docs/WORK_STATUS.md)
- [Gogo-to-GDScript design direction](docs/DESIGN_DIRECTION.md)
- [Vision and non-goals](docs/VISION.md)
- [System architecture and rendering backends](docs/ARCHITECTURE.md)
- [Gogo markup language](docs/GOGO_LANGUAGE.md)
- [Bindable properties and reactivity](docs/BINDING.md)
- [Godot editor integration](docs/EDITOR.md)
- [Project roadmap](docs/ROADMAP.md)
- [Architecture decisions and open questions](docs/DECISIONS.md)
- [Contributing](CONTRIBUTING.md)

## Picking up development with Codex

**One open PR total, one scoped task at a time.** Read [work status](docs/WORK_STATUS.md), `AGENTS.md`, the execution plan and the selected issue's latest handoff. ADR-0015-A [#69](https://github.com/resistdesign/Estragon/issues/69) formalizes architecture [#68](https://github.com/resistdesign/Estragon/issues/68); successors stay queued until owner review/merge. Never auto-merge or implement the whole roadmap in one PR.

## Naming

- **Estragon:** the overall framework and runtime
- **Gogo:** the GDScript-like language and compiler; files end in `.gogo`
- **GGX:** embedded XML-like Node composition syntax within Gogo
- **Godot:** native scene, rendering, transform, physics and platform services

This project is at the prototype stage; all syntax not explicitly described as supported is a **proposal**, not a working feature. Estragon is released under the [MIT License](LICENSE). See [Assets](Assets/) for the original logo files.
