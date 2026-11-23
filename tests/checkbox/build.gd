extends SceneTree
func _initialize():
	var result = preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("UI02_BUILD ",JSON.stringify(result))
	if not result.ok: quit(1); return
	var host = load("res://app/generated/Checkboxes.gd").new()
	host.name = "Checkboxes"
	var packed := PackedScene.new()
	var ok: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://app/Checkboxes.tscn")==OK
	host.free()
	if ok: print("UI02_BUILD_OK")
	quit(0 if ok else 1)
