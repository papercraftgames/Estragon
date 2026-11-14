extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (1),
        (1),
        (24),
        (12),
        (26),
        (1),
        (1),
        (12),
        (16),
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
        _gogo_value_1: int,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: int,
        _gogo_value_5: float,
        _gogo_value_6: int,
        _gogo_value_7: Variant,
        _gogo_value_8: Variant,
        _gogo_value_9: Variant,
        _gogo_value_10: int,
        _gogo_value_11: int
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"text": "Retained unit lengths", "font_size": _gogo_value_4}, {}, [], "examples/lengths/ResponsiveHome.gogo:10:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(_GogoProject_0, {"name": "Panel"}, {}, [], "examples/lengths/ResponsiveHome.gogo:12:17", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Text, {"text": "Resize the window."}, {}, [], "examples/lengths/ResponsiveHome.gogo:14:21", null, false)
        var _gogo_element_7 := _GogoElement_0.new(Text, {"text": "The blue panel follows its parent content box.", "font_size": _gogo_value_10}, {}, [], "examples/lengths/ResponsiveHome.gogo:15:21", null, false)
        var _gogo_element_8 := _GogoElement_0.new(Text, {"text": "Percent sizes and weighted flex are distinct.", "font_size": _gogo_value_11}, {}, [], "examples/lengths/ResponsiveHome.gogo:16:21", null, false)
        var _gogo_element_5 := _GogoElement_0.new(VBox, {"width": "100%", "gap": _gogo_value_9}, {}, [_gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/lengths/ResponsiveHome.gogo:13:17", null, false)
        var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Content", "flex": _gogo_value_5, "stretch": _gogo_value_6, "padding": _gogo_value_7, "gap": _gogo_value_8}, {}, [_gogo_element_4, _gogo_element_5], "examples/lengths/ResponsiveHome.gogo:11:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Page", "flex": _gogo_value_0, "stretch": _gogo_value_1, "padding": _gogo_value_2, "gap": _gogo_value_3}, {}, [_gogo_element_2, _gogo_element_3], "examples/lengths/ResponsiveHome.gogo:9:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100vw", "height": "100vh"}, {}, [_gogo_element_1], "examples/lengths/ResponsiveHome.gogo:8:12", null, false)
        return _gogo_element_0
