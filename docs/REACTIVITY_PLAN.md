**T09-B delivery:** [Reactive GGX contract](REACTIVE_GGX.md) implements explicit self-path property dependencies and native retained subscriptions/layout. Collection/repeater/two-way proposals below remain future stages; live #86 records exact evidence and review state.

# Estragon reactivity and component architecture contract

**Owner direction accepted 2026-10-29, adapted by ADR-0015 on 2026-11-02; T09-A property/model foundation merged; bounded T09-B bindings implemented for review; collection/two-way stages pending.** This document is the durable brief for staged T09 delivery. It extends [the binding design](BINDING.md), [the execution plan](EXECUTION_PLAN.md), [accepted decisions](DECISIONS.md), and the live [T09 umbrella issue #5](https://github.com/resistdesign/Estragon/issues/5). It does **not** claim collections, x/y positioning, keyed repeaters, two-way binding or `EstragonBox` exist. **Version baseline:** ADR-0014 requires Godot **4.0+** for all future implementations. [C01 #41](https://github.com/resistdesign/Estragon/issues/41) must close current API gaps and prove native editor/runtime/compiler compatibility before releases claim 4.0+. Current 4.7 checks are insufficient.

## Node-native target and current implementation

[ADR-0015](DECISIONS.md#adr-0015--ggx-node-native-composition-and-layout-first-estragon) / [#68](https://github.com/resistdesign/Estragon/issues/68) supersedes the earlier independent-tree/RefCounted Box target. Gogo is the language; GGX is general-purpose Node composition with inherited Node.add_child as the only child rule. Visual branches use Node2D/Node3D and compose shared layout. Non-Node models remain supported as a requirement, not hierarchy children. Any referenced Object can supply a native signal; target GGX handlers reference named handlers/Callable values, not inline anonymous declarations.

C4 PR #84 is merged (`402480f8`): one canonical native Node UI/compiler/editor/runtime replaces the old RefCounted display/surface tree. T09-A #43 now adds [observable typed Gogo properties and non-Node models](BINDABLE_PROPERTIES.md). Unrelated GGX expressions remain construction-time; explicit self paths follow the T09-B contract. The old surface sketch below is historical, not executable current API. Current-addon strict C4 acceptance passed on both approved Linux engines; T09-A has its own live issue/PR evidence.

## Language boundary and authoring

- **Only official annotation:** `@bindable`, exactly lowercase, **in authored `.gogo` files only**. This intentionally supersedes the former `@Bindable` in arbitrary authored `.gd` requirement. Gogo is a GDScript-like source language with XML-like component expressions; generated `.gd` must remain ordinary Godot-parseable GDScript. No Godot parser patches, native custom annotation registration, `.bgd` requirement, Bun/Node compiler, authored-source replacement or runtime Gogo interpreter.
- `@bindable` may annotate typed properties in a Gogo component/surface **or a code-only Gogo model class**, with no markup required. The supported T09-A declaration/accessor/equality/inheritance contract is [BINDABLE_PROPERTIES](BINDABLE_PROPERTIES.md); custom accessors reject explicitly. Model objects are not Estragon display components and must not require Godot `Node` inheritance (at minimum, typed `RefCounted`; investigate appropriate `Resource` semantics).
- The compiler generates typed property storage/accessors/change notifications. Ordinary operations such as `count += 1` and assignments to another Gogo model's bindable property must notify relevant subscribers without manual signals, setter invocation or complete UI reconstruction. Initial values do not spuriously fire change notifications; equal-value assignments can be suppressed under a defined equality contract.
- `@bindable` is an authoring/compiler feature, **not a claim that native Godot accepts the annotation in `.gd`**. R01 [research PR #38](https://github.com/resistdesign/Estragon/pull/38) contains the stock-Godot counterevidence.

Proposed source illustration (not currently valid/executable):

```gdscript
# Counter.gogo
extends EstragonSurface
@bindable var count: int = 0

func increment() -> void:
    count += 1

func build_view() -> EstragonVBox:
    return <VBox>
        <Text text={"Count: %d" % count}/>
        <Button text="+" pressed={increment}/>
    </VBox>
```

T09-B defines the **typed, source-aware bounded binding contract** for explicit self-path reads. Unrelated brace expressions remain construction-time; an annotation alone does not make bare `{count}` reactive.

## Binding behavior, data and geometry

1. **Property updates:** generated subscriptions track read dependencies, update only affected live component properties, and reconcile nested paths when intermediates (e.g. `model.player`) change. Cover `null`, replacing the model, repeated expressions, re-entrant updates and cyclic dependencies. Prevent duplicate callbacks; unsubscribe on unmount/replace/disposal and support transfers correctly. No per-frame polling.
2. **Visual and layout:** reactive values may drive any supported typed visual/layout property, including `width`, `height`, `gap`, sizing flags, `color`, `text`, disabled state, and **future** positioning `x`/`y`. Adapt invalidation to the composed measure/arrange core and native presentation: geometry changes affect only needed layout branches, while presentation-only changes must not spuriously remeasure. Coalesce multiple changes.
3. **Positioning is an explicit design task:** native Node transforms exist in the target, but layout-controlled versus native-controlled coordinates must be specified; `x`/`y` are *not implemented* on current `EstragonDisplayObject`. Define whether coordinates are relative offsets, absolute placement inside a dedicated container, or controlled layout inputs. Do not have HBox/VBox child bindings quietly fight the parent layout algorithm. Prove nested offsets, hit-testing, surface coordinates and viewport resizing.
4. **Bindable models:** code-only `.gogo` modules should compile to ordinary typed scripts with reliable imports/class names, cache/dependency ordering, inheritance, source maps, initialization and property semantics. Bindable values may contain other models or collection references; nested observers follow replacement and clean up automatically.
5. **Collections:** offer an observable, ArrayCollection-inspired `EstragonArrayCollection` (final API subject to typed Godot proof), not an assumption that native `Array.append()` can emit change notifications. A bindable variable holding a collection only detects **reference replacement**; the observable collection itself must publish *structural mutations* (insert/add/remove/replace/move/reset) and changes in bindable item models, with well-defined event kind/item/index/identity. Preserve stable item identity for incremental/efficient list rendering; optional view sort/filter may follow a tested base contract. Do not advertise generics syntax that stock GDScript cannot parse.
6. **Repeaters/data-driven components:** an iterable/collection expression used to build children needs explicit retained keyed Node update semantics, without virtual DOM reconciliation. An item edit updates its component; an add/remove/move creates, removes or moves only affected children. Preserve component identity, pointer/handler ownership and subscription lifetimes; do not rebuild the entire tree unnecessarily or cause leaked references.

For inspiration, Apache Flex [ArrayCollection and data providers](https://flex.apache.org/doc/flex/using/flx_about_dataproviders_ab.html) describe collection change events, item-property notifications and data views. Estragon should implement its own deliberately scoped contracts, not promise API parity with ActionScript.

## Deferred pixel conversion helpers and possible syntactic sugar (owner decision, 2026-10-30)

**Accepted 2D core contract:** Estragon's numeric dimensions and spacing use **pixels only**. ADR-0015 does not assume pixels are 3D world units; 3D units/axes/wrapping/overflow need a focused specification. `height={100}` and `height="100"` represent 100 pixels. `height="100%"` is **not** valid Gogo today and must fail with a source-located diagnostic; `auto` and existing fill flags retain their own semantics. The planned padding/margin box model in [#55](https://github.com/resistdesign/Estragon/issues/55) likewise uses pixel-valued lengths.

**Deferred extension:** Provide ordinary, reusable helpers that convert a number plus a unit into a **pixel number**, which can be passed through the same Gogo component properties and ordinary reactive property bindings as any other numeric expression. The approved direction is helper functions, **not** unit-aware core properties, an alternate layout engine, or compiler-generated layout callbacks. The friendly four-argument sketch is worth preserving; a standalone percentage conversion must also know *which dimension* supplies the reference:

```gdscript
# Conceptual future API only; not implemented and exact signatures TBD.
to_pixels(parent, child, 50, "%")           # desired concise form, if target axis is known
to_pixels(parent, child, 50, "%", "height") # explicitly convert relative to a height
to_pixels(parent, child, 50, "%", "width")  # explicitly convert relative to a width
```

**Required context and behavior:**

- A helper must have access to the relevant **parent and child width/height geometry**, not merely the authored width/height declarations; choose the reference box (e.g., the parent's **available content width or height**) according to the **target dimension/axis**. Other future units may require viewport, padding/margin, font or other contextual measurements. The exact API can use an explicit axis/property argument or a typed conversion context; never silently guess whether a percentage refers to width or height.
- Results are ordinary finite numeric **pixels**. Use existing or planned typed Gogo expression bindings for properties such as `width`, `height`, `padding` or `margin`; **do not invent separate unit-binding machinery**. When relevant geometry changes on resize/relayout, normal dependency tracking must observe that geometry and re-evaluate the bound helper expression at a safe stage; no per-frame polling. Existing braced expressions are construction-time until T09 bindings ship, so this behavior is a future requirement, not current functionality.
- Specify and test layout ordering and dependency cycles, especially `auto` parents, child-dependent measurements and self-referential percentages. Define overflow, invalid measurements and diagnostics without unstable repeated relayout.
- **Optional syntactic sugar can come later**, after helpers and normal bindings work. It may lower to the same pixel-returning helpers, but is **not** permission to accept `height="50%"` in the current grammar or change the pixel-only runtime contract. No compiler/runtime work belongs in the current [L01 #55](https://github.com/resistdesign/Estragon/issues/55) or C01 compatibility PRs.

See [deferred helper issue #54](https://github.com/resistdesign/Estragon/issues/54). This section specifies direction, not an implemented API.

## Inheritance and shared component behavior

**Retired pre-C4 Godot classes (archival context, no supported executable path):**

```text
EstragonDisplayObject
    └── EstragonContainer
          └── EstragonStack
                ├── EstragonVBox
                └── EstragonHBox
```

The earlier proposed RefCounted `EstragonBox extends EstragonContainer` hierarchy is **superseded as the future design** by ADR-0015. C4 removed that display hierarchy. Canonical EstragonRect/Text/Button/HBox/VBox now inherit Node2D; bounded 3D participants inherit Node3D. They share measurement/arrangement through composition. The former Stack compatibility path is retired; do not recreate it.

Native2D/Native3D adapters expose explicit or suitable provider-measured bounds. Ordinary Nodes are legal GGX children but not automatic layout participants; explicit entries re-enter below boundaries. Binding subscriptions must respect native Node lifetime/reparenting and separate PackedScene owner semantics. Preserve instance identity and native signals, invalidate only affected branches, coalesce updates and prevent feedback from layout-authored transforms. Animated geometry observation is explicit opt-in, not compulsory polling.

Observe viewport resize as a root layout input; handle relevant Window DPI/scaling independently. Theme changes flow through observable/bound theme data. Collection repeaters update retained keyed Nodes incrementally, without virtual DOM reconciliation, full-tree rebuild or required function-valued GGX children.

## Recommended task boundaries and proofs

**Prerequisites:** E01 #40 is merged; E01-F #44 is closed not planned with an accepted hidden-tab limitation, not a PASS. T09-A #43 is the active scoped property/model implementation after merged C4; see the current contract and live issue/PR. T09-B also needs the Node component/layout migration; C/D follow the prior reactive slices. See NODE_MIGRATION_PLAN for exact gates.

**T09-A — observable Gogo property and data-model foundation:** code-only Gogo modules, explicit lowercase annotation parsing/typechecking, generated setters/notifications, typed non-Node model proof and native editor/semantic tests. Confirm no implicit UI rebuild is needed to observe a plain property. Define/verify custom accessors, inheritance and equality. One scoped issue/PR.

**T09-B — reactive component props and layout:** bind expressions/dependency graph, nested replacement, automatic lifecycle, batching, layout versus paint invalidation. Determine x/y semantics, add geometry only with tests. Use the proved composed layout core and Node lifecycle contract; the old RefCounted Box refactor is not an independent target prerequisite. Show a value change updating text **and** geometry with no explicit `set_root()`.

**T09-C — observable collections and repeaters:** item change/structural change events, bindable model contents, incremental keyed child updates/moves/removal, replacement and disposal. Prove event counts, stable identities and no leaks; allow collection reference changes. Sort/filter/view features can be staged independently, but their contract must be considered in the model.

**T09-D — two-way bindings and hardening:** assignable paths, event adapters, null handling, feedback/cycle guards, batching across nested objects/collections, integrated editor demonstration. Separate reviewable PRs if needed.

### Acceptance and quality gate across stages

- Tests include 1) typed scalar update without manual refresh, 2) non-Node model update, 3) nested-object replacement, 4) layout/position dirty-phase behavior, 5) collection insert/remove/replace/move/item update, 6) keyed repeat behavior and owner cleanup, 7) fail-closed source diagnostics, 8) fresh Godot-only editor F5/F6 without Bun/Node, **only official 4.0.4 and pinned 4.7.0 under the owner's two-version cap; never require every-minor reruns**.
- Keep native compiler, source maps, callback evaluation semantics while migrating to retained native Nodes. Stage only supported properties/syntax; unknown types and unsupported mutations should fail visibly rather than pretend to be reactive.
- Protect the shipped Counter and legacy demo during migration. Never merge on behalf of the user. Maintain linked GitHub issues, scoped PRs, CI, checked acceptance evidence and durable session handoffs per `AGENTS.md`.

**Status/merge ordering:** ADR-0015-A and B1–C4 are merged through PR #84. T09-A #43 is merged in PR #85; T09-B #86 is the active property/layout binding slice; T09-C/D remain queued. Consult the live issue/sole PR for verification and review state. One PR at a time; no automatic merges or successor implementation.
