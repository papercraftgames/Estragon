# Native editable Input — UI-03

[Issue #199](https://github.com/papercraftgames/Estragon/issues/199) supplies a single-line editable **EstragonInput Node2D**. Use a normal exact Script import; an alias such as `TextInput` also works. Importing `Input` is lexical and shadows Godot's Input singleton only in that authored module.

```gogo
const Input = preload("../../../addons/estragon/runtime/node/input.gd")
# Inside a GGX render function, with a non-null typed observable model:
<Input value={self.model.text} placeholder="Your name"
       submitted={self.submitted} cancelled={self.cancelled} />
```

The [runnable Inputs example](../examples/input/Inputs.tscn) includes a shared model, one-way snapshot/computed fields, a parameter path, read-only/disabled/invalid states, keyed Grid children and nested clipping. [Implicit Bool/String binding](TWO_WAY_BINDINGS.md) defines source authority and lifecycle; no authored `bind:*` syntax is supported.

## Value and events

`value: String` is a typed observable property. `value_changed(previous: String, value: String)` emits synchronously for real user edits **and independent programmatic Input.value assignments**. Equal values are quiet. Both endpoints must have the writable/observable String contract for `value={self.model.text}` to bind two ways. Bool and String contracts do not cross-convert. Local String snapshots, computed/call/index expressions and plain/read-only/Dictionary properties remain one-way. Model/event writes are synchronous; native reconciliation coalesces through the existing deferred manager. Projection still notifies observers while the mounted binding suppresses automatic backflow.

`submitted(value: String)` follows native LineEdit Enter submission. `cancelled` follows Escape: focus is released, and the current committed value is retained. Application handlers can restore a previous model value if their form needs rollback. `focus_entered` / `focus_exited` follow native focus. Handlers are named methods/Callables and are not called during rendering.

`placeholder: String` is displayed by the native editor when empty; it is not a value. `read_only: bool` allows native focus, selection and copying while rejecting user edits. `disabled: bool` prevents focus/selection/editing and mutes text; it does not prohibit programmatic value updates. `invalid: bool` draws a local invalid outline, with priority over the focus outline; it does not implement a validation policy or reject model values.

## Editing and focus

Native LineEdit owns caret, selection, text shaping, Unicode typing, Backspace/Delete, Home/End/arrow and Shift selection, mouse selection, clipboard copy/cut/paste, native edit shortcuts/context menu and platform text input. Estragon does not translate raw key codes into another string buffer or forward/re-emit native editing events. Normal GUI consumption precedes game unhandled-key fallbacks. Key releases and unrecognized keys retain Godot's native delivery behavior; raw application `_input` handlers run before GUI and may intercept events.

The existing shared [focus registry](FOCUS_KEYBOARD.md) joins Input with Estragon Buttons/Checkboxes and ordinary native Controls. `focus_mode` accepts native None/Click/All (default All). `grab_focus()`, `release_focus()`, `has_focus()` and `get_focus_control()` refer to the real native endpoint. The latter returns the current runtime LineEdit as Control, or null outside the running tree/editor. Its public native selection/caret API can be used where necessary; do not depend on its private child name or assign its text instead of Input.value.

Unrelated parent recomposition and compatible keyed moves preserve the same Input and LineEdit, including focus/caret/selection. A genuinely changed model value projects into the editor, preserving/clamping caret and selection columns to the new String length. New mounts reconstruct an editor from the current authored value, not a saved hidden editing session. Hidden/disabled/unmounted/fully clipped fields cannot retain Estragon focus. Read-only fields remain eligible; disabled fields are skipped by Tab. No automatic scroll-into-view policy is added.

## Geometry, skin and lifetime

One private, runtime-only, owner-null LineEdit lives under the real Node2D Input. Its hit/focus rectangle matches the arranged **border-box**, including padding. A transparent native StyleBox uses the host's resolved content insets, so native text/caret/selection occupy the content area while the Node2D paints its normal local surface/border and focus/invalid outline. Native clipping/transforms/Viewport ancestry remain intact; there is no offscreen text buffer, overlay tree or visible author wrapper. The native endpoint is excluded from layout adapters, reconciliation children, scroll content adoption and PackedScene persistence. It is an actual input endpoint, not a binding bookkeeping Node.

The natural content viewport is **200 logical pixels wide and one native font line high**, plus ordinary border/padding. Default padding is 8px; width stays stable as text changes and native horizontal scrolling keeps the caret visible. Box/Grid/Wrap, lengths, margins, background/borders and clipping use the existing core. The unstyled host background is neutral charcoal `#383838`, matching EstragonButton; explicit colors remain owned by the author. Focus `#9cdcff` and invalid outlines retain their semantic hues. `font: Font`, `font_size: int` (default20), `color: Color`, `focus_color: Color` and `invalid_color: Color` are local. Placeholder uses native muted text; disabled text is muted. No parent style inheritance is introduced. If a constrained content rect has no width or cannot fit one native font line, its editor is hidden and ineligible; the host retains its allocated skin/geometry.

A directly authored PackedScene persists exported Input.value and reconstructs exactly one private endpoint on mount. Gogo-managed output remains transient and is recreated by the existing manager. Replacement/null/unmount/free disconnect stale String edit callbacks; a present null direct source rejects the whole commit at its authored value span. Use an ordinary conditional to omit fields when their model is absent. No second binding or reactive scheduler is introduced.

## Supported proof and limits

Fresh tests target **official Linux Godot4.0.4 and pinned4.7.0 only**, through native X11/Xvfb and software OpenGL. Synthetic native Unicode/key, mouse selection, clipboard, caret retention and real editor Play are tested separately from headless parsing. Both engines report their native IME capability, but **actual OS IME composition/candidate interaction is UNTESTED under Xvfb**. LineEdit remains responsible for platform IME and candidate placement in its actual scene rect; capability reporting is not composition proof. No mobile/virtual-keyboard, accessibility, password, multiline or custom text editor claim is made. Manual interactive Godot4.7 smoke status is recorded with the task evidence; physical keypresses are not a gate.

`tools/check-input.ts` runs the immutable direct-Yarn/compiler/game/rejection/pack/editor/restart/map/UID acceptance. [Test command](TESTING.md#ui-03-editable-input-and-string-binding-acceptance). Current merged source and the issue/PR determine shipped status.

[Paired native evidence, commands and retained failures](evidence/UI03_INPUT.md).
