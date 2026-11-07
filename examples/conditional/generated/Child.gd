extends "../../../addons/estragon/runtime/node/vbox.gd"
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = Model.new():
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

signal value_changed(previous: int, value: int)
var value: int = 0:
    set(_gogo_incoming_value):
        if is_same(value, _gogo_incoming_value): return
        var _gogo_previous_value: int = value
        value = _gogo_incoming_value
        value_changed.emit(_gogo_previous_value, _gogo_incoming_value)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"value_changed")
        return value

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(("%s: %d" % [model.title,value]))


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "ChildView", "text": _gogo_value_0}, {}, [], "examples/conditional/Child.gogo:8:12", null, false)
        return _gogo_element_0
