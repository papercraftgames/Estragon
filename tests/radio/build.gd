extends SceneTree
func _initialize():
	var result = preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("UI04_BUILD ",JSON.stringify(result))
	if not result.ok: quit(1); return
	var host = load("res://examples/radio/generated/Radios.gd").new()
	host.name = "Radios"
	var packed := PackedScene.new()
	var ok: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://examples/radio/Radios.tscn")==OK
	host.free()
	if ok: print("UI04_BUILD_OK")
	quit(0 if ok else 1)
