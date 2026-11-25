extends Node2D
const Inventory = preload("Inventory.gd")
const Item = preload("Item.gd")
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
signal inventory_changed(previous: Inventory, value: Inventory)
var inventory: Inventory = preload("../../../addons/estragon/runtime/data/state.tres").value({"items":[{"id":1,"name":"Rope","details":{"note":"Coiled"}},{"id":2,"name":"Lantern","quantity":2}]}, Inventory, null, "examples/data/Gallery.gogo:10:15"):
    set(_gogo_incoming_inventory):
        if is_same(inventory, _gogo_incoming_inventory): return
        var _gogo_previous_inventory: Inventory = inventory
        inventory = _gogo_incoming_inventory
        inventory_changed.emit(_gogo_previous_inventory, _gogo_incoming_inventory)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"inventory_changed")
        return inventory

var row_calls: Dictionary = {}
var summary_calls: int = 0
var summarize: Callable = summary.bind()
var root_calls: int = 0
signal show_rows_changed(previous: bool, value: bool)
var show_rows: bool = true:
    set(_gogo_incoming_show_rows):
        if is_same(show_rows, _gogo_incoming_show_rows): return
        var _gogo_previous_show_rows: bool = show_rows
        show_rows = _gogo_incoming_show_rows
        show_rows_changed.emit(_gogo_previous_show_rows, _gogo_incoming_show_rows)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_rows_changed")
        return show_rows

signal pulse_changed(previous: int, value: int)
var pulse: int = 0:
    set(_gogo_incoming_pulse):
        if is_same(pulse, _gogo_incoming_pulse): return
        var _gogo_previous_pulse: int = pulse
        pulse = _gogo_incoming_pulse
        pulse_changed.emit(_gogo_previous_pulse, _gogo_incoming_pulse)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"pulse_changed")
        return pulse

signal raw_changed(previous: Array, value: Array)
var raw: Array = []:
    set(_gogo_incoming_raw):
        if is_same(raw, _gogo_incoming_raw): return
        var _gogo_previous_raw: Array = raw
        raw = _gogo_incoming_raw
        raw_changed.emit(_gogo_previous_raw, _gogo_incoming_raw)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"raw_changed")
        return raw

signal raw_data_changed(previous: Dictionary, value: Dictionary)
var raw_data: Dictionary = {"value":0}:
    set(_gogo_incoming_raw_data):
        if is_same(raw_data, _gogo_incoming_raw_data): return
        var _gogo_previous_raw_data: Dictionary = raw_data
        raw_data = _gogo_incoming_raw_data
        raw_data_changed.emit(_gogo_previous_raw_data, _gogo_incoming_raw_data)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"raw_data_changed")
        return raw_data

func summary(value: Inventory) -> String:
    summary_calls += 1
    return value.title + ": " + str(value.items.size()) + " items; " + (value.items.at(0).details.note if not value.items.is_empty() else "empty")
func row(item: Item) -> Element:
    row_calls[item.id] = row_calls.get(item.id,0)+1
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/data/Gallery.gogo:1249", item.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0(
        (_gogo_mount_key),
        ("Row"+str(item.id)),
        (item.name+" × "+str(item.quantity)+" — "+item.details.note),
        (preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/data/Gallery.gogo:1438", self.use_item, "bind", [item], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.bind(_gogo_arguments[0]), func(): self.use_item.bind(item)))
    ))
func use_item(item: Item) -> void:
    preload("../../../addons/estragon/runtime/data/state.tres").assign(item, "quantity", item.quantity+1, "examples/data/Gallery.gogo:26:5", func(): item.quantity = item.quantity)
func build_view() -> Element:
    root_calls += 1
    return _GogoFactories_0._gogo_build_1((preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/data/Gallery.gogo:1751", summarize, "call", [inventory], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.call(_gogo_arguments[0]), func(): summarize.call(inventory))), (inventory.items.map(row) if self.show_rows else []), (str(self.pulse)+" / raw "+str(preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/data/Gallery.gogo:1887", self.raw, "size", [], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.size(), func(): self.raw.size()))+":"+str(self.raw_data.value)))
func replace_inventory() -> void:
    inventory = preload("../../../addons/estragon/runtime/data/state.tres").value({"title":"Refilled","items":[{"id":2,"name":"Lantern","quantity":3},{"id":1,"name":"Rope"}]}, Inventory, inventory, "examples/data/Gallery.gogo:31:5")
func replace_items() -> void:
    preload("../../../addons/estragon/runtime/data/state.tres").assign(inventory, "items", [{"id":1,"name":"Cable"}], "examples/data/Gallery.gogo:33:5", func(): inventory.items = inventory.items)

const _GOGO_DATA_TYPES_1d7df5c96fc828ad = {"inventory": Inventory,"show_rows": TYPE_BOOL,"pulse": TYPE_INT,"raw": TYPE_ARRAY,"raw_data": TYPE_DICTIONARY,}

const _GOGO_RENDER_FUNCTIONS_1d7df5c96fc828ad = {
"ordinary": ["summary", "use_item", "replace_inventory", "replace_items"],
"reactive": ["row", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_1d7df5c96fc828ad = {
"inventory": "Inventory",
"pulse": "int",
"raw": "Array",
"raw_data": "Dictionary",
"show_rows": "bool"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Variant,
        _gogo_value_1: StringName,
        _gogo_value_2: String,
        _gogo_value_3: Callable
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_2}, {}, [], "examples/data/Gallery.gogo:24:85", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(_GogoImport_0, {"name": "Action", "text": "Use"}, {"pressed": _gogo_value_3}, [], "examples/data/Gallery.gogo:24:159", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": _gogo_value_1, "width": "100%", "height": "48px"}, {}, [_gogo_element_1, _gogo_element_2], "examples/data/Gallery.gogo:24:12", _gogo_value_0, true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: String, _gogo_value_1: Variant, _gogo_value_2: String) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Title", "text": _gogo_value_0}, {}, [], "examples/data/Gallery.gogo:29:132", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Pulse", "text": _gogo_value_2}, {}, [], "examples/data/Gallery.gogo:29:238", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "List", "width": "100%", "height": "100%", "gap": "8px", "padding": "16px"}, {}, [_gogo_element_2, _gogo_value_1, _gogo_element_3], "examples/data/Gallery.gogo:29:62", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "DataUI", "width": "640px", "height": "360px"}, {}, [_gogo_element_1], "examples/data/Gallery.gogo:29:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
