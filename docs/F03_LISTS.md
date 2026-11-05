# F03 — native child sequences and keyed retained lists

[F03 #96](https://github.com/resistdesign/Estragon/issues/96) extends merged [F02](F02_CONDITIONALS.md) inside the same compiler, description and external computation manager. The live issue/sole PR contains actual verification and review state. F04's eager/helper cutover, F05 models/two-way binding and F06 optimization remain separate future work.

## Authoring and observation

In an explicitly typed `build_view() -> Element`, GGX produces cheap descriptions. Ordinary GDScript loops and `Array.map` can build children:

```gdscript
var rows: Array = []
for item in items:
    rows.append(<Row key={item.id} item={item} />)
return <VBox>
    <Text text="Inventory" />
    {rows}
    <Text text="Ready" />
</VBox>
```

`Row`, `VBox`, `Text` and `Element` are normal explicit preload aliases; the runnable example is `examples/inventory/Inventory.gogo`. `items.map(func(item): return <Row key={item.id} item={item} />)` inside the view function is equivalent. GGX in ordinary functions outside the composition function retains its existing eager semantics until F04; do not use an eager factory as a description mapper.

Child expressions accept one Element, null, an Array or nested Arrays of those values. Flatten left to right; empty lists allocate nothing and null creates a positional hole. Attribute/child expressions evaluate in native lexical order, with normal lazy conditional evaluation. Scalars, Dictionaries, live Nodes and Resources are not descriptions. Statically obvious invalid leaves/keys reject at authored spans; dynamically computed Variant results are completely validated before a commit. Cyclic or excessively deep child sequences reject at a bounded traversal depth of 128. There is no custom iteration syntax, runtime markup parsing or candidate native tree.

A bindable Array **reference reassignment** emits its ordinary property signal, even when the replacement has equal entries. For example `items = items + [new_item]` or duplicate/edit/reassign. Plain in-place `items.append`, `remove_at`, Array element edits and Dictionary mutations do not inherently notify. No proxy or mandatory collection wrapper is supplied. Read item fields in independently composed rows to subscribe only that row; a retained row does not rerun merely because its parent recomposed.

## Sibling identity

`key` is reserved composition identity, never a native property or metadata. It accepts an integer or nonempty String; explicit null, bool, float, StringName and Object reject. Equality includes the type: integer `1` and String `"1"` differ. Keys must be unique across the complete flattened real sibling set, including separate/nested list expressions and static/conditional children. They are scoped to their real desired parent, not globally. Omission means unkeyed positional identity; there is no required-key warning or inferred model key.

Unkeyed children match the authored child-slot plus nested Array index path. Changing a preceding list's length cannot shift a static footer's identity. Null preserves its position; an empty Array contributes no child. Unkeyed list entries follow index identity, so use explicit stable keys when item state must travel during insert/reorder. Keyed children match by key then native type regardless of their old slot. A key change or same-key/different-type output replaces the old branch. Keyed and unkeyed records never consume each other's identity. Reusing a key under a different parent remounts in that parent's scope.

## Commit and lifetime

The existing manager normalizes to a private desired snapshot, validates the entire tree and sibling key/name sets, and preflights property/signal/Callable/constructibility metadata and foreign-node destinations before native edits. Matching by the same key/path contract drives validation, foreign rescue and commit. Failure retains the previous native tree, declared snapshots and subscriptions; repairing source data can retry through the retained observer. Runtime rejection reports the composition boundary; compile-time diagnostics retain authored ranges/maps.

Unmatched/type-changed branches are disposed before mounting replacements. Retained Nodes receive only changed declared props/handlers. Desired snapshots preserve native animation/state for unchanged declarations. Managed sibling order uses a longest increasing subsequence of actual indices, moving each remaining child once in deterministic reverse order. A no-op does no native writes, allocations, frees or moves. Existing row computations/read sets remain independent; removed branches cancel queued descendants and disconnect once. No reconciliation fields/helper Nodes/set_meta are attached to application Nodes, models or Resources.

F02's native detach/reparent/free, foreign-child rescue and collision protection, owner/PackedScene transient-output policy, signal cleanup, native transforms and composed affected-branch layout still apply. Managed output has `owner=null`; pack authored hosts/foreign objects and reconstruct current desired output on mount. There is no universal rollback for side effects in arbitrary application constructors/setters/native callbacks. Composition remains repeatable; mutate source data in ordinary events/lifecycle methods.

## Runnable proof and evidence

Run `examples/inventory/Inventory.tscn`: append, middle insert, remove, reverse, replace, increment the first row's state, rename its model, toggle the conditional note and switch for/map authoring. Row state and native IDs travel with keys. Static title/footer survive structural updates.

`tools/check-lists.ts` verifies Godot-native source build/import, native IDs/allocations/frees/moves/state/observation/lifetime/preflight, invalid-output rejection and repair, real saved/unsaved main/current editor Play rollback/repair, and rendered initial/changed/reordered/resized captures. The strict addon gate, fresh/source-only cold builds and bare-process exported pack include the inventory. Focused CI mode `lists` uses one approved Linux engine; final acceptance uses only official 4.0.4 and pinned 4.7.0. Exact source/engine hashes, commands, stage counts, failures and manual-smoke status belong to #96/its sole PR. Automated editor/rendering evidence does not claim manual interactive smoke or untested engine/platform certification.
