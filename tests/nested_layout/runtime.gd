extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var checks := 0
var home: Node2D
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L03_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for index in range(8): await process_frame
func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
func rect(node: Node2D) -> Rect2:
	return Rect2(node.global_position,node.layout_size)
func snapshot(label: String) -> void:
	var data := {}
	for path in ["UI/Column/Hello","UI/Column/Fun","UI/Column/Settings/Row/Exit","UI/Column/Rose/Row/RoseText","UI/Column/Rose/Row/RoseButton"]:
		var node = home.get_node_or_null(path)
		if node != null: data[path] = {"position":str(node.global_position),"size":str(node.layout_size)}
	var file := FileAccess.open("res://"+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	print("L03_GEOMETRY ",label," ",JSON.stringify(data))
func click(node: Node2D) -> void:
	var point: Vector2 = node.get_global_transform_with_canvas()*(node.layout_size/2)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	home = load("res://app/generated/Home.gd").new()
	home.name = "Home"
	root.add_child(home)
	await frames()
	var column = home.get_node("UI/Column")
	var settings = column.get_node("Settings")
	var rose = column.get_node("Rose")
	var exit_button = settings.get_node("Row/Exit")
	var rose_text = rose.get_node("Row/RoseText")
	var before := OS.get_environment("L03_BEFORE")=="1"
	snapshot("before" if before else "after")
	await capture("before" if before else "after")
	if before:
		print("L03_BEFORE_OK")
		home.free()
		await frames()
		quit(); return
	check(rose_text.layout_size.x>0 and rose_text.layout_size.y>0,"nested Rose Text receives nonzero allocation")
	check(exit_button.global_position.y>=column.get_node("Fun").global_position.y+column.get_node("Fun").layout_size.y,"Settings Exit follows outer texts below flex spacer")
	check(rose_text.global_position.y>=rect(exit_button).end.y and rect(rose_text).end.y<=home.extent.y+0.1,"Rose follows Settings in bottom VBox region without overlap")
	check(settings.get_node("Row").position==Vector2.ZERO and settings.position.y>0,"host placement does not duplicate root offset")
	check(settings.owner==null and exit_button.owner==null,"managed hosts and views remain transient native Nodes")
	if OS.get_environment("L03_EXIT")=="1":
		print("L03_EXIT_READY")
		await click(exit_button)
		check(false,"actual Exit handler must quit the child process")
		quit(1); return
	var parent_record = State.records[home.get_instance_id()]
	var settings_id: int = settings.get_instance_id()
	settings.local_state = 42
	home.tick = 1
	await frames()
	check(column.get_node("Settings")==settings and settings.local_state==42 and settings.get_node("Row/Exit")==exit_button,"unrelated parent recomposition retains host/view identity and local state")
	var parent_runs: int = parent_record.runs
	var child_runs: int = State.records[settings_id].runs
	settings.caption = "Exit\nsecond line"
	await frames()
	check(parent_record.runs==parent_runs and State.records[settings_id].runs==child_runs+1,"child intrinsic change recomposes only its interested function once")
	check(rect(exit_button).size.y>44 and rose.global_position.y>=rect(exit_button).end.y,"child intrinsic growth reflows parent and subsequent sibling")
	settings.visible_button = false
	await frames()
	check(settings.get_node("Row").layout_size==Vector2.ZERO and rose.global_position.y==home.extent.y-rose_text.layout_size.y,"child removal shrinks measured parent slot without orphaned view")
	settings.visible_button = true
	settings.caption = "Exit"
	rose.button = true
	await frames()
	exit_button = settings.get_node("Row/Exit")
	var rose_button = rose.get_node("Row/RoseButton")
	check(not rect(exit_button).intersects(rect(rose_button)) and rect(exit_button).size.y>0 and rect(rose_button).size.y>0,"natural nested buttons occupy distinct nonoverlapping slots")
	await click(rose_button)
	check(rose.clicks==1,"actual pointer press reaches Rose at its arranged hit region")
	settings.wide = true
	rose.wide = true
	await frames()
	check(is_equal_approx(exit_button.layout_size.x,home.extent.x) and is_equal_approx(rose_button.layout_size.x,home.extent.x) and not rect(exit_button).intersects(rect(rose_button)),"root fill constraints forward through hosts to parent cross-axis allocation")
	await click(rose_button)
	check(rose.clicks==2,"filled Rose button remains clickable in its expanded hit region")
	settings.view_width = 280.0
	settings.view_height = 80.0
	column.gap = 7.0
	await frames()
	check(exit_button.layout_size==Vector2(280,80) and settings.get_node("Row").position==Vector2.ZERO and rose_button.global_position.y>=rect(exit_button).end.y+7,"fixed root dimensions override fill and parent sibling gaps remain deterministic")
	snapshot("geometry")
	await capture("filled-buttons")
	root.size = Vector2i(800,500)
	await frames()
	check(home.extent==Vector2(800,500) and rose_button.layout_size.x==800 and rect(rose_button).end.y<=500.1,"native window resize reflows nested fill and bottom-aligned siblings")
	settings.view_width = -1.0
	settings.view_height = -1.0
	settings.wide = false
	rose.wide = false
	settings.rotation = 0.1
	settings.scale = Vector2(1.2,1.2)
	settings.caption = "Exit!"
	await frames()
	check(is_equal_approx(settings.rotation,0.1) and settings.scale==Vector2(1.2,1.2) and settings.get_node("Row").position==Vector2.ZERO,"layout owns host translation once and preserves native rotation/scale")
	settings.rotation = 0
	settings.scale = Vector2.ONE
	home.reverse = true
	await frames()
	check(column.get_node("Settings")==settings and column.get_node("Rose")==rose and settings.local_state==42 and rose.global_position.y<settings.global_position.y,"keyed native sibling reorder retains identity/state and reflows order")
	settings.direct = true
	await frames()
	check(settings.get_node("Direct").layout_size.y>0 and settings.get_node_or_null("Row")==null,"root replacement from HBox to direct Text updates the same host slot")
	settings.direct = false
	settings.independent = true
	await frames()
	var independent = settings.get_node("Independent")
	check(independent.get_layout_root()==independent and independent.position==Vector2(250,40) and independent.get_node("IndependentText").layout_size.y>0,"explicit child Entry remains an independently positioned separate scope")
	settings.independent = false
	await frames()
	check(settings.get_node("Row/Exit").get_layout_root()==home.get_node("UI"),"returning from independent Entry reconnects the parent scope")
	home.show_settings = false
	await frames()
	check(not is_instance_valid(settings) and not State.records.has(settings_id),"nested removal disposes native host, computation and layout registration")
	home.show_settings = true
	home.reverse = false
	await frames()
	settings = column.get_node("Settings")
	check(settings.local_state==7 and column.get_children().filter(func(n): return n.name=="Settings").size()==1,"restored component mounts once with fresh local state")
	var before_runs: int = parent_record.runs
	var before_flush: int = home.get_node("UI").layout.flush_count
	await frames()
	check(parent_record.runs==before_runs and home.get_node("UI").layout.flush_count==before_flush,"idle tree performs no composition or layout polling")
	root.remove_child(home)
	await frames()
	check(not settings.get_node("Row/Exit").is_inside_tree(),"native detach suspends nested scope")
	root.add_child(home)
	await frames()
	check(column.get_node("Settings")==settings and settings.get_node("Row/Exit").get_layout_root()==home.get_node("UI"),"native detach/re-entry restores same host and continuous pointer/layout scope")
	home.deep = true
	await frames()
	var multi = column.get_node("Multi")
	var deep_settings = multi.get_node("Stack/Settings/Row/Exit")
	var deep_rose = multi.get_node("Stack/Rose/Row/RoseText")
	check(deep_settings.layout_size.y>0 and deep_rose.global_position.y>=rect(deep_settings).end.y+3,"two-plus host levels and mixed VBox/HBox roots measure and arrange continuously")
	await capture("multilevel")
	# A deliberate ordinary native Node2D still blocks scope propagation.
	var plain := Node2D.new()
	column.add_child(plain)
	var hidden = preload("res://addons/estragon/runtime/node/text.gd").new()
	hidden.text = "unscoped"
	plain.add_child(hidden)
	var foreign = preload("res://addons/estragon/runtime/node/text.gd").new()
	foreign.text = "scene child"
	multi.add_child(foreign)
	await frames()
	check(hidden.get_layout_root()==null and hidden.layout_size==Vector2.ZERO,"unrelated plain Node2D remains a boundary")
	check(foreign.layout_size==Vector2.ZERO and foreign.get_parent()==multi,"host bridge never measures or moves unmanaged scene children")
	plain.free()
	foreign.free()
	# A host returning another host forwards constraints without an extra root.
	var relay = load("res://app/generated/Relay.gd").new()
	column.add_child(relay)
	await frames()
	check(relay.get_node("Settings/Row/Exit").layout_size.y>0,"transparent host-to-host view root inherits the same scope")
	relay.free()
	await spatial_proof()
	# Native scene persistence saves authored host only and remounts once.
	var packed := PackedScene.new()
	check(packed.pack(home)==OK and packed.get_state().get_node_count()==1,"PackedScene excludes transient GGX hosts/views")
	check(ResourceSaver.save(packed,"res://Reload.tscn")==OK,"native scene saves")
	home.free()
	await frames()
	var saved: PackedScene = load("res://Reload.tscn")
	home = saved.instantiate()
	root.add_child(home)
	await frames()
	check(home.get_node("UI/Column/Settings/Row/Exit").layout_size.y>0 and home.get_node("UI/Column").get_children().filter(func(n): return n.name=="Settings").size()==1,"saved/reopened host remounts one nested view with correct allocation")
	print("L03_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L03_RUNTIME_OK")
	home.free()
	await frames()
	quit(1 if failed else 0)

func spatial_proof() -> void:
	var entry = preload("res://addons/estragon/runtime/node/estragon_3d.gd").new()
	entry.set_extent(Vector3(30,10,10))
	root.add_child(entry)
	var spatial = load("res://app/generated/Spatial.gd").new()
	entry.add_child(spatial)
	var sibling = preload("res://addons/estragon/runtime/node/component_3d.gd").new()
	sibling.set_extent(Vector3(1,1,1))
	entry.add_child(sibling)
	await frames()
	check(spatial.get_node("Row").layout_size==Vector3(7,3,4) and spatial.get_node("Row/B").position==Vector3(2,0,0) and sibling.position==Vector3(7,0,0),"3D host forwards bounded native intrinsic extents and sibling placement")
	spatial.room = 12.0
	await frames()
	check(sibling.position==Vector3(12,0,0) and spatial.get_node("Row").position==Vector3.ZERO,"3D reactive fixed root extent reflows parent without double translation")
	var wrong = load("res://app/generated/Rose.gd").new()
	entry.add_child(wrong)
	await frames()
	check(wrong.get_node("Row/RoseText").layout_size==Vector2.ZERO,"cross-dimensional host remains outside incompatible layout scope")
	entry.free()
	await frames()
