extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var report := Build.run_build()
	if not report.ok:
		push_error("Source-only build: " + str(report.diagnostics))
		quit(1)
		return
	for name in ["compiled/Layout", "mixed/Mixed", "counter/Counter"]:
		var parts: PackedStringArray = name.split("/")
		var path: String = "res://examples/" + parts[0] + "/generated/" + parts[1] + ".gd"
		var script = load(path)
		if script == null or not script.can_instantiate():
			push_error("Source-only output invalid: " + path)
			quit(1)
			return
	print("C01_H_SOURCE_ONLY_OK")
	quit()
