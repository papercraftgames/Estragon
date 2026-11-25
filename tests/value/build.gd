extends SceneTree
func _initialize():
	var result=preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("UI05_BUILD ",JSON.stringify(result))
	if not result.ok: quit(1); return
	var host=load("res://examples/values/generated/Values.gd").new()
	host.name="Values"
	var packed:=PackedScene.new()
	var ok:bool=packed.pack(host)==OK and ResourceSaver.save(packed,"res://examples/values/Values.tscn")==OK
	host.free()
	if ok: print("UI05_BUILD_OK")
	quit(0 if ok else 1)
