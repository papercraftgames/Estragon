extends SceneTree
func _initialize() -> void:
	var report = preload("res://addons/estragon/editor/build_service.gd").run_build()
	if report.ok: print("GGX_C2_BUILD_OK")
	else: printerr(report)
	quit(0 if report.ok else 1)
