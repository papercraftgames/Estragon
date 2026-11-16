extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var report := Build.run_build()
	print("UX01_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var node := Node2D.new()
	node.name = "UXGallery"
	node.set_script(load("res://app/generated/UXGallery.gd"))
	var scene := PackedScene.new()
	var error := scene.pack(node)
	if error==OK: error = ResourceSaver.save(scene,"res://app/UXGallery.tscn")
	node.free()
	if error==OK: print("UX01_BUILD_OK")
	quit(0 if error==OK else 1)
