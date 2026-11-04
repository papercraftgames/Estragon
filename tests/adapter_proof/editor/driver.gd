@tool
extends EditorPlugin
var failed: bool = false
var phase: int = 0
var stable_frames: int = 0
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		printerr("B3 EDITOR ASSERTION FAILED: " + message)
func _enter_tree() -> void:
	set_process(true)
func _process(_delta: float) -> void:
	if get_editor_interface().get_resource_filesystem().is_scanning():
		stable_frames = 0
		return
	stable_frames += 1
	if stable_frames < 12: return
	stable_frames = 0
	if phase == 0 or phase == 2:
		get_editor_interface().open_scene_from_path("res://tests/adapter_proof/Persisted%d.tscn" % (2 if phase == 0 else 3))
	elif phase == 1 or phase == 3:
		var scene := get_editor_interface().get_edited_scene_root()
		check(scene != null, "actual editor opens scene")
		if scene != null:
			var adapter = scene.get_node("Entry/NativeA")
			var visual = adapter.get_node("Visual")
			check(adapter.get_child_count() == 1, "single native visual")
			check(visual.owner == scene and adapter.owner == scene, "persisted owners")
			check(adapter.bounds.status == OK, "provider restored")
			check(visual.position == (Vector2(11,-7) if phase == 1 else Vector3(0.3,-0.2,0.4)), "native position survives layout/save/reopen")
			check(visual.rotation == 0.25 if phase == 1 else visual.rotation.is_equal_approx(Vector3(0.1,0.3,0.2)), "native rotation survives")
			check(get_editor_interface().save_scene() == OK, "real editor save_scene")
	else:
		set_process(false)
		if not failed: print("GGX_B3_EDITOR_OK")
		get_tree().quit(1 if failed else 0)
	phase += 1
