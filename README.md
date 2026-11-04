# Estragon

A layout-first Godot addon with native Node2D UI, bounded 2D/3D layout and Gogo: GDScript-like source with embedded GGX Node composition.

Open project.godot in Godot, enable the Estragon editor plugin, and run. The default scene is the native [Gogo Counter](examples/counter/Counter.gogo): click + / Reset and resize. Open examples/ggx/TwoD.tscn or ThreeD.tscn for source-authored dimensional demos. Godot and the bundled addon are all users need; no external compiler setup.

Canonical widgets: EstragonRect, EstragonText, EstragonButton, EstragonHBox and EstragonVBox. They derive from Node2D, share a composed layout core with the bounded 3D runtime and use inherited Node.add_child, native signals/lifetime and native drawing. The former RefCounted/RenderingServer UI and stage-0 JSON compiler/interpreter are retired.

- [UI API and demo](docs/NODE_UI.md), [runtime/adapters](docs/NODE_RUNTIME.md)
- [Gogo/GGX language](docs/GOGO_LANGUAGE.md), [editor workflow](docs/EDITOR.md)
- [Contributing](CONTRIBUTING.md), [testing/release evidence](docs/TESTING.md)
- [Architecture](docs/ARCHITECTURE.md), [decisions](docs/DECISIONS.md), [work status](docs/WORK_STATUS.md)

Godot 4.0+ remains the target. Routine verification uses official 4.0.4 and pinned 4.7.0 on Linux only; no untested minor/platform certification is implied. [Observable Gogo properties/non-Node models](docs/BINDABLE_PROPERTIES.md) are implemented in T09-A; run `examples/bindable/Demo.tscn` for the data demo. Automatic reactive GGX/layout is still future work. Broader widgets, focus/accessibility, bindings/repeaters and 3D wrapping remain future work. This is a Godot addon, not a standalone application distribution.
