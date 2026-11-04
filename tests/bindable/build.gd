extends SceneTree
func _initialize() -> void:
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	if not report.ok:
		push_error(str(report.diagnostics))
		quit(1)
		return
	print("BINDABLE_BUILD_OK")
	quit()
