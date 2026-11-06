
extends Node2D
const Model = preload("res://examples/twoway/generated/Model.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/vbox.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const Action = preload("res://addons/estragon/runtime/node/button.gd")
const Row = preload("res://examples/twoway/generated/Row.gd")
signal model_changed(previous: Model, value: Model)
var model: Model = Model.new():
    set(_gogo_incoming_model):
        if is_same(model, _gogo_incoming_model): return
        var _gogo_previous_model: Model = model
        model = _gogo_incoming_model
        model_changed.emit(_gogo_previous_model, _gogo_incoming_model)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"model_changed")
        return model

signal enabled_changed(previous: bool, value: bool)
var enabled: bool = false:
    set(_gogo_incoming_enabled):
        if is_same(enabled, _gogo_incoming_enabled): return
        var _gogo_previous_enabled: bool = enabled
        enabled = _gogo_incoming_enabled
        enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
        return enabled

signal show_row_changed(previous: bool, value: bool)
var show_row: bool = true:
    set(_gogo_incoming_show_row):
        if is_same(show_row, _gogo_incoming_show_row): return
        var _gogo_previous_show_row: bool = show_row
        show_row = _gogo_incoming_show_row
        show_row_changed.emit(_gogo_previous_show_row, _gogo_incoming_show_row)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"show_row_changed")
        return show_row

signal reverse_changed(previous: bool, value: bool)
var reverse: bool = false:
    set(_gogo_incoming_reverse):
        if is_same(reverse, _gogo_incoming_reverse): return
        var _gogo_previous_reverse: bool = reverse
        reverse = _gogo_incoming_reverse
        reverse_changed.emit(_gogo_previous_reverse, _gogo_incoming_reverse)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"reverse_changed")
        return reverse

signal revision_changed(previous: int, value: int)
var revision: int = 0:
    set(_gogo_incoming_revision):
        if is_same(revision, _gogo_incoming_revision): return
        var _gogo_previous_revision: int = revision
        revision = _gogo_incoming_revision
        revision_changed.emit(_gogo_previous_revision, _gogo_incoming_revision)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"revision_changed")
        return revision

func build_view() -> Element:
    var rows: Array = [_GogoFactories_0._gogo_build_0((1), (self.model)), _GogoFactories_0._gogo_build_1((2), (self.model))] if self.model != null and self.show_row else []
    if self.reverse: rows.reverse()
    return _GogoFactories_0._gogo_build_2(
        (8.0),
        (_GogoFactories_0._gogo_build_3((preload("res://addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root.model if _gogo_root != null and _gogo_root.model != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "model.enabled"))) if self.model != null else null),
        ("Enabled" if self.model != null and self.model.enabled else "Disabled"),
        (preload("res://addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "enabled")),
        ("Revision: %d" % self.revision),
        (rows),
        (replace_model),
        (toggle_rows),
        (reverse_rows)
    )
func replace_model() -> void:
    model = Model.new()
func toggle_rows() -> void:
    show_row = not show_row
func reverse_rows() -> void:
    reverse = not reverse
func _ready() -> void:
    if OS.get_environment("ESTRAGON_TWOWAY_PROOF")=="1": _proof.call_deferred()
func _proof() -> void:
    for index in range(8): await get_tree().process_frame
    var output := FileAccess.open("res://.godot/twoway-play.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"count":revision,"text":"Revision: %d" % revision}))
    output.close()


func _notification(_gogo_what: int) -> void:
    preload("res://addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("res://addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: Row.Model) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Row, {"name": "First", "model": _gogo_value_1}, {}, [], "examples/twoway/Demo.gogo:17:24", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant, _gogo_value_1: Row.Model) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Row, {"name": "Second", "model": _gogo_value_1}, {}, [], "examples/twoway/Demo.gogo:17:73", _gogo_value_0, true)
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: float,
        _gogo_value_1: Variant,
        _gogo_value_2: String,
        _gogo_value_3: Variant,
        _gogo_value_4: String,
        _gogo_value_5: Variant,
        _gogo_value_6: Callable,
        _gogo_value_7: Callable,
        _gogo_value_8: Callable
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Heading", "text": "Native two-way boolean input"}, {}, [], "examples/twoway/Demo.gogo:20:9", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Status", "text": _gogo_value_2}, {}, [], "examples/twoway/Demo.gogo:22:9", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Toggle, {"name": "HostEdit", "text": "Host flag"}, {}, [], "examples/twoway/Demo.gogo:23:9", null, false)
        _gogo_element_4.bindings = {"value": _gogo_value_3}
        var _gogo_element_5 := _GogoElement_0.new(Text, {"name": "Revision", "text": _gogo_value_4}, {}, [], "examples/twoway/Demo.gogo:24:9", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Action, {"text": "Replace model"}, {"pressed": _gogo_value_6}, [], "examples/twoway/Demo.gogo:26:9", null, false)
        var _gogo_element_7 := _GogoElement_0.new(Action, {"text": "Show / hide rows"}, {"pressed": _gogo_value_7}, [], "examples/twoway/Demo.gogo:27:9", null, false)
        var _gogo_element_8 := _GogoElement_0.new(Action, {"name": "Reverse", "text": "Reverse keys"}, {"pressed": _gogo_value_8}, [], "examples/twoway/Demo.gogo:28:9", null, false)
        var _gogo_element_1 := _GogoElement_0.new(Box, {"name": "Panel", "gap": _gogo_value_0}, {}, [_gogo_element_2, _gogo_value_1, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_value_5, _gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/twoway/Demo.gogo:19:29", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI"}, {}, [_gogo_element_1], "examples/twoway/Demo.gogo:19:12", null, false)
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Toggle, {"name": "Edit", "text": "Model enabled"}, {}, [], "examples/twoway/Demo.gogo:21:10", null, false)
        _gogo_element_0.bindings = {"value": _gogo_value_0}
        return _gogo_element_0
