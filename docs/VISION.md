# Direction and implementation

Estragon provides Flex-inspired, layout-first native Godot UI in 2D and extends the same model to 3D. Gogo is the GDScript-like authoring language; GGX composes ordinary/custom Nodes and Estragon components. Godot supplies rendering, transforms and native services. Estragon is neither a competing renderer nor a virtual DOM.

The shipped bounded slice includes canonical native Rect/Text/Button/HBox/VBox, retained Counter, explicit 2D/3D entries/participants/adapters, a shared mathematical core and bundled Godot-only compiler/editor. C4 removes the obsolete parallel UI. See [architecture](ARCHITECTURE.md), [API](NODE_UI.md) and [actual status](WORK_STATUS.md).

Broader Flex-style layout, style/theme systems, focus/accessibility, keyboard/touch, Gogo-only bindable properties, retained keyed collections/repeaters and 3D wrapping are future scoped work. Lowercase @bindable belongs only in Gogo, including code-only non-Node models. Preserve native identity and event-driven affected-branch updates; no mandatory frame polling or rebuilding. [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) and the staged reactivity plans govern future work.
