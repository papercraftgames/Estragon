extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	for index in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png("res://"+name+".png")!=OK: quit(1)
func click(button: Node2D) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas()*(button.layout_size*0.5)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.pressed = down
		event.button_index = MOUSE_BUTTON_LEFT
		Input.parse_input_event(event)
		await process_frame
func run() -> void:
	root.size = Vector2i(640,420)
	var scene: Node = load("res://examples/counter/Counter.tscn").instantiate()
	root.add_child(scene)
	await capture("c3-zero")
	await click(scene.ui.get_node("Panel/Actions/Increment"))
	if scene.count!=1: printerr("C3 visual click failed"); quit(1); return
	await capture("c3-one")
	root.size = Vector2i(800,480)
	await click(scene.ui.get_node("Panel/Actions/Reset"))
	if scene.count!=0: printerr("C3 visual reset failed"); quit(1); return
	await capture("c3-reset-resized")
	scene.free()
	print("C3_VISUAL_OK")
	quit()
