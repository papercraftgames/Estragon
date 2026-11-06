extends SceneTree
func _initialize() -> void:
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	if not report.ok:
		push_error("Source-only native build failed: "+str(report.diagnostics))
		quit(1)
		return
	print("PACKAGE_BUILD_OK")
	quit()
