extends Node2D
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const State = preload("res://examples/reactive/generated/State.gd")
const Model = preload("res://examples/reactive/generated/Model.gd")
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

signal count_changed(previous: int, value: int)
var count: int = 0:
    set(_gogo_incoming_count):
        if is_same(count, _gogo_incoming_count): return
        var _gogo_previous_count: int = count
        count = _gogo_incoming_count
        count_changed.emit(_gogo_previous_count, _gogo_incoming_count)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"count_changed")
        return count

var ui: Node:
    get: return get_node_or_null("UI")
func independent() -> String:
    return "Pure helper in the same observed view"
func _ready() -> void:
    if OS.get_environment("ESTRAGON_REACTIVE_PROOF") == "1": write_proof.call_deferred()
func build_view() -> Element:
    var player: State = model.player if model != null else null
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        (12.0 + self.count),
        (_GogoFactories_0._gogo_build_1((player.title), (player.tint)) if player != null else _GogoFactories_0._gogo_build_2()),
        (true),
        (12.0),
        (_GogoFactories_0._gogo_build_3((player.width), (40.0), (player.tint)) if player != null else _GogoFactories_0._gogo_build_4((40.0))),
        (80.0),
        (40.0),
        (Color(0.55,0.32,0.9)),
        ("Value: %d" % (self.count + self.count)),
        (advance),
        (independent())
    )
func advance() -> void:
    count += 1
    model.player.width += 40.0
    model.player.tint = Color(0.9,0.35,0.2)
    model.player.title = "Changed without rebuilding"
func write_proof() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var file := FileAccess.open("res://.godot/reactive-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":ui.get_node("Panel/Count").text}))


func _notification(_gogo_what: int) -> void:
    preload("res://addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("res://addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: float,
        _gogo_value_4: Variant,
        _gogo_value_5: bool,
        _gogo_value_6: float,
        _gogo_value_7: Variant,
        _gogo_value_8: float,
        _gogo_value_9: float,
        _gogo_value_10: Color,
        _gogo_value_11: String,
        _gogo_value_12: Callable,
        _gogo_value_13: String
    ) -> _GogoElement_0:
        var _gogo_element_3 := _GogoElement_0.new(Rect, {"name": "Other", "width": _gogo_value_8, "height": _gogo_value_9, "fill": _gogo_value_10}, {}, [], "examples/reactive/Demo.gogo:26:17", null, false)
        var _gogo_element_2 := _GogoElement_0.new(HBox, {"name": "Row", "fill_width": _gogo_value_5, "gap": _gogo_value_6}, {}, [_gogo_value_7, _gogo_element_3], "examples/reactive/Demo.gogo:24:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Text, {"name": "Count", "text": _gogo_value_11}, {}, [], "examples/reactive/Demo.gogo:28:13", null, false)
        var _gogo_element_5 := _GogoElement_0.new(UiButton, {"name": "Advance", "text": "Change model and layout"}, {"pressed": _gogo_value_12}, [], "examples/reactive/Demo.gogo:29:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Text, {"name": "Independent", "text": _gogo_value_13}, {}, [], "examples/reactive/Demo.gogo:30:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "fill_width": _gogo_value_2, "gap": _gogo_value_3}, {}, [_gogo_value_4, _gogo_element_2, _gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/reactive/Demo.gogo:22:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "viewport_width_scale": _gogo_value_1}, {}, [_gogo_element_1], "examples/reactive/Demo.gogo:21:12", null, false)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: String, _gogo_value_1: Color) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Title", "text": _gogo_value_0, "color": _gogo_value_1}, {}, [], "examples/reactive/Demo.gogo:23:14", null, false)
        return _gogo_element_0


    static func _gogo_build_2() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Title"}, {}, [], "examples/reactive/Demo.gogo:23:99", null, false)
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: float, _gogo_value_1: float, _gogo_value_2: Color) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Rect, {"name": "Bar", "width": _gogo_value_0, "height": _gogo_value_1, "fill": _gogo_value_2}, {}, [], "examples/reactive/Demo.gogo:25:18", null, false)
        return _gogo_element_0


    static func _gogo_build_4(_gogo_value_0: float) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Rect, {"name": "Bar", "height": _gogo_value_0}, {}, [], "examples/reactive/Demo.gogo:25:115", null, false)
        return _gogo_element_0
