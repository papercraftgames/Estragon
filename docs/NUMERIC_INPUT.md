# Native numeric controls — UI-05

Slider and NumberInput expose **float** `value/min_value/max_value/step`; IntegerInput exposes **int** fields and a typed int notification. All have `value_changed(previous,value)` with their exact type. They share one internal range/delegation implementation; IntegerInput does not override an inherited float property.

```gogo
# Paths from a generated app/generated Script in a direct Yarn consumer.
const Slider = preload("../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/node/slider.gd")
const NumberInput = preload("../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/node/number_input.gd")
const IntegerInput = preload("../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/node/integer_input.gd")
@bindable var volume: float = 0.5
@bindable var lives: int = 3
func build_view() -> Element:
    return <VBox gap="12px">
        <Slider value={self.volume} min_value={0.0} max_value={1.0} step={0.05} width="250px" />
        <Slider value={self.volume} min_value={0.0} max_value={1.0} step={0.05}
                orientation="vertical" width="40px" height="160px" />
        <NumberInput value={self.volume} min_value={0.0} max_value={1.0} step={0.05} />
        <IntegerInput value={self.lives} min_value={0} max_value={99} step={1} />
    </VBox>
```

The ordinary lexical VBox/Element imports must also be present. Direct typed observable paths use the existing [mounted binding](TWO_WAY_BINDINGS.md), with exact float↔float and int↔int contracts. No implicit int↔float or String conversion, Variant binding, IntegerSlider, alternate binding prop or scheduler exists. Independent native value assignments notify synchronously; equal canonical values are quiet. Model projection is guarded, reentrant source repairs win, and source replacement/unmount release stale writers. Local snapshots/computed expressions remain one-way.

## Range and model authority

Defaults are min0/max100/step1/value0, in the endpoint's exact type. Values/configuration must be finite, min<=max, float step>=0 (0 is continuous), integer step>=1. Integer fields are bounded to ±(2^53−1), the exact-integer range of Godot Range's double storage. Finite step/range quotients are required.

Canonicalization matches native Range: clamp to endpoints, snap on the **zero-origin** step lattice using `floor(value/step+0.5)*step` (native ties toward positive infinity), then clamp again. Endpoints remain legal even off the lattice; equal endpoints produce an immobile value. This is shared by both Slider orientations and SpinBox hosts. Native direct setters canonicalize and emit one actual typed transition. Native range changes canonicalize the current value; the internal coherent range/value transaction applies configuration first and emits once after the final value is known. Decimal source checks tolerate bounded round-off (`max(abs(value)*2e-15,step*1e-8,1e-300)`), not arbitrary off-step values.

**GGX authored values must already be canonical.** Wrong exact types, NaN/Infinity, inverted ranges, invalid steps/orientation or out-of-range/off-step authored values reject the complete desired commit at the authored field span. The previous usable view is retained. A noncanonical model assignment stays authored in the model until the application repairs it; the control does not silently normalize the source or start an infinite repair loop. Assign canonical model values when changing a bound range. Omitted, unbound value defaults may clamp to the final range. Range/value attributes commit together, independent of attribute order, with mounted projection suppression.

## Native input and editing

Slider has `orientation="horizontal"` (default) or `"vertical"`, backed by a real HSlider/VSlider. Native track clicks, drag, wheel and arrow/Home/End/Page keys own value changes. Native wheel scrolling is enabled for editable sliders; read-only/disabled ranges retain native routing. Orientation changes retain the host and bindings, recreate only the private endpoint and transfer eligible native focus. Min/max/step and both axis geometries use the same mathematical layout core and post-gutter parent reference.

NumberInput/IntegerInput use a private native SpinBox and its LineEdit. Godot owns editing, selection/copy, shortcuts, undo, expression parsing, step buttons, wheel and text formatting. `update_on_text_changed=false`: partial text stays native until Enter/focus commit; it publishes no invalid numeric model value and survives unrelated Gogo renders with caret/focus. Enter applies Godot's numeric expression and restores a canonical display; Escape restores the current committed value and releases focus. External changed values take authority over partial text. Rejected/invalid text returns to the committed value. Integer Range rounding guarantees typed integer publication.

`read_only` allows native focus/selection/copy but no value edits; `disabled` prevents focus/editing and mutes the endpoint. `focus_mode`, `grab_focus`, `release_focus`, `has_focus`, `get_focus_control` join the shared native registry. `get_native_control` returns the Range/SpinBox; NumberInput's focus control is its LineEdit. Native scene storage persists the complete typed range/value as one internal configuration transaction; Inspector/public fields retain individual validation. This avoids valid ranges failing when Godot restores minimum and maximum in field order. Private endpoints stay in the actual clipped ancestry, owner-null and excluded from authored packing/GGX/layout. They are not hidden text buffers. Local neutral square skins, font_size/color, focus outline and optional `invalid` outline do not mutate global themes. Content natural size is stable200px by at least32px/one font line; vertical Slider is24×160px, plus normal host padding/border.

See the [showcase](../examples/values/Values.gogo), [Select](SELECT.md) and `tools/check-values.ts --editor` for two-version native compiler, graphics, popup, input, range, lifecycle, package/maps/UID and isolated real editor proof. Manual interactive smoke, actual OS IME, assistive technology, mobile keyboards and other operating systems are **UNTESTED**. Synthetic native GUI events are not OS certification.
