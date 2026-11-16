extends RefCounted
var edits: Array = []
func edited(value: bool) -> void: edits.append(value)
func click(host: Node, button: Node) -> void:
	var extent: Vector2 = button.size if button is Control else button.layout_size
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(extent*Vector2(0.99,0.5))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	host.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	host.get_viewport().push_input(event,true)
func run(host: Node) -> void:
	var tree := host.get_tree()
	var samples: Array = []
	for extent in [Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = extent
		for frame in range(12): await tree.process_frame
		var panel = host.get_node("UI/Panel")
		var button = panel.get_node("Continue")
		var toggle = panel.get_node("Enabled")
		if not toggle.value_changed.is_connected(edited): toggle.value_changed.connect(edited)
		for target in [button,toggle,panel.get_node("Native")]: click(host,target)
		for frame in range(8): await tree.process_frame
		await RenderingServer.frame_post_draw
		var image := tree.root.get_texture().get_image()
		image.save_png("res://editor-spreads-"+str(extent.x)+".png")
		samples.append({"viewport":str(extent),"root":host.get_node("UI").layout_size==Vector2(extent),"panel":str(panel.layout_size),"content":panel.get_content_rect().size.x,"button":str(button.layout_size),"half_width":button.layout_size.x==panel.get_content_rect().size.x/2,"height":button.layout_size.y,"border":image.get_pixelv(Vector2i(panel.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc"))})
	var result := {"clicks":host.clicks,"native":host.native_clicks,"edits":edits,"samples":samples}
	print("S03_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/s03-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/s03-game.tmp","res://.godot/s03-game.json")
