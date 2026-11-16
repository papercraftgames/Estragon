extends SceneTree
var clicks := 0
func pressed(): clicks += 1
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var clip := Control.new()
	clip.position = Vector2(30,30)
	clip.size = Vector2(100,100)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(clip)
	var content := Node2D.new()
	clip.add_child(content)
	var nested := Control.new()
	nested.position = Vector2(10,10)
	nested.size = Vector2(80,80)
	nested.clip_contents = true
	nested.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(nested)
	var inner := Node2D.new()
	nested.add_child(inner)
	var button := Button.new()
	button.position = Vector2(40,10)
	button.size = Vector2(100,40)
	button.text = "Native"
	button.pressed.connect(pressed)
	inner.add_child(button)
	for frame in range(8): await process_frame
	for point in [Vector2(90,65),Vector2(125,65)]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		root.push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		root.push_input(event,true)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://ux01-clip-probe.png")
	print("UX01_CLIP_PROBE ",Engine.get_version_info().string," clicks=",clicks," focus=",button.has_focus())
	clip.free()
	if clicks==1: print("UX01_CLIP_OK")
	quit(0 if clicks==1 else 1)
