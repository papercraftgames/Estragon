
extends "../../../addons/estragon/runtime/node/hbox.gd"
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Item = preload("res://examples/inventory/generated/Item.gd")
signal item_changed(previous: Item, value: Item)
var item: Item = null:
    set(_gogo_incoming_item):
        if is_same(item, _gogo_incoming_item): return
        var _gogo_previous_item: Item = item
        item = _gogo_incoming_item
        item_changed.emit(_gogo_previous_item, _gogo_incoming_item)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"item_changed")
        return item

signal clicks_changed(previous: int, value: int)
var clicks: int = 0:
    set(_gogo_incoming_clicks):
        if is_same(clicks, _gogo_incoming_clicks): return
        var _gogo_previous_clicks: int = clicks
        clicks = _gogo_incoming_clicks
        clicks_changed.emit(_gogo_previous_clicks, _gogo_incoming_clicks)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"clicks_changed")
        return clicks

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(("%s | row state: %d" % [item.title,clicks] if item != null else "Empty"))
func increment() -> void:
    clicks += 1


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Caption", "text": _gogo_value_0}, {}, [], "examples/inventory/Row.gogo:10:12", null, false)
        return _gogo_element_0
