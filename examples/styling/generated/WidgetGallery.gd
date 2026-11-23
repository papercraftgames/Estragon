extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const Rose = preload("StyledRose.gd")
signal enabled_changed(previous: bool, value: bool)
var enabled: bool = true:
    set(_gogo_incoming_enabled):
        if is_same(enabled, _gogo_incoming_enabled): return
        var _gogo_previous_enabled: bool = enabled
        enabled = _gogo_incoming_enabled
        enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
        return enabled

signal flipped_changed(previous: bool, value: bool)
var flipped: bool = false:
    set(_gogo_incoming_flipped):
        if is_same(flipped, _gogo_incoming_flipped): return
        var _gogo_previous_flipped: bool = flipped
        flipped = _gogo_incoming_flipped
        flipped_changed.emit(_gogo_previous_flipped, _gogo_incoming_flipped)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"flipped_changed")
        return flipped

signal extra_changed(previous: bool, value: bool)
var extra: bool = false:
    set(_gogo_incoming_extra):
        if is_same(extra, _gogo_incoming_extra): return
        var _gogo_previous_extra: bool = extra
        extra = _gogo_incoming_extra
        extra_changed.emit(_gogo_previous_extra, _gogo_incoming_extra)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"extra_changed")
        return extra

var clicks: int = 0
var native_clicks: int = 0
func clicked() -> void:
    clicks += 1
func native_clicked() -> void:
    native_clicks += 1
func build_view() -> Element:
    var keys = [2,1] if self.flipped else [1,2]
    return _GogoFactories_0._gogo_build_0(
        (1),
        (1),
        (Color("#ffcc66")),
        (Color.WHITE),
        (self.clicked),
        (true),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "self.enabled", (self.enabled) if self != null else null)),
        (false),
        (self.native_clicked),
        (keys.map(func(id): return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/styling/WidgetGallery.gogo:3222", id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_1((_gogo_mount_key), ("Key"+str(id)))))),
        (_GogoFactories_0._gogo_build_2() if self.extra else null)
    )

const _GOGO_RENDER_FUNCTIONS_a636d14d4f74f3c0 = {
"ordinary": ["clicked", "native_clicked"],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_a636d14d4f74f3c0 = {
"enabled": "bool",
"extra": "bool",
"flipped": "bool"
}

const _GogoProject_0 = preload("StyledRose.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: float,
        _gogo_value_1: int,
        _gogo_value_2: Color,
        _gogo_value_3: Color,
        _gogo_value_4: Callable,
        _gogo_value_5: bool,
        _gogo_value_6: Variant,
        _gogo_value_7: bool,
        _gogo_value_8: Callable,
        _gogo_value_9: Variant,
        _gogo_value_10: Variant
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Caption", "text": "Gold on blue", "color": _gogo_value_2, "padding": "6px", "padding_left": "11px", "background_color": "#142a3a", "border_color": "#85aacc", "border_width": "1px", "border_left_width": "3px"}, {}, [], "examples/styling/WidgetGallery.gogo:25:13", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(Rect, {"name": "Legacy", "width": "60px", "height": "42px", "fill": _gogo_value_3}, {}, [], "examples/styling/WidgetGallery.gogo:27:17", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(Rect, {"name": "Styled", "width": "130px", "height": "42px", "background_color": "#2288aa", "border_color": "#e9efff", "border_width": "2px"}, {}, [], "examples/styling/WidgetGallery.gogo:28:17", null, false)
        _gogo_element_5.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Rects", "gap": "12px"}, {}, [_gogo_element_4, _gogo_element_5], "examples/styling/WidgetGallery.gogo:26:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_7 := _GogoElement_0.new(_GogoImport_0, {"name": "Normal", "text": "Continue", "width": "120px", "height": "54px", "padding": "10px", "padding_left": "16px", "padding_top": "5px", "background_color": "#355e92", "hover_background_color": "#477dbb", "pressed_background_color": "#23446e", "disabled_background_color": "#313947", "border_color": "#cbd8ed", "border_width": "2px", "border_right_width": "4px"}, {"pressed": _gogo_value_4}, [], "examples/styling/WidgetGallery.gogo:31:17", null, false)
        _gogo_element_7.resolve_bindings()
        var _gogo_element_8 := _GogoElement_0.new(_GogoImport_0, {"name": "Hover", "text": "Hover", "width": "120px", "height": "54px", "background_color": "#355e92", "hover_background_color": "#477dbb", "border_color": "#cbd8ed", "border_width": "2px"}, {}, [], "examples/styling/WidgetGallery.gogo:32:17", null, false)
        _gogo_element_8.resolve_bindings()
        var _gogo_element_9 := _GogoElement_0.new(_GogoImport_0, {"name": "Held", "text": "Pressed", "width": "120px", "height": "54px", "background_color": "#355e92", "pressed_background_color": "#23446e", "border_color": "#cbd8ed", "border_width": "2px"}, {}, [], "examples/styling/WidgetGallery.gogo:33:17", null, false)
        _gogo_element_9.resolve_bindings()
        var _gogo_element_10 := _GogoElement_0.new(_GogoImport_0, {"name": "Disabled", "text": "Disabled", "width": "120px", "height": "54px", "disabled": _gogo_value_5, "disabled_background_color": "#313947", "border_color": "#cbd8ed", "border_width": "2px"}, {}, [], "examples/styling/WidgetGallery.gogo:34:17", null, false)
        _gogo_element_10.resolve_bindings()
        var _gogo_element_6 := _GogoElement_0.new(HBox, {"name": "Buttons", "gap": "8px"}, {}, [_gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_10], "examples/styling/WidgetGallery.gogo:30:13", null, false)
        _gogo_element_6.resolve_bindings()
        var _gogo_element_12 := _GogoElement_0.new(Toggle, {"name": "Controlled", "text": "Enabled", "value": _gogo_value_6, "checked_background_color": "#227a60", "border_color": "#cbd8ed", "border_width": "2px"}, {}, [], "examples/styling/WidgetGallery.gogo:37:17", null, false)
        _gogo_element_12.origins["value"] = "examples/styling/WidgetGallery.gogo:37:58"
        _gogo_element_12.resolve_bindings()
        var _gogo_element_13 := _GogoElement_0.new(Toggle, {"name": "Unchecked", "text": "Unchecked", "value": _gogo_value_7}, {}, [], "examples/styling/WidgetGallery.gogo:38:17", null, false)
        _gogo_element_13.resolve_bindings()
        var _gogo_element_14 := _GogoElement_0.new(NativeButton, {"name": "Native", "text": "Native Button"}, {"pressed": _gogo_value_8}, [], "examples/styling/WidgetGallery.gogo:39:17", null, false)
        _gogo_element_14.resolve_bindings()
        var _gogo_element_11 := _GogoElement_0.new(HBox, {"name": "Edits", "gap": "8px"}, {}, [_gogo_element_12, _gogo_element_13, _gogo_element_14], "examples/styling/WidgetGallery.gogo:36:13", null, false)
        _gogo_element_11.resolve_bindings()
        var _gogo_element_15 := _GogoElement_0.new(_GogoProject_0, {"name": "Rose"}, {}, [], "examples/styling/WidgetGallery.gogo:41:13", null, false)
        _gogo_element_15.resolve_bindings()
        var _gogo_element_16 := _GogoElement_0.new(HBox, {"name": "Keys", "gap": "4px"}, {}, [_gogo_value_9], "examples/styling/WidgetGallery.gogo:42:13", null, false)
        _gogo_element_16.resolve_bindings()
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "grow": _gogo_value_0, "stretch": _gogo_value_1, "padding": "12px", "gap": "8px", "background_color": "#252b38", "border_color": "#8295bc", "border_width": "2px"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_6, _gogo_element_11, _gogo_element_15, _gogo_element_16, _gogo_value_10], "examples/styling/WidgetGallery.gogo:24:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "8px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/styling/WidgetGallery.gogo:23:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant, _gogo_value_1: StringName) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Rect, {"name": _gogo_value_1, "width": "20px", "height": "12px", "background_color": "#8295bc"}, {}, [], "examples/styling/WidgetGallery.gogo:42:68", _gogo_value_0, true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Extra", "text": "Conditional child", "background_color": "#142a3a", "padding": "3px"}, {}, [], "examples/styling/WidgetGallery.gogo:43:14", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
