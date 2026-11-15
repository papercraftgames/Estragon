extends RefCounted
func run(host: Node) -> void:
	var tree := host.get_tree()
	var samples: Array = []
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = viewport
		for frame in range(12): await tree.process_frame
		var panel = host.get_node("UI/Panel")
		var settings = panel.get_node("Settings")
		for button in [settings.get_node("Controls/Native"),settings.get_node("Controls/Ui")]:
			var extent: Vector2 = button.size if button is Control else button.layout_size
			var event := InputEventMouseButton.new()
			event.position = button.get_global_transform_with_canvas()*(extent/2)
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			tree.root.push_input(event,true)
			event = event.duplicate()
			event.pressed = false
			tree.root.push_input(event,true)
		samples.append({"viewport":str(viewport),"panel":str(panel.layout_size),"half":panel.get_node("Header").layout_size.x,"content":panel.layout.model.content_reference.x,"root":host.get_node("UI").layout_size==Vector2(viewport),"color":panel.background_color=="#252b38"})
	var settings = host.get_node("UI/Panel/Settings")
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png("res://editor-game.png")
	var result := {"samples":samples,"native":settings.native_clicks,"ui":settings.ui_clicks}
	print("S01_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/s01-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/s01-game.tmp","res://.godot/s01-game.json")
