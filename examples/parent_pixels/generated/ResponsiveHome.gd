extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (1.0),
        (1.0),
        (true),
        (true),
        (24),
        (12),
        (26),
        (true),
        (true),
        (12),
        (16),
        (true),
        (8),
        (16),
        (16)
    )


const _GogoProject_0 = preload("ResponsivePanel.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: float,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: bool,
        _gogo_value_4: float,
        _gogo_value_5: float,
        _gogo_value_6: int,
        _gogo_value_7: bool,
        _gogo_value_8: bool,
        _gogo_value_9: float,
        _gogo_value_10: float,
        _gogo_value_11: bool,
        _gogo_value_12: float,
        _gogo_value_13: int,
        _gogo_value_14: int
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"text": "Parent-relative pixel helpers", "font_size": _gogo_value_6}, {}, [], "examples/parent_pixels/ResponsiveHome.gogo:10:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(_GogoProject_0, {"name": "Panel"}, {}, [], "examples/parent_pixels/ResponsiveHome.gogo:12:17", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Text, {"text": "Resize the window."}, {}, [], "examples/parent_pixels/ResponsiveHome.gogo:14:21", null, false)
        var _gogo_element_7 := _GogoElement_0.new(Text, {"text": "The blue panel follows its parent content box.", "font_size": _gogo_value_13}, {}, [], "examples/parent_pixels/ResponsiveHome.gogo:15:21", null, false)
        var _gogo_element_8 := _GogoElement_0.new(Text, {"text": "Percentages are pixel floats, separate from fill.", "font_size": _gogo_value_14}, {}, [], "examples/parent_pixels/ResponsiveHome.gogo:16:21", null, false)
        var _gogo_element_5 := _GogoElement_0.new(VBox, {"fill_width": _gogo_value_11, "gap": _gogo_value_12}, {}, [_gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/parent_pixels/ResponsiveHome.gogo:13:17", null, false)
        var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Content", "fill_width": _gogo_value_7, "fill_height": _gogo_value_8, "padding": _gogo_value_9, "gap": _gogo_value_10}, {}, [_gogo_element_4, _gogo_element_5], "examples/parent_pixels/ResponsiveHome.gogo:11:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Page", "fill_width": _gogo_value_2, "fill_height": _gogo_value_3, "padding": _gogo_value_4, "gap": _gogo_value_5}, {}, [_gogo_element_2, _gogo_element_3], "examples/parent_pixels/ResponsiveHome.gogo:9:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "viewport_width_scale": _gogo_value_0, "viewport_height_scale": _gogo_value_1}, {}, [_gogo_element_1], "examples/parent_pixels/ResponsiveHome.gogo:8:12", null, false)
        return _gogo_element_0
