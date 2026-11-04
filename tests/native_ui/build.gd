extends SceneTree
func _initialize() -> void:
	var result = preload("res://addons/estragon/editor/build_service.gd").run_build()
	if result.ok: print("C3_BUILD_OK")
	else: printerr(result)
	quit(0 if result.ok else 1)
