# Native Select and Option — UI-05

Import the exact Scripts. For a generated Gogo Script in `app/generated` in a direct Yarn consumer:

```gogo
const Select = preload("../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/node/select.gd")
const Option = preload("../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/node/option.gd")
@bindable var mode: String = "explore"
func build_view() -> Element:
    return <Select value={self.mode} width="220px">
        <Option value="build">Build</Option>
        <Option value="explore">Explore</Option>
        <Option value="repair" disabled>Repair</Option>
    </Select>
```

Select is a native Node2D participant with a private Godot OptionButton/PopupMenu. Godot owns actual menu placement, item picking, focus, keyboard, popup scrolling and window behavior. Option is a nonvisual Node record with String `value`/`text` and Bool `disabled`/`hidden`; it has no layout footprint or selected Bool. IDs must be nonempty and unique within the nearest Select, including hidden/disabled items. Current popup indices are internal projections of IDs, never values written to models. Imports remain lexical; no built-in Godot tags are remapped.

`value: String` and synchronous `value_changed(previous: String,value: String)` use the [single typed binding contract](TWO_WAY_BINDINGS.md). A changed direct native setter notifies, equal writes are quiet, and mounted projection cannot echo into the source. Direct observable String paths bind two ways; snapshots/computed/spread values stay one-way. Option.value never binds two ways. The current item list may come from mapped keyed ArrayCollection data.

Empty value and unknown/removed/hidden/disabled IDs are valid pending selections. The closed trigger displays `placeholder` (default `Choose…`), without selecting a neighbor or changing the String. Eligibility restoration restores its label. Label updates/reorder/list projection generate no fabricated user events. Native setters and whole desired-tree preflight reject empty/duplicate IDs and wrong types; invalid desired output retains the previous mounted view/focus and repairs normally. Source replacement/unmount disconnect the existing mounted writer.

`read_only` retains focus but disables opening/committing the menu; `disabled` also prevents focus. Native Tab/Shift-Tab joins other Estragon and foreign Controls. Arrow/Enter/Space/Escape follow native OptionButton/PopupMenu behavior. A popup can extend beyond trigger content through Godot's actual window behavior; no new overlay framework is included. Membership changes, source replacement, value projection, clipping/hide and unmount close stale menus. The closed trigger remains subject to native ancestor clips and shared focus eligibility. Public `get_native_control()` / `get_focus_control()` expose the current private endpoint for native inspection; it is owner-null, excluded from layout/GGX children and never persisted as authored output.

The stable natural content minimum is 200px by at least32px/one native font line; labels do not resize it; long selected labels clip within the allocated trigger. Existing Length/padding/border/min-max/Grid/scrolling owns geometry. A neutral square local skin supplies hover/pressed/disabled/focus feedback with no global Theme changes. Font size/color and host surface/border are local. The [repository showcase](../examples/values/Values.gogo) mixes this API with both Slider axes, typed inputs and other focusable controls.

Multi-select, searchable/combo Select and an Estragon popup compositor remain outside UI-05. Native automated Linux proof is separate from manual OS/screen-reader/IME certification; those are untested.
