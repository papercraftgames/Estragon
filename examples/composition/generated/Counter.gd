extends Node2D
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
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

signal unused_changed(previous: int, value: int)
var unused: int = 0:
    set(_gogo_incoming_unused):
        if is_same(unused, _gogo_incoming_unused): return
        var _gogo_previous_unused: int = unused
        unused = _gogo_incoming_unused
        unused_changed.emit(_gogo_previous_unused, _gogo_incoming_unused)
    get:
        preload("res://addons/estragon/runtime/composition/state.tres").observe(self, &"unused_changed")
        return unused

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

func heading() -> String:
    return model.title
func build_view() -> Element:
    var caption: String = "Count: %d" % count
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        (12.0),
        (heading()),
        (Color(0.74,0.64,0.94)),
        (caption),
        (model.width + count * 10.0),
        (10.0),
        (Color(0.2,0.8,0.6)),
        (increment),
        (count == 0),
        (reset_count)
    )
func increment() -> void:
    count += 1
func reset_count() -> void:
    count = 0
func _ready() -> void:
    if OS.get_environment("ESTRAGON_COMPOSITION_PROOF") == "1": write_proof.call_deferred()
func write_proof() -> void:
    for index in range(5): await get_tree().process_frame
    var file := FileAccess.open("res://.godot/composition-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":get_node("UI/Panel/Count").text}))


func _notification(_gogo_what: int) -> void:
    preload("res://addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _Element = preload("res://addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: float,
        _gogo_value_4: String,
        _gogo_value_5: Color,
        _gogo_value_6: String,
        _gogo_value_7: float,
        _gogo_value_8: float,
        _gogo_value_9: Color,
        _gogo_value_10: Callable,
        _gogo_value_11: bool,
        _gogo_value_12: Callable
    ) -> _Element:
        var element_2 := _Element.new(Text, {"name": "Title", "text": _gogo_value_4, "color": _gogo_value_5}, {}, [], "examples/composition/Counter.gogo:18:13")
        var element_3 := _Element.new(Text, {"name": "Count", "text": _gogo_value_6}, {}, [], "examples/composition/Counter.gogo:19:13")
        var element_4 := _Element.new(Rect, {"name": "Bar", "width": _gogo_value_7, "height": _gogo_value_8, "fill": _gogo_value_9}, {}, [], "examples/composition/Counter.gogo:20:13")
        var element_5 := _Element.new(UiButton, {"name": "Increment", "text": "+"}, {"pressed": _gogo_value_10}, [], "examples/composition/Counter.gogo:21:13")
        var element_6 := _Element.new(UiButton, {"name": "Reset", "text": "Reset", "disabled": _gogo_value_11}, {"pressed": _gogo_value_12}, [], "examples/composition/Counter.gogo:22:13")
        var element_1 := _Element.new(VBox, {"name": "Panel", "fill_width": _gogo_value_2, "gap": _gogo_value_3}, {}, [element_2, element_3, element_4, element_5, element_6], "examples/composition/Counter.gogo:17:9")
        var element_0 := _Element.new(Entry, {"name": "UI", "position": _gogo_value_0, "viewport_width_scale": _gogo_value_1}, {}, [element_1], "examples/composition/Counter.gogo:16:12")
        return element_0
