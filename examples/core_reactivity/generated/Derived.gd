extends "Base.gd"
const ViewElement=preload("../../../addons/estragon/runtime/composition/element.gd")
const ViewText=preload("../../../addons/estragon/runtime/node/text.gd")
const ViewBox=preload("../../../addons/estragon/runtime/node/box.gd")
signal tick_changed(previous: int, value: int)
var tick: int = 0:
    set(_gogo_incoming_tick):
        if is_same(tick, _gogo_incoming_tick): return
        var _gogo_previous_tick: int = tick
        tick = _gogo_incoming_tick
        tick_changed.emit(_gogo_previous_tick, _gogo_incoming_tick)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"tick_changed")
        return tick

var override_calls: int = 0
func badge() -> ViewElement:
    override_calls += 1
    return ViewElement.new(ViewText,{"name":"Override","text":self.title})
func build_view() -> ViewElement:
    preload("../../../addons/estragon/runtime/composition/state.tres").base_at("examples/core_reactivity/Derived.gogo:467", self, "res://examples/core_reactivity/generated/Derived.gd", "ordinary", ["unused"], func(_gogo_receiver, _gogo_arguments): super.ordinary(_gogo_arguments[0]), func(): super.ordinary("unused"))
    var value := (preload("../../../addons/estragon/runtime/composition/state.tres").base_at("examples/core_reactivity/Derived.gogo:509", self, "res://examples/core_reactivity/generated/Derived.gd", "ordinary", [self.title], func(_gogo_receiver, _gogo_arguments): return super.ordinary(_gogo_arguments[0]), func(): super.ordinary(self.title)) as String)
    var normal := (preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Derived.gogo:554", ordinary, [self.title], func(): ordinary(self.title)) as String)
    var secret := (preload("../../../addons/estragon/runtime/composition/state.tres").base_at("examples/core_reactivity/Derived.gogo:593", self, "res://examples/core_reactivity/generated/Derived.gd", "hidden", [], func(_gogo_receiver, _gogo_arguments): return super.hidden(), func(): super.hidden()) as String)
    return _GogoFactories_0._gogo_build_0(
        (str(self.tick)),
        (value),
        (normal),
        (secret),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").base_at("examples/core_reactivity/Derived.gogo:877", self, "res://examples/core_reactivity/generated/Derived.gd", "badge", [], func(_gogo_receiver, _gogo_arguments): return super.badge(), func(): super.badge()) as ViewElement)),
        ((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/core_reactivity/Derived.gogo:901", badge, [], func(): badge()) as ViewElement))
    )

const _GOGO_RENDER_FUNCTIONS_ef9ffda749d2bdcd = {
"ordinary": ["badge"],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: String,
        _gogo_value_1: String,
        _gogo_value_2: String,
        _gogo_value_3: String,
        _gogo_value_4: Variant,
        _gogo_value_5: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(ViewText, {"name": "Tick", "text": _gogo_value_0}, {}, [], "examples/core_reactivity/Derived.gogo:16:9", null, false)
        var _gogo_element_2 := _GogoElement_0.new(ViewText, {"name": "Explicit", "text": _gogo_value_1}, {}, [], "examples/core_reactivity/Derived.gogo:17:9", null, false)
        var _gogo_element_3 := _GogoElement_0.new(ViewText, {"name": "Normal", "text": _gogo_value_2}, {}, [], "examples/core_reactivity/Derived.gogo:18:9", null, false)
        var _gogo_element_4 := _GogoElement_0.new(ViewText, {"name": "Hidden", "text": _gogo_value_3}, {}, [], "examples/core_reactivity/Derived.gogo:19:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(ViewBox, {"name": "Inherited", "direction": "column"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_value_4, _gogo_value_5], "examples/core_reactivity/Derived.gogo:15:12", null, false)
        return _gogo_element_0
