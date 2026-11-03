extends Node
## Native scene controls; press Enter to change an extent, resize the window to reflow.
@export var dimension: int = 2
var entry: Node
var _changed: bool = false

func _ready() -> void:
	var factory = load("res://examples/layout_proof/generated/Layout.gd").new()
	entry = factory.make_2d() if dimension == 2 else factory.make_3d()
	factory.free()
	add_child(entry)
	if dimension == 3:
		var camera := Camera3D.new()
		camera.position = Vector3(0, 4, 11)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 9.0
		add_child(camera)
		camera.look_at(Vector3(0, 0, 0))
		camera.current = true
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -30, 0)
		light.light_energy = 1.4
		add_child(light)

func change_extent() -> void:
	_changed = not _changed
	entry.get_node("Left").width = (160.0 if _changed else 100.0) if dimension == 2 else (2.5 if _changed else 1.5)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): change_extent()
