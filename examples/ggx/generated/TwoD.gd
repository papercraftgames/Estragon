extends "res://examples/ggx/base.gd"
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Native = preload("../../../addons/estragon/runtime/node/native_2d.gd")
const Custom = preload("res://examples/ggx/probe_2d.gd")

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(value("root",50),100)),
        (value("gap",30)),
        (value("first",120)),
        (70.0),
        (PackedVector2Array([Vector2.ZERO,Vector2(100,0),Vector2(100,60),Vector2(0,60)])),
        (Color(0.2,0.8,0.6)),
        (PackedVector2Array([Vector2.ZERO,Vector2(90,0),Vector2(90,60),Vector2(0,60)])),
        (Color(0.55,0.35,0.9)),
        (true),
        (on_timeout),
        (value("custom",7)),
        (palette),
        (Vector2(10,150)),
        (Vector2(3,4))
    )

func _enter_tree() -> void:
    dimension = 2
    palette.changed.connect(on_palette_changed)

func _exit_tree() -> void:
    if palette.changed.is_connected(on_palette_changed): palette.changed.disconnect(on_palette_changed)



func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: float,
        _gogo_value_3: float,
        _gogo_value_4: PackedVector2Array,
        _gogo_value_5: Color,
        _gogo_value_6: PackedVector2Array,
        _gogo_value_7: Color,
        _gogo_value_8: bool,
        _gogo_value_9: Callable,
        _gogo_value_10: float,
        _gogo_value_11: Gradient,
        _gogo_value_12: Vector2,
        _gogo_value_13: Vector2
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new("Polygon2D", {"name": "Visual", "polygon": _gogo_value_4, "color": _gogo_value_5}, {}, [], "examples/ggx/TwoD.gogo:10:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(Native, {"name": "First", "width": _gogo_value_2, "height": _gogo_value_3}, {}, [_gogo_element_2], "examples/ggx/TwoD.gogo:9:9", null, false)
        var _gogo_element_4 := _GogoElement_0.new("Polygon2D", {"name": "Visual", "polygon": _gogo_value_6, "color": _gogo_value_7}, {}, [], "examples/ggx/TwoD.gogo:13:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Native, {"name": "Second"}, {}, [_gogo_element_4], "examples/ggx/TwoD.gogo:12:9", null, false)
        var _gogo_element_5 := _GogoElement_0.new("Timer", {"name": "Pulse", "one_shot": _gogo_value_8}, {"timeout": _gogo_value_9}, [], "examples/ggx/TwoD.gogo:15:9", null, false)
        var _gogo_element_7 := _GogoElement_0.new("Node2D", {"name": "Nested", "position": _gogo_value_13}, {}, [], "examples/ggx/TwoD.gogo:17:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(Custom, {"name": "Custom", "amount": _gogo_value_10, "palette": _gogo_value_11, "position": _gogo_value_12}, {}, [_gogo_element_7], "examples/ggx/TwoD.gogo:16:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "Entry", "position": _gogo_value_0, "gap": _gogo_value_1}, {}, [_gogo_element_1, _gogo_element_3, _gogo_element_5, _gogo_element_6], "examples/ggx/TwoD.gogo:8:12", null, false)
        return _gogo_element_0
