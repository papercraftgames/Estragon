# Gogo reactivity and composition — implementation plan

**F04 current cutover:** [Single-runtime contract/removal/parity](F04_CUTOVER.md), [#98](https://github.com/resistdesign/Estragon/issues/98), [PR #99](https://github.com/resistdesign/Estragon/pull/99). F01–F03 are merged. All GGX now produces descriptions through one compiler/manager; eager/static-binder implementations are removed. Live issue/PR records exact verification and review; F05/F06 remain future.

**Active, owner-approved architecture:** [ADR-0016 — Signal-driven function composition and retained Godot reconciliation](REACTIVE_COMPOSITION_ARCHITECTURE.md), [decision entry](DECISIONS.md#adr-0016--signal-driven-function-recomposition-with-retained-native-nodes), [#89](https://github.com/resistdesign/Estragon/issues/89), [T09 umbrella #5](https://github.com/resistdesign/Estragon/issues/5).

**Shipped versus planned as of November 5, 2026:**
- **Merged T09-A:** source-authored Gogo-only lowercase `@bindable` on typed instance fields, normal native GDScript setter/storage and typed per-property signals; non-Node RefCounted data models. See [BINDABLE_PROPERTIES](BINDABLE_PROPERTIES.md), [PR #85](https://github.com/resistdesign/Estragon/pull/85).
- **Historical merged T09-B (replaced by F04):** reactive individual GGX properties/layout with explicit supported self paths, target-owned helper Nodes and coalesced native signal subscriptions. See [REACTIVE_GGX](REACTIVE_GGX.md), [PR #87](https://github.com/resistdesign/Estragon/pull/87). **Not a dynamic composition engine.**
- **Merged F01/F02:** getter-observed view functions, virtual descriptions, conditional child slots and nested retained reconciliation. **Merged F03:** mapped/keyed sequences. **F04 review slice:** final cutover/removal. **Future:** class-level `@bindable`, observable in-place collection events, two-way binding and generic data graph hydration.
- **New ADR-0016 direction:** rewrite the final compiler/runtime **without a legacy compatibility burden** after each acceptance checkpoint, adopting a **single** automatic signal-driven recomposition/reconciliation path. Intermediate T09-B's particular compiled observer mechanism may be removed once equivalent checks pass.

## User mental model

1. Write a normal Gogo function describing what should exist, using GGX, locals, conditionals and loops.
2. Use mutable typed Gogo state and non-Node model objects. Read their bindable values normally.
3. Assign new values normally, including compound assignments. Native signals automatically mark only relevant composed components for a rerender.
4. Reconciliation preserves native Godot Node identity and state where type/key/position is stable, applies changed declared props and necessary structural edits, and lets existing layout invalidation handle actual geometry changes.
5. Godot draws and runs physics normally; no GGX/Virtual DOM polling or tree recreation every frame.

A **lightweight virtual element tree is explicitly part of this design**. Its descriptions/records belong to the Estragon runtime manager; **no reconciliation keys/fibers/metadata are injected on application Nodes/Resources/models**. User code needs no hooks or manual invalidation function. Even if a component function does more work than theoretically necessary, prefer the understandable source to an elaborate optimizer unless profiling proves otherwise.

## Phase ordering

| Work | Deliverable | Acceptance focus |
| --- | --- | --- |
| **F01: minimal signal → function → reconciler spike** | Typed getter read tracking, one view function returning element descriptions, initial mount and automatic refresh-free rerun | Godot 4.0.4 and pinned 4.7.0 native compilation, existing real Node IDs, update timing, compiler/source-map integrity |
| **F02: dynamic conditional composition** | Child description expressions, nested component scopes, conditional type/position/key reconciliation and safe parent-first scheduler | False→false retains child, false→true changes one branch, null/replaced nested models, disposal, deep nesting, only necessary layout invalidation |
| **F03: native mapped lists** | GDScript for/map authoring, flattening arrays of descriptions, unique sibling-scoped keys and keyed add/remove/reorder reuse | Inventory/HUD real-scene proof, unchanged item state/IDs, duplicate-key diagnostics, no required `Repeater` |
| **F04: one production pipeline** | Cut over all active demos/compiler/editor/runtime tests and delete eager GGX and per-property binder Node paths | No dual compiler, no old helpers/shims, current addon source-only editor, saved/unsaved F5/F6, pack export and real graphics |
| **F05: model ergonomics and controlled inputs** | Class-level [`@bindable` #90](https://github.com/resistdesign/Estragon/issues/90), typed two-way binding and feedback guards in focused PRs | Several auto-observed class properties, one source of truth, native input edits and model replacement without cycles |
| **F06: measured optimization** | Profile descriptor allocations, render passes, actual Nodes moved/allocated/freed, layout work and memory; only then add safe caching | Idle work zero; profiling of 2D/3D, deeply nested views and inventory reordering |

**Observable in-place collection mutation:** do not assume a special collection must exist for F03. Bindable reference reassignment already notifies. Add an opt-in evented collection/adapter if actual use cases require in-place mutation, sharing the same list reconciler, not a separate repeater subsystem. Plain native Array/Dictionary mutations cannot emit the model's property signal automatically.

**Serialization:** not a prerequisite to composition. Standard Godot data/Resource serialization and explicitly typed dictionary constructors are preferred over AMF, RemoteObject or universal nested observable wrappers. Only the changed portions needing live observation should be modeled as bindables. A separately reviewed hydration/round-trip task may follow real use cases.

## Invalidations and nested updates

- Source signals synchronously describe *data* changes, while view recomposition/commit coalesce at a safe SceneTree point. An ordinary setter does not promise a synchronously updated Node before it returns.
- A render computation collects actual Gogo observable getter reads. On rerun, its dependency set changes according to the conditional path; stale subscriptions are removed, newly accessed ones attached. Deep nested model replacement naturally rewires when parent and nested values are themselves bindable.
- Parent components win scheduling order over children; discarded branches lose queued tasks/listeners. Ordinary child components do not rerun just because an unaffected parent descriptor was compared.
- Only reconcile declared managed boundaries, leaving other native Godot children and their scripts untouched.
- Gogo render functions are **description computations**. Ordinary lifecycle/events carry side effects; repeated rendering must not spawn actors, emit messages or edit the actual scene directly.
- Layout invalidation is based on actual changed structure/geometry. Pure text/color redraws use existing text/font/redraw logic; affected-branch caches are preserved. Do not write to layout-owned transforms on every recompose.

## Positioning, theme and data conversion boundaries

- 2D component numerical geometry/spacing is expressed in **pixels**. Height/width/gap/fill values use the existing native shared measure/arrange core. Relative percentages and `height="50%"` remain unsupported. Any future unit helpers return ordinary pixel numbers used by standard binding; see [unit conversion issue #54](https://github.com/resistdesign/Estragon/issues/54).
- Node2D positioning and 3D transforms have *native versus layout-authored authority*. Reactive dynamic position/x/y needs the scoped [position spec #88](https://github.com/resistdesign/Estragon/issues/88), avoiding loops between authored bindings and HBox/VBox placement. No magical 3D wrapping or automatic pixel-to-world units.
- Bindable models can store references to ordinary Godot Objects/Resources. Their observed *property* changes follow only generated Gogo bindables or explicit approved event adapters. Changing an external source that emits no observable event cannot trigger recomposition spontaneously.
- Theme changes may be observable typed data; viewport changes invalidate layout through the existing native coordinator. Distinguish redraw, layout, and structural recomposition.

## Engineering and acceptance

Follow `AGENTS.md`: source plan, issue checkpoints, durable handoff, one PR total, owner merges manually. **Godot 4.0+ target; routine tests only official 4.0.4 and pinned 4.7.0 on Linux CI.** Production Gogo/GDScript and bundled Godot-native editor compiler only. New contributor tooling TypeScript/Yarn, **no Python**. Preserve native source maps, semantics, saved/unsaved editor main/current Play rejection/rollback/repair, stable UIDs, correct source-only imports, actual current-addon pack/runtime acceptance, and honest runtime/graphics evidence. Design changes are **not** marked implemented until corresponding PRs are merged.

The previous proposed RefCounted EstragonBox display inheritance, legacy RenderingServer-owned UI and no-per-component-Node decisions are retired. Gogo `RefCounted` *data models* remain valid. Historical failed tests and earlier design claims belong to git history/archival reports, not an active compatibility or runtime requirement.
