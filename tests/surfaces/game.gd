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
	var round = ui.get_layout_child("Panels").get_layout_child("Round")
	var clipped = ui.get_layout_child("Clipped")
	var identity: int = round.get_instance_id()
	var ok := true
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800)]:
		tree.root.size = size
		await frames(tree)
		ok = ok and ui.layout_size==Vector2(size) and round.get_instance_id()==identity
		ui.scroll_offset = Vector2(0,clipped.position.y-20)
		await frames(tree)
		click(clipped.get_layout_child("Custom"))
		await frames(tree)
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://surface-game-"+str(size.x)+".png")
	var native = clipped.get_layout_child("Native")
	click(native)
	await frames(tree)
	ok = ok and host.clicks==4 and native.has_focus()
	var runs: int = State.records[host.get_instance_id()].runs
	var stats: Dictionary = round.get_layout_stats()
	round.corner_radius = "9px"
	round.background_texture = host.PANEL_TEXTURE
	await frames(tree)
	ok = ok and stats==round.get_layout_stats() and runs==State.records[host.get_instance_id()].runs
	var result := {"ok":ok,"clicks":host.clicks,"identity":identity,"resource":round.background_texture is GradientTexture2D}
	print("S04_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/s04-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/s04-game.tmp","res://.godot/s04-game.json")
	return result
