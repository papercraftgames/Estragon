extends SceneTree
func _initialize():
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("D07_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var host = load("res://app/generated/Buttons.gd").new()
	host.name = "Buttons"
	var scene := PackedScene.new()
	var ok: bool = scene.pack(host)==OK and ResourceSaver.save(scene,"res://app/Buttons.tscn")==OK
	host.free()
	if ok: print("D07_BUILD_OK")
	quit(0 if ok else 1)
