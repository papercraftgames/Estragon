extends RefCounted
var edits: Array = []
func edited(_previous: bool, value: bool) -> void: edits.append(value)
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
		var content = host.get_node("UI/Content")
		var header = content.get_node("Header")
		var even = content.get_node("Even")
		var row = content.get_node("Configurable")
		var toggle = row.get_node("Enabled")
		if not toggle.value_changed.is_connected(edited): toggle.value_changed.connect(edited)
		for target in [header.get_node("Close"),row.get_node("Action"),toggle,row.get_node("Native")]: click(host,target)
		for frame in range(8): await tree.process_frame
		await RenderingServer.frame_post_draw
		var image := tree.root.get_texture().get_image()
		image.save_png("res://editor-alignment-"+str(extent.x)+".png")
		var width: float = even.layout_size.x
		var positions: Array = []
		for name in ["a","b","c"]: positions.append(str(even.get_node(name).position))
		samples.append({"viewport":str(extent),"root":host.get_node("UI").layout_size==Vector2(extent),"width":width,"positions":positions,"evenly":even.get_node("a").position.x==(width-120)/4 and even.get_node("b").position.x==(width-120)/2+40 and even.get_node("c").position.x==3*(width-120)/4+80,"self_end":even.get_node("b").position.y==66,"border":image.get_pixelv(Vector2i(header.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc"))})
	var result := {"clicks":host.clicks,"native":host.native_clicks,"edits":edits,"samples":samples}
	print("L08_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/l08-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/l08-game.tmp","res://.godot/l08-game.json")
