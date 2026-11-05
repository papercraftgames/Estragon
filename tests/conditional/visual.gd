extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func capture(name: String) -> void:
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://"+name+".png")!=OK: quit(1)
func run() -> void:
	root.size = Vector2i(640,480)
	var scene = preload("res://examples/conditional/generated/Counter.gd").new()
	root.add_child(scene)
	await capture("conditional-initial")
	scene.count = 5
	scene.show_bonus = true
	await capture("conditional-changed")
	if not scene.has_node("UI/Panel/Bonus/Deep"):
		push_error("Conditional branch did not update")
		quit(1)
		return
	root.size = Vector2i(800,600)
	await capture("conditional-resized")
	scene.free()
	print("CONDITIONAL_VISUAL_OK")
	quit()
