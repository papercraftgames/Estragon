extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Checkbox = preload("../../../addons/estragon/runtime/node/checkbox.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
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

var presses: int = 0
func pressed(): presses += 1
func row(item: Model) -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/checkbox/Checkboxes.gogo:915", "parameter", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0((preload("../../../addons/estragon/runtime/composition/binding.gd").new(item, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "flag", func(_gogo_source, _gogo_edit: bool): _gogo_source.flag = _gogo_edit, "item.flag"))))
func build_view() -> Element:
    var current: bool = self.model.flag if self.model != null else false
    return _GogoFactories_0._gogo_build_1(
        ("Checkbox / implicit Bool — revision "+str(self.revision)),
        (24),
        (_GogoFactories_0._gogo_build_2(
            (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "flag", func(_gogo_source, _gogo_edit: bool): _gogo_source.flag = _gogo_edit, "self.model.flag")),
            (self.pressed),
            (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "flag", func(_gogo_source, _gogo_edit: bool): _gogo_source.flag = _gogo_edit, "self.model.flag")),
            (current),
            (not self.model.flag),
            (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
            ((preload("../../../addons/estragon/runtime/composition/state.tres").method_at("examples/checkbox/Checkboxes.gogo:1805", self, "row", [self.model], func(_gogo_receiver, _gogo_arguments): return _gogo_receiver.row(_gogo_arguments[0]), func(): self.row(self.model)) as Element))
        ) if self.model != null and self.show else null),
        (([preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/checkbox/Checkboxes.gogo:1962", "b", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_3((true))),preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/checkbox/Checkboxes.gogo:2020", "a", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_4())] if self.reverse else [preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/checkbox/Checkboxes.gogo:2087", "a", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_5()),preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/checkbox/Checkboxes.gogo:2131", "b", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_6((true)))])),
        (2),
        (true)
    )

const _GOGO_RENDER_FUNCTIONS_770127f043a1791d = {
"ordinary": ["pressed"],
"reactive": ["row", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_770127f043a1791d = {
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
        var _gogo_element_0 := _GogoElement_0.new(Checkbox, {"name": "Parameter", "value": _gogo_value_0}, {}, [], "examples/checkbox/Checkboxes.gogo:19:12", "parameter", true)
        _gogo_element_0.origins["value"] = "examples/checkbox/Checkboxes.gogo:19:55"
        _gogo_element_0.resolve_bindings()
        _gogo_element_0.set_text_body([["Parameter path", "examples/checkbox/Checkboxes.gogo:19:73"]])
        return _gogo_element_0


    static func _gogo_build_1(
        _gogo_value_0: String,
        _gogo_value_1: int,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: bool
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_0, "font_size": _gogo_value_1}, {}, [], "examples/checkbox/Checkboxes.gogo:23:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(HBox, {"name": "Rows", "gap": "12px", "width": "360px", "wrap": true}, {}, [_gogo_value_3], "examples/checkbox/Checkboxes.gogo:31:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(Checkbox, {"name": "GridCheck"}, {}, [], "examples/checkbox/Checkboxes.gogo:35:13", null, false)
        _gogo_element_4.resolve_bindings()
        _gogo_element_4.set_text_body([["Grid natural size", "examples/checkbox/Checkboxes.gogo:35:40"]])
        var _gogo_element_5 := _GogoElement_0.new(Checkbox, {"name": "Disabled", "disabled": true, "value": _gogo_value_5}, {}, [], "examples/checkbox/Checkboxes.gogo:36:13", null, false)
        _gogo_element_5.resolve_bindings()
        _gogo_element_5.set_text_body([["Disabled square", "examples/checkbox/Checkboxes.gogo:36:61"]])
        var _gogo_element_3 := _GogoElement_0.new(Grid, {"name": "Grid", "columns": _gogo_value_4, "column_gap": "12px"}, {}, [_gogo_element_4, _gogo_element_5], "examples/checkbox/Checkboxes.gogo:34:9", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "direction": "column", "gap": "12px", "padding": "20px", "background_color": "#172332"}, {}, [_gogo_element_1, _gogo_value_2, _gogo_element_2, _gogo_element_3], "examples/checkbox/Checkboxes.gogo:22:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: Variant,
        _gogo_value_1: Callable,
        _gogo_value_2: Variant,
        _gogo_value_3: bool,
        _gogo_value_4: bool,
        _gogo_value_5: Variant,
        _gogo_value_6: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Checkbox, {"name": "Bound", "value": _gogo_value_0}, {"pressed": _gogo_value_1}, [], "examples/checkbox/Checkboxes.gogo:25:13", null, false)
        _gogo_element_1.origins["value"] = "examples/checkbox/Checkboxes.gogo:25:36"
        _gogo_element_1.resolve_bindings()
        _gogo_element_1.set_text_body([["Checkbox square and label", "examples/checkbox/Checkboxes.gogo:25:83"]])
        var _gogo_element_2 := _GogoElement_0.new(Toggle, {"name": "Toggle", "value": _gogo_value_2}, {}, [], "examples/checkbox/Checkboxes.gogo:26:13", null, false)
        _gogo_element_2.origins["value"] = "examples/checkbox/Checkboxes.gogo:26:35"
        _gogo_element_2.resolve_bindings()
        _gogo_element_2.set_text_body([["Toggle shares the model", "examples/checkbox/Checkboxes.gogo:26:59"]])
        var _gogo_element_3 := _GogoElement_0.new(Checkbox, {"name": "Snapshot", "value": _gogo_value_3}, {}, [], "examples/checkbox/Checkboxes.gogo:27:13", null, false)
        _gogo_element_3.resolve_bindings()
        _gogo_element_3.set_text_body([["One-way local snapshot", "examples/checkbox/Checkboxes.gogo:27:55"]])
        var _gogo_element_4 := _GogoElement_0.new(Checkbox, {}, {}, [], "examples/checkbox/Checkboxes.gogo:28:13", null, false)
        _gogo_element_4.expand([["name", "Computed", "examples/checkbox/Checkboxes.gogo:28:23"], ["value", _gogo_value_4, "examples/checkbox/Checkboxes.gogo:28:39"], [null, _gogo_value_5, "examples/checkbox/Checkboxes.gogo:28:67"]])
        _gogo_element_4.resolve_bindings()
        _gogo_element_4.set_text_body([["One-way computed expression", "examples/checkbox/Checkboxes.gogo:28:83"]])
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Controls", "gap": "10px"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_value_6], "examples/checkbox/Checkboxes.gogo:24:10", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: bool) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Checkbox, {"name": "B", "value": _gogo_value_0}, {}, [], "examples/checkbox/Checkboxes.gogo:32:16", "b", true)
        _gogo_element_0.resolve_bindings()
        _gogo_element_0.set_text_body([["Second", "examples/checkbox/Checkboxes.gogo:32:56"]])
        return _gogo_element_0


    static func _gogo_build_4() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Checkbox, {"name": "A"}, {}, [], "examples/checkbox/Checkboxes.gogo:32:74", "a", true)
        _gogo_element_0.resolve_bindings()
        _gogo_element_0.set_text_body([["First", "examples/checkbox/Checkboxes.gogo:32:101"]])
        return _gogo_element_0


    static func _gogo_build_5() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Checkbox, {"name": "A"}, {}, [], "examples/checkbox/Checkboxes.gogo:32:141", "a", true)
        _gogo_element_0.resolve_bindings()
        _gogo_element_0.set_text_body([["First", "examples/checkbox/Checkboxes.gogo:32:168"]])
        return _gogo_element_0


    static func _gogo_build_6(_gogo_value_0: bool) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Checkbox, {"name": "B", "value": _gogo_value_0}, {}, [], "examples/checkbox/Checkboxes.gogo:32:185", "b", true)
        _gogo_element_0.resolve_bindings()
        _gogo_element_0.set_text_body([["Second", "examples/checkbox/Checkboxes.gogo:32:225"]])
        return _gogo_element_0
