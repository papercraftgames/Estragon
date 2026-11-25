extends Node2D
const Item = preload("Item.gd")
const Header = preload("Header.gd")
const Row = preload("Row.gd")
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/input.gd")
signal items_changed(previous: _GogoArrayCollection, value: _GogoArrayCollection)
var items: _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/state.tres").value([{"id":1,"label":"One"},{"id":2,"label":"Two"},{"id":3,"label":"Three"},{"id":4,"label":"Four"},{"id":5,"label":"Five"},{"id":6,"label":"Six"},{"id":7,"label":"Seven"},{"id":8,"label":"Eight"},{"id":9,"label":"Nine"},{"id":10,"label":"Ten"}], [Item], null, "examples/constraint_layout/Constraints.gogo:12:15"):
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: _GogoArrayCollection = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
        return items

signal caption_changed(previous: String, value: String)
var caption: String = "Edit me":
    set(_gogo_incoming_caption):
        if is_same(caption, _gogo_incoming_caption): return
        var _gogo_previous_caption: String = caption
        caption = _gogo_incoming_caption
        caption_changed.emit(_gogo_previous_caption, _gogo_incoming_caption)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"caption_changed")
        return caption

signal show_header_changed(previous: bool, value: bool)
var show_header: bool = true:
    set(_gogo_incoming_show_header):
        if is_same(show_header, _gogo_incoming_show_header): return
        var _gogo_previous_show_header: bool = show_header
        show_header = _gogo_incoming_show_header
        show_header_changed.emit(_gogo_previous_show_header, _gogo_incoming_show_header)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_header_changed")
        return show_header

var calls: int = 0
func row(value: Item) -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/constraint_layout/Constraints.gogo:1058", value.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0((_gogo_mount_key), ("Row"+str(value.id)), (value)))
func build_view() -> Element:
    calls += 1
    return _GogoFactories_0._gogo_build_1(
        (2),
        (["auto","1fr"]),
        (_GogoFactories_0._gogo_build_2((0), (0)) if self.show_header else null),
        (0),
        (1),
        (1),
        (0),
        (2),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "caption", func(_gogo_source, _gogo_edit: String): _gogo_source.caption = _gogo_edit, "self.caption", (self.caption) if self != null else null, TYPE_STRING)),
        (items.map(row))
    )
const _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/array_collection.gd")

const _GOGO_DATA_TYPES_e42a690000f2e313 = {"items": [Item],"caption": TYPE_STRING,"show_header": TYPE_BOOL,}

const _GOGO_RENDER_FUNCTIONS_e42a690000f2e313 = {
"ordinary": [],
"reactive": ["row", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_e42a690000f2e313 = {
"caption": "String",
"items": "ArrayCollection[Item]",
"show_header": "bool"
}

const _GogoProject_0 = preload("Row.gd")

const _GogoProject_1 = preload("Header.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: _GogoProject_0.Item) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoProject_0, {"name": _gogo_value_1, "item": _gogo_value_2}, {}, [], "examples/constraint_layout/Constraints.gogo:17:12", _gogo_value_0, true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(
        _gogo_value_0: Variant,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: Variant,
        _gogo_value_6: Variant,
        _gogo_value_7: Variant,
        _gogo_value_8: Variant,
        _gogo_value_9: Variant
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "Fixed", "row": _gogo_value_3, "column": _gogo_value_4, "width": "10px", "height": "10px", "background_color": "#dd9966"}, {}, [], "examples/constraint_layout/Constraints.gogo:23:13", null, false)
        _gogo_element_2.origins["row"] = "examples/constraint_layout/Constraints.gogo:23:32"
        _gogo_element_2.origins["column"] = "examples/constraint_layout/Constraints.gogo:23:40"
        _gogo_element_2.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {"name": "Editor", "width": "140px", "value": _gogo_value_8}, {}, [], "examples/constraint_layout/Constraints.gogo:25:17", null, false)
        _gogo_element_4.origins["value"] = "examples/constraint_layout/Constraints.gogo:25:52"
        _gogo_element_4.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(VBox, {"name": "Body", "row": _gogo_value_5, "column": _gogo_value_6, "column_span": _gogo_value_7, "vertical_scroll": true, "padding": "20px", "border_width": "2px", "border_color": "#88aacc", "background_color": "#202a34", "gap": "6px"}, {}, [_gogo_element_4, _gogo_value_9], "examples/constraint_layout/Constraints.gogo:24:13", null, false)
        _gogo_element_3.origins["row"] = "examples/constraint_layout/Constraints.gogo:24:31"
        _gogo_element_3.origins["column"] = "examples/constraint_layout/Constraints.gogo:24:39"
        _gogo_element_3.origins["column_span"] = "examples/constraint_layout/Constraints.gogo:24:50"
        _gogo_element_3.resolve_bindings()
        var _gogo_element_1 := _GogoElement_0.new(Grid, {"name": "Grid", "width": "100%", "height": "100%", "columns": _gogo_value_0, "rows": _gogo_value_1, "column_gap": "20px", "row_gap": "12px"}, {}, [_gogo_value_2, _gogo_element_2, _gogo_element_3], "examples/constraint_layout/Constraints.gogo:21:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%"}, {}, [_gogo_element_1], "examples/constraint_layout/Constraints.gogo:20:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2(_gogo_value_0: Variant, _gogo_value_1: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoProject_1, {"name": "Title", "row": _gogo_value_0, "column": _gogo_value_1}, {}, [], "examples/constraint_layout/Constraints.gogo:22:14", null, false)
        _gogo_element_0.origins["row"] = "examples/constraint_layout/Constraints.gogo:22:35"
        _gogo_element_0.origins["column"] = "examples/constraint_layout/Constraints.gogo:22:43"
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
