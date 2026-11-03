@tool
extends Node2D
const Probe2D = preload("res://examples/node_proof/probe_2d.gd")
const Probe3D = preload("res://examples/node_proof/probe_3d.gd")

@export var palette: Gradient = Gradient.new()
var evaluations: Array[String] = []
var ticks: int = 0
var changes: int = 0
var _observed_palette: Gradient

func value(label: String, number: float) -> float:
    evaluations.append(label)
    return number

func compose() -> void:
    var subtree := _GogoFactories_0._gogo_build_0(
        (Vector2(value("root", 40.0), 60.0)),
        (value("custom2d", 7.0)),
        (palette),
        (Vector2(20, 10)),
        (PackedVector2Array([Vector2.ZERO, Vector2(160, 0), Vector2(160, 90), Vector2(0, 90)])),
        (Color(0.25, 0.8, 0.6)),
        (Vector2(3, 4)),
        (value("timer", 0.5)),
        (true),
        (on_timeout),
        (Vector2(5, 6)),
        (value("custom3d", 9.0)),
        (Vector3(10, 20, 30)),
        (Vector3(1, 2, 3)),
        (BoxMesh.new()),
        (Vector3(4, 5, 6))
    )
    add_child(subtree)
    # Explicitly persist this newly created composition in the hosting scene.
    # B1 disallows borrowed/expression children, so this visits only new Nodes.
    persist_new_subtree(subtree)

func persist_new_subtree(node: Node) -> void:
    node.owner = self
    for child in node.get_children():
        persist_new_subtree(child)

func _enter_tree() -> void:
    # Non-Node Object signal source, referenced directly from authored Gogo.
    # It is an external subscription, deliberately not CONNECT_PERSIST.
    _observed_palette = palette
    _observed_palette.changed.connect(on_palette_changed)

func _exit_tree() -> void:
    if _observed_palette != null and _observed_palette.changed.is_connected(on_palette_changed):
        _observed_palette.changed.disconnect(on_palette_changed)
    _observed_palette = null

func _ready() -> void:
    if get_child_count() == 0:
        compose()

func on_timeout() -> void:
    ticks += 1
    var shape: Polygon2D = get_node("Composition/Panel/Shape")
    shape.color = Color(0.6, 0.3, 0.9) if ticks % 2 else Color(0.25, 0.8, 0.6)
    print("B1 native Timer.timeout: ", ticks)

func on_palette_changed() -> void:
    changes += 1

func _unhandled_key_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        get_node("Composition/Pulse").start()



class _GogoFactories_0:

    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: float,
        _gogo_value_2: Gradient,
        _gogo_value_3: Vector2,
        _gogo_value_4: PackedVector2Array,
        _gogo_value_5: Color,
        _gogo_value_6: Vector2,
        _gogo_value_7: float,
        _gogo_value_8: bool,
        _gogo_value_9: Callable,
        _gogo_value_10: Vector2,
        _gogo_value_11: float,
        _gogo_value_12: Vector3,
        _gogo_value_13: Vector3,
        _gogo_value_14: Mesh,
        _gogo_value_15: Vector3
    ) -> Node2D:
        var component_0: Node2D = Node2D.new()
        component_0.name = "Composition"
        component_0.position = _gogo_value_0
        var component_1: Probe2D = Probe2D.new()
        component_1.name = "Panel"
        component_1.amount = _gogo_value_1
        component_1.palette = _gogo_value_2
        component_1.position = _gogo_value_3
        var component_2: Polygon2D = Polygon2D.new()
        component_2.name = "Shape"
        component_2.polygon = _gogo_value_4
        component_2.color = _gogo_value_5
        component_1.add_child(component_2)
        var component_3: Node2D = Node2D.new()
        component_3.name = "Nested2D"
        component_3.position = _gogo_value_6
        component_1.add_child(component_3)
        component_0.add_child(component_1)
        var component_4: Timer = Timer.new()
        component_4.name = "Pulse"
        component_4.wait_time = _gogo_value_7
        component_4.one_shot = _gogo_value_8
        component_0.add_child(component_4)
        var component_5: Node = Node.new()
        component_5.name = "Boundary"
        var component_6: Node2D = Node2D.new()
        component_6.name = "Reset2D"
        component_6.position = _gogo_value_10
        component_5.add_child(component_6)
        var component_7: Probe3D = Probe3D.new()
        component_7.name = "Space"
        component_7.amount = _gogo_value_11
        component_7.position = _gogo_value_12
        var component_8: Node3D = Node3D.new()
        component_8.name = "Nested3D"
        component_8.position = _gogo_value_13
        component_7.add_child(component_8)
        var component_9: MeshInstance3D = MeshInstance3D.new()
        component_9.name = "Mesh"
        component_9.mesh = _gogo_value_14
        component_7.add_child(component_9)
        var component_10: Node = Node.new()
        component_10.name = "ResetBoundary"
        var component_11: Node3D = Node3D.new()
        component_11.name = "Reset3D"
        component_11.position = _gogo_value_15
        component_10.add_child(component_11)
        component_7.add_child(component_10)
        component_5.add_child(component_7)
        component_0.add_child(component_5)
        component_2.owner = component_0
        component_3.owner = component_0
        component_1.owner = component_0
        component_4.owner = component_0
        component_6.owner = component_0
        component_8.owner = component_0
        component_9.owner = component_0
        component_11.owner = component_0
        component_10.owner = component_0
        component_7.owner = component_0
        component_5.owner = component_0
        if not _gogo_value_9.is_valid() or component_4.timeout.connect(_gogo_value_9, Object.CONNECT_PERSIST) != OK:
            push_error("res://examples/node_proof/.proof/Composition.gogo:22:85: B1 signal timeout requires a valid Callable/connection")
            component_0.free()
            return null
        return component_0
