# Direction and implementation

Estragon provides Flex-inspired, layout-first native Godot UI in 2D and extends the same model to 3D. Gogo is the GDScript-like authoring language; GGX composes ordinary/custom Nodes and Estragon components. Godot supplies rendering, transforms and native services. Godot remains the renderer; ADR-0016 adds a lightweight Virtual DOM of descriptions for native reconciliation.

The shipped bounded slice includes canonical native Rect/Text/Button/HBox/VBox, retained Counter, explicit 2D/3D entries/participants/adapters, a shared mathematical core and bundled Godot-only compiler/editor. C4 removes the obsolete parallel UI. See [architecture](ARCHITECTURE.md), [API](NODE_UI.md) and [actual status](WORK_STATUS.md).

T09-A adds Gogo-only typed observable properties, including code-only non-Node models; see [the bounded contract](BINDABLE_PROPERTIES.md) and live #43 for review state. Broader Flex-style layout, style/theme systems, focus/accessibility, keyboard/touch, retained keyed collections/repeaters and 3D wrapping remain future scoped work. Preserve native identity and event-driven affected-branch updates; no mandatory frame polling or rebuilding. [ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) and the staged reactivity plans govern future work.

T09-B adds bounded [reactive GGX properties/layout](REACTIVE_GGX.md) with native weak subscriptions, retained Nodes and explicit self paths. Reactive transforms/position, collections and two-way machinery remain future work.

F01 [native composition spike](F01_COMPOSITION.md) implements the first bounded function/description/reconciliation proof. F02–F06 remain future work; live #92 records exact verification and review state.
