extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
var edits: Array = []
func edited(_previous: bool, value: bool) -> void: edits.append(value)
func click(host: Node, button: Node) -> void:
	var extent: Vector2 = button.size if button is Control else button.layout_size
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(extent*Vector2(0.6,0.5))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	host.get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	host.get_viewport().push_input(event,true)
func run(host: Node) -> Dictionary:
	var tree := host.get_tree()
	var samples: Array = []
	var ids: Array = []
	var initial_runs: Array = []
	for extent in [Vector2i(320,480),Vector2i(640,480),Vector2i(1000,800),Vector2i(640,480)]:
		tree.root.size = extent
		for frame in range(12): await tree.process_frame
		var ui = host.get_node("UI")
		var content = ui.get_node("Content")
		var cards = content.get_node("Cards")
		var named = content.get_node("Named")
		var automatic = content.get_node("Automatic")
		var main = named.get_node("Main")
		var toggle = named.get_node("Sidebar/Enabled")
		var native = named.get_node("Sidebar/Native")
		if not toggle.value_changed.is_connected(edited): toggle.value_changed.connect(edited)
		var runs := [State.records[host.get_instance_id()].runs,State.records[main.get_instance_id()].runs]
		var current_ids := [cards.get_node("a").get_instance_id(),main.get_instance_id(),toggle.get_instance_id(),native.get_instance_id()]
		if ids.is_empty():
			ids = current_ids
			initial_runs = runs
		if extent.x>=640:
			for target in [cards.get_node("a"),toggle,native,main.get_node("Body/NestedAction")]: click(host,target)
			for frame in range(8): await tree.process_frame
		var stats := [cards.get_layout_stats(),named.get_layout_stats(),automatic.get_layout_stats()]
		for frame in range(8): await tree.process_frame
		await RenderingServer.frame_post_draw
		var image := tree.root.get_texture().get_image()
		image.save_png("res://responsive-"+str(extent.x)+".png")
		var trace: Array = []
		for child in cards.get_children(): trace.append({"name":str(child.name),"position":str(child.position),"size":str(child.layout_size)})
		var expected_lines := 3 if extent.x==320 else (2 if extent.x==640 else 1)
		var column: float = (automatic.get_content_rect().size.x-20)/3
		var result := {"viewport":str(extent),"root":ui.layout_size==Vector2(extent),"wrap":cards.layout_size.y==expected_lines*36+(expected_lines-1)*12,"grid":is_equal_approx(automatic.get_node("One").layout_size.x,column) and is_equal_approx(automatic.get_node("Three").position.x,2*(column+10)),"named":main.position==Vector2(162,70),"ids":ids==current_ids,"runs":runs==initial_runs,"idle":stats==[cards.get_layout_stats(),named.get_layout_stats(),automatic.get_layout_stats()],"owner":cards.get_node("a").owner==null and main.owner==null,"border":image.get_pixelv(Vector2i(named.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc")),"cards":trace,"named_size":str(named.layout_size)}
		samples.append(result)
		initial_runs = [State.records[host.get_instance_id()].runs,State.records[main.get_instance_id()].runs]
	var nested_clicks: int = host.get_node("UI/Content/Named/Main").clicks
	var passed: bool = host.clicks==3 and host.native_clicks==3 and nested_clicks==3 and edits==[true,false,true]
	for sample in samples:
		for key in ["root","wrap","grid","named","ids","runs","idle","owner","border"]: passed = passed and sample[key]
	var result := {"ok":passed,"clicks":host.clicks,"native":host.native_clicks,"nested":nested_clicks,"edits":edits,"samples":samples}
	print("L0910_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/l0910-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/l0910-game.tmp","res://.godot/l0910-game.json")
	return result
