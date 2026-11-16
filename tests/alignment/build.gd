extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var report := Build.run_build()
	print("L08_BUILD ",JSON.stringify(report))
	if not report.ok: quit(1); return
	var node := Node2D.new()
	node.name = "AlignmentGallery"
	node.set_script(load("res://app/generated/AlignmentGallery.gd"))
	var scene := PackedScene.new()
	var error := scene.pack(node)
	if error==OK: error = ResourceSaver.save(scene,"res://app/AlignmentGallery.tscn")
	node.free()
	if error==OK: print("L08_BUILD_OK")
	quit(0 if error==OK else 1)
