extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var assertions := 0
func check(ok: bool, label: String):
	assertions += 1
	print("UX01_GAME_CHECK ",label,": ",ok)
	failed = failed or not ok
func frames(tree: SceneTree):
	for i in range(8): await tree.process_frame
func click(host: Node, node: Node):
	var size: Vector2 = node.size if node is Control else node.layout_size
	var input := InputEventMouseButton.new()
	input.position = node.get_global_transform_with_canvas()*(size*Vector2(0.4,0.4))
	input.button_index = MOUSE_BUTTON_LEFT
	input.pressed = true
	host.get_viewport().push_input(input,true)
	input = input.duplicate()
	input.pressed = false
	host.get_viewport().push_input(input,true)
func run(host: Node) -> Dictionary:
	var tree := host.get_tree()
	await frames(tree)
	var scroll = host.get_node("UI/Content/Scroll")
	var list = scroll
	var native = list.get_layout_child("NativeRow")
	var custom = list.get_layout_child("CustomRow")
	var toggle = list.get_layout_child("ToggleRow")
	var ids := [scroll.get_instance_id(),native.get_instance_id(),custom.get_instance_id(),toggle.get_instance_id()]
	var runs: int = State.records[host.get_instance_id()].runs
	var edits: Array = []
	var samples: Array = []
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800),Vector2i(320,240)]:
		tree.root.size = size
		await frames(tree)
		var content = host.get_node("UI/Content")
		var wrap = content.get_node("Wrap")
		check(wrap.layout_size.x<=size.x-24 and scroll.layout_size.x==size.x-24,"responsive auto wrap and scroll width")
		check(scroll.layout_size.y<=380 and scroll.content_extent.y==900 and is_equal_approx(scroll.scroll_range.y,900-scroll.get_content_rect().size.y),"natural900 content / responsive bounded viewport")
		check(scroll.get_instance_id()==ids[0] and native.get_instance_id()==ids[1] and toggle.get_instance_id()==ids[3] and State.records[host.get_instance_id()].runs==runs,"resize keeps identity/owner and no recomposition")
		check(native.owner==null and scroll.owner==null,"generated helpers/views remain transient")
		for offset in [0,420,int(scroll.scroll_range.y)]:
			scroll.scroll_offset = Vector2(0,offset)
			await frames(tree)
			await RenderingServer.frame_post_draw
			var image := tree.root.get_texture().get_image()
			image.save_png("res://ux01-gallery-"+str(size.x)+"-"+str(offset)+".png")
			samples.append({"viewport":str(size),"offset":str(scroll.scroll_offset),"range":str(scroll.scroll_range),"content":str(scroll.content_extent)})
		var stats = [scroll.get_layout_stats(),list.get_layout_stats()]
		await frames(tree)
		check(stats==[scroll.get_layout_stats(),list.get_layout_stats()],"settled idle quiet")
		scroll.scroll_offset = Vector2.ZERO
		await frames(tree)
		click(host,native)
		await frames(tree)
		check(native.has_focus(),"native scroll button owns focus")
		scroll.scroll_offset = Vector2(0,60)
		await frames(tree)
		click(host,custom)
		await frames(tree)
		scroll.scroll_offset = Vector2(0,120)
		await frames(tree)
		click(host,toggle)
		await frames(tree)
		edits.append(host.enabled)
		runs = State.records[host.get_instance_id()].runs
	check(host.clicks==8 and edits==[true,false,true,false],"single native/custom clicks and controlled Toggle edits")
	var offset: Vector2 = scroll.scroll_offset
	host.username = "é 🌱"
	await frames(tree)
	check(host.get_node("UI/Content/Greeting").text=="Hello é 🌱!" and scroll.get_instance_id()==ids[0] and scroll.scroll_offset==offset,"body text update preserves scroll identity/offset")
	host.order = [0,2,3,4]
	await frames(tree)
	check(scroll.scroll_offset.y<=scroll.scroll_range.y and list.get_layout_child("NativeRow").get_instance_id()==ids[1],"keyed shrink clamps offset and retains native child")
	host.order = [3,2,0,4]
	await frames(tree)
	check(list.get_layout_children()[2].get_instance_id()==ids[1],"keyed Grid/Toggle/native reorder")
	check(host.get_node("UI/Content/Overflow").layout_size.x<=180 if host.has_node("UI/Content/Overflow") else true,"owner max only")
	var result := {"ok":not failed,"assertions":assertions,"clicks":host.clicks,"edits":edits,"samples":samples}
	print("UX01_EDITOR_GAME ",JSON.stringify(result))
	var file := FileAccess.open("res://.godot/ux01-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/ux01-game.tmp","res://.godot/ux01-game.json")
	return result
