extends RefCounted
func frames(tree: SceneTree):
	for i in range(10): await tree.process_frame
func click(node: Node):
	var event := InputEventMouseButton.new()
	event.position = node.get_global_transform_with_canvas()*Vector2(12,12)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	node.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	node.get_viewport().push_input(event,true)
func run(host: Node) -> Dictionary:
	var tree := host.get_tree()
	await frames(tree)
	var app = host.get_node("UI/App")
	var side = app.get_node("Side")
	var body = app.get_node("Body")
	var action = body.get_node("Action")
	var identity: int = action.get_instance_id()
	var ok := true
	for size in [Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = size
		await frames(tree)
		ok = ok and app.layout_size==Vector2(tree.root.size) and side.layout_size.x==160 and action.get_instance_id()==identity and body.get_node("Imported/Shared/Upper").layout_size.y>0
		click(action)
		click(body.get_node("Toggle"))
		await frames(tree)
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://layout-game-"+str(size.x)+".png")
	var result := {"ok":ok,"clicks":host.clicks,"selected":host.selected,"identity":action.get_instance_id()==identity}
	print("EL02_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/el02-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/el02-game.tmp","res://.godot/el02-game.json")
	return result
