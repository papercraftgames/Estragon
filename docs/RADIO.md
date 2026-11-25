# Radio and RadioGroup — UI-04

[Issue #202](https://github.com/papercraftgames/Estragon/issues/202) adds native Node2D choice controls. Import their Scripts explicitly, as with Input and Checkbox:

```gogo
const RadioGroup = preload("../../../addons/estragon/runtime/node/radio_group.gd")
const Radio = preload("../../../addons/estragon/runtime/node/radio.gd")
@bindable var choice: String = "build"
func build_view() -> Element:
    return <RadioGroup value={self.choice} direction="row" gap="12px">
        <Radio value="build">Build</Radio>
        <Radio value="explore">Explore</Radio>
        <Radio value="repair" disabled>Repair</Radio>
    </RadioGroup>
```

`RadioGroup.value: String` is the single authoritative option identifier. A real transition emits synchronous `value_changed(previous: String, value: String)`, including independent programmatic writes; equality is quiet. The [existing String binding contract](TWO_WAY_BINDINGS.md) handles direct observable/writable paths, projection suppression, reentrant model repair, source replacement and teardown. Local snapshots, computed expressions and spreads stay one-way. There is no `bind:value`, default-value prop or sibling Bool synchronization.

`Radio.value: String` is its identity, never a Bool or a two-way binding destination. Identifiers must be nonempty and unique within their nearest group, including disabled/hidden options. `is_selected()` reports derived participation/selection; there is no writable `selected` property. Native identity assignments reject empty/duplicate IDs. Gogo literal errors have authored ranges; dynamic desired descriptions reject invalid types/IDs and duplicates before committing, retaining the prior mounted view/focus/value. Prevalidated identity swaps commit together without obsolete sibling IDs blocking them. Ordinary non-Radio children do not count; nested groups are independent.

An empty group value selects nothing. Any other unmatched String is valid pending selection: removal, hide or disable never rewrites the selected model String. Restoring an eligible matching option restores its indicator. Orphan Radios have no independent selection model and cannot activate. Native tree changes maintain weak ordered membership; keyed maps from `ArrayCollection` retain native instances/focus and follow current layout order. No frame scans or separate layout/binding scheduler exist.

Group `disabled` applies effectively without overwriting each option's authored `disabled`, and cancels active capture/focus. Hidden/unmounted/fully clipped options cannot activate or retain focus. `focus_mode` retains Button semantics: None still permits pointer selection; Click skips Tab. The shared native focus registry treats a group as one logical Tab stop, using its selected eligible option or first eligible option. Tab/Shift-Tab join Input, Checkbox, Button and foreign native Controls. Explicit native focus paths keep priority. Row Left/Right and column Up/Down wrap through current eligible order, select once and move actual native focus; Home/End choose the endpoints. Enter/Space use inherited configured `ui_accept` press/release semantics and `pressed`. Clicking an already selected Radio may emit `pressed`, with no extra value transition. Clipped targets are skipped rather than automatically scrolled into view. Input/LineEdit arrows remain native.

RadioGroup inherits Box, defaulting to `direction="column"`; row, Wrap, gaps, padding/border, lengths, Grid placement, scrolling and natural measures all use the existing core. Radio inherits Button's pointer/cancel/occlusion, text/font/color, padding, lengths and local validated surface styles. Its natural indicator is `max(16,font_size)`, followed by 8px of label spacing. The neutral circular outline, selected dot and inset focus border stay inside its arranged border-box. `border_color` also colors the selected dot when nontransparent; hover/pressed/disabled backgrounds use existing validated properties. Styles never mutate a global theme.

[Radios.gogo](../examples/radio/Radios.gogo) / [scene](../examples/radio/Radios.tscn) demonstrate both directions, observable keyed options, pending/disabled choices, Grid, scrolling, one-way snapshots, model reset/source replacement and mixed native controls. [Select/Slider #203](https://github.com/papercraftgames/Estragon/issues/203) remains separate; it can reuse these typed String selection semantics without introducing Variant binding.

`tools/check-radio.ts --editor` verifies one immutable direct-Yarn package on official Linux4.0.4/pinned4.7.0, native graphics/input/focus, compiler and atomic negative cases, Bool/Input/focus/layout/scrollbar regressions, editor current/main rejection/repair/Play and restart, exact maps/UIDs and pack/reopen. Manual interactive smoke, actual OS IME and assistive-technology interaction are separately UNTESTED; synthetic events are native dispatch proof, not OS interaction certification.
