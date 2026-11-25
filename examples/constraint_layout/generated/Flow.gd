extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
var calls: int = 0
func build_view() -> Element:
    calls += 1
    return _GogoFactories_0._gogo_build_0()

const _GOGO_RENDER_FUNCTIONS_a6cc7420130e67f0 = {
"ordinary": [],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0() -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Rect, {"name": "A", "width": "90px", "height": "20px", "background_color": "#66bb99"}, {}, [], "examples/constraint_layout/Flow.gogo:9:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "B", "width": "90px", "height": "20px", "background_color": "#88ccaa"}, {}, [], "examples/constraint_layout/Flow.gogo:10:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(Rect, {"name": "C", "width": "90px", "height": "20px", "background_color": "#aaddbb"}, {}, [], "examples/constraint_layout/Flow.gogo:11:9", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "Flow", "wrap": true, "column_gap": "10px", "row_gap": "8px"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3], "examples/constraint_layout/Flow.gogo:8:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
