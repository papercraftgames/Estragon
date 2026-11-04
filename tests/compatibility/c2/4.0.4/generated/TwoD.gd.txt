extends "res://examples/ggx/base.gd"
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Native = preload("res://addons/estragon/runtime/node/native_2d.gd")
const Custom = preload("res://examples/ggx/probe_2d.gd")

func compose() -> Node:
    dimension = 2
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
    palette.changed.connect(on_palette_changed)

func _exit_tree() -> void:
    if palette.changed.is_connected(on_palette_changed): palette.changed.disconnect(on_palette_changed)




class _GogoFactories_0:

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
    ) -> Entry:
        var component_0: Entry = Entry.new()
        component_0.name = "Entry"
        component_0.position = _gogo_value_0
        component_0.gap = _gogo_value_1
        var component_1: Native = Native.new()
        component_1.name = "First"
        component_1.width = _gogo_value_2
        component_1.height = _gogo_value_3
        var component_2: Polygon2D = Polygon2D.new()
        component_2.name = "Visual"
        component_2.polygon = _gogo_value_4
        component_2.color = _gogo_value_5
        component_1.add_child(component_2)
        component_0.add_child(component_1)
        var component_3: Native = Native.new()
        component_3.name = "Second"
        var component_4: Polygon2D = Polygon2D.new()
        component_4.name = "Visual"
        component_4.polygon = _gogo_value_6
        component_4.color = _gogo_value_7
        component_3.add_child(component_4)
        component_0.add_child(component_3)
        var component_5: Timer = Timer.new()
        component_5.name = "Pulse"
        component_5.one_shot = _gogo_value_8
        component_0.add_child(component_5)
        var component_6: Custom = Custom.new()
        component_6.name = "Custom"
        component_6.amount = _gogo_value_10
        component_6.palette = _gogo_value_11
        component_6.position = _gogo_value_12
        var component_7: Node2D = Node2D.new()
        component_7.name = "Nested"
        component_7.position = _gogo_value_13
        component_6.add_child(component_7)
        component_0.add_child(component_6)
        component_2.owner = component_0
        component_1.owner = component_0
        component_4.owner = component_0
        component_3.owner = component_0
        component_5.owner = component_0
        component_7.owner = component_0
        component_6.owner = component_0
        if not _gogo_value_9.is_valid() or component_5.timeout.connect(_gogo_value_9, Object.CONNECT_PERSIST) != OK:
            push_error("examples/ggx/TwoD.gogo:15:53: Node GGX signal timeout requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
