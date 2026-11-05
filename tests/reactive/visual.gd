extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func capture(name: String) -> void:
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://"+name+".png")!=OK: quit(1)
func run() -> void:
	root.size = Vector2i(640,360)
	var scene = preload("res://examples/reactive/generated/Demo.gd").new()
	root.add_child(scene)
	await capture("reactive-initial")
	scene.advance()
	await capture("reactive-changed")
	if scene.ui.get_node("Panel/Row/Bar").layout_size.x!=160.0 or scene.ui.get_node("Panel/Title").text!="Changed without rebuilding":
		push_error("Reactive visual geometry/text did not update")
		quit(1)
		return
	root.size = Vector2i(800,480)
	await capture("reactive-resized")
	scene.free()
	print("REACTIVE_VISUAL_OK")
	quit()
