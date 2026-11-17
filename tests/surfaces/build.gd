extends SceneTree
func _initialize():
	var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
	print("S04_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var host = load("res://app/generated/SurfaceGallery.gd").new()
	host.name = "SurfaceGallery"
	var scene := PackedScene.new()
	var ok: bool = scene.pack(host)==OK and ResourceSaver.save(scene,"res://app/SurfaceGallery.tscn")==OK
	host.free()
	if ok: print("S04_BUILD_OK")
	quit(0 if ok else 1)
