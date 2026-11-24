extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0()

const _GOGO_RENDER_FUNCTIONS_4ba53689790f78b0 = {
"ordinary": [],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0() -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(_GogoImport_0, {"width": "186px", "text": "First action"}, {}, [], "examples/scrollbars/ScrollPanel.gogo:7:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(_GogoImport_0, {"width": "186px", "text": "Right edge action"}, {}, [], "examples/scrollbars/ScrollPanel.gogo:8:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(_GogoImport_0, {"width": "186px", "text": "Next line"}, {}, [], "examples/scrollbars/ScrollPanel.gogo:9:9", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "Panel", "wrap": true, "width": "100%", "column_gap": "8px", "row_gap": "8px", "background_color": "#535353"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3], "examples/scrollbars/ScrollPanel.gogo:6:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
