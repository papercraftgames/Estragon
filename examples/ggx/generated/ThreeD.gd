extends "res://examples/ggx/base.gd"
const Entry = preload("res://addons/estragon/runtime/node/estragon_3d.gd")
const Native = preload("res://addons/estragon/runtime/node/native_3d.gd")
const Custom = preload("res://examples/ggx/probe_3d.gd")

func compose() -> Node:
    dimension = 3
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
    palette.changed.connect(on_palette_changed)

func _exit_tree() -> void:
    if palette.changed.is_connected(on_palette_changed): palette.changed.disconnect(on_palette_changed)




class _GogoFactories_0:
    const _Element = preload("res://addons/estragon/runtime/composition/element.gd")


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
    ) -> Entry:
        var component_0: Entry = Entry.new()
        component_0.name = "Entry"
        component_0.position = _gogo_value_0
        component_0.gap = _gogo_value_1
        var component_1: Native = Native.new()
        component_1.name = "First"
        component_1.width = _gogo_value_2
        component_1.height = _gogo_value_3
        component_1.depth = _gogo_value_4
        var component_2: MeshInstance3D = MeshInstance3D.new()
        component_2.name = "Visual"
        component_2.mesh = _gogo_value_5
        component_1.add_child(component_2)
        component_0.add_child(component_1)
        var component_3: Native = Native.new()
        component_3.name = "Second"
        var component_4: MeshInstance3D = MeshInstance3D.new()
        component_4.name = "Visual"
        component_4.mesh = _gogo_value_6
        component_3.add_child(component_4)
        component_0.add_child(component_3)
        var component_5: Timer = Timer.new()
        component_5.name = "Pulse"
        component_5.one_shot = _gogo_value_7
        component_0.add_child(component_5)
        var component_6: Node = Node.new()
        component_6.name = "Boundary"
        var component_7: Custom = Custom.new()
        component_7.name = "Custom"
        component_7.amount = _gogo_value_9
        component_7.palette = _gogo_value_10
        component_7.position = _gogo_value_11
        var component_8: Node3D = Node3D.new()
        component_8.name = "Nested"
        component_8.position = _gogo_value_12
        component_7.add_child(component_8)
        component_6.add_child(component_7)
        component_0.add_child(component_6)
        component_2.owner = component_0
        component_1.owner = component_0
        component_4.owner = component_0
        component_3.owner = component_0
        component_5.owner = component_0
        component_8.owner = component_0
        component_7.owner = component_0
        component_6.owner = component_0
        if not _gogo_value_8.is_valid() or component_5.timeout.connect(_gogo_value_8, Object.CONNECT_PERSIST) != OK:
            push_error("examples/ggx/ThreeD.gogo:15:53: Node GGX signal timeout requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
