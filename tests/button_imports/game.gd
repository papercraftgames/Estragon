extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
func frames(tree: SceneTree):
	for i in range(8): await tree.process_frame
func click(node: Node):
	var event := InputEventMouseButton.new()
	event.position = node.get_global_transform_with_canvas()*Vector2(20,20)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	node.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	node.get_viewport().push_input(event,true)
func run(host: Node) -> Dictionary:
	var tree := host.get_tree()
	await frames(tree)
	var ui = host.get_node("UI")
	var column = ui.get_layout_child("Column")
	var action = column.get_node("Kinds/Action")
	var native = column.get_node("Kinds/Native")
	var unimported = column.get_node("Kinds/Unimported")
	var identity: int = action.get_instance_id()
	var ok := true
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = size
		ui.scroll_offset = Vector2.ZERO
		await frames(tree)
		print("D07_GAME_SIZE requested=",size," actual=",tree.root.size," layout=",ui.layout_size)
		ok = ok and ui.layout_size==Vector2(tree.root.size) and action.get_instance_id()==identity
		for node in [action,native,unimported.get_node("Godot")]: click(node)
		await frames(tree)
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://button-game-"+str(size.x)+".png")
	var result := {"ok":ok,"clicks":host.clicks,"native_clicks":host.native_clicks,"unimported_clicks":unimported.clicks,"identity":identity,"resource":column.get_node("Surface").background_texture is GradientTexture2D}
	print("D07_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/d07-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/d07-game.tmp","res://.godot/d07-game.json")
	return result
