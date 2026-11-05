# F05-B — native controlled boolean input

Implementation/review evidence: [#101](https://github.com/resistdesign/Estragon/issues/101) and its sole PR. F05-A is merged in #100 (`3487d86`). F06 remains future. This first input slice uses the existing description/reconciliation manager, generated Gogo getters/setters and native pointer/layout authority.

```gdscript
@bindable
extends Node2D
const Model = preload("res://examples/twoway/generated/Model.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
var model: Model = Model.new()
func build_view() -> Element:
    return <Toggle text="Enabled" bind:value={self.model.enabled} />
```

`Model.gogo` is a class-wide or selectively bindable Gogo model with `var enabled: bool`. Ordinary explicit aliases are used; Toggle is not a reserved tag. Run `examples/twoway/Demo.tscn` for host/model controls, model replacement, nested conditional rows and keyed reorder. No event-to-model handler, refresh call, duplicate state or required model base appears in the sample.

## Source contract

Only `bind:value={self.field}` or `bind:value={self.model.field}` (including deeper dotted identifiers) is reserved. The lexer/parser retains original spans; native source metadata proves every traversed field is an explicitly typed Gogo bindable, ending in bool. Referenced models use explicit preload aliases to generated paths with corresponding authored `.gogo`; this avoids stale generated metadata during source-only builds. Inferred/untyped, constants, static, native/unobservable fields and custom accessors do not acquire a binding contract by sharing a signal name. Use owned declared fields in this bounded slice.

The target must expose a writable bool `value` and exactly `value_changed(value: bool)`. Invalid type/arity/read-only/unknown metadata rejects. Duplicate binding, explicit `value` or `value_changed` beside binding rejects as contradictory; other ordinary properties and named signal handlers retain their existing rules. Quoted values, calls, arithmetic, indexing, omitted self, arbitrary expressions and other `bind:*` names reject at authored spans. No `.gd` custom annotations or runtime markup interpreter.

A potentially null model must omit its control intentionally:

```gdscript
return <Toggle bind:value={self.model.enabled} /> if self.model != null else null
```

A present null binding invalidates the complete desired commit and retains the previous tree. Null is never silently made writable. Native semantic validation remains actual-path transactional with original maps, stable UIDs/cache identity, failure rollback and repair. Godot 4.0.4 retains its documented optional authored semantic-location limitation.

## Model authority and timing

Model→view reads run in the existing dynamic getter scope. A generated setter signal schedules only observing computations; the deferred parent-first manager coalesces and commits the desired value. Drawing frames performs no recomposition. User pointer activation changes the toggle's bool and emits one native user-edit signal. The mounted binding synchronously writes the same generated model setter only when the value differs. The native model transition is immediate; the reconciled label/control projection commits at the next safe scheduler drain.

Programmatic control value assignment only redraws; it never emits a user edit. A later controlled commit compares the actual control value as well as desired data, restoring model authority even after reentrant model callbacks restore the previous value. While an input boundary is writing, recursively emitted edits on that boundary are ignored; model setters keep their ordinary depth-first notification semantics. No queued model writes, per-frame scans, feedback store or second scheduler exists. Unbounded application-authored model signal cycles remain ordinary user code; this boundary does not add a global signal-cycle interpreter.

## Ownership and cleanup

Descriptions carry compiler-generated native read/write linkage, value and weak root/source references. Mounted records own callbacks outside application Nodes/models. Path code checks null intermediates and compares the current endpoint with the captured source before writeback; changing a model reference makes a stale callback inert immediately, before its deferred projection commits. Connections are reused for the same root/path/source and rewired once for replacement. Source dependencies remain the existing getter subscriptions.

Suspend/dispose/unmount disconnect edits; detached/free controls and inactive computations cannot write. Resume commits and reconnects once. Keyed compatible controls retain native identity. Removed branches cancel their computations; foreign children and their native scene owners follow existing rescue rules. Transient managed controls and binding records are not serialized into PackedScene; authored hosts reconstitute the view and subscriptions on mount. There are no `set_meta` calls, target helper Nodes or reconciliation fields on models.

## EstragonToggle

`EstragonToggle` extends native `EstragonButton`, inherits its composed layout/text/draw path and entry-scoped primary-pointer router. It toggles on a completed primary press/release over the same visible enabled target. Disabled, hidden, released-outside, cancelled capture and other mouse buttons follow Button. Green background/underline indicate true. `value: bool` is typed and programmatically quiet; `value_changed(value: bool)` means a user edit. Inherited `pressed` remains available for ordinary named event handlers.

Keyboard focus, text editing, IME/caret/selection, accessibility, wider input types, in-place collections, serialization adapters and F06 optimization are outside this boolean slice.

## Verification

`tools/check-twoway.ts` uses isolated native builds/imports, real pointer dispatch, compiler/maps/negative paths, equality/reentrancy, model replacement, nested/keyed identity, detach/reparent/free/foreign ownership and PackedScene reconstitution. A real isolated editor proves saved/unsaved main/current Play, invalid/unsavable rejection, transactional code/map/UID/timestamp/Script identity and repair. Actual initial/changed/resized graphics are captured separately from headless assertions. Strict native-addon and source-only/cold/pack distribution groups include the demo. Focused workflow mode `twoway`; final acceptance only official Linux 4.0.4 and pinned 4.7.0. Exact commands, source/engine/log hashes, outcomes, artifacts and manual interactive smoke status are in #101/its sole PR; no untested platform/minor certification.
