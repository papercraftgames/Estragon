extends SceneTree
func _initialize():
	var result = preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("CORE01_BUILD ",JSON.stringify(result))
	if not result.ok: quit(1); return
	var host = load("res://app/generated/Core.gd").new()
	host.name="Core"
	var packed := PackedScene.new()
	var ok: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://app/Core.tscn")==OK
	host.free()
	if ok: print("CORE01_BUILD_OK")
	quit(0 if ok else 1)
