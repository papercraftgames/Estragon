extends SceneTree
const Entry2D = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Entry3D = preload("res://addons/estragon/runtime/node/estragon_3d.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
const Build = preload("res://addons/estragon/editor/build_service.gd")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L05_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(10): await process_frame
func capture(name: String, entry: Node, rose: Node) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
	var file := FileAccess.open("res://"+name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"visible":str(root.get_visible_rect().size),"allocation":str(entry.layout_size),"rose_bottom":rose.global_position.y+rose.layout_size.y}))
	file.close()
func input_click(button: Node, extent: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(extent/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func connections(view: Viewport, entry: Node) -> int:
	var count := 0
	for item in view.get_signal_connection_list("size_changed"):
		if item.callable==entry.layout._viewport_changed: count += 1
	return count
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1152,648)
	var snapshot = load("res://app/generated/Snapshot.gd").new()
	root.add_child(snapshot)
	await frames()
	root.size = Vector2i(1800,1100)
	await frames()
	var rose = snapshot.get_node("UI/Column/Rose/Row/RoseText")
	check(snapshot.get_node("UI").layout_size==Vector2(1152,648) and rose.global_position.y+rose.layout_size.y==648,"owner static viewport expressions remain composition snapshots after resize")
	capture("snapshot-tall",snapshot.get_node("UI"),rose)
	snapshot.free()
	root.size = Vector2i(1152,648)
	var home = load("res://app/Home.tscn").instantiate()
	root.add_child(home)
	await frames()
	var entry = home.get_node("UI")
	var settings = home.get_node("UI/Column/Settings")
	rose = home.get_node("UI/Column/Rose/Row/RoseText")
	var button: Button = settings.get_node("Row/Exit")
	var borrowed: Button = home.get_node("Borrowed")
	borrowed.pressed.connect(home.pressed)
	var identities := [settings.get_instance_id(),settings.get_script(),rose.get_instance_id(),button.get_instance_id(),borrowed.get_instance_id()]
	var runs := [State.get("records")[home.get_instance_id()].runs,State.get("records")[settings.get_instance_id()].runs]
	var cached: int = rose.layout.model.measure_count
	for size in [Vector2i(1152,648),Vector2i(1800,1100),Vector2i(760,420)]:
		root.size = size
		await frames()
		check(entry.layout_size==root.get_visible_rect().size and rose.global_position.y+rose.layout_size.y==root.get_visible_rect().size.y and rose.global_position.y>=borrowed.global_position.y+borrowed.size.y and borrowed.global_position.y>=button.global_position.y+button.size.y,"live X/Y allocation and bottom slots match visible viewport "+str(size))
		capture("live-"+str(size.x),entry,rose)
	check(identities==[settings.get_instance_id(),settings.get_script(),rose.get_instance_id(),button.get_instance_id(),borrowed.get_instance_id()] and borrowed.owner==home and borrowed.get_parent()==home,"resize preserves actual Gogo/Control/Script identities and borrowed scene ownership")
	check(runs==[State.get("records")[home.get_instance_id()].runs,State.get("records")[settings.get_instance_id()].runs] and rose.layout.model.measure_count==cached,"viewport layout never reruns views or remeasures a clean sibling")
	input_click(button,button.size)
	if OS.get_environment("L05_EXIT")=="1": return
	check(settings.clicks==1,"native Exit GUI remains single-dispatch after grow/shrink")
	input_click(borrowed,borrowed.size)
	check(home.clicks==1,"scene-owned borrowed native Button keeps GUI signal authority")
	var ui = preload("res://addons/estragon/runtime/node/button.gd").new()
	ui.text = "Framework"
	ui.pressed.connect(home.pressed)
	home.get_node("UI/Column").add_child(ui)
	await frames()
	input_click(ui,ui.layout_size)
	check(home.clicks==2,"UiButton pointer routing remains functional after viewport resize")
	var idle := [entry.get_layout_stats(),rose.get_layout_stats()]
	await frames()
	check(idle==[entry.get_layout_stats(),rose.get_layout_stats()],"idle viewport tree has zero further measure/arrange/flush work")
	home.free()
	await frames()
	await axes_and_lifetime()
	await language()
	check(Hosts.get("controls").is_empty() and Hosts.get("hosts").is_empty() and State.get("records").is_empty(),"teardown releases layout/composition/native Control records")
	print("L05_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L05_RUNTIME_OK")
	quit(1 if failed else 0)

func axes_and_lifetime() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(400,300)
	root.add_child(view)
	for dimension in [2,3]:
		var entry = Entry2D.new() if dimension==2 else Entry3D.new()
		entry.width = 80
		entry.height = 60
		if dimension==3: entry.depth = 7
		view.add_child(entry)
		await frames()
		check(entry.layout.model.size==Vector3(80,60,0 if dimension==2 else 7),"neither axis preserves fixed sizing "+str(dimension))
		var world: float = 1.0 if dimension==2 else 0.01
		entry.viewport_width_scale = world
		await frames()
		check(entry.layout.model.size==Vector3(400*world,60,0 if dimension==2 else 7),"width-only retains existing fixed precedence "+str(dimension))
		entry.viewport_width_scale = 0
		entry.viewport_height_scale = 0.75*world
		await frames()
		check(entry.layout.model.size==Vector3(80,225*world,0 if dimension==2 else 7),"height-only overrides height and leaves X/Z unchanged "+str(dimension))
		entry.viewport_width_scale = 0.9*world
		view.size = Vector2i(500,200)
		await frames()
		check(entry.layout.model.size.is_equal_approx(Vector3(450*world,150*world,0 if dimension==2 else 7)),"independent fractions follow aspect changes with explicit3D world scales "+str(dimension))
		var before = entry.get_layout_stats()
		for bad in [-1.0,NAN,INF,-INF]:
			entry.viewport_height_scale = bad
			entry.viewport_width_scale = bad
		entry.viewport_height_scale = entry.viewport_height_scale
		await frames()
		check(entry.viewport_width_scale==0.9*world and entry.viewport_height_scale==0.75*world and before==entry.get_layout_stats(),"invalid/equal writes retain prior scales and do no layout work "+str(dimension))
		var flushes: int = entry.layout.flush_count
		view.size = Vector2i(220,140)
		view.size = Vector2i(240,160)
		view.size = Vector2i(260,180)
		await frames()
		check(entry.layout.flush_count==flushes+1 and entry.layout.model.size.is_equal_approx(Vector3(234*world,135*world,0 if dimension==2 else 7)),"native resize bursts coalesce to one subsequent arrange "+str(dimension))
		for tiny in [Vector2i.ZERO,Vector2i.ONE,Vector2i(2,3)]:
			view.size = tiny
			await frames()
			var visible := view.get_visible_rect().size
			check(entry.layout.model.size.is_equal_approx(Vector3(visible.x*0.9*world,visible.y*0.75*world,0 if dimension==2 else 7)),"zero/near-zero request follows native visible viewport, including native minimum clamp "+str(dimension)+str(tiny))
		entry.viewport_width_scale = 0
		entry.viewport_height_scale = 0
		await frames()
		check(entry.layout.model.size==Vector3(80,60,0 if dimension==2 else 7),"positive-to-zero returns to current fixed data without stale viewport allocation "+str(dimension))
		entry.width = -1
		entry.height = -1
		await frames()
		check(entry.layout.model.size==Vector3(0,0,0 if dimension==2 else 7),"unselected natural axes remain natural "+str(dimension))
		entry.viewport_height_scale = world
		check(connections(view,entry)==1,"one scoped viewport listener "+str(dimension))
		view.remove_child(entry)
		check(connections(view,entry)==0,"detach disconnects old viewport "+str(dimension))
		var other := SubViewport.new()
		other.size = Vector2i(120,90)
		root.add_child(other)
		other.add_child(entry)
		await frames()
		check(connections(other,entry)==1 and is_equal_approx(entry.layout.model.size.y,90*world),"re-entry uses new native viewport without duplicate listeners "+str(dimension))
		flushes = entry.layout.flush_count
		view.size = Vector2i(400,300)
		await frames()
		check(entry.layout.flush_count==flushes,"stale viewport cannot invalidate reparented Entry "+str(dimension))
		var independent = Entry2D.new() if dimension==2 else Entry3D.new()
		independent.viewport_height_scale = 0.5*world
		entry.add_child(independent)
		await frames()
		check(independent.get_layout_root()==independent and is_equal_approx(independent.layout.model.size.y,45*world) and not entry.layout.model.children.has(independent.layout.model),"nested Entry remains an independent native viewport scope "+str(dimension))
		other.free()
		await frames()
	var spatial = load("res://app/generated/Spatial.gd").new()
	view.add_child(spatial)
	await frames()
	check(spatial.get_node("UI").layout_size.is_equal_approx(Vector3(4,6,7)),"compiled Gogo Entry3D uses explicit X/Y world scales and preserves depth")
	view.size_2d_override = Vector2i(320,180)
	view.size_2d_override_stretch = true
	await frames()
	var visible := view.get_visible_rect().size
	check(spatial.get_node("UI").layout_size.is_equal_approx(Vector3(visible.x*0.01,visible.y*0.02,7)),"native viewport stretch uses visible coordinates instead of render-target pixels")
	view.free()
	await frames()

func language() -> void:
	var entry := Entry2D.new()
	check(entry.get_property_list().any(func(item): return item.name=="viewport_height_scale" and item.type==TYPE_FLOAT and (item.usage & PROPERTY_USAGE_EDITOR)!=0),"height scale is a typed exported Inspector property")
	entry.free()
	var original := FileAccess.get_file_as_string("res://app/Home.gogo")
	var output := "res://app/generated/Home.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script: Script = load(output)
	preload("build.gd").write("res://app/Home.gogo",original.replace("viewport_height_scale","viewport_heigth_scale"))
	var report := Build.run_build()
	check(not report.ok and str(report.diagnostics).contains("viewport_heigth_scale") and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"misspelled GGX scale rejects with authored diagnostic and keeps valid Script/maps")
	preload("build.gd").write("res://app/Home.gogo",original.replace('viewport_height_scale={1.0}','viewport_height_scale="bad"'))
	report = Build.run_build()
	print("L05_TYPED_DIAGNOSTIC ",JSON.stringify(report))
	check(not report.ok and str(report.diagnostics).contains("Typed Node values require") and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==bytes,"non-string scale retains authored typed GGX expression validation")
	preload("build.gd").write("res://app/Home.gogo",original)
	check(Build.run_build().ok,"repair recovers native actual-path compilation")
