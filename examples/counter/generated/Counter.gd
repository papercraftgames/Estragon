extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
signal count_changed(previous: int, value: int)
var count: int = 0:
    set(_gogo_incoming_count):
        if is_same(count, _gogo_incoming_count): return
        var _gogo_previous_count: int = count
        count = _gogo_incoming_count
        count_changed.emit(_gogo_previous_count, _gogo_incoming_count)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"count_changed")
        return count

var ui: Node:
    get: return get_node_or_null("UI")

func _ready() -> void:
    if OS.get_environment("ESTRAGON_C3_PROOF") == "1": write_proof.call_deferred()

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (16.0),
        (8.0),
        (Color(0.2,0.8,0.6)),
        (28),
        (Color(0.74,0.64,0.94)),
        ("Count: %d" % self.count),
        (26),
        (12.0),
        (1),
        (increment),
        (1),
        (self.count == 0),
        (reset_count),
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
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Color,
        _gogo_value_4: int,
        _gogo_value_5: Color,
        _gogo_value_6: String,
        _gogo_value_7: int,
        _gogo_value_8: Variant,
        _gogo_value_9: float,
        _gogo_value_10: Callable,
        _gogo_value_11: float,
        _gogo_value_12: bool,
        _gogo_value_13: Callable,
        _gogo_value_14: Variant,
        _gogo_value_15: int,
        _gogo_value_16: int
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Rect, {"name": "Accent", "height": _gogo_value_2, "width": "100%", "fill": _gogo_value_3}, {}, [], "examples/counter/Counter.gogo:19:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Title", "text": "Estragon native Gogo Counter", "font_size": _gogo_value_4, "color": _gogo_value_5}, {}, [], "examples/counter/Counter.gogo:20:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Text, {"name": "Count", "text": _gogo_value_6, "font_size": _gogo_value_7}, {}, [], "examples/counter/Counter.gogo:21:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(UiButton, {"name": "Increment", "text": "+", "flex": _gogo_value_9}, {"pressed": _gogo_value_10}, [], "examples/counter/Counter.gogo:23:17", null, false)
        var _gogo_element_7 := _GogoElement_0.new(UiButton, {"name": "Reset", "text": "Reset", "flex": _gogo_value_11, "disabled": _gogo_value_12}, {"pressed": _gogo_value_13}, [], "examples/counter/Counter.gogo:24:17", null, false)
        var _gogo_element_5 := _GogoElement_0.new(HBox, {"name": "Actions", "width": "100%", "gap": _gogo_value_8}, {}, [_gogo_element_6, _gogo_element_7], "examples/counter/Counter.gogo:22:13", null, false)
        var _gogo_element_9 := _GogoElement_0.new(Text, {"name": "Hint", "text": "Click + to update retained Nodes.", "font_size": _gogo_value_15}, {}, [], "examples/counter/Counter.gogo:27:17", null, false)
        var _gogo_element_10 := _GogoElement_0.new(Text, {"name": "Resize", "text": "Resize the window: nested native stacks reflow.", "font_size": _gogo_value_16}, {}, [], "examples/counter/Counter.gogo:28:17", null, false)
        var _gogo_element_8 := _GogoElement_0.new(VBox, {"name": "Details", "width": "100%", "gap": _gogo_value_14}, {}, [_gogo_element_9, _gogo_element_10], "examples/counter/Counter.gogo:26:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "width": "100%", "gap": _gogo_value_1}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_8], "examples/counter/Counter.gogo:18:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "width": "90vw"}, {}, [_gogo_element_1], "examples/counter/Counter.gogo:17:12", null, false)
        return _gogo_element_0
