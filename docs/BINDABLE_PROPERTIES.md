**F01 implementation checkpoint:** [Native composition spike](F01_COMPOSITION.md) / [#92](https://github.com/resistdesign/Estragon/issues/92) supplies the bounded getter-read → description → retained static-shape path for review. Full ADR-0016/F02–F06 behavior is not claimed; exact verification and review state are in the live issue/sole PR.

# T09-A — observable Gogo properties and models

T09-A / [#43](https://github.com/resistdesign/Estragon/issues/43) implements the property/model foundation. T09-A alone does not make brace expressions reactive. [T09-B](REACTIVE_GGX.md) adds bounded explicit self-path dependencies and native UI/layout subscriptions. Collections/keyed repeaters and two-way/cycle machinery remain T09-C/D.

Run `examples/bindable/Demo.tscn` in Godot with the bundled Estragon addon enabled. Author `Model.gogo`, `Derived.gogo` and `Demo.gogo`; normal save and main/current Play compile them without external tools. The demo prints two observed model changes while preserving the same RefCounted data object. RefCounted data models are intentional non-Node values, not retired display components. They cannot be GGX hierarchy children.

```gdscript
# Model.gogo (code-only; no markup)
extends RefCounted
@bindable var count: int = 3

func increment() -> void:
    count += 1
```

The ordinary typed generated `.gd` property uses Godot's native backing storage/setter and exposes `count_changed(previous: int, value: int)`. Observe through normal native signal connections; `model.count += 1` and assignments inside ordinary methods use the same setter. No refresh call, manual notification, wrapper, common model base or polling is required. The `.gogo` annotation is compiler-owned and never registered with the ordinary `.gd` parser. Code-only models, Node properties and native/script-typed values share this lowering.

## Supported declaration and accessor contract

Exactly lowercase `@bindable`, inline or on its preceding line, annotates a **top-level instance `var name: ExplicitType [= native_initializer]`**. Native types, typed arrays, explicit imported types and inheritance retain Godot's semantic authority. Initializers are native GDScript (including multiline expressions); direct GGX initializers, inferred/untyped/static/const/local/inner-class declarations, annotation arguments/duplicates/composition, multiple declarations and custom get/set on the annotated property are explicitly rejected in this slice. Existing ordinary native/GGX code is preserved. Use ordinary methods to transform values before assignment when a generated observable setter is desired; there is no silently composed custom accessor.

Each property reserves `<name>_changed` in its class. Authored declaration collisions reject at source; inherited collisions/redeclarations are rejected by mapped native semantic validation. Generated setter local names avoid authored identifiers. Base properties/signals remain inherited; derived classes may add independent bindable properties and use inherited setters normally. Redeclaring an inherited property does not replace its notification contract. The generated declaration/type ranges retain original-source mapping, including CRLF and comments.

Annotation/declaration diagnostics are source-located on both approved engines. Native semantic diagnostics use the existing C01-E bridge: 4.7's Logger exposes mapped authored locations; 4.0.4 reports rejection against the authored file, explicitly states that the exact authored location is unavailable and leaves the native engine diagnostic visible. Actual-path validation, rejection/rollback and recovery remain mandatory on both. Optional diagnostic capture never becomes an authoring restriction.

Declaration initialization sets backing values **without emission**. Later assignments, including explicit `_init` assignments, notify normally once a subscriber is connected. `is_same(old, new)` suppresses identical values/references: value types compare natively, reference types (Object/Array/Dictionary/packed arrays) compare identity. Replacing an array by an equal-content different array is observable; mutating the same array in place is not a property assignment and emits no structural event. Native float equality applies, without approximate comparison; native NaN behavior is retained. See the [Godot 4.0 is_same contract](https://docs.godotengine.org/en/4.0/classes/class_%40globalscope.html#class-globalscope-method-is-same).

The setter stores the new value before native synchronous emission. Reentrant subscriber writes emit depth-first with captured previous/new arguments; the outer setter performs no post-notification write that can erase newer state. Other subscribers may see a later current value after reentrancy while receiving the earlier transition's arguments. Caller-authored unbounded signal loops remain the caller's responsibility; no cycle guard, queue/batching or T09-D feedback system is implied.

Use native `disconnect`, receiver/source lifetime and normal ownership to end observations. Freeing a Node receiver drops its native subscriptions. RefCounted models release when normal references disappear; the generated setter introduces no source/receiver ownership service or hidden global registry. Consumers retaining model references in callbacks still need ordinary Godot lifetime discipline.

## Verification boundary

`tools/check-bindable.ts` runs isolated normal bundled builds/imports, native code-only model/runtime/negative/map tests and a real editor with actual saved/unsaved main/current Play. It proves syntax/type failures and unsavable source block stale execution, preserve code/maps/UID/timestamps/Script identity and recover after repair. The native-only process PATH has no external compiler. Linux acceptance runs only official 4.0.4 and pinned 4.7.0; generated artifacts, logs and source/engine provenance are review evidence. The current strict addon gate also keeps Counter, native 2D/3D/runtime/UI/highlighter/metadata/distribution coverage. See [TESTING](TESTING.md) and live #43/PR for exact outcomes; no untested minor/platform or release/publishing claim.
