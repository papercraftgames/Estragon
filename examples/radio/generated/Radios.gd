extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const Checkbox = preload("../../../addons/estragon/runtime/node/checkbox.gd")
const _GogoImport_1 = preload("../../../addons/estragon/runtime/node/input.gd")
const RadioGroup = preload("../../../addons/estragon/runtime/node/radio_group.gd")
const Radio = preload("../../../addons/estragon/runtime/node/radio.gd")
const _GogoImport_2 = preload("../../godot_button.gd")
const Model = preload("Model.gd")
const Item = preload("Item.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = preload("../../../addons/estragon/runtime/data/state.tres").value(Model.new(), Model, null, "examples/radio/Radios.gogo:15:15"):
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

signal items_changed(previous: _GogoArrayCollection, value: _GogoArrayCollection)
var items: _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/state.tres").value([{"id":"a","label":"Build"},{"id":"b","label":"Explore"},{"id":"c","label":"Repair"},{"id":"d","label":"Unavailable","disabled":true}], [Item], null, "examples/radio/Radios.gogo:16:15"):
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: _GogoArrayCollection = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
        return items

signal column_changed(previous: String, value: String)
var column: String = "":
    set(_gogo_incoming_column):
        if is_same(column, _gogo_incoming_column): return
        var _gogo_previous_column: String = column
        column = _gogo_incoming_column
        column_changed.emit(_gogo_previous_column, _gogo_incoming_column)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"column_changed")
        return column

signal caption_changed(previous: String, value: String)
var caption: String = "Native input":
    set(_gogo_incoming_caption):
        if is_same(caption, _gogo_incoming_caption): return
        var _gogo_previous_caption: String = caption
        caption = _gogo_incoming_caption
        caption_changed.emit(_gogo_previous_caption, _gogo_incoming_caption)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"caption_changed")
        return caption

signal flag_changed(previous: bool, value: bool)
var flag: bool = false:
    set(_gogo_incoming_flag):
        if is_same(flag, _gogo_incoming_flag): return
        var _gogo_previous_flag: bool = flag
        flag = _gogo_incoming_flag
        flag_changed.emit(_gogo_previous_flag, _gogo_incoming_flag)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"flag_changed")
        return flag

signal revision_changed(previous: int, value: int)
var revision: int = 0:
    set(_gogo_incoming_revision):
        if is_same(revision, _gogo_incoming_revision): return
        var _gogo_previous_revision: int = revision
        revision = _gogo_incoming_revision
        revision_changed.emit(_gogo_previous_revision, _gogo_incoming_revision)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"revision_changed")
        return revision

signal group_props_changed(previous: Dictionary, value: Dictionary)
var group_props: Dictionary = {}:
    set(_gogo_incoming_group_props):
        if is_same(group_props, _gogo_incoming_group_props): return
        var _gogo_previous_group_props: Dictionary = group_props
        group_props = _gogo_incoming_group_props
        group_props_changed.emit(_gogo_previous_group_props, _gogo_incoming_group_props)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"group_props_changed")
        return group_props

signal option_values_changed(previous: Dictionary, value: Dictionary)
var option_values: Dictionary = {}:
    set(_gogo_incoming_option_values):
        if is_same(option_values, _gogo_incoming_option_values): return
        var _gogo_previous_option_values: Dictionary = option_values
        option_values = _gogo_incoming_option_values
        option_values_changed.emit(_gogo_previous_option_values, _gogo_incoming_option_values)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"option_values_changed")
        return option_values

signal show_changed(previous: bool, value: bool)
var show: bool = true:
    set(_gogo_incoming_show):
        if is_same(show, _gogo_incoming_show): return
        var _gogo_previous_show: bool = show
        show = _gogo_incoming_show
        show_changed.emit(_gogo_previous_show, _gogo_incoming_show)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_changed")
        return show

var calls: int = 0
func reset() -> void: preload("../../../addons/estragon/runtime/data/state.tres").assign(model, "choice", "b", "examples/radio/Radios.gogo:25:23", func(): model.choice = model.choice)
func replace() -> void: model = preload("../../../addons/estragon/runtime/data/state.tres").value(Model.new(), Model, model, "examples/radio/Radios.gogo:26:25")
func option(item: Item) -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/radio/Radios.gogo:1521", item.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0(
        (_gogo_mount_key),
        ("Option"+item.id),
        (item.id),
        (item.label),
        (item.disabled),
        (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.option_values.get(item.id,{})))
    ))
func build_view() -> Element:
    calls += 1
    var snapshot: String = self.model.choice if self.model != null else ""
    return _GogoFactories_0._gogo_build_1(
        (24),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "caption", func(_gogo_source, _gogo_edit: String): _gogo_source.caption = _gogo_edit, "self.caption", (self.caption) if self != null else null, TYPE_STRING)),
        (["2fr","1fr"]),
        (_GogoFactories_0._gogo_build_2((preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "choice", func(_gogo_source, _gogo_edit: String): _gogo_source.choice = _gogo_edit, "self.model.choice", (self.model.choice) if self != null and self.model != null else null, TYPE_STRING)), (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.group_props)), (self.items.map(self.option))) if self.show and self.model != null else null),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "column", func(_gogo_source, _gogo_edit: String): _gogo_source.column = _gogo_edit, "self.column", (self.column) if self != null else null, TYPE_STRING)),
        (snapshot),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "flag", func(_gogo_source, _gogo_edit: bool): _gogo_source.flag = _gogo_edit, "self.flag", (self.flag) if self != null else null)),
        (self.reset),
        (self.replace),
        ("Selected: "+snapshot+" / column: "+self.column+" / revision: "+str(self.revision))
    )
const _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/array_collection.gd")

const _GOGO_DATA_TYPES_17bfe61b55ef6118 = {"model": Model,"items": [Item],"column": TYPE_STRING,"caption": TYPE_STRING,"flag": TYPE_BOOL,"revision": TYPE_INT,"group_props": TYPE_DICTIONARY,"option_values": TYPE_DICTIONARY,"show": TYPE_BOOL,}

const _GOGO_RENDER_FUNCTIONS_17bfe61b55ef6118 = {
"ordinary": ["reset", "replace"],
"reactive": ["option", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_17bfe61b55ef6118 = {
"caption": "String",
"column": "String",
"flag": "bool",
"group_props": "Dictionary",
"items": "ArrayCollection[Item]",
"model": "Model",
"option_values": "Dictionary",
"revision": "int",
"show": "bool"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Variant,
        _gogo_value_1: StringName,
        _gogo_value_2: String,
        _gogo_value_3: String,
        _gogo_value_4: bool,
        _gogo_value_5: Variant
    ) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Radio, {}, {}, [], "examples/radio/Radios.gogo:28:12", _gogo_value_0, true)
        _gogo_element_0.expand([["name", _gogo_value_1, "examples/radio/Radios.gogo:28:33"], ["value", _gogo_value_2, "examples/radio/Radios.gogo:28:57"], ["text", _gogo_value_3, "examples/radio/Radios.gogo:28:73"], ["disabled", _gogo_value_4, "examples/radio/Radios.gogo:28:91"], [null, _gogo_value_5, "examples/radio/Radios.gogo:28:116"]])
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(
        _gogo_value_0: int,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: String,
        _gogo_value_6: Variant,
        _gogo_value_7: Callable,
        _gogo_value_8: Callable,
        _gogo_value_9: String
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "Radio choices — one String value", "font_size": _gogo_value_0}, {}, [], "examples/radio/Radios.gogo:33:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(_GogoImport_1, {"name": "Before", "value": _gogo_value_1, "width": "240px"}, {}, [], "examples/radio/Radios.gogo:34:9", null, false)
        _gogo_element_2.origins["value"] = "examples/radio/Radios.gogo:34:30"
        _gogo_element_2.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(Radio, {"name": "X", "value": "x"}, {}, [], "examples/radio/Radios.gogo:40:17", null, false)
        _gogo_element_5.resolve_bindings()
        _gogo_element_5.set_text_body([["North", "examples/radio/Radios.gogo:40:43"]])
        var _gogo_element_6 := _GogoElement_0.new(Radio, {"name": "Y", "value": "y"}, {}, [], "examples/radio/Radios.gogo:41:17", null, false)
        _gogo_element_6.resolve_bindings()
        _gogo_element_6.set_text_body([["South", "examples/radio/Radios.gogo:41:43"]])
        var _gogo_element_7 := _GogoElement_0.new(Radio, {"name": "Z", "value": "z", "disabled": true}, {}, [], "examples/radio/Radios.gogo:42:17", null, false)
        _gogo_element_7.resolve_bindings()
        _gogo_element_7.set_text_body([["Disabled", "examples/radio/Radios.gogo:42:52"]])
        var _gogo_element_4 := _GogoElement_0.new(RadioGroup, {"name": "Column", "gap": "6px", "value": _gogo_value_4}, {}, [_gogo_element_5, _gogo_element_6, _gogo_element_7], "examples/radio/Radios.gogo:39:13", null, false)
        _gogo_element_4.origins["value"] = "examples/radio/Radios.gogo:39:49"
        _gogo_element_4.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(Grid, {"name": "Grid", "columns": _gogo_value_2, "width": "100%", "column_gap": "20px"}, {}, [_gogo_value_3, _gogo_element_4], "examples/radio/Radios.gogo:35:9", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_10 := _GogoElement_0.new(Radio, {"name": "A", "value": "a"}, {}, [], "examples/radio/Radios.gogo:47:17", null, false)
        _gogo_element_10.resolve_bindings()
        _gogo_element_10.set_text_body([["One-way snapshot: Build", "examples/radio/Radios.gogo:47:43"]])
        var _gogo_element_11 := _GogoElement_0.new(Radio, {"name": "B", "value": "b"}, {}, [], "examples/radio/Radios.gogo:48:17", null, false)
        _gogo_element_11.resolve_bindings()
        _gogo_element_11.set_text_body([["One-way snapshot: Explore", "examples/radio/Radios.gogo:48:43"]])
        var _gogo_element_12 := _GogoElement_0.new(Radio, {"name": "C", "value": "c"}, {}, [], "examples/radio/Radios.gogo:49:17", null, false)
        _gogo_element_12.resolve_bindings()
        _gogo_element_12.set_text_body([["One-way snapshot: Repair", "examples/radio/Radios.gogo:49:43"]])
        var _gogo_element_9 := _GogoElement_0.new(RadioGroup, {"name": "Snapshot", "value": _gogo_value_5, "gap": "8px"}, {}, [_gogo_element_10, _gogo_element_11, _gogo_element_12], "examples/radio/Radios.gogo:46:13", null, false)
        _gogo_element_9.resolve_bindings()
        var _gogo_element_8 := _GogoElement_0.new(VBox, {"name": "Scroll", "height": "80px", "width": "100%", "vertical_scroll": true, "padding": "4px", "border_width": "1px", "border_color": "#777777"}, {}, [_gogo_element_9], "examples/radio/Radios.gogo:45:9", null, false)
        _gogo_element_8.resolve_bindings()
        var _gogo_element_13 := _GogoElement_0.new(Checkbox, {"name": "After", "value": _gogo_value_6}, {}, [], "examples/radio/Radios.gogo:52:9", null, false)
        _gogo_element_13.origins["value"] = "examples/radio/Radios.gogo:52:32"
        _gogo_element_13.resolve_bindings()
        _gogo_element_13.set_text_body([["Other shared focus stop", "examples/radio/Radios.gogo:52:50"]])
        var _gogo_element_14 := _GogoElement_0.new(_GogoImport_0, {"name": "Reset"}, {"pressed": _gogo_value_7}, [], "examples/radio/Radios.gogo:53:9", null, false)
        _gogo_element_14.resolve_bindings()
        _gogo_element_14.set_text_body([["Reset from model", "examples/radio/Radios.gogo:53:51"]])
        var _gogo_element_15 := _GogoElement_0.new(_GogoImport_0, {"name": "Replace"}, {"pressed": _gogo_value_8}, [], "examples/radio/Radios.gogo:54:9", null, false)
        _gogo_element_15.resolve_bindings()
        _gogo_element_15.set_text_body([["Replace source", "examples/radio/Radios.gogo:54:55"]])
        var _gogo_element_16 := _GogoElement_0.new(Text, {"text": _gogo_value_9}, {}, [], "examples/radio/Radios.gogo:55:9", null, false)
        _gogo_element_16.resolve_bindings()
        var _gogo_element_17 := _GogoElement_0.new(_GogoImport_2, {"name": "Native", "text": "Native Godot Button"}, {}, [], "examples/radio/Radios.gogo:56:9", null, false)
        _gogo_element_17.resolve_bindings()
        var _gogo_element_18 := _GogoElement_0.new("LineEdit", {"name": "NativeEdit", "text": "Foreign native LineEdit"}, {}, [], "examples/radio/Radios.gogo:57:9", null, false)
        _gogo_element_18.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "direction": "column", "padding": "16px", "gap": "12px", "background_color": "#202020"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_8, _gogo_element_13, _gogo_element_14, _gogo_element_15, _gogo_element_16, _gogo_element_17, _gogo_element_18], "examples/radio/Radios.gogo:32:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2(_gogo_value_0: Variant, _gogo_value_1: Variant, _gogo_value_2: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(RadioGroup, {}, {}, [_gogo_value_2], "examples/radio/Radios.gogo:36:14", null, false)
        _gogo_element_0.origins["value"] = "examples/radio/Radios.gogo:36:69"
        _gogo_element_0.expand([["name", "Row", "examples/radio/Radios.gogo:36:26"], ["direction", "row", "examples/radio/Radios.gogo:36:37"], ["wrap", true, "examples/radio/Radios.gogo:36:53"], ["gap", "12px", "examples/radio/Radios.gogo:36:58"], ["value", _gogo_value_0, "examples/radio/Radios.gogo:36:69"], [null, _gogo_value_1, "examples/radio/Radios.gogo:36:95"]])
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
