# CORE-02: observable collections and typed plain data

Issue [#200](https://github.com/papercraftgames/Estragon/issues/200) implements the collection/data portion of ADR-0031 through the existing CORE-01 render cache and composition scheduler. The implementation is a review candidate until its owner-merged PR lands. See `examples/data` for the complete native Inventory gallery.

```gdscript
# Item.gogo
@bindable
extends RefCounted
var id: int
var name: String = "Unnamed"
var quantity: int = 1
```

```gdscript
# Inventory.gogo (preloads are relative to the generated output)
@bindable
extends RefCounted
const Item = preload("Item.gd")
var items: ArrayCollection[Item] = []
var selected: Item
```

```gdscript
const Inventory = preload("Inventory.gd")
var inventory: Inventory = {"items": [{"id": 1, "name": "Rope"}]}

func refill() -> void:
    inventory = {"items": [{"id": 2}]}
    inventory.items = [{"id": 3}]
    inventory.items.append({"id": 4})
    var plain: Dictionary = inventory.to_data()
```

`ArrayCollection[T]` is Gogo syntax lowered to one native RefCounted Script plus an element descriptor. It works on official 4.0.4; it does not require native user-defined generics. Elements can be typed Gogo data models, JSON scalar types, plain Arrays/Dictionaries, or nested collections. Model/collection references permit null. Strings, bools and numbers retain their declared type; integral JSON numbers hydrate int fields and integers hydrate float fields. Missing keys retain exactly the authored initializer or the native typed default, including null references. No field is implicitly required. Native typed Array fields also validate recursively and remain native Arrays.

The compiler wraps typed model/collection declarations, later assignments and member assignments rooted at typed locals, parameters or owned fields. Conversion happens before native property/call checks; the emitted properties remain natively typed. Lexical shadowing, source maps, ordinary native code and direct `.gd` imports retain their contracts. This does not rewrite arbitrary native `.gd`, Variant values, inferred variables or reflective `Object.set` calls. For an external native boundary, `runtime/data/state.tres.hydrate(value, Script)` returns `{ok, value}` or `{ok: false, error}`; inspect `ok` before publishing the value. No authored constructor, conversion protocol, cast, union or mapping function is needed in Gogo.

Class-level `@bindable` declares the eligible owned typed data shape. Generated `to_data()` recursively serializes its declared fields and collections into plain Dictionaries/Arrays. Untyped/static fields and native Object internals are not serialized. Ordinary imported `.gd` is not a data shape. Hydration constructs RefCounted/Resource data classes, not authored Nodes. Native vectors/resources/callables, unknown fields, non-finite numbers, invalid element types and cyclic plain data fail with a field/index path. An existing model/collection stays unchanged after a rejected assignment/reset; malformed declarations report an error and keep the native null default. Construction validates the complete replacement before publication and suppresses generated per-field initialization notifications. Authored initializers still execute normally. `to_data` and `_gogo_data_changed` collisions produce authored compiler diagnostics.

## Collection operations and notifications

`size()`, `is_empty()`, `at(index)`, `to_array()`, native `for` iteration and `map(callback)` provide ordered reads. `to_array()` returns a shallow snapshot; mutating that Array does not mutate the collection. Gogo iteration uses native Variant iteration to avoid the 4.0 statically typed custom-iterator fast-path defect; external `.gd` can use a Variant iterator or `to_array()`.

`append(value)`, `insert(index, value)`, `remove_at(index)`, `replace(index, value)`, `move(from, to)` and `reset(Array)` return bool success. Indices are bounded and zero based; move's destination is the final index. Equal replacement, same-position movement and equal reset are quiet. Rejected mutations report errors and retain the old contents. Dictionary insertion automatically hydrates a typed model element. Native callers may explicitly preload `array_collection.gd` and construct an empty collection with its Script or Variant-type element descriptor.

`structure_changed` fires once per structural mutation. Nested `begin_update()` / `end_update()` coalesces structural edits into one notification at the outer end. The broader `changed` signal also propagates observed item/deep-child changes. Child edits are synchronous; batching does not defer arbitrary model-field signals. Mutations during iteration have normal live ordered-container semantics; use a snapshot when intentionally editing membership while traversing it.

Each class-level model exposes `_gogo_data_changed` for upward argument invalidation; existing per-property signals retain their captured previous/new values. Weak external graph records subscribe once to each child instance per parent. Duplicate membership retains one subscription until the final occurrence is removed. Replacement/removal rewires edges; garbage collection disconnects dead owners. Shared-child diamonds emit once per upward propagation, cycle attachment is rejected, and reentrant upward listeners cannot create recursive notification storms. Caller-authored unbounded loops on ordinary per-property signals retain their existing native responsibility.

The existing manager observes these signals for same-identity function arguments. Collection traversal observes structure separately from item fields. Named render callbacks and compiled inline GGX callbacks use the existing invocation cache; keyed reconciliation retains native Nodes, focus, handlers and hit geometry. No revision counter, proxy, helper Node, metadata on user instances, second scheduler or idle polling is introduced. Data graph edges live for their data owners; unmount removes view subscriptions, while a still-live data model can continue serving other consumers.

Plain Array/Dictionary in-place mutation remains unobserved. Bindable reference replacement remains native and observable. Raw containers do not acquire deep bubbling merely because they contain Objects. Native typed Arrays are also ordinary Arrays, not observable collections.

## Verification

Run `bun install --frozen-lockfile` and `bun run check`. The focused immutable direct-Yarn package acceptance is Linux only:

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/check-data.ts --editor \
  --engine 4.0.4=/absolute/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/absolute/Godot_v4.7-stable_linux.x86_64 \
  --output /new/absolute/evidence-directory
```

Use Xvfb/software graphics as documented in TESTING.md. The collector runs native compiler/runtime tests, rendered keyboard/pointer/focus/reorder proof at two sizes, isolated current/main Play rejection/rollback/repair and editor restart. Installed package bytes and authored/generated maps/UIDs are checked after testing. Physical-key tests and manual interactive smoke are not claimed; OS IME composition is unrelated and untested. This collector is opt-in and does not expand routine CI.
