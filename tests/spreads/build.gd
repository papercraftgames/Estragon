extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var report := Build.run_build()
	print("S03_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var node := Node2D.new()
	node.set_script(load("res://app/generated/SpreadGallery.gd"))
	var scene := PackedScene.new()
	var error := scene.pack(node)
	if error==OK: error = ResourceSaver.save(scene,"res://app/SpreadGallery.tscn")
	node.free()
	if error==OK: print("S03_BUILD_OK")
	quit(0 if error==OK else 1)
