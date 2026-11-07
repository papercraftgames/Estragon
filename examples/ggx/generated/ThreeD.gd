extends "res://examples/ggx/base.gd"
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_3d.gd")
const Native = preload("../../../addons/estragon/runtime/node/native_3d.gd")
const Custom = preload("res://examples/ggx/probe_3d.gd")

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector3(value("root",0),0,0)),
        (value("gap",0.5)),
        (value("first",2.0)),
        (1.2),
        (1.0),
        (make_mesh()),
        (make_mesh(Color(0.55,0.35,0.9))),
        (true),
        (on_timeout),
        (value("custom",7)),
        (palette),
        (Vector3(10,20,30)),
        (Vector3(1,2,3))
    )

func _enter_tree() -> void:
    dimension = 3
    palette.changed.connect(on_palette_changed)

func _exit_tree() -> void:
    if palette.changed.is_connected(on_palette_changed): palette.changed.disconnect(on_palette_changed)



func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector3,
        _gogo_value_1: float,
        _gogo_value_2: float,
        _gogo_value_3: float,
        _gogo_value_4: float,
        _gogo_value_5: Mesh,
        _gogo_value_6: Mesh,
        _gogo_value_7: bool,
        _gogo_value_8: Callable,
        _gogo_value_9: float,
        _gogo_value_10: Gradient,
        _gogo_value_11: Vector3,
        _gogo_value_12: Vector3
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new("MeshInstance3D", {"name": "Visual", "mesh": _gogo_value_5}, {}, [], "examples/ggx/ThreeD.gogo:10:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(Native, {"name": "First", "width": _gogo_value_2, "height": _gogo_value_3, "depth": _gogo_value_4}, {}, [_gogo_element_2], "examples/ggx/ThreeD.gogo:9:9", null, false)
        var _gogo_element_4 := _GogoElement_0.new("MeshInstance3D", {"name": "Visual", "mesh": _gogo_value_6}, {}, [], "examples/ggx/ThreeD.gogo:13:13", null, false)
        var _gogo_element_3 := _GogoElement_0.new(Native, {"name": "Second"}, {}, [_gogo_element_4], "examples/ggx/ThreeD.gogo:12:9", null, false)
        var _gogo_element_5 := _GogoElement_0.new("Timer", {"name": "Pulse", "one_shot": _gogo_value_7}, {"timeout": _gogo_value_8}, [], "examples/ggx/ThreeD.gogo:15:9", null, false)
        var _gogo_element_8 := _GogoElement_0.new("Node3D", {"name": "Nested", "position": _gogo_value_12}, {}, [], "examples/ggx/ThreeD.gogo:18:17", null, false)
        var _gogo_element_7 := _GogoElement_0.new(Custom, {"name": "Custom", "amount": _gogo_value_9, "palette": _gogo_value_10, "position": _gogo_value_11}, {}, [_gogo_element_8], "examples/ggx/ThreeD.gogo:17:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new("Node", {"name": "Boundary"}, {}, [_gogo_element_7], "examples/ggx/ThreeD.gogo:16:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "Entry", "position": _gogo_value_0, "gap": _gogo_value_1}, {}, [_gogo_element_1, _gogo_element_3, _gogo_element_5, _gogo_element_6], "examples/ggx/ThreeD.gogo:8:12", null, false)
        return _gogo_element_0
