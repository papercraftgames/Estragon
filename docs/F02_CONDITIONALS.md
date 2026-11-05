**F03 implementation:** [Child sequences and keyed lists](F03_LISTS.md) / [#96](https://github.com/resistdesign/Estragon/issues/96) extends merged F01/F02 with native for/map descriptions, nested Array flattening and sibling-scoped retained keys. Live issue/sole PR records verification and review; F04 cutover and F05/F06 remain future. Earlier stage-specific restrictions below describe their original boundaries.

# F02 — conditional children and nested native composition

[F02 #94](https://github.com/resistdesign/Estragon/issues/94) extends merged [F01](F01_COMPOSITION.md) in the same descriptor/getter/record engine. Live issue/sole PR records exact acceptance and review state. General keys/arrays/mapping (F03), final eager/T09-B helper removal (F04), class-level/two-way (F05) and profiling (F06) remain unimplemented.

## Source contract

In an explicitly typed `build_view() -> Element`, a braced child is a single GGX description or null, optionally selected by native GDScript conditional expressions:

```gdscript
return <EstragonVBox>
    <EstragonText name="Before" text="Retained" />
    {<EstragonButton name="Action" text="OK" pressed={act} /> if count > 4 else <EstragonText name="Prompt" text="Not yet" />}
    {<EstragonRect name="Bonus" height={8.0} /> if show_bonus else null}
    <EstragonText name="After" text="Still the same Node" />
</EstragonVBox>
```

Parentheses and nested `A if condition else B` choices are supported, including conditional children inside conditional subtrees. Conditions use normal GDScript lexical scope/operators/helper calls and generated getter observation; only the chosen branch evaluates its attributes. Result leaves must be inline GGX or null. Arbitrary result helper calls, scalars, live Nodes and arrays reject explicitly; helper calls in conditions/attribute values remain ordinary GDScript. This bounded result validation closes Godot's mixed-Variant ternary conversion loophole before Play. There is no JavaScript ternary parser, source regex rewriting or runtime markup interpretation. Typed factories and source maps retain native property/Callable validation. Explicit named preload aliases remain ordinary imports.

Each authored child is a **stable slot**, including null holes. Match same type at that slot; remove/mount only the changed slot. Null is not compacted out before matching, so an optional child cannot shift/remount static siblings after it. Active native children are placed in slot order with normal Node operations. **Keys are deferred to F03** and reject as reserved unsupported attributes. No general iterable/array flattening or separate keyed-list reconciler is supplied here.

Nested Gogo composition hosts are normal Node script types in descriptions. Their inputs are typed native properties; use explicitly typed Gogo declarations (`@bindable` for observed inputs). Cold metadata resolution reads authored declarations and their constructible Node base without running constructors or publishing partial scripts, then actual-path native semantic validation remains mandatory. Gogo data/resource values remain values rather than tree children. Authored mandatory constructor arguments reject; metadata discovery never constructs candidate Nodes.

## Scheduling, ownership and reconciliation

One framework-owned manager queues computations and processes external computation ownership depth (with native ancestry for independent roots), parents first. A retained child has its own dynamic read set and is not recomposed because the parent reran. A changed bindable input/own observed source schedules it. Before freeing a branch, nested computations are disposed and their subscriptions/queued jobs invalidated. Finite reentrant writes coalesce safely; no SceneTree mutations run recursively in source signal callbacks, and no per-frame render scan exists.

External mounted records hold type, weak actual Node identity, previous desired props/handlers and nullable slot records. Type-compatible Nodes retain native state, transforms and handlers. Desired values compare against the previous desired snapshot, never current animation/native values. **Removed declared props relinquish declarative control and leave the current native value alone**; reintroduction writes it as a new declaration. Removed/changed handlers disconnect exactly; unchanged Callables never duplicate. Existing setters distinguish redraw versus cached affected-branch measure/arrange; no extra layout engine or transform-authority policy is introduced.

Before destructive edits, the complete desired output is preflighted: valid Element/null slots; constructible Node/script target and zero required constructor args; declared property/signal metadata and value kinds; valid named Callables; duplicate sibling names and conflicts with foreign children at managed boundaries. Known static name/key/result errors reject at authored compilation. Runtime-dependent name/output conflicts reject before commit, retaining the previous branch and subscriptions. Preflight also accounts for foreign descendants that a removal would rescue to the surviving host, rejecting destination-name collisions before freeing the branch. No candidate Nodes are instantiated for preflight. Arbitrary user constructors/setters/native callbacks are application code: there is no promise of rolling back external side effects or allocations if those callbacks fail after validated commit starts. Composition must remain repeatable and source-data mutations belong in ordinary lifecycle/events.

Managed dynamic output remains transient `owner=null`. PackedScene persists authored hosts/foreign objects by ordinary owner rules and recomposes transient output once on reload. Branch removal frees its record-owned descendants and nested computation-owned views; genuine foreign descendants are moved to the surviving host, preserving an owner if still an ancestor. Foreign objects outside the region are untouched. Native host detach/reparent/reattach suspends/reconnects without extra observers; host deletion cancels deferred work. A surviving record-owned Node moved elsewhere is returned to its declared parent on the next owning commit; an externally freed owned slot remounts once. Logical computation ownership retains parent-first order even while a managed child is temporarily reparented outside its native ancestor. This does not adopt arbitrary live Nodes as expression children or promise universal foreign-node conflict repair.

## Demo and proof

Run `examples/conditional/Counter.tscn` with the bundled addon enabled. `+` changes Prompt → Action, bonus toggling creates/removes a nested branch, and the nested-component toggle mounts/unmounts an independently observed child. All author code uses ordinary assignments, no refresh/subscription/rebuild calls. Before/after siblings retain IDs, and the same native layout core arranges the changed branch.

`tools/check-conditional.ts` runs native source build/import, runtime transitions/IDs/allocations/frees/moves/lifetime/model-switch/preflight tests, real saved/unsaved main/current Play invalid/unsavable rejection with transactional code/map/UID/timestamp/cache rollback and repair, and renderer-backed initial/changed/resized captures. Strict addon and fresh/cold/pack checks include the F02 scene and preserve F01/T09-A/B/current 2D/3D/native UI evidence. Focused workflow mode `conditional` selects an approved Linux engine. Final acceptance uses only official 4.0.4 and pinned 4.7.0, with exact commands/clean source/engine hashes and manual-smoke status recorded on #94/its sole PR. C01-E's measured diagnostic capability bridge remains; actual-path rejection/rollback is mandatory on both.
