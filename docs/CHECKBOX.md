# Native Estragon Checkbox — UI-02

`EstragonCheckbox` is a Node2D control with a **square/checkmark and label**, distinct from Toggle's checked fill/underline. Import its exact Script under any ordinary Gogo alias:

```gogo
const Checkbox = preload("../../../addons/estragon/runtime/node/checkbox.gd")
# In a render function under an Entry:
<Checkbox value={self.model.flag} text="Enabled" />
<Checkbox value={self.model.flag}>Enabled</Checkbox>
```

An unimported Godot `CheckBox` retains its native type; Checkbox is not a reserved tag. Native completion/import tooling offers the installed Estragon Script. `value` is typed Bool and `value_changed(previous: bool, value: bool)` notifies user and independent programmatic transitions. [Implicit binding, origin suppression and one-way values](TWO_WAY_BINDINGS.md) govern model ownership; no authored `bind:value` remains.

Checkbox inherits the current Button's text/font/color, local surface/border/padding, hover/held/disabled states, primary-pointer capture, exact inverse-canvas hit testing, native focus endpoint/ring, keyboard accept/repeat/cancel and native clipping/scroll behavior. It extends the shared Toggle Bool setter/activation path rather than introducing another event or binding manager. `pressed` remains a native named-handler signal. Disabled/hidden/cancelled activation cannot edit.

Natural content size reserves a square of `max(16, font_size)` logical pixels, eight pixels between square and nonempty label, and the label's measured size. Border/padding are then consumed by the existing mathematical core. Box/Grid/Wrap use this same natural size, retain native identity and expose the whole allocated border-box as the hit/focus rectangle; square and label clicks do not dispatch independent activations. Constrained tiny allocations bound the square to available content. Label line handling/font metrics follow current Text; wrapping/shaping is not added here.

The square uses local `checked_background_color`, an outlined border and a native polyline checkmark. Disabled drawing is muted. Checkbox does not paint Toggle's underline or checked whole-surface state. Standard local surface, border, background, padding, font size and text color remain available; **no automatic parent label style inheritance** is introduced. Focus remains visible on the real border-box and clips with its actual native ancestry.

[Checkboxes.tscn](../examples/checkbox/Checkboxes.tscn) demonstrates direct model linkage, a local snapshot, a computed value, a parameter path, Toggle peers, disabled controls and keyed Box/Wrap/Grid placement. [Focused acceptance](TESTING.md#ui-02-checkbox-and-implicit-bool-acceptance) checks actual native input/rendering, lifetime, model replacement/null, both Play paths, source maps and immutable directly installed package bytes. Production Input/String binding remains UI-03; real OS IME composition remains untested and outside this slice.
