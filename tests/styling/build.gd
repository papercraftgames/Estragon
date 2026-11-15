extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
func _initialize() -> void:
	var file := FileAccess.open("res://app/Overrides.gogo",FileAccess.WRITE)
	file.store_string('extends Node2D\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")\nconst Box = preload("res://addons/estragon/runtime/node/box.gd")\n@bindable var edge: bool = true\nfunc build_view() -> Element:\n\tvar props = {"width":100,"height":80,"border_width":3}\n\tif self.edge: props["border_left_width"] = 1\n\treturn <Entry width={200} height={100}>{Element.new(Box,props,{},[],"Overrides.gogo:8:2")}</Entry>\n')
	file.close()
	var report := Build.run_build()
	print("S01_BUILD ",JSON.stringify(report))
	if report.ok:
		var host := Node2D.new()
		host.name = "StyleGallery"
		host.set_script(load("res://app/generated/StyleGallery.gd"))
		var scene := PackedScene.new()
		scene.pack(host)
		ResourceSaver.save(scene,"res://app/StyleGallery.tscn")
		host.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/StyleGallery.tscn")
		ProjectSettings.save()
		print("S01_BUILD_OK")
	quit(0 if report.ok else 1)
