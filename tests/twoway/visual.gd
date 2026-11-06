extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func capture(name: String) -> void:
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://"+name+".png")!=OK: quit(1)
func run() -> void:
	root.size = Vector2i(640,480)
	var scene = preload("res://examples/twoway/generated/Demo.gd").new()
	root.add_child(scene)
	await capture("twoway-initial")
	var last = scene.get_node("UI/Panel/Reverse")
	if last.global_position.y+last.layout_size.y>root.size.y:
		push_error("Demo commands must remain visible at initial viewport")
		quit(1)
		return
	scene.model.enabled = true
	await capture("twoway-changed")
	if not scene.has_node("UI/Panel/Edit"):
		push_error("Conditional branch did not update")
		quit(1)
		return
	root.size = Vector2i(800,600)
	await capture("twoway-resized")
	scene.free()
	print("TWOWAY_VISUAL_OK")
	quit()
