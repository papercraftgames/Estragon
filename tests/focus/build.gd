extends SceneTree
func _initialize():
	var result = preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("UI01_BUILD ",JSON.stringify(result))
	if not result.ok: quit(1); return
	var host = load("res://app/generated/Focus.gd").new()
	host.name = "Focus"
	var packed := PackedScene.new()
	var ok: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://app/Focus.tscn")==OK
	host.free()
	if ok: print("UI01_BUILD_OK")
	quit(0 if ok else 1)
