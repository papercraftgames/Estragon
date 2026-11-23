# Implicit observable Bool binding — UI-02

[UI-02 #198](https://github.com/papercraftgames/Estragon/issues/198) implements the Bool slice of [ADR-0031](DECISIONS.md#adr-0031--ggx-implied-reactive-render-functions-automatic-memoizationbinding-and-observable-typed-data) over the existing native description/commit manager. UI-01 focus/keyboard ownership is merged in PR #216. Checkbox and Toggle use the same Bool contract; production Input/String binding remains UI-03.

```gogo
@bindable
extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Checkbox = preload("../../../addons/estragon/runtime/node/checkbox.gd")
const Model = preload("Model.gd")
var model: Model = Model.new()
func build_view() -> Element:
    return <Checkbox value={self.model.flag}>Enabled</Checkbox> if self.model != null else null
```

`Model.gogo` declares typed Gogo `@bindable var flag: bool`. Native aliases are explicit imports; no reserved short tag or remapping of Godot's `CheckBox`. See the [runnable Checkbox example](../examples/checkbox/Checkboxes.tscn) and migrated [two-way demo](../examples/twoway/Demo.gogo).

## Direct property paths versus one-way values

A direct dotted property expression such as `value={self.flag}`, `value={self.model.flag}` or `value={item.flag}` creates automatic two-way linkage **only when both endpoints have the typed writable/observable Bool contract**. Gogo owned typed bindable fields publish that contract on their compiled Script. The shared native Checkbox/Toggle value property implements its equivalent. A matching signal name alone does not prove a plain/read-only field writable or observable.

The compiler lexes the actual expression and emits native read/write linkage only for direct identifier/property paths. It does not invert expressions or chase arbitrary aliases. A local Bool snapshot is one-way:

```gogo
var current := self.model.flag
return <Checkbox value={current}>Snapshot</Checkbox>
```

The snapshot's getter read still observes the model when its render function executes. Literals, computed/call/index expressions, plain/unobservable or read-only source fields also stay one-way. A later relevant render projects the authored Bool value even if the control changed independently. Passing a model object to a helper and writing `item.flag` is a direct property path; capturing the Bool into `current` is not.

Spreads retain ordinary left-to-right value precedence. A spread containing a Bool value is a snapshot, not an invertible property reference. A later spread can replace an earlier direct-path value with a one-way value, and a later explicit direct-path value can replace an earlier spread. `key` and all removed `bind:*` names remain forbidden inside spreads. Named `value_changed`/`pressed` handlers remain ordinary native Callables, never invoked during rendering; a correctly typed native observer may accompany implicit value binding.

**Authored `bind:value` and other `bind:*` syntax are removed**, with an authored-location diagnostic. No compatibility alias, target-owned binder Node, per-property recipe or second binding engine remains. All executable examples/tests use implicit `value`. Older F05-B reports/raw evidence preserve the historical explicit syntax and user-only one-argument signal; those are not supported APIs after this cutover.

## Native notifications and source authority

Checkbox/Toggle expose `value: bool` and **`value_changed(previous: bool, value: bool)`**. Their setters mirror Gogo typed bindables: a real transition redraws and emits synchronously, including independent programmatic assignments. Same-value assignments are quiet; programmatic writes need not be user input to notify. Getter reads participate in the existing signal observation scope.

Completed primary-pointer or focused keyboard activation changes value through that same setter, once. The inherited `pressed` signal remains available. The mounted binding synchronously writes the current source endpoint only when its value differs. Model setters preserve native depth-first/reentrant notification semantics; affected view jobs still coalesce through the one deferred manager.

During model-to-view reconciliation, the existing mounted binding marks its own projection write. Value observers still receive a native transition, but the automatic edit callback does **not** write that projection back to the model. Initial setup, reused connections and source replacement follow the same rule. Reentrant model callbacks can restore an earlier value; the scheduled commit compares the actual control value and restores source authority even if the desired snapshot itself is unchanged. The boundary guards recursive writes; it does not interpret arbitrary application-authored signal cycles.

## Ownership, nulls and teardown

Linkage captures weak root/source identity, field/path, typed native read/write closures and the current Bool snapshot. Each native mount owns one connection outside user models/Nodes, including repeated use of a cached description. On a `self.model.flag` path, replacing/nulling the model makes a stale callback inert immediately, before deferred commit; successful reconciliation rewires once. Direct object-parameter paths are relative to that object, with the lifetime of the current mounted occurrence.

A null path that is still present in a desired tree **rejects the complete commit**, reports the authored value span and retains previous native output. Use an ordinary conditional to omit the control when its model is null, as above. A source repair schedules normal reconciliation; null never becomes a silently writable false value. Wrong dynamic Bool/length/style props also fail preflight atomically.

Unmount, source replacement, suspension, direct native removal and disposal disconnect mounted callbacks. A captured native Callable can become invalid when its old binding is released; callers must use normal `is_valid()` checks. Keyed moves retain compatible native controls/focus. Packed scenes persist authored hosts and owners, not transient managed output or binding records; reloading reconstructs one connection through normal composition. No reconciliation metadata is injected onto user objects.

Compiler-owned Script constants describe authored bindable fields, just as Script constants describe render functions. This is static language metadata, not per-instance state or a public marker to add to arbitrary scripts. It prevents an unrelated same-named signal from manufacturing a writable contract. The native4.0 signal metadata bridge reads the real declaration through inherited Scripts when optional typed argument metadata is absent; native loading and typed callbacks remain authoritative. It neither instantiates controls nor raises the engine minimum.

## Verification and boundaries

`tools/check-checkbox.ts` checks native compiler/maps/negative paths; actual pointer/key/focus, programmatic notifications, origin suppression, equality/reentrancy, one-way values, replacement/null/keyed identity, preflight repair, pack/lifetime and idle-zero behavior; direct Yarn and real isolated editor current/main rollback/repair/Play/restart. Existing two-way/core/focus regressions remain live with the new contract. Only official Linux4.0.4/pinned4.7.0 are fresh proof; exact evidence and manual-smoke status are tracked in the issue/PR and committed report.

No String Input, collection mutation observation, OS IME validation, automatic label style inheritance, additional scheduler or scene system is included. [Checkbox drawing/geometry](CHECKBOX.md), [shared native focus and keyboard path](FOCUS_KEYBOARD.md).
