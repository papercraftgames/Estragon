extends Node2D
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
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

func _ready() -> void:
    if OS.get_environment("ESTRAGON_C3_PROOF") == "1": write_proof.call_deferred()

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        (16.0),
        (8.0),
        (true),
        (Color(0.2,0.8,0.6)),
        (28),
        (Color(0.74,0.64,0.94)),
        ("Count: %d" % self.count),
        (26),
        (true),
        (12.0),
        (true),
        (increment),
        (true),
        (self.count == 0),
        (reset_count),
        (true),
        (6.0),
        (18),
        (18)
    )

func increment() -> void:
    count += 1

func reset_count() -> void:
    count = 0

func write_proof() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    var file := FileAccess.open("res://.godot/c3-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":ui.get_node("Panel/Count").text,"native":ui.get_layout_root()==ui}))


func _notification(_gogo_what: int) -> void:
    preload("res://addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("res://addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: float,
        _gogo_value_4: float,
        _gogo_value_5: bool,
        _gogo_value_6: Color,
        _gogo_value_7: int,
        _gogo_value_8: Color,
        _gogo_value_9: String,
        _gogo_value_10: int,
        _gogo_value_11: bool,
        _gogo_value_12: float,
        _gogo_value_13: bool,
        _gogo_value_14: Callable,
        _gogo_value_15: bool,
        _gogo_value_16: bool,
        _gogo_value_17: Callable,
        _gogo_value_18: bool,
        _gogo_value_19: float,
        _gogo_value_20: int,
        _gogo_value_21: int
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "Accent", "height": _gogo_value_4, "fill_width": _gogo_value_5, "fill": _gogo_value_6}, {}, [], "examples/counter/Counter.gogo:19:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Title", "text": "Estragon native Gogo Counter", "font_size": _gogo_value_7, "color": _gogo_value_8}, {}, [], "examples/counter/Counter.gogo:20:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Text, {"name": "Count", "text": _gogo_value_9, "font_size": _gogo_value_10}, {}, [], "examples/counter/Counter.gogo:21:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(UiButton, {"name": "Increment", "text": "+", "fill_width": _gogo_value_13}, {"pressed": _gogo_value_14}, [], "examples/counter/Counter.gogo:23:17", null, false)
        var _gogo_element_7 := _GogoElement_0.new(UiButton, {"name": "Reset", "text": "Reset", "fill_width": _gogo_value_15, "disabled": _gogo_value_16}, {"pressed": _gogo_value_17}, [], "examples/counter/Counter.gogo:24:17", null, false)
        var _gogo_element_5 := _GogoElement_0.new(HBox, {"name": "Actions", "fill_width": _gogo_value_11, "gap": _gogo_value_12}, {}, [_gogo_element_6, _gogo_element_7], "examples/counter/Counter.gogo:22:13", null, false)
        var _gogo_element_9 := _GogoElement_0.new(Text, {"name": "Hint", "text": "Click + to update retained Nodes.", "font_size": _gogo_value_20}, {}, [], "examples/counter/Counter.gogo:27:17", null, false)
        var _gogo_element_10 := _GogoElement_0.new(Text, {"name": "Resize", "text": "Resize the window: nested native stacks reflow.", "font_size": _gogo_value_21}, {}, [], "examples/counter/Counter.gogo:28:17", null, false)
        var _gogo_element_8 := _GogoElement_0.new(VBox, {"name": "Details", "fill_width": _gogo_value_18, "gap": _gogo_value_19}, {}, [_gogo_element_9, _gogo_element_10], "examples/counter/Counter.gogo:26:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "fill_width": _gogo_value_2, "gap": _gogo_value_3}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_8], "examples/counter/Counter.gogo:18:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "viewport_width_scale": _gogo_value_1}, {}, [_gogo_element_1], "examples/counter/Counter.gogo:17:12", null, false)
        return _gogo_element_0
