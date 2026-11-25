extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Select = preload("../../../addons/estragon/runtime/node/select.gd")
const Option = preload("../../../addons/estragon/runtime/node/option.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/slider.gd")
const NumberInput = preload("../../../addons/estragon/runtime/node/number_input.gd")
const IntegerInput = preload("../../../addons/estragon/runtime/node/integer_input.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const _GogoImport_1 = preload("../../../addons/estragon/runtime/node/input.gd")
const Checkbox = preload("../../../addons/estragon/runtime/node/checkbox.gd")
const RadioGroup = preload("../../../addons/estragon/runtime/node/radio_group.gd")
const Radio = preload("../../../addons/estragon/runtime/node/radio.gd")
const Model = preload("Model.gd")
const Item = preload("Item.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = preload("../../../addons/estragon/runtime/data/state.tres").value(Model.new(), Model, null, "examples/values/Values.gogo:19:15"):
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

signal items_changed(previous: _GogoArrayCollection, value: _GogoArrayCollection)
var items: _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/state.tres").value([{"id":"build","label":"Build"},{"id":"explore","label":"Explore"},{"id":"repair","label":"Repair","disabled":true}], [Item], null, "examples/values/Values.gogo:20:15"):
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: _GogoArrayCollection = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"items_changed")
        return items

signal caption_changed(previous: String, value: String)
var caption: String = "Shared native focus":
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

signal numeric_props_changed(previous: Dictionary, value: Dictionary)
var numeric_props: Dictionary = {}:
    set(_gogo_incoming_numeric_props):
        if is_same(numeric_props, _gogo_incoming_numeric_props): return
        var _gogo_previous_numeric_props: Dictionary = numeric_props
        numeric_props = _gogo_incoming_numeric_props
        numeric_props_changed.emit(_gogo_previous_numeric_props, _gogo_incoming_numeric_props)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"numeric_props_changed")
        return numeric_props

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

signal props_changed(previous: Dictionary, value: Dictionary)
var props: Dictionary = {}:
    set(_gogo_incoming_props):
        if is_same(props, _gogo_incoming_props): return
        var _gogo_previous_props: Dictionary = props
        props = _gogo_incoming_props
        props_changed.emit(_gogo_previous_props, _gogo_incoming_props)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"props_changed")
        return props

signal option_props_changed(previous: Dictionary, value: Dictionary)
var option_props: Dictionary = {}:
    set(_gogo_incoming_option_props):
        if is_same(option_props, _gogo_incoming_option_props): return
        var _gogo_previous_option_props: Dictionary = option_props
        option_props = _gogo_incoming_option_props
        option_props_changed.emit(_gogo_previous_option_props, _gogo_incoming_option_props)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"option_props_changed")
        return option_props

func option(item: Item) -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/values/Values.gogo:1716", item.id, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0(
        (item.id),
        (_gogo_mount_key),
        (item.id),
        (item.label),
        (item.disabled),
        (item.hidden),
        (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.option_props.get(item.id,{})))
    ))
func build_view() -> Element:
    var snapshot: float = self.model.volume
    return _GogoFactories_0._gogo_build_1(
        (24),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "mode", func(_gogo_source, _gogo_edit: String): _gogo_source.mode = _gogo_edit, "self.model.mode", (self.model.mode) if self != null and self.model != null else null, TYPE_STRING)),
        (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
        (self.items.map(self.option)),
        (["2fr","1fr"]),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "volume", func(_gogo_source, _gogo_edit: float): _gogo_source.volume = _gogo_edit, "self.model.volume", (self.model.volume) if self != null and self.model != null else null, TYPE_FLOAT)),
        (0.0),
        (1.0),
        (0.05),
        (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.numeric_props)),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "volume", func(_gogo_source, _gogo_edit: float): _gogo_source.volume = _gogo_edit, "self.model.volume", (self.model.volume) if self != null and self.model != null else null, TYPE_FLOAT)),
        (0.0),
        (1.0),
        (0.05),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "lives", func(_gogo_source, _gogo_edit: int): _gogo_source.lives = _gogo_edit, "self.model.lives", (self.model.lives) if self != null and self.model != null else null, TYPE_INT)),
        (0),
        (99),
        (1),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "volume", func(_gogo_source, _gogo_edit: float): _gogo_source.volume = _gogo_edit, "self.model.volume", (self.model.volume) if self != null and self.model != null else null, TYPE_FLOAT)),
        (0.0),
        (1.0),
        (0.05),
        (snapshot),
        (0.0),
        (1.0),
        (0.05),
        (0.5),
        (0.0),
        (1.0),
        (0.05),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "caption", func(_gogo_source, _gogo_edit: String): _gogo_source.caption = _gogo_edit, "self.caption", (self.caption) if self != null else null, TYPE_STRING)),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "flag", func(_gogo_source, _gogo_edit: bool): _gogo_source.flag = _gogo_edit, "self.flag", (self.flag) if self != null else null)),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "mode", func(_gogo_source, _gogo_edit: String): _gogo_source.mode = _gogo_edit, "self.model.mode", (self.model.mode) if self != null and self.model != null else null, TYPE_STRING)),
        ("Mode: "+self.model.mode+" / Volume: "+str(self.model.volume)+" / Lives: "+str(self.model.lives)+" / revision "+str(self.revision))
    )
const _GogoArrayCollection = preload("../../../addons/estragon/runtime/data/array_collection.gd")

const _GOGO_DATA_TYPES_3658ddff408a495c = {"model": Model,"items": [Item],"caption": TYPE_STRING,"flag": TYPE_BOOL,"numeric_props": TYPE_DICTIONARY,"revision": TYPE_INT,"props": TYPE_DICTIONARY,"option_props": TYPE_DICTIONARY,}

const _GOGO_RENDER_FUNCTIONS_3658ddff408a495c = {
"ordinary": [],
"reactive": ["option", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_3658ddff408a495c = {
"caption": "String",
"flag": "bool",
"items": "ArrayCollection[Item]",
"model": "Model",
"numeric_props": "Dictionary",
"option_props": "Dictionary",
"props": "Dictionary",
"revision": "int"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: StringName,
        _gogo_value_1: Variant,
        _gogo_value_2: String,
        _gogo_value_3: String,
        _gogo_value_4: bool,
        _gogo_value_5: bool,
        _gogo_value_6: Variant
    ) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Option, {}, {}, [], "examples/values/Values.gogo:28:12", _gogo_value_1, true)
        _gogo_element_0.expand([["name", _gogo_value_0, "examples/values/Values.gogo:28:20"], ["value", _gogo_value_2, "examples/values/Values.gogo:28:49"], ["text", _gogo_value_3, "examples/values/Values.gogo:28:65"], ["disabled", _gogo_value_4, "examples/values/Values.gogo:28:83"], ["hidden", _gogo_value_5, "examples/values/Values.gogo:28:108"], [null, _gogo_value_6, "examples/values/Values.gogo:28:129"]])
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(
        _gogo_value_0: int,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: Variant,
        _gogo_value_6: float,
        _gogo_value_7: float,
        _gogo_value_8: float,
        _gogo_value_9: Variant,
        _gogo_value_10: Variant,
        _gogo_value_11: float,
        _gogo_value_12: float,
        _gogo_value_13: float,
        _gogo_value_14: Variant,
        _gogo_value_15: int,
        _gogo_value_16: int,
        _gogo_value_17: int,
        _gogo_value_18: Variant,
        _gogo_value_19: float,
        _gogo_value_20: float,
        _gogo_value_21: float,
        _gogo_value_22: float,
        _gogo_value_23: float,
        _gogo_value_24: float,
        _gogo_value_25: float,
        _gogo_value_26: float,
        _gogo_value_27: float,
        _gogo_value_28: float,
        _gogo_value_29: float,
        _gogo_value_30: Variant,
        _gogo_value_31: Variant,
        _gogo_value_32: Variant,
        _gogo_value_33: String
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "Native value controls", "font_size": _gogo_value_0}, {}, [], "examples/values/Values.gogo:32:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Select, {}, {}, [_gogo_value_3], "examples/values/Values.gogo:33:9", null, false)
        _gogo_element_2.origins["value"] = "examples/values/Values.gogo:33:45"
        _gogo_element_2.expand([["name", "Select", "examples/values/Values.gogo:33:17"], ["width", "220px", "examples/values/Values.gogo:33:31"], ["value", _gogo_value_1, "examples/values/Values.gogo:33:45"], [null, _gogo_value_2, "examples/values/Values.gogo:33:69"]])
        _gogo_element_2.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(_GogoImport_0, {}, {}, [], "examples/values/Values.gogo:38:17", null, false)
        _gogo_element_5.origins["value"] = "examples/values/Values.gogo:38:43"
        _gogo_element_5.expand([["name", "Horizontal", "examples/values/Values.gogo:38:25"], ["value", _gogo_value_5, "examples/values/Values.gogo:38:43"], ["min_value", _gogo_value_6, "examples/values/Values.gogo:38:69"], ["max_value", _gogo_value_7, "examples/values/Values.gogo:38:85"], ["step", _gogo_value_8, "examples/values/Values.gogo:38:101"], ["width", "250px", "examples/values/Values.gogo:38:113"], [null, _gogo_value_9, "examples/values/Values.gogo:38:127"]])
        _gogo_element_5.resolve_bindings()
        var _gogo_element_6 := _GogoElement_0.new(NumberInput, {"name": "Number", "value": _gogo_value_10, "min_value": _gogo_value_11, "max_value": _gogo_value_12, "step": _gogo_value_13}, {}, [], "examples/values/Values.gogo:39:17", null, false)
        _gogo_element_6.origins["value"] = "examples/values/Values.gogo:39:44"
        _gogo_element_6.resolve_bindings()
        var _gogo_element_7 := _GogoElement_0.new(IntegerInput, {"name": "Integer", "value": _gogo_value_14, "min_value": _gogo_value_15, "max_value": _gogo_value_16, "step": _gogo_value_17}, {}, [], "examples/values/Values.gogo:40:17", null, false)
        _gogo_element_7.origins["value"] = "examples/values/Values.gogo:40:46"
        _gogo_element_7.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(VBox, {"gap": "12px"}, {}, [_gogo_element_5, _gogo_element_6, _gogo_element_7], "examples/values/Values.gogo:37:13", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_8 := _GogoElement_0.new(_GogoImport_0, {"name": "Vertical", "value": _gogo_value_18, "min_value": _gogo_value_19, "max_value": _gogo_value_20, "step": _gogo_value_21, "orientation": "vertical", "width": "40px", "height": "160px"}, {}, [], "examples/values/Values.gogo:42:13", null, false)
        _gogo_element_8.origins["value"] = "examples/values/Values.gogo:42:37"
        _gogo_element_8.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(Grid, {"name": "Ranges", "columns": _gogo_value_4, "width": "100%", "column_gap": "16px"}, {}, [_gogo_element_4, _gogo_element_8], "examples/values/Values.gogo:36:9", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_9 := _GogoElement_0.new(NumberInput, {"name": "Snapshot", "value": _gogo_value_22, "min_value": _gogo_value_23, "max_value": _gogo_value_24, "step": _gogo_value_25}, {}, [], "examples/values/Values.gogo:44:9", null, false)
        _gogo_element_9.resolve_bindings()
        var _gogo_element_13 := _GogoElement_0.new(Option, {"value": "x", "text": "Nested popup"}, {}, [], "examples/values/Values.gogo:47:68", null, false)
        _gogo_element_13.resolve_bindings()
        var _gogo_element_14 := _GogoElement_0.new(Option, {"value": "y", "text": "Second"}, {}, [], "examples/values/Values.gogo:47:107", null, false)
        _gogo_element_14.resolve_bindings()
        var _gogo_element_12 := _GogoElement_0.new(Select, {"name": "ClippedSelect", "value": "", "width": "100%"}, {}, [_gogo_element_13, _gogo_element_14], "examples/values/Values.gogo:47:17", null, false)
        _gogo_element_12.resolve_bindings()
        var _gogo_element_15 := _GogoElement_0.new(_GogoImport_0, {"name": "ClippedSlider", "value": _gogo_value_26, "min_value": _gogo_value_27, "max_value": _gogo_value_28, "step": _gogo_value_29, "width": "100%"}, {}, [], "examples/values/Values.gogo:48:17", null, false)
        _gogo_element_15.resolve_bindings()
        var _gogo_element_11 := _GogoElement_0.new(VBox, {"name": "Clip", "width": "290px", "height": "70px", "vertical_scroll": true, "gap": "8px", "padding": "8px", "border_width": "2px", "border_color": "#888888"}, {}, [_gogo_element_12, _gogo_element_15], "examples/values/Values.gogo:46:13", null, false)
        _gogo_element_11.resolve_bindings()
        var _gogo_element_10 := _GogoElement_0.new(HBox, {"name": "ClipRow", "gap": "12px", "width": "100%", "wrap": true}, {}, [_gogo_element_11], "examples/values/Values.gogo:45:9", null, false)
        _gogo_element_10.resolve_bindings()
        var _gogo_element_16 := _GogoElement_0.new(_GogoImport_1, {"name": "Input", "value": _gogo_value_30}, {}, [], "examples/values/Values.gogo:51:9", null, false)
        _gogo_element_16.origins["value"] = "examples/values/Values.gogo:51:29"
        _gogo_element_16.resolve_bindings()
        var _gogo_element_17 := _GogoElement_0.new(Checkbox, {"name": "Check", "value": _gogo_value_31}, {}, [], "examples/values/Values.gogo:52:9", null, false)
        _gogo_element_17.origins["value"] = "examples/values/Values.gogo:52:32"
        _gogo_element_17.resolve_bindings()
        _gogo_element_17.set_text_body([["Other controls", "examples/values/Values.gogo:52:50"]])
        var _gogo_element_19 := _GogoElement_0.new(Radio, {"value": "build"}, {}, [], "examples/values/Values.gogo:54:13", null, false)
        _gogo_element_19.resolve_bindings()
        _gogo_element_19.set_text_body([["Build", "examples/values/Values.gogo:54:34"]])
        var _gogo_element_20 := _GogoElement_0.new(Radio, {"value": "explore"}, {}, [], "examples/values/Values.gogo:54:47", null, false)
        _gogo_element_20.resolve_bindings()
        _gogo_element_20.set_text_body([["Explore", "examples/values/Values.gogo:54:70"]])
        var _gogo_element_18 := _GogoElement_0.new(RadioGroup, {"name": "Radio", "value": _gogo_value_32, "direction": "row", "gap": "12px"}, {}, [_gogo_element_19, _gogo_element_20], "examples/values/Values.gogo:53:9", null, false)
        _gogo_element_18.origins["value"] = "examples/values/Values.gogo:53:34"
        _gogo_element_18.resolve_bindings()
        var _gogo_element_21 := _GogoElement_0.new("Button", {"name": "NativeButton", "text": "Foreign native Button"}, {}, [], "examples/values/Values.gogo:56:9", null, false)
        _gogo_element_21.resolve_bindings()
        var _gogo_element_22 := _GogoElement_0.new("LineEdit", {"name": "NativeLine", "text": "Foreign native editor"}, {}, [], "examples/values/Values.gogo:57:9", null, false)
        _gogo_element_22.resolve_bindings()
        var _gogo_element_23 := _GogoElement_0.new(Text, {"text": _gogo_value_33}, {}, [], "examples/values/Values.gogo:58:9", null, false)
        _gogo_element_23.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "direction": "column", "gap": "12px", "padding": "16px", "background_color": "#202020"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_9, _gogo_element_10, _gogo_element_16, _gogo_element_17, _gogo_element_18, _gogo_element_21, _gogo_element_22, _gogo_element_23], "examples/values/Values.gogo:31:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
