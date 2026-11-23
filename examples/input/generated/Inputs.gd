extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/input.gd")
const Model = preload("Model.gd")
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

signal reverse_changed(previous: bool, value: bool)
var reverse: bool = false:
    set(_gogo_incoming_reverse):
        if is_same(reverse, _gogo_incoming_reverse): return
        var _gogo_previous_reverse: bool = reverse
        reverse = _gogo_incoming_reverse
        reverse_changed.emit(_gogo_previous_reverse, _gogo_incoming_reverse)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"reverse_changed")
        return reverse

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

var submits: Array = []
var cancels: int = 0
func submitted(text: String): submits.append(text)
func cancelled(): cancels += 1
func parameter(item: Model) -> Element:
    return _GogoFactories_0._gogo_build_0((preload("../../../addons/estragon/runtime/composition/binding.gd").new(item, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "text", func(_gogo_source, _gogo_edit: String): _gogo_source.text = _gogo_edit, "item.text", (item.text) if item != null else null, TYPE_STRING)))
func build_view() -> Element:
    var current: String = self.model.text if self.model != null else ""
    return _GogoFactories_0._gogo_build_1(
        ("Input / String binding — revision "+str(self.revision)),
        (24),
        (_GogoFactories_0._gogo_build_2(
            (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "text", func(_gogo_source, _gogo_edit: String): _gogo_source.text = _gogo_edit, "self.model.text", (self.model.text) if self != null and self.model != null else null, TYPE_STRING)),
            (self.submitted),
            (self.cancelled),
            (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
            (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "text", func(_gogo_source, _gogo_edit: String): _gogo_source.text = _gogo_edit, "self.model.text", (self.model.text) if self != null and self.model != null else null, TYPE_STRING)),
            (current),
            (preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/input/Inputs.gogo:1613", self.model.text, "to_upper", [], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.to_upper(), func(): self.model.text.to_upper())),
            ((preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/input/Inputs.gogo:1657", self, "parameter", [self.model], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.parameter(_gogo_arguments[0]), func(): self.parameter(self.model)) as Element))
        ) if self.show and self.model != null else null),
        (2),
        (([preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/input/Inputs.gogo:1848", "b", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_3()),preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/input/Inputs.gogo:1896", "a", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_4())] if self.reverse else [preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/input/Inputs.gogo:1969", "a", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_5()),preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/input/Inputs.gogo:2019", "b", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_6())]) if self.show else null)
    )

const _GOGO_RENDER_FUNCTIONS_e9a4beacb98128bb = {
"ordinary": ["submitted", "cancelled"],
"reactive": ["parameter", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_e9a4beacb98128bb = {
"model": "Model",
"props": "Dictionary",
"reverse": "bool",
"revision": "int",
"show": "bool"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "Parameter", "value": _gogo_value_0, "placeholder": "Parameter path"}, {}, [], "examples/input/Inputs.gogo:19:12", null, false)
        _gogo_element_0.origins["value"] = "examples/input/Inputs.gogo:19:36"
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(
        _gogo_value_0: String,
        _gogo_value_1: int,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_0, "font_size": _gogo_value_1}, {}, [], "examples/input/Inputs.gogo:23:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(_GogoImport_0, {"name": "ReadOnly", "read_only": true, "value": "Read only / copy"}, {}, [], "examples/input/Inputs.gogo:33:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {"name": "Disabled", "disabled": true, "value": "Disabled"}, {}, [], "examples/input/Inputs.gogo:34:13", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(_GogoImport_0, {"name": "Invalid", "invalid": true, "placeholder": "Required"}, {}, [], "examples/input/Inputs.gogo:35:13", null, false)
        _gogo_element_5.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Grid, {"name": "Grid", "columns": _gogo_value_3, "column_gap": "12px", "row_gap": "10px", "width": "560px"}, {}, [_gogo_value_4, _gogo_element_3, _gogo_element_4, _gogo_element_5], "examples/input/Inputs.gogo:31:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_7 := _GogoElement_0.new(_GogoImport_0, {"name": "Clipped", "width": "320px", "value": "Native clipped text and caret"}, {}, [], "examples/input/Inputs.gogo:38:13", null, false)
        _gogo_element_7.resolve_bindings()
        var _gogo_element_6 := _GogoElement_0.new(Box, {"name": "Clip", "width": "220px", "height": "56px", "clip_content": true, "padding": "4px"}, {}, [_gogo_element_7], "examples/input/Inputs.gogo:37:9", null, false)
        _gogo_element_6.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "direction": "column", "gap": "12px", "padding": "20px", "background_color": "#172332"}, {}, [_gogo_element_1, _gogo_value_2, _gogo_element_2, _gogo_element_6], "examples/input/Inputs.gogo:22:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: Variant,
        _gogo_value_1: Callable,
        _gogo_value_2: Callable,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: String,
        _gogo_value_6: String,
        _gogo_value_7: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(_GogoImport_0, {}, {}, [], "examples/input/Inputs.gogo:25:13", null, false)
        _gogo_element_1.origins["value"] = "examples/input/Inputs.gogo:25:33"
        _gogo_element_1.expand([["name", "Bound", "examples/input/Inputs.gogo:25:20"], ["value", _gogo_value_0, "examples/input/Inputs.gogo:25:33"], ["placeholder", "Your name", "examples/input/Inputs.gogo:25:57"], ["submitted", _gogo_value_1, "examples/input/Inputs.gogo:25:81"], ["cancelled", _gogo_value_2, "examples/input/Inputs.gogo:25:108"], [null, _gogo_value_3, "examples/input/Inputs.gogo:25:135"]])
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(_GogoImport_0, {"name": "Peer", "value": _gogo_value_4}, {}, [], "examples/input/Inputs.gogo:26:13", null, false)
        _gogo_element_2.origins["value"] = "examples/input/Inputs.gogo:26:32"
        _gogo_element_2.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(_GogoImport_0, {"name": "Snapshot", "value": _gogo_value_5}, {}, [], "examples/input/Inputs.gogo:27:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {"name": "Computed", "value": _gogo_value_6}, {}, [], "examples/input/Inputs.gogo:28:13", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "Controls", "direction": "column", "gap": "10px"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_value_7], "examples/input/Inputs.gogo:24:10", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_3() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "B", "placeholder": "Second"}, {}, [], "examples/input/Inputs.gogo:32:16", "b", true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_4() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "A", "value": "Retained caret"}, {}, [], "examples/input/Inputs.gogo:32:64", "a", true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_5() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "A", "value": "Retained caret"}, {}, [], "examples/input/Inputs.gogo:32:137", "a", true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_6() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "B", "placeholder": "Second"}, {}, [], "examples/input/Inputs.gogo:32:187", "b", true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
