extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const Nested = preload("MinimumPanel.gd")
signal constrained_changed(previous: bool, value: bool)
var constrained: bool = true:
    set(_gogo_incoming_constrained):
        if is_same(constrained, _gogo_incoming_constrained): return
        var _gogo_previous_constrained: bool = constrained
        constrained = _gogo_incoming_constrained
        constrained_changed.emit(_gogo_previous_constrained, _gogo_incoming_constrained)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"constrained_changed")
        return constrained

signal floor_width_changed(previous: String, value: String)
var floor_width: String = "280px":
    set(_gogo_incoming_floor_width):
        if is_same(floor_width, _gogo_incoming_floor_width): return
        var _gogo_previous_floor_width: String = floor_width
        floor_width = _gogo_incoming_floor_width
        floor_width_changed.emit(_gogo_previous_floor_width, _gogo_incoming_floor_width)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"floor_width_changed")
        return floor_width

signal enabled_changed(previous: bool, value: bool)
var enabled: bool = false:
    set(_gogo_incoming_enabled):
        if is_same(enabled, _gogo_incoming_enabled): return
        var _gogo_previous_enabled: bool = enabled
        enabled = _gogo_incoming_enabled
        enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
        return enabled

var clicks: int = 0
var native_clicks: int = 0
func pressed() -> void:
    clicks += 1
func native_pressed() -> void:
    native_clicks += 1
func build_view() -> Element:
    var panel = _GogoFactories_0._gogo_build_0(
        (Color("#ffcc66")),
        (18),
        (self.pressed),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "enabled")),
        (self.native_pressed)
    )
    if self.constrained:
        panel.properties["min_width"] = self.floor_width
        panel.properties["min_height"] = "200px"
    return _GogoFactories_0._gogo_build_1((panel))


const _GogoProject_0 = preload("MinimumPanel.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Color,
        _gogo_value_1: int,
        _gogo_value_2: Callable,
        _gogo_value_3: Variant,
        _gogo_value_4: Callable
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"name": "Caption", "text": "A readable minimum", "min_width": "120px", "color": _gogo_value_0}, {}, [], "examples/lengths/MinimumGallery.gogo:20:9", null, false)
        var _gogo_element_2 := _GogoElement_0.new(UiButton, {"name": "Continue", "text": "Continue", "width": "50%", "height": "20px", "min_width": "96px", "min_height": "36px", "padding": "6px", "font_size": _gogo_value_1, "background_color": "#355e92", "border_color": "#cbd8ed", "border_width": "1px"}, {"pressed": _gogo_value_2}, [], "examples/lengths/MinimumGallery.gogo:21:9", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Toggle, {"name": "Enabled", "text": "Enabled", "min_width": "120px", "min_height": "36px"}, {}, [], "examples/lengths/MinimumGallery.gogo:22:9", null, false)
        _gogo_element_3.bindings = {"value": _gogo_value_3}
        var _gogo_element_4 := _GogoElement_0.new("Button", {"name": "Native", "text": "Native Button"}, {"pressed": _gogo_value_4}, [], "examples/lengths/MinimumGallery.gogo:23:9", null, false)
        var _gogo_element_5 := _GogoElement_0.new(_GogoProject_0, {"name": "Nested"}, {}, [], "examples/lengths/MinimumGallery.gogo:24:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Panel", "width": "100%", "padding": "12px", "border_width": "2px", "border_color": "#8295bc", "background_color": "#252b38", "gap": "12px"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5], "examples/lengths/MinimumGallery.gogo:19:17", null, false)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24"}, {}, [_gogo_value_0], "examples/lengths/MinimumGallery.gogo:29:12", null, false)
        return _gogo_element_0
