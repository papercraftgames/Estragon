@tool
extends EditorPlugin
## Process-state driver avoids suspended continuations across 4.0 editor reloads.
var failed: bool = false
var phase: int = 0
var stable_frames: int = 0

func _enter_tree() -> void:
	set_process(true)

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		printerr("B1 EDITOR ASSERTION FAILED: " + message)

func _process(_delta: float) -> void:
	if get_editor_interface().get_resource_filesystem().is_scanning():
		stable_frames = 0
		return
	stable_frames += 1
	if stable_frames < 8: return
	stable_frames = 0
	if phase == 0:
		phase = 1
		check(OS.get_environment("PATH").ends_with("no-tools"), "editor external toolchain absent")
		get_editor_interface().open_scene_from_path("res://tests/node_proof/Persisted.tscn")
	elif phase == 1:
		phase = 2
		verify_scene()
	else:
		set_process(false)
		if not failed: print("GGX_B1_EDITOR_OK")
		get_tree().quit(1 if failed else 0)

func verify_scene() -> void:
	var scene := get_editor_interface().get_edited_scene_root()
	check(scene != null, "real editor opens saved generated scene")
	if scene == null: return
	check(scene.get_child_count() == 1, "no duplicate tool-created composition")
	check(scene.get_node("Composition/Panel").amount == 7.0, "custom property persists in editor")
	check(scene.get_node("Composition/Panel").owner == scene, "scene owner retained")
	check(scene.get_node("Composition/Pulse").timeout.get_connections().size() == 1, "persistent named handler retained")
	var ticks: int = scene.ticks
	scene.get_node("Composition/Pulse").timeout.emit()
	check(scene.ticks == ticks + 1, "editor restored signal executes")
	check(scene.get_node("Composition/Boundary/Space/Nested3D").global_position == Vector3(11, 22, 33), "editor native 3D transforms")
	check(get_editor_interface().save_scene() == OK, "native editor save_scene")
