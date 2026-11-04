@tool
extends Node
## Native-authored fixtures deliberately keep scene ownership separate from parentage.
const Entry2D = preload("res://addons/estragon/layout_proof/entry_2d.gd")
const Entry3D = preload("res://addons/estragon/layout_proof/entry_3d.gd")
const Native2D = preload("res://addons/estragon/adapter_proof/native_2d.gd")
const Native3D = preload("res://addons/estragon/adapter_proof/native_3d.gd")
@export var dimension: int = 2
var entry: Node

func _ready() -> void:
	# Persisted scenes already contain their native nodes; never rebuild them.
	entry = get_node_or_null("Entry")
	if entry != null: return
	entry = make_entry(dimension)
	add_child(entry)
	own(entry)
	if dimension == 3:
		var camera := Camera3D.new()
		camera.name = "Camera"
		camera.position = Vector3(4, 5, 12)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 10
		add_child(camera)
		camera.look_at(Vector3(3, 1, 0))
		camera.current = true
		own(camera)
		var light := DirectionalLight3D.new()
		light.name = "Light"
		light.rotation_degrees = Vector3(-45,-30,0)
		add_child(light)
		own(light)

func own(node: Node) -> void:
	node.owner = self
	for child in node.get_children(): own(child)

static func make_entry(dimension: int) -> Node:
	var result = Entry2D.new() if dimension == 2 else Entry3D.new()
	result.name = "Entry"
	result.tint = Color.TRANSPARENT
	result.position = Vector2(50,100) if dimension == 2 else Vector3(-1,0,0)
	result.gap = 30 if dimension == 2 else 0.5
	for index in range(2):
		var adapter = Native2D.new() if dimension == 2 else Native3D.new()
		adapter.name = "NativeA" if index == 0 else "NativeB"
		adapter.observe_native = true
		var visual: Node
		if dimension == 2:
			visual = Polygon2D.new()
			visual.polygon = PackedVector2Array([Vector2(-40,-30),Vector2(40,-30),Vector2(40,30),Vector2(-40,30)])
			visual.position = Vector2(11,-7)
			visual.rotation = 0.25 if index == 0 else -0.15
			visual.scale = Vector2(1.2,1)
			visual.color = Color("30c9b0") if index == 0 else Color("8566e0")
		else:
			visual = MeshInstance3D.new()
			visual.mesh = BoxMesh.new()
			visual.mesh.size = Vector3(1.5,1.2,1)
			visual.position = Vector3(0.3,-0.2,0.4)
			visual.rotation = Vector3(0.1,0.3,0.2)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("30c9b0") if index == 0 else Color("8566e0")
			visual.material_override = material
		visual.name = "Visual"
		adapter.add_child(visual)
		result.add_child(adapter)
	return result

func change_geometry() -> void:
	var adapter = entry.get_node("NativeA")
	var visual = adapter.get_node("Visual")
	if dimension == 2:
		visual.scale.x += 0.3
	else:
		visual.mesh.size.x += 0.5
	adapter.invalidate_native()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): change_geometry()
