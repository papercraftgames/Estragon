# T09-B — reactive GGX properties

T09-B [#86](https://github.com/resistdesign/Estragon/issues/86) extends [observable Gogo properties](BINDABLE_PROPERTIES.md) to retained native Nodes. See the live issue/sole PR for review status and exact verification. The bundled Godot compiler/editor is sufficient; there is no external compiler, polling, virtual DOM or tree rebuild.

## Explicit reads in ordinary braces

```gdscript
@bindable var count: int = 0
# In a normal instance method on a Node host:
return <EstragonText text={"Count: %d" % self.count} />
```

A **property** expression with an explicit `self.<property>` read opts into binding. Its root must be a typed top-level `@bindable` declared in the current module. `self.model.player.title` observes each property along that path, using its native `<name>_changed(previous,value)` signal. Models may be typed RefCounted values; they are never hierarchy children. Generated typed reads and signal access preserve native semantic validation and authored source maps. An absent signal/member or incompatible result type rejects before Play. Dependency segments must be declared bindable properties of the current host/model module; inherited dependency declarations and ordinary native/.gd data-object metadata are outside this bounded subset. T09-A inheritance and ordinary once-only expressions remain available.

Pure reactive expressions support literals, self property paths, arithmetic/comparison/logical/conditional operations and native Color/Vector/String/numeric value constructors. Indexing, calls to authored functions or methods, lambdas/await, assignment and nested GGX reject with source diagnostics. Bare expressions without `self` remain ordinary once-only GDScript, including unrelated side effects. Signal attributes remain once-only named handler/Callable values. This does not dynamically discover dependencies hidden inside arbitrary functions or silently make every expression reactive.

Initial argument reads retain authored traversal order. Native helper activation also checks the current value when the target enters the tree, to catch changes between construction and attachment; unchanged values do not rewrite the target. Null intermediate Objects stop path traversal, subscribe through the last non-null segment and hold the last target value (or native default before the first non-null value). Replacement/null recovery reconnects the new path. Multiple mentions of a signal in one binding produce one connection.

## Scheduling and lifetime

T09-A source notifications stay synchronous. Each affected binding immediately rewires to release replaced model listeners, then schedules one deferred evaluation/application. Multiple writes, including finite reentrant writes, apply the latest value once; do not expect UI properties to change synchronously inside the source setter. Target writes use native `is_same` equality suppression. Independent bindings are not evaluated. No transaction across different bindings or general cycle/feedback solver is promised; unbounded author-created feedback remains outside T09-B.

A native helper is parented to its target, uses weak source/Node-host references and stores generated method names rather than a closure retaining the host/model. Tree exit/free disconnects; reattach/reparent reconnects and recomputes current values without accumulating callbacks. Detached targets have no active observers. Host exit suspends bindings even if their target moved to another branch. Ordinary Node parentage/removal and event handlers remain native. Scene owner persistence is separate: GGX owns newly generated helpers as part of the subtree, and their exported host-relative path/method names support PackedScene reload. Hosts are Nodes; non-Node data models remain supported dependency values.

## Native presentation and layout

Bindings assign existing typed properties. Color/fill/disabled invoke native redraw/input setters; dimensions/gap/fill flags and text use existing composed affected-branch layout invalidation and cached measurements. Deferred source applications coalesce before layout reflow; unrelated branches retain measurement caches. There is no second layout algorithm or ancestor transform feedback.

**Reactive position/transform/rotation/scale and x/y are deferred** with an explicit diagnostic. Static native placement is unchanged. Parent HBox/VBox arrangement owns child positions; a separate positioning specification must distinguish layout-controlled offsets, native transform authority, hit testing and adapter behavior before adding bindings that can compete with it.

Run the reactive Counter (`examples/counter/Counter.tscn`) or nested-model style/geometry demo (`examples/reactive/Demo.tscn`). Counter increments/resets use only ordinary assignments. The model demo's `advance()` changes title/color/width through the same mechanism, preserving all UI Nodes and the unrelated once-only expression. Tests exercise real geometry, caches, model replacement/null/reentrancy, detach/reparent/free, PackedScene restoration, source diagnostics and actual editor Play rejection/rollback/repair.

## Verification and future work

`tools/check-reactive.ts` runs isolated native build/import/runtime/editor and graphics-backed captures. Focused workflow mode `reactive` uses one approved engine; final strict addon acceptance requires official 4.0.4 and pinned 4.7.0 on Linux only. Diagnostics retain the C01-E bridge: exact mapped native errors on 4.7; explicit unavailable-location rejection and visible native errors on 4.0.4. Actual-path validation and rollback remain mandatory on both. See [TESTING](TESTING.md) and live #86 for commands/provenance/results, including whether a manual interactive smoke ran.

T09-C observable collection mutation/keyed repeaters and T09-D two-way bindings/general feedback-cycle hardening remain unimplemented. No CSS/style/focus expansion, generalized 3D wrapping or pixel conversion helpers are supplied by this slice.
