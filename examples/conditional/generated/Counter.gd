
extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Child = preload("res://examples/conditional/generated/Child.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
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

signal show_bonus_changed(previous: bool, value: bool)
var show_bonus: bool = false:
    set(_gogo_incoming_show_bonus):
        if is_same(show_bonus, _gogo_incoming_show_bonus): return
        var _gogo_previous_show_bonus: bool = show_bonus
        show_bonus = _gogo_incoming_show_bonus
        show_bonus_changed.emit(_gogo_previous_show_bonus, _gogo_incoming_show_bonus)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_bonus_changed")
        return show_bonus

signal show_child_changed(previous: bool, value: bool)
var show_child: bool = true:
    set(_gogo_incoming_show_child):
        if is_same(show_child, _gogo_incoming_show_child): return
        var _gogo_previous_show_child: bool = show_child
        show_child = _gogo_incoming_show_child
        show_child_changed.emit(_gogo_previous_show_child, _gogo_incoming_show_child)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_child_changed")
        return show_child

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

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (0.9),
        (true),
        (12.0),
        ("Count: %d" % count),
        (_GogoFactories_0._gogo_build_1((increment)) if count > 2 else _GogoFactories_0._gogo_build_2((model.title))),
        (_GogoFactories_0._gogo_build_3((4.0), ((_GogoFactories_0._gogo_build_4((model.width), (8.0)) if model.width < 160.0 else _GogoFactories_0._gogo_build_5((model.width), (8.0))) if count > 4 else _GogoFactories_0._gogo_build_6())) if show_bonus else null),
        (_GogoFactories_0._gogo_build_7((model)) if show_child else null),
        (increment),
        (toggle_bonus),
        (toggle_child)
    )
func increment() -> void:
    count += 1
func toggle_bonus() -> void:
    show_bonus = not show_bonus
func toggle_child() -> void:
    show_child = not show_child
func _ready() -> void:
    if OS.get_environment("ESTRAGON_CONDITIONAL_PROOF") == "1": write_proof.call_deferred()
func write_proof() -> void:
    for index in range(5): await get_tree().process_frame
    var file := FileAccess.open("res://.godot/conditional-play.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"count":count,"text":get_node("UI/Panel/Always").text}))

signal unobserved_changed(previous: int, value: int)
var unobserved: int = 0:
    set(_gogo_incoming_unobserved):
        if is_same(unobserved, _gogo_incoming_unobserved): return
        var _gogo_previous_unobserved: int = unobserved
        unobserved = _gogo_incoming_unobserved
        unobserved_changed.emit(_gogo_previous_unobserved, _gogo_incoming_unobserved)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"unobserved_changed")
        return unobserved



func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: bool,
        _gogo_value_3: float,
        _gogo_value_4: String,
        _gogo_value_5: Variant,
        _gogo_value_6: Variant,
        _gogo_value_7: Variant,
        _gogo_value_8: Callable,
        _gogo_value_9: Callable,
        _gogo_value_10: Callable
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Always", "text": _gogo_value_4}, {}, [], "examples/conditional/Counter.gogo:18:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "After", "text": "Stable sibling after optional slot"}, {}, [], "examples/conditional/Counter.gogo:23:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(UiButton, {"name": "Increment", "text": "+"}, {"pressed": _gogo_value_8}, [], "examples/conditional/Counter.gogo:25:13", null, false)
        var _gogo_element_5 := _GogoElement_0.new(UiButton, {"name": "Toggle", "text": "Toggle bonus"}, {"pressed": _gogo_value_9}, [], "examples/conditional/Counter.gogo:26:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(UiButton, {"name": "ToggleChild", "text": "Toggle nested component"}, {"pressed": _gogo_value_10}, [], "examples/conditional/Counter.gogo:27:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "fill_width": _gogo_value_2, "gap": _gogo_value_3}, {}, [_gogo_element_2, _gogo_value_5, _gogo_value_6, _gogo_element_3, _gogo_value_7, _gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/conditional/Counter.gogo:17:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "viewport_width_scale": _gogo_value_1}, {}, [_gogo_element_1], "examples/conditional/Counter.gogo:16:12", null, false)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Callable) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(UiButton, {"name": "Action", "text": "Ready"}, {"pressed": _gogo_value_0}, [], "examples/conditional/Counter.gogo:19:14", null, false)
        return _gogo_element_0


    static func _gogo_build_2(_gogo_value_0: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Prompt", "text": _gogo_value_0}, {}, [], "examples/conditional/Counter.gogo:19:92", null, false)
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: float, _gogo_value_1: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Bonus", "gap": _gogo_value_0}, {}, [_gogo_value_1], "examples/conditional/Counter.gogo:20:14", null, false)
        return _gogo_element_0


    static func _gogo_build_4(_gogo_value_0: float, _gogo_value_1: float) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Rect, {"name": "Deep", "width": _gogo_value_0, "height": _gogo_value_1}, {}, [], "examples/conditional/Counter.gogo:21:19", null, false)
        return _gogo_element_0


    static func _gogo_build_5(_gogo_value_0: float, _gogo_value_1: float) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Rect, {"name": "Wide", "width": _gogo_value_0, "height": _gogo_value_1}, {}, [], "examples/conditional/Counter.gogo:21:101", null, false)
        return _gogo_element_0


    static func _gogo_build_6() -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Wait", "text": "Keep counting"}, {}, [], "examples/conditional/Counter.gogo:21:174", null, false)
        return _gogo_element_0


    static func _gogo_build_7(_gogo_value_0: Child.Model) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Child, {"name": "Nested", "model": _gogo_value_0}, {}, [], "examples/conditional/Counter.gogo:24:14", null, false)
        return _gogo_element_0
