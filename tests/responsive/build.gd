extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var report := Build.run_build()
	print("L0910_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var node := Node2D.new()
	node.name = "ResponsiveGallery"
	node.set_script(load("res://app/generated/ResponsiveGallery.gd"))
	var scene := PackedScene.new()
	var error := scene.pack(node)
	if error==OK: error = ResourceSaver.save(scene,"res://app/ResponsiveGallery.tscn")
	node.free()
	if error==OK: print("L0910_BUILD_OK")
	quit(0 if error==OK else 1)
