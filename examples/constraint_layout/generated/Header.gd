extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Flow = preload("Flow.gd")
var calls: int = 0
func build_view() -> Element:
    calls += 1
    return _GogoFactories_0._gogo_build_0()

const _GOGO_RENDER_FUNCTIONS_7b29b57962a30c95 = {
"ordinary": [],
"reactive": ["build_view"]
}

const _GogoProject_0 = preload("Flow.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0() -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(_GogoProject_0, {"name": "Nested"}, {}, [], "examples/constraint_layout/Header.gogo:9:69", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "Rule", "height": "10px", "background_color": "#ccaa88"}, {}, [], "examples/constraint_layout/Header.gogo:9:91", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Header", "horizontal_align": "stretch", "gap": "6px"}, {}, [_gogo_element_1, _gogo_element_2], "examples/constraint_layout/Header.gogo:9:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
