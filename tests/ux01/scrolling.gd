extends SceneTree
var failed := false
func check(ok: bool, label: String):
	print("UX01_SCROLL ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func click(point: Vector2):
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var host = load("res://app/generated/ScrollProof.gd").new()
	root.add_child(host)
	await frames()
	var scroll = host.get_node("UI/Scroll")
	var list = scroll.get_content_root()
	check(scroll.scroll_range==Vector2(0,600) and list.layout_size.y==900,"900 content /300 viewport =600 range")
	var native = list.get_node("Middle")
	click(Vector2(40,350))
	await frames()
	check(host.clicks==0,"offviewport native Button cannot activate")
	click(Vector2(40,60))
	await frames()
	check(host.clicks==1,"inside Estragon Button activates once")
	for offset in [0,300,600,0]:
		var stats = list.get_layout_stats()
		scroll.scroll_offset = Vector2(0,offset)
		await frames()
		check(stats==list.get_layout_stats(),"offset is transform only, no layout/recomposition")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ux01-scroll-"+str(offset)+".png")
	scroll.scroll_offset = Vector2(0,300)
	await frames()
	click(Vector2(40,60))
	await frames()
	check(host.clicks==2 and native.has_focus(),"visible native Button activates once and owns native focus")
	scroll.scroll_offset = Vector2(0,600)
	await frames()
	click(Vector2(40,60))
	await frames()
	check(host.enabled,"visible Toggle controlled edit")
	click(Vector2(40,350))
	await frames()
	check(host.enabled and host.clicks==2,"all offviewport pointer paths remain excluded")
	host.free()
	await frames()
	if not failed: print("UX01_SCROLL_OK")
	quit(1 if failed else 0)
