**F04 single-runtime cutover:** [Current contract, removal inventory and parity](F04_CUTOVER.md), [#98](https://github.com/resistdesign/Estragon/issues/98). Every GGX expression now builds Element descriptions, including ordinary helpers/lambdas. Eager factories and per-target binding helpers are removed. F01–F03 are merged; live issue/sole PR records F04 verification/review. F05/F06 remain future. Earlier stage text below records that stage’s original scope.

**F03 review slice:** [Native mapped/keyed sequence contract](F03_LISTS.md), [issue #96](https://github.com/resistdesign/Estragon/issues/96), [PR #97](https://github.com/resistdesign/Estragon/pull/97). F01 #93 and F02 #95 are merged. F03 supplies nested child sequences and sibling keys in the same manager; F04 final cutover and F05/F06 remain unimplemented. Exact acceptance/review state is in the live issue/PR.

**F02 implementation checkpoint:** [Conditional child/nested composition contract](F02_CONDITIONALS.md) / [#94](https://github.com/resistdesign/Estragon/issues/94) extends the merged F01 engine with stable nullable slots, branch replacement and parent-first nested ownership. Exact verification/review state is in the live issue/sole PR; F03 lists/keys and F04 cutover remain future work. Earlier F01-only shape restrictions below are historical.

**F01 implementation checkpoint:** [Native composition spike](F01_COMPOSITION.md) / [#92](https://github.com/resistdesign/Estragon/issues/92) supplies the bounded getter-read → description → retained static-shape path for review. Full ADR-0016/F02–F06 behavior is not claimed; exact verification and review state are in the live issue/sole PR.

# ADR-0016 — Signal-driven function composition and retained Godot reconciliation

**Status:** Owner-approved target architecture, 2026-11-05. **Implementation:** F01 native getter/description/reconciliation and F02 conditional/nested ownership are merged after T09-A (#43 / PR #85) and T09-B (#86 / PR #87). F03 merged in PR #97 (`eb153f1`); F04 is the single-runtime review slice above. F05/F06 remain future. **Architecture tracking:** [#89](https://github.com/resistdesign/Estragon/issues/89); [T09 umbrella #5](https://github.com/resistdesign/Estragon/issues/5); [class-level bindability #90](https://github.com/resistdesign/Estragon/issues/90). This document supersedes earlier T09-C implementation guesses and ADR-0015's statement that a Virtual DOM is prohibited.

## 1. The product contract

**Estragon is React-like declarative function composition with Flex-like automatic observation, hosted by Godot's mutable, retained native scene graph.** Application authors walk through ordinary GDScript-like functions and return GGX. They mutate typed Gogo `@bindable` properties normally. No hooks, no `setState`, no explicit `refresh` or `invalidate` to update ordinary declarative output.

- **Data changes:** generated setters publish native signals; reads performed during composition determine automatic subscriptions. A relevant change schedules recomposition **only for the component(s) that observed it**. Multiple writes are coalesced.
- **Composition changes:** rerun the affected component function to produce *descriptions* of desired children. Reconcile those descriptions against the retained Godot scene. Do not instantiate candidate Godot Nodes just to diff and discard them.
- **Actual Nodes:** keep identity, transforms, physics state, animations, signal connections, caches, and other native behavior for unchanged elements. Commit only changed declared properties/handlers and necessary child mutations; never duplicate the scene in a second set of live Nodes.
- **Rendering:** Godot keeps drawing/processing actual Nodes as normal. **Drawing a frame does not execute GGX composition.** An idle component does no recomposition.
- **Ownership:** all reconciliation identity, bookkeeping, dependency subscriptions and last-declared-property snapshots live in **framework-owned runtime records external to user Nodes and data objects**. No `set_meta`, injected reconciliation fields/keys on native Nodes, additional per-element tracking Nodes or mandatory subclass for native Godot components.
- **Pre-release freedom:** Estragon is unreleased. Do **not** preserve a second permanent creation path, existing GGX behavior, old generated files, old helper Nodes, APIs or tests merely for backwards compatibility. Migrate real consumers/tests to one coherent model and remove superseded implementation. Preserve accurate historical evidence as historical facts.

Readable source is the priority. The first implementation can reexecute a modest function unnecessarily; compiler cleverness is a later measured optimization. React Compiler's explicit non-goal of perfect memoization is a useful constraint: tracking overhead may be more expensive than recomputation.

## 2. Terminology and layers

| Term | Meaning | Lifetime |
| --- | --- | --- |
| **Observable model** | A Gogo class (Node-based or non-Node `RefCounted`/`Resource`) with generated property getters/setters and native change signals | Normal Godot model ownership |
| **Component host** | A Gogo-authored Node with a declarative composition function (`build_view` as the initial source convention) and normal native lifecycle | A real Godot Node |
| **Element description (virtual element)** | Cheap immutable-by-convention value describing a desired native type, declared properties, handlers, optional key and child descriptions | Temporary desired render output |
| **Reconciler record** | Runtime-owned correspondence between previous description, an existing native Node, child records, subscriptions and component identity | While that managed element is mounted |
| **Render/recomposition** | Call an affected component's composition function to compute a desired virtual element subtree | Only after initial mount or relevant observed change |
| **Reconcile** | Match new descriptions to previous records by type, sibling position and optional key | Only when recomposition happens |
| **Commit** | Apply necessary native `Node` property/signal changes and `add_child`/`remove_child`/`move_child`/free operations | At a safe SceneTree point |
| **Layout** | Existing shared measure/arrange invalidation, after actual relevant structure/geometry changes | Existing native coordinator |
| **Draw** | Godot's usual render/physics/update phases | Engine controlled |

**Yes, this uses a Virtual DOM.** It is a small *description/identity layer*, not the DOM itself and not a second hierarchy of instantiated Godot Nodes. Reconciliation and keyed identity are named honestly. We do not introduce an independent shadow set of mutable game objects.

## 3. Authoring: ordinary readable Gogo functions

The familiar Gogo module remains an ordinary Node/typed data object with GDScript methods. The framework recognizes a declared composition entry (`build_view` for the first vertical slice; select a final exact return type after native feasibility proof). Ordinary event methods perform ordinary state assignments.

The following sketches are **future Gogo syntax, not runnable with current main**. They deliberately use **GDScript conditional expressions** (`value_if_true if condition else value_if_false`), not JavaScript ternaries:

```gdscript
# Counter.gogo — proposed post-migration syntax
extends Node2D
@bindable var count: int = 0

func increment() -> void:
    count += 1

func build_view():
    return <EstragonVBox>
        <EstragonText text={"Count: %d" % self.count} />
        <EstragonButton text="+" pressed={increment} />
        <EstragonButton text="Reset" disabled={self.count == 0} pressed={reset_count} />
    </EstragonVBox>

func reset_count() -> void:
    count = 0
```

The function is a **declaration of desired output**, not a factory that immediately allocates each nested Node. It is called on mount and again when observed state used in its last evaluation changes. The compiler preserves ordinary branching, locals, function calls and iteration whenever safe. No hooks, lifecycle hook call-order rules, manual memo wrappers or special `Repeater` are required.

Conditional composition:

```gdscript
# Proposed expression-child syntax, pending implementation
func build_view():
    return <EstragonVBox>
        {<MyButton text="OK" /> if self.model.count > 4 else <MyInput value={self.model.count} />}
    </EstragonVBox>
```

Collections can use **ordinary loop logic** rather than requiring a branded Repeater:

```gdscript
func build_view():
    var rows: Array = []
    for item in self.items:
        rows.append(<InventoryRow key={item.id} model={item} />)
    return <EstragonVBox>{rows}</EstragonVBox>
```

`key` is a **reserved GGX composition identity attribute**, not a Godot Node property and never written onto the Node or model. It exists only in virtual descriptions/reconciler records. Plain native `Array.map(Callable)` is an equivalent authoring candidate when it keeps familiar GDScript source and correct typed diagnostics. Expression children may produce a description, a sequence of descriptions, or null/empty; nested sequences flatten consistently. Arbitrary live Node insertion inside a declarative child expression is not supported. Compiler support for the exact examples is a delivery item, not a claim that they work now.

A nested Gogo component may own its own `build_view` function and state. A parent description refers to that component type; the reconciler retains its actual Node on compatible rerenders, and its own dependency record determines when to rerun its function. A changed parent's unrelated child is **not automatically recomposed** merely because its parent ran.

## 4. Observation: signals trigger function reruns automatically

**Chosen target:** automatic **dynamic dependency tracking** for Gogo-generated observable property *reads* during a scoped component composition call, backed by ordinary native signals for changes. This is simpler at the authoring level than requiring the compiler to enumerate every possible expression/path, and handles conditional branches and helpers that read observable fields. It is not a generic proxy for arbitrary Godot values.

1. The reconciler enters a bounded **current computation scope** for the component being composed.
2. An emitted Gogo bindable getter returns its normal typed value and records (`source Object identity`, `property signal`) in that active scope. Outside a composition scope the getter behaves like an ordinary read.
3. As the function evaluates, conditionally accessed values become its **actual dependencies**. Repeated reads deduplicate; a nested component creates its own scope so parent and child dependencies remain separate.
4. On successful composition, compare newly observed dependency pairs with the component's previous subscriptions; keep shared, detach stale, attach new. Signals use native `<property>_changed(previous, value)`. These subscriptions are runtime-owned and do not embed render metadata in source objects.
5. A setter mutates the property immediately and emits the existing T09-A signal according to its defined `is_same` equality policy. The scheduler marks the observing computation dirty once. A model reference change automatically reroutes subsequent reads and subscriptions, including deep paths.
6. On unmount/free or removal of an owning component, remove the computation and all subscriptions. Weak signal targets/source references and generation tokens prevent a stale queued job from acting on freed Nodes or obsolete models.

**Feasibility gate:** a focused first Codex implementation must prove that generated GDScript getter read capture works on **Godot 4.0.4 and pinned 4.7.0**, including typed self/external properties, nested calls, inherited Gogo properties, nested composition scopes, reentrant signals, Resource/RefCounted lifetime and source maps. If the proof reveals an actual Godot limitation, retain the same user-visible contract using **compiler-emitted explicit read capture** for supported types or a similarly small verified bridge. Do not silently ship a second independent observation engine. The architecture (signal-triggered function recomposition + native reconciliation) does not change with the tracker implementation.

**Honest boundaries:** only instrumented Gogo bindables (and separately adapted supported native signals) are automatically observed. Reads from arbitrary Godot objects, native transforms, a normal `.gd` field, raw dictionaries, and native arrays are not magically observable. If authoring declares output dependent on these, it updates when another observed source schedules the owning function, or when the application explicitly opts into an **external-event adapter**. There is no compulsory per-frame polling. Unsupported source assumptions should have clear documentation/diagnostics, not a fake automatic guarantee.

## 5. Element descriptions and the reconciler

The compiler lowers GGX inside recognized composition functions into **lightweight typed descriptions** rather than direct `.new()`/`add_child` calls. An element description contains:

- constructible native Godot class or script identity (validated without running constructors in the compiler);
- declared, already evaluated typed props and separately declared event handlers;
- optional sibling-scoped key and ordered flattened child descriptions;
- source positions for compiler/editor errors (not metadata stored on a Node);
- optional nested Gogo composition type/inputs.

The **reconciler record**, external to Godot Nodes, holds previous declared values, child matching identity and the actual Node reference/weak lifecycle guard. The user-facing Node retains its normal class, signals and fields; no hidden `key`, `fiber`, `_vdom`, metadata or per-element helper `Node` is added to it.

**Baseline diff:** match *key + type* among keyed siblings, or *position + type* among unkeyed siblings. Keys must be unique **among siblings in one list**, not globally. Type changes replace the native instance. On a compatible match, reuse the existing Node and child records. A keyed reorder moves the existing real Nodes using native `move_child`; keyed insert/delete creates/frees only affected instances. Duplicate keys fail with meaningful authored/diagnostic context. Do not compare arbitrary user-mutated Node state to desired values to decide whether to reset it.

**Props:** compare *new declared value* to the previous **committed declared value**, not to whatever current value game code or animation has placed on the actual Node. Set only properties whose declarative desired values changed, or whose Node is first mounted. This preserves native state and animations for props not changed by Gogo. A property explicitly controlled by Gogo may be overwritten on a *new desired value*; native-controlled and layout-controlled transform authority still follows the existing Node2D/Node3D adapter/layout contracts. Event Callable connection sets are diffed and properly disconnected/reconnected.

**Foreign children:** reconcile only descendants explicitly owned by the declared GGX managed region. A native game script's unrelated children stay untouched, including when parent Node happens to be a managed type. If a foreign child conflicts with the desired sibling position/name/ownership, fail visibly or use a well-defined managed insertion boundary; **never delete foreign Nodes to make a virtual tree match**. A rendering root registers its managed boundaries with the runtime manager, not by tagging child Nodes.

**No full-scene rendering:** a component's dependent change reexecutes that component's function; siblings outside its dependency scope are not touched. Inside the affected component it is fine to walk its declarative children, because maintaining *more* fine-grained tracking than the cost of recomposition may be counterproductive. Optimize static subtrees, descriptor allocation or child recomposition only after measuring.

## 6. Update scheduler, deep nesting and safety

**Data is synchronous; presentation is scheduled.** Normal Gogo assignments update model values immediately. Render invalidation and SceneTree commits are deferred/coalesced to a safe Godot idle point, ordinarily before the next visible frame. Do not promise that reading a rendered Node immediately inside a setter reflects the new state.

- A live component is enqueued at most once per flush. Unaffected components have no render work.
- Process **parents before descendants**; when a parent removes or replaces a branch, invalidate/cancel queued work for the obsolete children. If parent and child both changed, reconcile parent first, then run only surviving dirty children.
- Each component collects a new dependency set per run; switching conditional branches or nested `model.player` references detaches stale sources automatically. A null intermediate is handled using actual GDScript-safe logic, not an implicit magical nullable path rewrite.
- Changes triggered while composing/committing enqueue a subsequent bounded pass; render cannot recursively mutate the scene in an uncontrolled signal stack. Detect runaway self-invalidating cycles with an actionable error; never silently drop a legitimate final change.
- If the host or owned Node exits the tree, suspend commits, drop stale work, disconnect sources and reestablish subscriptions on a valid reattach. Compatible reparenting preserves managed Node identities, unless the explicit mount ownership boundary has changed.
- Godot's forbidden SceneTree/physics mutation contexts are respected: schedule native add/remove/move/free operations at a safe phase, rather than assuming signals always fire at an attach-safe time. Measure/arrange requests follow the existing affected-branch coordinator; unchanged branches retain caches.
- No virtual-loop ticking, global `_process` invalidation scanner, VDOM comparison per frame or forced every-frame model wrappers.

**Nested dynamic example:** if an outer condition removes an inventory panel while an inner list changed on the same tick, the parent commit wins. The old panel's queued list work is cancelled and its subscriptions are detached. A newly mounted panel computes from the latest model once. Unchanged siblings keep their native instances and state.

## 7. State, events, identity and two-way binding

- **No hooks:** local state is a normal Gogo property on the component host (`@bindable var`), a referenced Gogo model, or ordinary native Godot state. Do not implement `useState`, positional hook arrays, hook call-order rules or explicit recomposition callbacks.
- **Render description should be repeatable:** component composition functions calculate descriptions. Side effects (spawning unrelated game actors, network calls, changing model state, connecting signals, modifying existing real Nodes) belong in ordinary Godot lifecycle/event methods such as `_ready`, named signal handlers, and explicit application services, **not inside the composition function**. This purity is only at the composition boundary; the *game's data and Nodes remain mutable*. If a Gogo authored function read performs side effects, repeated recomposition is an expected hazard; provide clear diagnostics for known unsupported operations and document the rule rather than attempting an impossible perfect static purity analysis.
- **Native handler identity:** event handler attributes bind ordinary named `Callable` references; compare/disconnect without accumulating duplicates. Reconciled Node identity keeps ongoing pointer/animation/input state where compatible. Losing the branch deliberately frees it; recreating it later is a new Node unless a future explicit keep-alive feature exists.
- **Controlled versus native-managed:** only declared props are under Gogo desired-value authority. Properties never declared in GGX remain native-managed. For existing declared props, unchanged desired values do not reset externally animated/native changes on every recompose. A dedicated position/transform authority decision remains [#88](https://github.com/resistdesign/Estragon/issues/88).
- **Two-way binding (T09-D):** later `bind:value={self.model.name}`-like syntax (illustrative, not final) may lower to one-way model→view updates plus a typed view-change signal→model setter. Update-origin/equality checks and bounded flushes prevent feedback loops; validate assignable paths, null/replaced models, native event ordering, user editing/selection and teardown. Do not make the UI and model parallel sources of truth.

## 8. Arrays, keyed iteration and model ergonomics

The authoring goal is *ordinary GDScript loops/`Array.map` that return GGX descriptions*, not compulsory `Repeater` controls. Rendering an array snapshot after a **bindable reference replacement** invokes component recomposition and local keyed reconciliation. Stable `key` lets inserted/moved items keep their native Node identities and state. Item components may subscribe to their own observed model fields without forcing unrelated items to recompose.

**In-place mutation limitation:** raw Godot `Array.append`, `Dictionary.set` and arbitrary nested native data edits **do not emit a Gogo bindable property's change signal**. An observable collection (optional future T09-C2 adapter) is warranted for users who need automatic in-place add/remove/move/replace notifications. It should expose normal collection operations and emit *one structural change event* for the owning component, which then uses **the same reconciliation code**. Do not build a separate repeater reconciliation algorithm. A reference-reassignment workflow is a valid first implementation and avoids requiring wrappers everywhere.

**Class-level `@bindable`:** [#90](https://github.com/resistdesign/Estragon/issues/90) is a distinct required ergonomic follow-up, inspired by Flex's class-level `[Bindable]`. A class-level annotation in authored `.gogo` should instrument all **eligible explicitly typed instance fields** using the *same generated getters/setters/signals* as T09-A. Static, const and local fields are not eligible. Unsupported custom accessors/collisions report source-located errors. Existing per-property annotation remains supported. No second binding runtime and **no custom annotation in normal `.gd`**. Precise class-declaration grammar/override policy must be proven during that focused feature.

**External JSON and Resource data:** not all data must be observable. Plain `Dictionary`/`Array`/JSON is a valid transport/cache/save format. Convert to typed observable models only where an application needs automatic in-place notifications. Use normal Gogo constructors/factories or small `from_dict`/`to_dict` adapters and Godot `Resource` mechanisms; preserve nested null/default/error/identity semantics when such helpers are needed. **No AMF/RemoteObject clone, universal deep-proxy graph, mandatory hydration pass, or serialization on each render.** Godot custom `Resource.changed` is not automatically emitted on custom field writes; a generated setter or explicit adapter remains necessary.

## 9. PackedScene, editor, and scene boundaries

The **source-authored composition function is the authority** for managed dynamic children. Persist actual scene-authored host/native nodes in `.tscn`; reconstruct managed GGX children from the latest source/state on mount. **Do not serialize a second snapshot of transient reconciler/VDOM records into the scene, or persist stale dynamic children that will be duplicated on reopen.** Existing checked-in static/generated scene fixtures must be deliberately migrated; no silent change to actual scene owner semantics.

A component host owns a logical view root/mount boundary. Its runtime context is held by Estragon's reconciliation service (one context per mounted view root and logical child records), keyed via safe weak native identity; **not by attaching per-element metadata to Nodes**, creating a binder/helper Node per property, or putting framework state on arbitrary user models. Source-described *native* child owners still use normal Godot ownership when explicit persistence is intended, but transient dynamic view subtrees are re-created at mount rather than saved as authoritative SceneTree snapshots.

Editor preview and source compilation should use the **same renderer contract** in isolated preview state, with clear scene restoration behavior. A running game's hot reload is **not** promised; normal save/reopen and Play must consume the current compiled Gogo and fail closed on invalid or unsavable source.

Compiler/editor invariants survive: typed native type/property/signal validation, original-source maps, stable script UIDs, class/cache identity, source-only clean imports, actual-path semantic validation, transactional rollback/repair, saved/unsaved main/current Play, no external compiler requirement. The new description IR exists in compiled output/runtime; never a runtime XML/JSON Gogo interpreter.

## 10. Compiler and runtime responsibility split

**Compiler (Godot-native GDScript):**
1. Lex/parse mixed GDScript/GGX with source spans, including conditional expression children, optional key and mapped list/array expression returns using actual 4.0-compatible grammar.
2. Typecheck against native Godot Node constructors, explicit script imports, signal/event attributes, property values and key rules. Reject unsupported Node child values, invalid branch return shapes and duplicate keys with useful authored diagnostics where statically possible.
3. Lower GGX inside view functions to typed, lightweight element descriptions, preserving normal control flow and side-effect evaluation order. Do **not** lower a declarative view into eager `Node.new`/`add_child` calls.
4. Extend existing T09-A observable properties to signal + getter read capture. Keep deterministic ordinary GDScript and range maps; let Godot native semantic validation remain authoritative.
5. Optionally use **React Compiler-inspired** automatic memoization/static subtree reuse later, but never require Gogo authors to add memo hooks. Avoid a giant new HIR/SSA optimizer unless profiling demonstrates a real need.

**Runtime (Godot-native GDScript):**
1. Manage an external per-mount computation/reconciliation context, subscription set and virtual element records.
2. Subscribe to observed signal sources weakly, schedule affected component rerenders, coalesce, reconcile by type/position/key and commit only true native changes.
3. Respect Node2D/Node3D, ordinary Node boundaries, native signals/lifetime, game state and existing shared layout coordinator.
4. Dispose/rebuild only managed boundaries on unmount/reparent/reload; never attach fiber/reconciliation metadata to user Nodes.

This is **one compositional engine**. F04 removes T09-B's static path compiler and target-owned binding helpers, generated reader/source methods and eager output branch. Active tests/examples now use the description manager; T09-A signals and native UI/layout behavior remain. See [removal/parity inventory](F04_CUTOVER.md). Earlier phase evidence remains historical.

## 11. Delivery plan and migration gates

These are serial work packages with **one open PR repo-wide**; the live issue/PR and merged tests determine each stage’s actual completion. A docs-only architecture PR precedes new Codex implementation work.

1. **F01 — Minimum end-to-end spike:** prove generated getter read tracking and signal scheduling (with explicit fallback decision only if a documented Godot gap exists), a one-component virtual description render, initial mount, one event-triggered rerun, native Node identity retained, and safe update timing. Real Gogo Counter, not an abstract JavaScript simulation. Validate on official 4.0.4/pinned 4.7.0 Linux. Define the exact public source convention/type contract. If proof exposes serious complexity, report it before building more machinery.
2. **F02 — Reconciler and conditional GGX:** implement structural children/conditionals with GDScript syntax, typed descriptors, type/position/optional key matching, selective props/handlers, deep nested component scopes, parent-first scheduling, null/model replacement and cleanup. Test preserving unchanged Nodes/animations/foreign children, nested branch changes and safe commit/rollback.
3. **F03 — Maps and keyed lists:** support ordinary GDScript for/map-authored descriptions, arrays/flattening and stable keyed moves/inserts/deletes. No mandatory Repeater. Key diagnostics, item-state identity and nested list/conditional tests. Start with observable reference replacement; add an optional in-place observable list adapter only if genuine product acceptance requires it.
4. **F04 — Single-runtime cutover:** migrate all live Gogo examples, compiler/emitter, runtime binding helpers and editor/distribution tests to declarative virtual descriptions and native reconciler. **Delete** superseded eager GGX creation, property-binding helper Nodes, duplicate dispatch/subscription code and obsolete tests; no dual mode, deprecation period or compatibility shims. Retarget Counter/reactive/2D/3D and packed scene/editor acceptance without weakening meaningful behavior.
5. **F05 — Model ergonomics and controlled inputs:** deliver separately tracked [class-level `@bindable` #90](https://github.com/resistdesign/Estragon/issues/90) with exact class grammar, then T09-D two-way adapters/feedback/cycle controls and a real input component; keep scope serial and focused. Optional serialization/hydration only by independently approved task.
6. **F06 — Profile then optimize:** use instrumented render counts, element allocations, native new/free/move counts, layout/paint work, subscription counts and memory/leak checks. Profile representative inventory (nested lists, reorders), HUD (frequent property changes) and 2D/3D scenes. Memoize only where measurements warrant; avoid optimizing every frame/field by default.

**Every implementation slice:** a scoped GitHub issue, mini-plan/checkpoints, one PR for owner review, reproducible Godot-native tests, no auto-merge. Verify **only official 4.0.4 and pinned 4.7.0 on Linux CI**, proportionate acceptance rather than unnecessary matrices. Preserve Godot-only no-tools editor F5/F6 and strict current-addon distribution/release evidence. New contributor automation uses TypeScript/Yarn, no Python. Recompute real graphics captures when relevant. Keep test evidence truthful: no stale FAIL relabeled PASS.

**Completion means:** changing observed model state automatically reruns only relevant Gogo component(s), updates properties/conditionals/lists without author hooks, preserves compatible actual Node instances and game state, never renders/diffs per frame, has no reconciliation metadata on user Nodes, and no obsolete parallel runtime or compiler path remains.

## 12. What we deliberately reject

- Requiring React hooks or immutable tree replacement in Godot.
- A giant global synthetic scene graph of actual Nodes, per-frame virtual render/diff, full-scene rerender or React's browser DOM rules.
- Denying that element descriptions/keys/reconciliation are a Virtual DOM: they are.
- Special-purpose duplicate runtimes for property bindings versus structural/collection bindings.
- Metadata or tracking helper Nodes on every application Node/component/object.
- A mandatory Repeater widget or deep observable wrapper on every imported JSON document.
- Building an elaborate compiler HIR/SSA/memo optimizer before the readable baseline proves adequate.
- Preserving compatibility with pre-release framework APIs or retaining legacy paths merely because tests used them.
- Claiming that arbitrary Godot properties/arrays can emit signals automatically, or that native Resource.changed fires for custom fields without generated/accessor behavior.

## 13. Reference designs (lessons, not dependencies)

- [React: rendering and committing](https://react.dev/learn/render-and-commit), [component identity and keys](https://react.dev/learn/preserving-and-resetting-state): readable functions, desired vs committed output, native instance retention.
- [React Compiler introduction](https://react.dev/learn/react-compiler/introduction), [design goals / HIR](https://github.com/react/react/blob/main/compiler/docs/DESIGN_GOALS.md): memoization without author annotations; re-render bound is more important than theoretical perfect minimal computation.
- [Svelte 5 $effect](https://svelte.dev/docs/svelte/%24effect), [compiler](https://svelte.dev/docs/svelte/svelte-compiler): fine-grained dependency collection, batched updates, nested effect lifetimes and compiled conditional/each blocks. Inspiration for future optimization rather than obligatory extra abstractions.
- [Solid: fine-grained reactivity](https://docs.solidjs.com/advanced-concepts/fine-grained-reactivity): signal reads/subscriptions and update scopes; note that Solid's component function behavior differs from our intentionally React-like rerunnable component baseline.
- [Godot 4.0 Node](https://docs.godotengine.org/en/4.0/classes/class_node.html), [GDScript properties](https://docs.godotengine.org/en/4.0/tutorials/scripting/gdscript/gdscript_basics.html), [Resource.changed](https://docs.godotengine.org/en/4.0/classes/class_resource.html): real ownership, native setters/getters and the limits of auto-observation.

**Authority:** [ADR-0016 in DECISIONS](DECISIONS.md#adr-0016--signal-driven-function-recomposition-with-retained-native-nodes); this document is its detailed contract. Existing documentation of shipped T09-A/T09-B behavior remains accurate historical/current implementation evidence until migration is complete, but does not override this new target.
