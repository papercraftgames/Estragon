extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
signal title_changed(previous: String, value: String)
var title: String = "Base":
    set(_gogo_incoming_title):
        if is_same(title, _gogo_incoming_title): return
        var _gogo_previous_title: String = title
        title = _gogo_incoming_title
        title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
        return title

var ordinary_calls: int = 0
var hidden_calls: int = 0
var base_calls: int = 0
func ordinary(value: String) -> String:
    ordinary_calls += 1
    return value.to_upper()
func hidden() -> String:
    hidden_calls += 1
    return self.title
func badge() -> Element:
    base_calls += 1
    var label: String = self.title
    return _GogoFactories_0._gogo_build_0((label))

const _GOGO_RENDER_FUNCTIONS_f391fae5a7e51185 = {
"ordinary": ["ordinary", "hidden"],
"reactive": ["badge"]
}
const _GOGO_BINDABLE_PROPERTIES_f391fae5a7e51185 = {
"title": "String"
}


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "BaseBadge", "text": _gogo_value_0}, {}, [], "examples/core_reactivity/Base.gogo:18:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
