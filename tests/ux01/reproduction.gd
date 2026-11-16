extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
func check(ok: bool, label: String):
	print("UX01_REPRO ",label,": ",ok)
	failed = failed or not ok
func _initialize(): run.call_deferred()
func run():
	var host = load("res://app/generated/WrapReproduction.gd").new()
	root.add_child(host)
	var ids: Array = []
	var runs := 0
	for width in [1000,640,320,1000]:
		root.size = Vector2i(width,800)
		for frame in range(8): await process_frame
		var column = host.get_node("UI/Column")
		var words = column.get_node("Words")
		var next: Array = []
		var lines := {}
		for child in words.get_children():
			next.append(child.get_instance_id())
			lines[child.position.y] = true
			check(child.position.x+child.layout_size.x<=words.layout_size.x+0.01,"measured unbreakable item fits line")
		if ids.is_empty():
			ids = next
			runs = State.records[host.get_instance_id()].runs
		check(ids==next and runs==State.records[host.get_instance_id()].runs,"resize retains nodes without Gogo recomposition")
		check(lines.size()>1 and words.layout_size.x<=width-40 and is_equal_approx(words.position.x+words.layout_size.x,width-20),"exact owner reproduction wraps/end aligns width%d" % width)
		check(words.layout.model.content_reference.x==-1,"capacity never becomes percentage reference")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ux01-repro-"+str(width)+".png")
		var stats = words.get_layout_stats()
		for frame in range(8): await process_frame
		check(stats==words.get_layout_stats(),"idle quiet")
	host.free()
	for frame in range(5): await process_frame
	if not failed: print("UX01_REPRO_OK")
	quit(1 if failed else 0)
