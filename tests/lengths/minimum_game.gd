extends RefCounted
var edits: Array = []
func edited(_previous: bool, value: bool) -> void: edits.append(value)
func run(host: Node) -> void:
	var tree := host.get_tree()
	var samples: Array = []
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = viewport
		for frame in range(12): await tree.process_frame
		var panel = host.get_node("UI/Panel")
		var action = panel.get_node("Continue")
		var native = panel.get_node("Native")
		var toggle = panel.get_node("Enabled")
		if not toggle.value_changed.is_connected(edited): toggle.value_changed.connect(edited)
		for button in [action,native,toggle]:
			var extent: Vector2 = button.size if button is Control else button.layout_size
			var event := InputEventMouseButton.new()
			event.position = button.get_global_transform_with_canvas()*(extent/2)
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			tree.root.push_input(event,true)
			event = event.duplicate()
			event.pressed = false
			tree.root.push_input(event,true)
		for frame in range(10): await tree.process_frame
		await RenderingServer.frame_post_draw
		var image := tree.root.get_texture().get_image()
		image.save_png("res://editor-minimums-"+str(viewport.x)+".png")
		samples.append({"root":host.get_node("UI").layout_size==Vector2(viewport),"panel":str(panel.layout_size),"content":panel.get_content_rect().size.x,"width":action.layout_size.x,"height":action.layout_size.y,"origin":str(action.get_label_origin()),"border":image.get_pixelv(Vector2i(panel.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc"))})
	var result := {"samples":samples,"clicks":host.clicks,"native":host.native_clicks,"edits":edits}
	print("L11_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/l11-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/l11-game.tmp","res://.godot/l11-game.json")
