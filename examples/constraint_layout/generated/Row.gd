extends Node2D
const Item = preload("Item.gd")
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
signal item_changed(previous: Item, value: Item)
var item: Item:
    set(_gogo_incoming_item):
        if is_same(item, _gogo_incoming_item): return
        var _gogo_previous_item: Item = item
        item = _gogo_incoming_item
        item_changed.emit(_gogo_previous_item, _gogo_incoming_item)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"item_changed")
        return item

var presses: int = 0
var calls: int = 0
func activate() -> void:
    presses += 1
func build_view() -> Element:
    calls += 1
    return _GogoFactories_0._gogo_build_0((item.label), (activate))

const _GOGO_DATA_TYPES_2fb3a1be98b94ed2 = {"item": Item,}

const _GOGO_RENDER_FUNCTIONS_2fb3a1be98b94ed2 = {
"ordinary": ["activate"],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_2fb3a1be98b94ed2 = {
"item": "Item"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: String, _gogo_value_1: Callable) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "Action", "width": "90px", "height": "32px", "padding": "0px", "text": _gogo_value_0}, {"pressed": _gogo_value_1}, [], "examples/constraint_layout/Row.gogo:12:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
