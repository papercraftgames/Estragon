extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Pixels = preload("../../../addons/estragon/runtime/composition/pixels.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
signal width_percent_changed(previous: float, value: float)
var width_percent: float = 50.0:
    set(_gogo_incoming_width_percent):
        if is_same(width_percent, _gogo_incoming_width_percent): return
        var _gogo_previous_width_percent: float = width_percent
        width_percent = _gogo_incoming_width_percent
        width_percent_changed.emit(_gogo_previous_width_percent, _gogo_incoming_width_percent)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"width_percent_changed")
        return width_percent

func toggle_width() -> void:
    width_percent = 25.0 if width_percent == 50.0 else 50.0
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Pixels.parent_width(self,self.width_percent)),
        (Pixels.parent_height(self,75.0)),
        (10),
        (8),
        ("%s%% width / 75%% height" % self.width_percent),
        (18),
        (true),
        (true),
        (Color(0.25,0.5,0.9)),
        (40),
        (true),
        (self.toggle_width)
    )


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: float,
        _gogo_value_1: float,
        _gogo_value_2: float,
        _gogo_value_3: float,
        _gogo_value_4: String,
        _gogo_value_5: int,
        _gogo_value_6: bool,
        _gogo_value_7: bool,
        _gogo_value_8: Color,
        _gogo_value_9: float,
        _gogo_value_10: bool,
        _gogo_value_11: Callable
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_4, "font_size": _gogo_value_5}, {}, [], "examples/parent_pixels/ResponsivePanel.gogo:13:9", null, false)
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "Color", "fill_width": _gogo_value_6, "fill_height": _gogo_value_7, "fill": _gogo_value_8}, {}, [], "examples/parent_pixels/ResponsivePanel.gogo:14:9", null, false)
        var _gogo_element_3 := _GogoElement_0.new(UiButton, {"name": "Action", "text": "Toggle 25% / 50%", "height": _gogo_value_9, "fill_width": _gogo_value_10}, {"pressed": _gogo_value_11}, [], "examples/parent_pixels/ResponsivePanel.gogo:15:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Panel", "width": _gogo_value_0, "height": _gogo_value_1, "padding": _gogo_value_2, "gap": _gogo_value_3}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3], "examples/parent_pixels/ResponsivePanel.gogo:12:12", null, false)
        return _gogo_element_0
