extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func capture(name: String) -> void:
	for index in range(8): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://"+name+".png")!=OK: quit(1)
func run() -> void:
	root.size = Vector2i(640,360)
	var scene = preload("res://examples/composition/generated/Counter.gd").new()
	root.add_child(scene)
	await capture("composition-zero")
	scene.get_node("UI/Panel/Increment").pressed.emit()
	await capture("composition-one")
	if scene.get_node("UI/Panel/Count").text!="Count: 1":
		push_error("F01 rendered counter did not recompose")
		quit(1)
		return
	root.size = Vector2i(800,480)
	scene.reset_count()
	await capture("composition-reset-resized")
	scene.free()
	print("COMPOSITION_VISUAL_OK")
	quit()
