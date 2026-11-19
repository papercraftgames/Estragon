# Estragon: current architecture, reality check, and core-first roadmap

**Snapshot:** November 18, 2026, after the owner merged [EL02 PR #193](https://github.com/papercraftgames/Estragon/pull/193) (merge commit `21794a057b626c92bb079cf369faf8953a427c60`).  
**Reconciliation tracker:** [#194](https://github.com/papercraftgames/Estragon/issues/194).  
**Status:** Project-state and issue-plan baseline. This file states what has been delivered, what remains missing, and the chosen priority order. **New scoped issue series: #195–#209.** It is **not** a claim that future work is implemented.

## 1. Product direction and rule of interpretation

Estragon is a pre-1.0 alpha/beta **native Godot addon**. Gogo is its GDScript-like language; GGX is XML-like markup for composing Godot Nodes. Estragon builds layout-first Node2D UI plus bounded Node3D layouts/adapters using the actual Godot SceneTree, signals, editor, renderer, input facilities and ownership. The addon bundles its own compiler/editor integration, with no external authoring compiler.

The repository documents public npm **beta** packages and a working tag-based release workflow; that is not a claim that Estragon has shipped a stable product or locked its API. **Do not spend engineering effort on source/binary compatibility with earlier alpha/beta releases.** When a current API is wrong, replace it cleanly, adjust all live examples/tests/docs, and delete obsolete shims. Preserve meaningful product behavior, native reliability, source maps and exact packaging integrity—not accidental historical naming.

**Development preference:** finish foundations, correctness and supporting mechanisms before visual novelty, broad syntax sugar or a bespoke designer. Make forms usable early; make Gogo formatting useful now. Avoid turning architecture audits into repeated indefinite design projects. Every successor is a bounded implementation issue with end-to-end tests and a single owner-review-ready PR.

This baseline supersedes obsolete execution *status and ordering* in older umbrella issues. Accepted current architecture remains governed by [ADRs 0015–0030](DECISIONS.md), [current implementation](ARCHITECTURE.md), [layout contracts](LAYOUT_FOUNDATION.md), [current Gogo](GOGO_LANGUAGE.md), [reactivity](REACTIVE_GGX.md), and [AGENTS.md](../AGENTS.md). Where a historical source disagrees with the merged code, **the current merged implementation and real test behavior win**.

## 2. What is already working

| Area | Delivered current contract | Important boundary |
| --- | --- | --- |
| GGX/Gogo | Native source-mapped compiler for typed GDScript/GGX, expressions, normal methods/helpers, imported and discovered project components, nested/conditional descriptions, mapped Arrays, ordered props spreading, Boolean shorthand and String bodies. Editor save/Play validates actual paths, rejects stale/invalid source and repairs transactionally. | Not JavaScript/React/DOM, no mandatory external compiler; editor is not a full native GDScript language substitution. |
| Rendering/composition | GGX yields lightweight Element **descriptions**. External retained reconciler mounts/updates **real** Godot Nodes using type/position/key. Existing native Node IDs and behavior are preserved when possible. | No duplicate live Node tree, hooks, per-element binder Nodes, Node metadata/fibers or frame polling. |
| Reactivity | Typed Gogo `@bindable` fields and class-wide eligible fields emit native change signals. Dynamic getter reads in `build_view()` and helpers determine subscriptions. Nested components have independent computation scopes. | Not every native Godot field or Array/Dictionary mutation is observable. `bind:value` currently covers the typed Bool Toggle path. |
| Structure | Ordinary GDScript loops/`Array.map`, nested Arrays/null slots, keyed sibling reconciliation, move/insert/delete and model replacement; current F06 profiling improved reorders and established idle-zero work. | An in-place `items.append()` does not notify a bindable Array property; assigning a new Array reference does. |
| 2D layout | One parent-owned measure/arrange coordinator and mathematical core; Box/HBox/VBox, grow/stretch/align, Wrap, Grid tracks/auto/`fr`/spans/named areas, padding/margins/gaps, minimums, length units, viewport/containing-box percentages, inherited scroll/clipping. | Unanchored percentages and intrinsic-size feedback have bounded limits. No universal size for arbitrary Nodes; no generic 3D Wrap/Grid promise. |
| Layout declarations | Merged EL02 `layout const/var` introduces case-sensitive reusable root and area component presets, nested reuse, sequential lexical shadowing, default props/merging, same-name spanning regions and native Grid/row/column mode override. | A declaration mounts nothing; use its root (for example `<Base>`). `width="25%"` is **not** a track declaration. Grid child percentages refer to the full parent Grid content, not individual grid cells. |
| UI/styling | Native Estragon Rect/Text/Button/Toggle, local surfaces and borders/text foreground, opt-in visual clipping, inherited scrolling, native Control adapter/borrowed Scene-dock children. Godot native Controls may be composed directly. | No complete Estragon-owned text entry, Checkbox, keyboard/focus and IME system or comprehensive form family. No CSS cascade. |
| Editor | Gogo source editing, highlighting/completion, component discovery/imports, diagnostics, script creation, Play gates and normal Godot Scene dock interaction with authored native children. | **No working Gogo-specific format/auto-indent command.** Generated GGX children are not yet fully authored/arranged as edit-time manipulable 2D scene geometry. |
| Packaging | Curated addon package through Yarn, public npm betas, verified tag-overlay versioning and bounded CI/release integrity gates. Recent #193 required CI finished in 37 seconds. | No stable-release compatibility promise; explicit 4.0.4 export cleanup and isolated editor shutdown leak investigations remain historical observations, not automatically current regressions. |

**Source anchors:** [current architecture](ARCHITECTURE.md), [reactive GGX](REACTIVE_GGX.md), [mapped children](F03_LISTS.md), [F06 profile](F06_PROFILING.md), [two-way Bool](TWO_WAY_BINDINGS.md), [layouts](RESPONSIVE_LAYOUT.md), [EL02](LAYOUT_DECLARATIONS.md), [scene children](SCENE_CHILDREN.md), [editor](EDITOR.md), [native styling](STYLING.md), and [release](CI_PERFORMANCE.md).

## 3. Reactivity: what actually happens, and the remaining questions

### Existing authoritative execution cycle

1. An actual model assignment to a generated, typed `@bindable` property updates its value **synchronously** and emits its native property-change signal according to the current equality rule.
2. During `build_view()`, every generated bindable getter read is recorded by the shared manager's active scope. Reads inside called helper functions and conditional branches participate. Replaced/null models and changed branches cause stale subscriptions to detach on the next successful composition.
3. A relevant signal queues **the observing component computation**, not a global UI redraw. Scheduling is deferred/coalesced through `state.gd`; the dirty queue is drained parent-first and reentrant render mutations are bounded. A setter does **not** guarantee immediately updated rendered Node properties in the same synchronous call stack.
4. The computation reruns its declarative function and builds an Element description. The runtime validates/preflights the desired tree before making native edits; reconciler records compare previous properties/handlers/children. Unchanged retained native Nodes remain mounted, with matching keys preserving list identity.
5. Native layout invalidates and measures/arranges only affected branches. Godot paints through native drawing. Once idle, tests/profile evidence report no repeated GGX composition, Node structural changes or layout passes.

**No hooks, manual render invocation, `setState`, per-frame VDOM loop, mandatory immutable model, shadow live Godot tree or app-side component refresh calls.** Composition functions should be repeatable and free of side effects; effects belong in normal Godot callbacks/handlers/lifecycle.

Current source: `addons/estragon/runtime/composition/state.gd`, `computation.gd`, `binding.gd` and `docs/REACTIVE_COMPOSITION_ARCHITECTURE.md`. The manager currently uses a deferred queue and sort by computation depth; it guards against unbounded self-invalidation.

### Are there computed regions?

**Not as a separately documented or publicly supported computed-region/memo primitive.** Ordinary **derived values** already work in declarative computations: for example a pure helper reading bindable fields computes its result when its owning view runs, and the getter observations automatically subscribe that view. Nested Gogo components create independent rerun boundaries.

That is **not** the same as a separately cached, graph-aware computed signal, subexpression cache, memoized dependency cell, or source-level reactive region. No such new abstraction is justified merely because another framework names one. Before considering one, prove a real use case requiring derived values reused outside views, selective invalidation across several consumers, or expensive derivation that currently reruns unnecessarily. Prefer a minimal property/derived-value facility sharing the current signal graph over a second effects scheduler.

### Verified gaps/risks, not claims of failure

- **Raw in-place collection operations do not signal:** `Array.append`, index mutation and Dictionary edits do not automatically trigger recomposition. A bindable reference replacement and ordinary keyed maps **are shipped**. Determine whether a lightweight optional observable collection or generated mutation adapter actually improves ordinary authoring and correctly emits structural changes.
- **`bind:value` is Bool-only:** String text editing requires typed String endpoint support and proper model-to-view/edited-view-to-model ownership, identity, replacement/null/cycle guards. Do not invent a second data-binding engine.
- **Ordinary native properties are not automatically tracked:** they require generated Gogo bindable getters or an explicit supported signal adapter. Do not claim arbitrary Godot property reads have observability.
- **Scheduler quality, derived granularity and event order deserve a focused hardening gate:** test burst writes, chained derived reads, nested parent/child invalidation, list reorder, reentrant writes, source replacement, skipped/failed commits, removal, and idle work. Check no lost last write, double connections, redundant descendant reruns or accidental repeated layout. Evaluate measurements before adding memoization.
- **Error path:** if a new desired tree is invalid, previously committed native output remains. Ensure subsequent valid changes and subscription recovery are predictable.

**Decision:** one targeted reactive-runtime/derived-state contract issue first; observable collections can be a separate small successor. Do **not** reopen F01–F06 as if unimplemented, rewrite the reconciler without evidence, or assume a new `computed` keyword is mandatory.

## 4. Layout: what is architecture versus missing features?

Estragon **already has its layout architecture**: parent-owned measured border-box **slots**, common unit resolution, inner content rects, margins/padding, min/fixed/intrinsic participation, growth and physical-axis alignment, one coordinator, affected-branch cached measure/arrange and real native placement. Box row/column/Wrap/Grid are strategies over that foundation. Gogo hosts bridge managed roots into a parent layout; ordinary Node boundaries and native Controls have defined authority.

Already shipped: L01, L06, L07A, L07, L08, L09–10, EL02 (check [layout foundation](LAYOUT_FOUNDATION.md), [responsive Grid](RESPONSIVE_LAYOUT.md), [declarations](LAYOUT_DECLARATIONS.md)). The old [#58](https://github.com/papercraftgames/Estragon/issues/58) is principally historical research, **not an instruction to rewrite layout**.

Actual possible gaps, to tackle narrowly:
- **Constraint-aware intrinsic text measurement:** available width changes text line breaks; natural height must recompute accurately without loops, stale font metrics, clipped text or whole-tree measuring. This connects directly to Input/text components.
- **Hard cases in nested auto/percent/min/max tracks and overflow:** verify two-pass or bounded measure needed when size depends on allocation. Preserve one core and avoid ungrounded CSS emulation.
- **Absolute/out-of-flow placement and transform authority:** define interaction with native Node2D/3D transforms, reactive x/y offsets, hit testing and parent flow. This was #88; do not add a second layout engine.
- **3D feature boundaries:** current 3D layout is bounded; do not claim 2D Wrap/Grid or text UI is automatically 3D. Only add a separately motivated capability.

### Exactly what “Advanced EasyLayout” is missing

**Not missing:** named cells, rectangular validation, spanning, rows/columns/`fr`/`auto` tracks, compact Grid templates, reusable/nested named-area declarations, exact-case areas, preset props, or Grid/row/column mode switching. The recent manual nested-layout screenshots prove basic composition works.

**Potential genuine gap:** choosing **alternate area/track templates from a layout container's actual allocated width/height**, with stable breakpoint rules and zero feedback loops. Today a caller may change observable template-related props, but Estragon does not have a documented declarative **container-responsive template recipe** that automatically adapts to allocated size. This is an optional follow-up once sizing constraints are stable. A separate “EasyLayout engine” would be architectural duplication.

**Not a core gap:** a custom drag/drop visual EasyLayout designer. Prefer first exploring the existing Godot Scene dock + 2D editor as the authoring surface. Estragon already uses real native Nodes, editor-owned saved scenes and borrowed scene children. Investigate safe edit-time previews and authored-vs-generated source/ownership. **Never assume the editor must output GGX** or round-trip a graph back to Gogo; compare node-authored scene compositions, Gogo-authored dynamic views and a deliberate hybrid. Only design code generation if concrete source-of-truth semantics make sense.

## 5. Controls, editing and product-completeness gaps

**Gogo formatting is essential and immediate.** CodeEdit needs a useful `Format Gogo` / auto-indent command for mixed GDScript+GGX, nested tags, multiline props and expressions; preserve arbitrary unsaved source, Undo/Redo, caret/selection, comments, indentation conventions and deterministic/idempotent output. Avoid a JS/Python/Node external formatter or regex-only destructive rewrites.

**Native form controls are next.** Start with shared event/focus/keyboard ownership, then ship a real Estragon-owned Checkbox (distinct appearance from Toggle) and an actual editable Input. Input must cover user edits, caret/selection/clipboard, focus, repeat/key events and IME where supported, plus typed String `bind:value`. Reuse proven native Godot platform text editing facilities where it is architecturally sound; test before choosing a hidden native delegate or fully custom editor. Keep Estragon responsible for its own layout, presentation and events; never call a decorative rectangle a complete Input.

After that, fill deliberate missing text/intrinsic-layout, additional common form controls, accessibility and polish. Existing native Godot LineEdit/CheckBox/Controls remain available as a practical integration path; they are not proof Estragon's own API is complete.

## 6. Core-first dependency order — new actionable issues

These are **15 individually filed, priority-numbered tasks**. Their issue bodies hold implementable acceptance and proof. Only one PR can be open, owner merges, and numbering is not permission to start several simultaneously.

| Order | Issue | Work package | Rationale/dependency |
| --- | --- | --- | --- |
| 1 | [CORE-01 #195](https://github.com/papercraftgames/Estragon/issues/195) | Reactive execution, derived calculations and selective scheduling | First correctness gate. Confirm no need for separate computed-region runtime. |
| 2 | [EDIT-01 #196](https://github.com/papercraftgames/Estragon/issues/196) | Native Gogo formatter and safe GGX indentation | Urgent authoring foundation; independent of forms. |
| 3 | [UI-01 #197](https://github.com/papercraftgames/Estragon/issues/197) | Focus, keyboard and text-edit delegate infrastructure | Unblocks real form input and Checkbox. |
| 4 | [UI-02 #198](https://github.com/papercraftgames/Estragon/issues/198) | Estragon Checkbox | Depends UI-01; reuses Bool model binding. |
| 5 | [UI-03 #199](https://github.com/papercraftgames/Estragon/issues/199) | Editable Input + typed String bind:value | Depends CORE-01/UI-01. |
| 6 | [CORE-02 #200](https://github.com/papercraftgames/Estragon/issues/200) | Observable collection mutation and keyed mapped updates | Reuses one manager; no required Repeater. |
| 7 | [LAYOUT-01 #201](https://github.com/papercraftgames/Estragon/issues/201) | Constraint-aware text/intrinsic measurement and nested auto sizing | Existing slot core, no rewrite. |
| 8 | [UI-04 #202](https://github.com/papercraftgames/Estragon/issues/202) | Radio/choice selection controls | After focus/input foundations. |
| 9 | [UI-05 #203](https://github.com/papercraftgames/Estragon/issues/203) | Select, Slider and numeric controls | After common choice/value semantics; split before implementation if needed. |
| 10 | [LAYOUT-02 #204](https://github.com/papercraftgames/Estragon/issues/204) | Out-of-flow placement and native transform authority | After measurement contracts. |
| 11 | [TEXT-01 #205](https://github.com/papercraftgames/Estragon/issues/205) | Text wrapping/shaping/fallback and accessibility essentials | Crosscuts controls and layout. |
| 12 | [RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206) | Current-source alpha package/export/publication readiness | After core UI; no retro compatibility or automatic publish. |
| 13 | [LAYOUT-03 #207](https://github.com/papercraftgames/Estragon/issues/207) | Container-responsive named-area template recipes | The actual optional Advanced EasyLayout gap; later. |
| 14 | [EDIT-02 #208](https://github.com/papercraftgames/Estragon/issues/208) | Native Godot 2D/Scene authoring integration | Prototype source-of-truth; not presumed GGX generator. |
| 15 | [GOGO-01 #209](https://github.com/papercraftgames/Estragon/issues/209) | Remaining targeted GGX ergonomics | Late, and only if concrete productivity value. |

**Phases:** 1–7 core execution/editor/forms/data/measurement; 8–11 core control/text/position completion; 12 distribution quality; 13–15 optional adaptive/visual/syntax authoring. The next work is [CORE-01 #195](https://github.com/papercraftgames/Estragon/issues/195); urgent formatter [#196](https://github.com/papercraftgames/Estragon/issues/196) follows. A later issue may be intentionally skipped or split if evidence shows it adds no value, without reopening the old umbrella issues.

## 7. Old open issue reconciliation ledger (pre-reset)

**Twenty pre-reset open issues**, verified November 18; the [#194 tracker](https://github.com/papercraftgames/Estragon/issues/194) is new and excluded. Closure means **completed/superseded/absorbed into the fresh plan**, not that every historical checklist and feature was proved complete. Historic failures remain historic evidence; new reproducible bugs may be reopened as focused new issues.

| Old issue | Decision | Successor/retained context |
| --- | --- | --- |
| [#1](https://github.com/papercraftgames/Estragon/issues/1) old separate retained display tree | Close: architecture superseded | Native Node2D/Node3D + lightweight desired descriptions, not old self-rendering display list. |
| [#2](https://github.com/papercraftgames/Estragon/issues/2) self-renderer research | Close: original premise superseded | Godot rendering-native; revisit only measured backend needs, not as general UI roadmap. |
| [#3](https://github.com/papercraftgames/Estragon/issues/3) huge UI umbrella | Close: replace | [UI-01 #197](https://github.com/papercraftgames/Estragon/issues/197)/02/03/04, [LAYOUT-01 #201](https://github.com/papercraftgames/Estragon/issues/201), [TEXT-01 #205](https://github.com/papercraftgames/Estragon/issues/205). |
| [#5](https://github.com/papercraftgames/Estragon/issues/5) T09 umbrella | Close: foundational F01–F06 already merged | [CORE-01 #195](https://github.com/papercraftgames/Estragon/issues/195)/02 and [UI-03 #199](https://github.com/papercraftgames/Estragon/issues/199) typed String binding. |
| [#6](https://github.com/papercraftgames/Estragon/issues/6) broad Gogo editor | Close: mostly delivered, leftovers scoped | [EDIT-01 #196](https://github.com/papercraftgames/Estragon/issues/196)/02, [GOGO-01 #209](https://github.com/papercraftgames/Estragon/issues/209). |
| [#37](https://github.com/papercraftgames/Estragon/issues/37) E01 highlighting | Close: merged PR #40, accepted exception | No broad rerun; report a new reproducible issue if encountered. |
| [#41](https://github.com/papercraftgames/Estragon/issues/41) broad historical compatibility | Close: reframe | Current 4.0.4/4.7 native acceptance and [RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206); no beta API compatibility debt. |
| [#45](https://github.com/papercraftgames/Estragon/issues/45) old C01-B sizing | Close: merged PR #53 | Old acceptance residuals no longer govern current Node runtime. |
| [#51](https://github.com/papercraftgames/Estragon/issues/51) C01-H distribution gate | Close: reframe | [RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206) using *current* P04/CI02 and source-bound certification. |
| [#58](https://github.com/papercraftgames/Estragon/issues/58) layout research | Close: delivered foundation | [LAYOUT-01 #201](https://github.com/papercraftgames/Estragon/issues/201)/02/03 only where genuinely missing. |
| [#65](https://github.com/papercraftgames/Estragon/issues/65) 4.0.4 sample export cleanup | Close: historical targeted follow-up | [RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206) should first reproduce on current source, then fix if real/current. |
| [#68](https://github.com/papercraftgames/Estragon/issues/68) ADR-0015 migration | Close: accepted and subsequently implemented | Retain ADR and current ARCHITECTURE, no legacy conversion work. |
| [#88](https://github.com/papercraftgames/Estragon/issues/88) transform authority | Close: replace | [LAYOUT-02 #204](https://github.com/papercraftgames/Estragon/issues/204). |
| [#109](https://github.com/papercraftgames/Estragon/issues/109) routine CI ≤60s | Close: objective demonstrated | Keep 60s policy and release gate; new bug if concrete regression. |
| [#117](https://github.com/papercraftgames/Estragon/issues/117) old beta release | Close: superseded by P04 | [RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206), fresh tag/source-based release only. |
| [#130](https://github.com/papercraftgames/Estragon/issues/130) formatter | Close: replace, **still urgent** | [EDIT-01 #196](https://github.com/papercraftgames/Estragon/issues/196). |
| [#148](https://github.com/papercraftgames/Estragon/issues/148) isolated editor shutdown leaks | Close: historical investigation, not proved production bug | [CORE-01 #195](https://github.com/papercraftgames/Estragon/issues/195)/[RELEASE-01 #206](https://github.com/papercraftgames/Estragon/issues/206) targeted reproduction if leakage persists. |
| [#182](https://github.com/papercraftgames/Estragon/issues/182) TSX-like Gogo umbrella | Close: already shipped many items | [GOGO-01 #209](https://github.com/papercraftgames/Estragon/issues/209) only for remaining confirmed ergonomic gaps. |
| [#189](https://github.com/papercraftgames/Estragon/issues/189) forms | Close: split into implementable work | [UI-01 #197](https://github.com/papercraftgames/Estragon/issues/197)/02/03/04. |
| [#190](https://github.com/papercraftgames/Estragon/issues/190) EasyLayout/design | Close: named-area/layout authoring delivered via #192 | [LAYOUT-03 #207](https://github.com/papercraftgames/Estragon/issues/207) responsive policy and [EDIT-02 #208](https://github.com/papercraftgames/Estragon/issues/208) native scene authoring study, if warranted. |

## 8. Implementation and review conventions

- **One active implementation PR in the repo**; owner reviews/merges. New issues are implementation targets, not automatic commands to start all of them. Create one issue-level mini-plan with exact acceptance and handoff for the chosen next issue.
- Standard reference and tests: current \`main\`, [AGENTS](../AGENTS.md), [architecture](ARCHITECTURE.md), source-mapped native compiler/runtime, direct Yarn installed addon, real Godot editor/Play, official Linux **4.0.4 and pinned 4.7.0** only for routine feature acceptance. Source-only/cold restart/UID/map tests remain proportional to the change.
- Routine PR/main CI **≤60 seconds**; independent measured release certification and exact-version artifact checks. No Python, contributor scripts TypeScript + Yarn. Do not publish or merge without owner action.
- Remove alpha/beta compatibility shims if architectural cleanup requires it. Preserve existing source and evidence history for audit, but don't carry obsolete milestones as live blockers.
- Test what matters: user-visible form operation, rendered geometry, true click/focus/IME where available, keyed retained Node state, **correct selective rendering and no idle work**, no hidden fallback/invalid-source execution. Do not demand heavyweight unit-test proliferation in place of meaningful integration tests.
- For scene/visual authoring, settle *where source of truth lives* before editing both authored scene Nodes and generated GGX. Native Godot tools may be the correct solution without a designer generator.

**Snapshot maintenance:** after owner merges this documentation PR, update the current handoff/status entry and follow the new issue sequence. This document is a durable consolidated baseline; do not backfill historical issues merely to make their checkboxes look green.
