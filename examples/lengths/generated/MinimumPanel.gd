extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0((16))

const _GOGO_RENDER_FUNCTIONS_45a2076c6334f657 = {
"ordinary": [],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: int) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "Nested minimum, retained native nodes", "font_size": _gogo_value_0}, {}, [], "examples/lengths/MinimumPanel.gogo:7:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Body", "width": "100%", "min_width": "150px", "min_height": "40px", "padding": "6px", "background_color": "#30394d"}, {}, [_gogo_element_1], "examples/lengths/MinimumPanel.gogo:6:12", null, false)
        return _gogo_element_0
