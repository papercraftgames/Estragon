extends SceneTree
func _initialize() -> void:
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	if not report.ok:
		for diagnostic in report.diagnostics: printerr(diagnostic)
		quit(1)
		return
	print("CONDITIONAL_BUILD_OK")
	quit()
