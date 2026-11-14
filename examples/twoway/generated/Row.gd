
extends "../../../addons/estragon/runtime/node/hbox.gd"
const Model = preload("res://examples/twoway/generated/Model.gd")
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Box = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
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

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0((12.0), (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "model.enabled")), ("Enabled" if self.model.enabled else "Disabled"))


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: Variant, _gogo_value_2: String) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Toggle, {"name": "Edit", "text": "Enabled"}, {}, [], "examples/twoway/Row.gogo:11:9", null, false)
        _gogo_element_1.bindings = {"value": _gogo_value_1}
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Status", "text": _gogo_value_2}, {}, [], "examples/twoway/Row.gogo:12:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "RowView", "gap": _gogo_value_0}, {}, [_gogo_element_1, _gogo_element_2], "examples/twoway/Row.gogo:10:12", null, false)
        return _gogo_element_0
