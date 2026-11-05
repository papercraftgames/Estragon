# F04 — one description compiler and retained native runtime

[F04 #98](https://github.com/resistdesign/Estragon/issues/98) completes the cutover after merged F01/F02/F03. The live issue and sole PR record exact verification and review state. F05 class-level bindability/two-way inputs and F06 measured optimization remain unimplemented.

## Supported contract

Every GGX expression evaluates to a lightweight `Element` description. This includes markup in ordinary functions, lambdas, map callbacks, loops and helper modules; it never eagerly allocates live Godot Nodes. There is one emitter and one description API. Native expression evaluation order and lazy branches are preserved.

A Node-based Gogo host automatically composes a top-level zero-argument `build_view() -> Element`, where `Element` is an explicit preload alias for `res://addons/estragon/runtime/composition/element.gd`. The generated lifecycle hook delegates to the same external manager. Observed Gogo getters in that function or any called helpers register actual read dependencies. Ordinary typed bindable getters/setters/signals work outside composition too, including RefCounted data models.

```gdscript
extends Node2D
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
@bindable var count: int = 0

func build_view() -> Element:
    return <VBox>
        {caption()}
        <UiButton text="+" pressed={increment} />
    </VBox>

func caption() -> Element:
    return <Text text={"Count: %d" % count} />

func increment() -> void:
    count += 1
```

Helpers compute descriptions; functions/lambdas do not create a second automatic computation scope. Independent nested Gogo hosts do. Typed native props/signals, explicit tag aliases, normal Godot `Button`, native conditionals and for/map child arrays use the same validation and source maps. See [conditional slots](F02_CONDITIONALS.md), [keys/sequences](F03_LISTS.md) and [bindables](BINDABLE_PROPERTIES.md).

Old `build_view() -> Node` markup rejects with an authored declaration diagnostic. Passing a description where a native Node is required fails native semantic validation before Play with existing source-map/capability guarantees. No eager mode, deprecated wrapper, runtime markup parser, external compiler or compatibility factory remains. Descriptor-building static methods are compiler-generated typed helpers, not a native creation backend.

Composition is repeatable and reruns helpers. Once-only effects belong in `_ready` or event methods. Nullable models use explicit native conditional fallback expressions; there is no hidden property-path evaluator with hold-last semantics. Array reference replacement notifies; arbitrary native Array/Dictionary mutation does not.

The manager defers/coalesces commits, orders parent work first, preflights the entire desired tree, preserves compatible real Node IDs/native state and only changes declared props/handlers/structure. One set of getter observers, one scheduler/reconciler, no metadata or per-property helper Nodes on user objects, no frame polling. Existing composed layout caches and Node2D/Node3D/native authority remain; #88 is not expanded.

## Exact removal and consumer migration

| Removed implementation | Replacement / retained responsibility |
| --- | --- |
| `compiler/reactive.gd` and `.uid` | Actual Gogo getter reads through `composition/state.tres`; native metadata resolver remains. |
| `runtime/node/internal/property_binding.gd` and `.uid` | External computation records/subscriptions, single deferred manager and reconciler. No target-owned binder child. |
| `GdExpression.dependencies`, `Component.described`, lexical `_mark` | One descriptor AST/lowering for all GGX; lexical composition entry detection only. |
| Emitter `_component`, `_reader`, reactive reader/source fields, eager owner/connection/child construction state and dispatch | `_description` plus typed mapped expression parameters. Reconciler owns actual native constructors/attachments. |
| Generated `_gogo_read_*`, `binding_*`, eager `component_*` factory bodies | Rebuilt current scripts/maps with preserved script UIDs. |
| Counter manual build/add/persist and GGX base `compose()->Node` manual mount | Automatic typed `build_view`, native event methods retained; camera/light and Resource subscriptions remain ordinary code. |
| Reactive demo once-only expression side effect and implicit null holding | Pure repeatable helper, explicit nullable model fallbacks, same visible model/style/layout interactions. |
| Tests of per-target binder counts, synchronous binder rewiring and persisted binder graphs | One read subscription per computation, safe deferred replacement, native IDs/layout/event parity, observer cleanup and transient output reload. |

No live source, generated asset, runner, scene or pack refers to the removed implementations. Historical research and old evidence remain truthful archives. `tools/audit-native-source.ts` guards removed paths, eager/binder generated output, dead compiler dispatch, canonical UID pairing/uniqueness, import references and authored maps. Native constructors and `add_child/remove_child/move_child` in application code, scene tests, native layout and reconciler are legitimate and remain.

## Source-to-native parity

| Consumer / previous behavior | Sole path proof |
| --- | --- |
| Canonical `examples/counter/Counter.tscn`: +/Reset, disabled input, text and resize | Same scene/path/visuals; count getter queues its view, retained label/buttons/handlers, native hit testing and layout caches. |
| `examples/ggx/{TwoD,ThreeD}.tscn`: custom tags, native properties/transforms, Timer/Gradient signals, adapter resizing | Same real 2D/3D/custom Nodes and Resource values; transient descriptions, native camera/light setup and explicit application Resource cleanup. |
| `examples/reactive/Demo.tscn`: nested model text/style/width/gap | Same dynamic visible behavior, one external computation, coalesced native writes and affected-branch layout; explicit null fallback/repair. |
| `examples/composition/Counter.tscn`: dynamic getter scope/read tests | Dedicated richer model/read-set proof retained; sole descriptor emitter/runtime, no old path. |
| Conditional and inventory scenes | Existing stable null slots, deep ownership and keyed row state/lists use the same manager; regression gates retained. |
| Bindable models | Native typed signals/equality/reentrancy/inheritance retained; no Node required for data. |
| Scene ownership/distribution | Persist authored hosts and genuine foreign objects; managed dynamic output remains `owner=null`, reconstructed once on mount/reload, fresh/cold source build and bare pack process. |

Mount is deferred. `_ready` must not assume the managed view already exists; native event methods run after normal mounting. The examples' `ui`/`entry` accessors resolve the actual managed child without storing framework bookkeeping. Native scene parentage and persistence remain distinct. Pack authored host state and foreign objects using Godot ownership; do not serialize a stale dynamic snapshot. Arbitrary application constructor/setter/callback side effects retain F02's documented limits.

## Verification and release

Focused workflow mode `cutover` selects existing compiler/GGX/native-UI/model groups on one approved Linux engine. No release group was removed: final `check-native-addon.ts` still requires all compiler, runtime, UI, bindable, model, composition, conditional, list, metadata and distribution stages, including native saved/unsaved main/current Play rollback/repair, source-only/cold builds and bare-process pack runtime. Only official 4.0.4 and pinned 4.7.0 are routine verification. Exact source/engine hashes, commands, failures/repairs, captures, stage counts and manual-smoke status are in #98/its sole PR. Automated real editor/game/rendering does not imply manual interactive smoke or untested platform/minor certification.
