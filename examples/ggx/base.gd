extends Node
## Shared native demo interactions, not a compiler or widget implementation.
var entry: Node:
	get: return get_node_or_null("Entry")
var count: int = 0
@export var palette := Gradient.new()
var object_events: int = 0
var evaluations: Array[String] = []
@export var dimension: int = 2

func value(label: String, number: float) -> float:
	evaluations.append(label)
	return number

func make_mesh(color: Color = Color(0.2,0.8,0.6)) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.4,1.2,1)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material = material
	return mesh

func on_timeout() -> void:
	count += 1
	var adapter = entry.get_node("First")
	adapter.width += 25 if dimension == 2 else 0.5
	palette.changed.emit()

func on_palette_changed() -> void:
	object_events += 1

func _ready() -> void:
	if dimension == 3:
		var camera := Camera3D.new()
		camera.position = Vector3(3,5,12)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 10
		add_child(camera)
		camera.look_at(Vector3(2,1,0))
		camera.current = true
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45,-30,0)
		add_child(light)
	# Isolated editor acceptance requests a child-game proof without a toolchain.
	if OS.get_environment("ESTRAGON_C2_PROOF") == "1":
		call_deferred("_write_proof")

func _write_proof() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var output := FileAccess.open("res://.godot/c2-play.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"width":entry.get_node("First").width,"dimension":dimension,"native":entry.get_layout_root()==entry}))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): entry.get_node("Pulse").timeout.emit()
