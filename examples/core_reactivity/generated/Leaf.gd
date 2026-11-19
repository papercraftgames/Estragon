extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Model = preload("Model.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = null:
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

var views: int = 0
func build_view() -> Element:
    views += 1
    var label: String = "null" if self.model == null else self.model.label
    return _GogoFactories_0._gogo_build_0((label))

const _GOGO_RENDER_FUNCTIONS_4aa00326bb5946cd = {
"ordinary": [],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_0}, {}, [], "examples/core_reactivity/Leaf.gogo:11:45", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Box, {"width": "180px", "height": "32px"}, {}, [_gogo_element_1], "examples/core_reactivity/Leaf.gogo:11:12", null, false)
        return _gogo_element_0
