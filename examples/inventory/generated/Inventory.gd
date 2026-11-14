extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Row = preload("res://examples/inventory/generated/Row.gd")
const Item = preload("res://examples/inventory/generated/Item.gd")
signal items_changed(previous: Array, value: Array)
var items: Array = [Item.new(1,"Apple"),Item.new(2,"Bread"),Item.new(3,"Carrot")]:
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: Array = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
        return items

signal show_note_changed(previous: bool, value: bool)
var show_note: bool = true:
    set(_gogo_incoming_show_note):
        if is_same(show_note, _gogo_incoming_show_note): return
        var _gogo_previous_show_note: bool = show_note
        show_note = _gogo_incoming_show_note
        show_note_changed.emit(_gogo_previous_show_note, _gogo_incoming_show_note)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_note_changed")
        return show_note

signal use_map_changed(previous: bool, value: bool)
var use_map: bool = false:
    set(_gogo_incoming_use_map):
        if is_same(use_map, _gogo_incoming_use_map): return
        var _gogo_previous_use_map: bool = use_map
        use_map = _gogo_incoming_use_map
        use_map_changed.emit(_gogo_previous_use_map, _gogo_incoming_use_map)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"use_map_changed")
        return use_map

var next_id: int = 4
func build_view() -> Element:
    var rows: Array = []
    if use_map:
        rows = items.map(func(item): return _GogoFactories_0._gogo_build_0((item.id), ("Row%d" % item.id), (item)))
    else:
        for item in items:
            rows.append(_GogoFactories_0._gogo_build_1((item.id), ("Row%d" % item.id), (item)))
    return _GogoFactories_0._gogo_build_2(
        (Vector2(24,24)),
        (10.0),
        (_GogoFactories_0._gogo_build_3() if show_note else null),
        ([[], rows, null]),
        (8.0),
        (append_item),
        (insert_item),
        (remove_item),
        (reverse_items),
        (8.0),
        (replace_item),
        (first_state),
        (rename_item),
        (toggle_note),
        (toggle_map)
    )
func append_item() -> void:
    items = items + [Item.new(next_id,"Item %d" % next_id)]
    next_id += 1
func insert_item() -> void:
    var next: Array = items.duplicate()
    next.insert(mini(1,next.size()),Item.new(next_id,"Inserted %d" % next_id))
    next_id += 1
    items = next
func remove_item() -> void:
    items = items.slice(1)
func reverse_items() -> void:
    var next: Array = items.duplicate()
    next.reverse()
    items = next
func replace_item() -> void:
    if items.is_empty(): return
    var next: Array = items.duplicate()
    next[0] = Item.new(next_id,"Replacement %d" % next_id)
    next_id += 1
    items = next
func first_state() -> void:
    if not items.is_empty(): get_node("UI/Panel/Row%d" % items[0].id).increment()
func rename_item() -> void:
    if not items.is_empty(): items[0].title += "!"
func toggle_note() -> void:
    show_note = not show_note
func toggle_map() -> void:
    use_map = not use_map
func _ready() -> void:
    if OS.get_environment("ESTRAGON_LISTS_PROOF") == "1": write_proof.call_deferred()
func write_proof() -> void:
    for index in range(5): await get_tree().process_frame
    var file := FileAccess.open("res://.godot/lists-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":items.size(),"text":get_node("UI/Panel/Row1/Caption").text}))


const _GogoProject_0 = preload("Row.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: _GogoProject_0.Item) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoProject_0, {"name": _gogo_value_1, "item": _gogo_value_2}, {}, [], "examples/inventory/Inventory.gogo:17:45", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: _GogoProject_0.Item) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoProject_0, {"name": _gogo_value_1, "item": _gogo_value_2}, {}, [], "examples/inventory/Inventory.gogo:20:25", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: Vector2,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: Callable,
        _gogo_value_6: Callable,
        _gogo_value_7: Callable,
        _gogo_value_8: Callable,
        _gogo_value_9: Variant,
        _gogo_value_10: Callable,
        _gogo_value_11: Callable,
        _gogo_value_12: Callable,
        _gogo_value_13: Callable,
        _gogo_value_14: Callable
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Title", "text": "Inventory | keyed native rows"}, {}, [], "examples/inventory/Inventory.gogo:23:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Footer", "text": "Static footer retains its native identity"}, {}, [], "examples/inventory/Inventory.gogo:26:13", null, false)
        var _gogo_element_5 := _GogoElement_0.new(UiButton, {"text": "Append"}, {"pressed": _gogo_value_5}, [], "examples/inventory/Inventory.gogo:28:17", null, false)
        var _gogo_element_6 := _GogoElement_0.new(UiButton, {"text": "Insert"}, {"pressed": _gogo_value_6}, [], "examples/inventory/Inventory.gogo:29:17", null, false)
        var _gogo_element_7 := _GogoElement_0.new(UiButton, {"text": "Remove"}, {"pressed": _gogo_value_7}, [], "examples/inventory/Inventory.gogo:30:17", null, false)
        var _gogo_element_8 := _GogoElement_0.new(UiButton, {"text": "Reverse"}, {"pressed": _gogo_value_8}, [], "examples/inventory/Inventory.gogo:31:17", null, false)
        var _gogo_element_4 := _GogoElement_0.new(HBox, {"name": "Controls", "gap": _gogo_value_4}, {}, [_gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/inventory/Inventory.gogo:27:13", null, false)
        var _gogo_element_10 := _GogoElement_0.new(UiButton, {"text": "Replace"}, {"pressed": _gogo_value_10}, [], "examples/inventory/Inventory.gogo:34:17", null, false)
        var _gogo_element_11 := _GogoElement_0.new(UiButton, {"text": "First +"}, {"pressed": _gogo_value_11}, [], "examples/inventory/Inventory.gogo:35:17", null, false)
        var _gogo_element_12 := _GogoElement_0.new(UiButton, {"text": "Rename"}, {"pressed": _gogo_value_12}, [], "examples/inventory/Inventory.gogo:36:17", null, false)
        var _gogo_element_13 := _GogoElement_0.new(UiButton, {"text": "Note"}, {"pressed": _gogo_value_13}, [], "examples/inventory/Inventory.gogo:37:17", null, false)
        var _gogo_element_14 := _GogoElement_0.new(UiButton, {"text": "For / map"}, {"pressed": _gogo_value_14}, [], "examples/inventory/Inventory.gogo:38:17", null, false)
        var _gogo_element_9 := _GogoElement_0.new(HBox, {"gap": _gogo_value_9}, {}, [_gogo_element_10, _gogo_element_11, _gogo_element_12, _gogo_element_13, _gogo_element_14], "examples/inventory/Inventory.gogo:33:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "width": "100%", "gap": _gogo_value_1}, {}, [_gogo_element_2, _gogo_value_2, _gogo_value_3, _gogo_element_3, _gogo_element_4, _gogo_element_9], "examples/inventory/Inventory.gogo:22:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "width": "90vw"}, {}, [_gogo_element_1], "examples/inventory/Inventory.gogo:21:12", null, false)
        return _gogo_element_0


    static func _gogo_build_3() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Note", "text": "Select First +, then Reverse: row state travels with its key."}, {}, [], "examples/inventory/Inventory.gogo:24:14", null, false)
        return _gogo_element_0
