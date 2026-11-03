# Estragon vision

**Estragon provides Flex-inspired, layout-first 2D UI components and extends the same approach to 3D, using Godot's native scene and rendering systems.** This is accepted future direction under [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon), not a claim that the current runtime is migrated.

Gogo is the GDScript-like language in `.gogo`. GGX is its embedded XML-like general-purpose Node composition syntax, borrowing TSX authoring ergonomics without React's render loop or virtual DOM. It compiles to ordinary typed GDScript through the bundled Godot-only compiler. GGX supports ordinary/custom Nodes as well as Estragon components, with inherited Node.add_child as the sole child rule, native typed properties and named-handler/Callable native signals. Referenced non-Node Objects can be values/signal sources, never hierarchy children.

## Responsibilities

Estragon's UI suite replaces Godot Control UI for its intended uses, providing its own Flex-style measurement, layout, sizing, positioning and reactive composition. Visual 2D components derive from Node2D and 3D participants from Node3D, sharing a mathematical layout core through composition. Godot retains SceneTree identity/lifetime, transforms, physics, rendering and platform/window services. Actual drawing/presentation belongs to the respective native visual components.

Explicit spatial entries establish layout boundaries. Ordinary Nodes remain native and do not automatically participate; another entry re-enters Estragon beneath them. Native2D/Native3D adapters can expose explicit or suitably measured bounds and authority. Specify coordinates, owner persistence and feedback guards deliberately.

Retain Node identity. Use event-driven affected-branch measure/arrange, cached bounds and coalesced updates, not full-tree rebuilding or compulsory polling. Theme, model and collection changes should flow through observable data. Lowercase Gogo-only `@bindable`, typed non-Node models and observable collections remain planned requirements. 2D uses pixels; 3D units, axes, wrapping and overflow need focused specifications.

## Quality and delivery

Current code uses RefCounted components and a RenderingServer surface; native compiler/editor, minimal stack layout, text/buttons and primary pointer input are implemented. Node-native GGX, 3D layout, adapters, bindings and repeaters are not. [The migration plan](NODE_MIGRATION_PLAN.md) proves native composition, layout and adapters before broader migration, preserving working examples and honest compatibility evidence.

Text shaping, font fallback, localization/RTL, clipping, advanced layout, high-DPI scaling, focus/keyboard/IME, touch/scroll, accessibility and richer widgets still need scoped implementation and evidence. Completion/navigation, live preview and debugger remapping remain future work. Do not claim performance, platform coverage or release readiness before testing; C01 strict release remains BLOCKED.

The Godot 4.0+ target, only 4.0.4/4.7.0 live verification, native product compilation, TypeScript/Yarn future tooling, no Python, one reviewed PR at a time and durable handoffs remain guardrails. See [design direction](DESIGN_DIRECTION.md), [architecture](ARCHITECTURE.md) and [work status](WORK_STATUS.md).
