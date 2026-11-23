extends RefCounted
func frames(tree: SceneTree):
	for index in range(8): await tree.process_frame
func click(node: Node):
	var event := InputEventMouseButton.new()
	event.position=node.get_global_transform_with_canvas()*Vector2(12,12)
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	node.get_viewport().push_input(event,true)
	event=event.duplicate()
	event.pressed=false
	node.get_viewport().push_input(event,true)
func run(host: Node) -> Dictionary:
	var tree:=host.get_tree()
	await frames(tree)
	var column=host.get_node("UI/Column")
	var action=column.get_node("Action")
	var id: int=action.get_instance_id()
	var ok:=true
	var observed:=true
	var static_text: String=column.get_node("Ordinary/Static").text
	for size in [Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size=size
		host.model.label="Game "+str(size.x)
		await frames(tree)
		click(action)
		await frames(tree)
		ok=ok and host.get_node("UI").layout_size==Vector2(640,480) and action.get_instance_id()==id
		observed=observed and column.get_node("Badges").get_child(0).get_node("Label").text==host.model.label.to_upper()
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://core01-game-"+str(size.x)+".png")
	var result: Dictionary={"ok":ok,"edits":host.edits,"value":host.model.value,"identity":id==action.get_instance_id(),"observed":observed,"static":column.get_node("Ordinary/Static").text==static_text}
	print("CORE01_GAME ",JSON.stringify(result))
	var file:=FileAccess.open("res://.godot/core01-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/core01-game.tmp","res://.godot/core01-game.json")
	return result
