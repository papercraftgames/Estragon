extends SceneTree
func _initialize() -> void:
	var config := ConfigFile.new()
	if config.load("res://addons/estragon/editor/plugin.cfg") != OK or config.get_value("plugin","version") != OS.get_environment("ESTRAGON_EXPECTED_PACKAGE_VERSION"):
		push_error("Installed native plugin version differs from npm package")
		quit(1)
		return
	print("PACKAGE_NATIVE_VERSION ",config.get_value("plugin","version"))
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	if not report.ok:
		push_error("Source-only native build failed: "+str(report.diagnostics))
		quit(1)
		return
	print("PACKAGE_BUILD_OK")
	quit()
