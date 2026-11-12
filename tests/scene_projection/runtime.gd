extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
# Native const-Resource.member dictionary reads can be folded/aliased when
# several initially empty dictionaries share a function's constant pool on both
# approved engines. get() inspects each live registry, never a folded snapshot.
const Build = preload("build.gd")
var failed := false
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	print("E08_CHECK ",label,": ",value)
	if not value: failed = true
func frames() -> void:
	for index in range(8): await process_frame
func click(button: Node2D) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()
func capture(name: String) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if OS.get_environment("E08_NEGATIVE")=="1":
		await negatives()
		return
	var home := Build.scene()
	root.add_child(home)
	await frames()
	var settings = home.get_node("Settings")
	var sprite = home.get_node("Sprite2D")
	var action = settings.get_node("View/Action")
	var hello = home.get_node("UI/Column/Hello")
	var middle = home.get_node("UI/Column/Middle")
	check(settings.get_parent()==home and settings.owner==home and sprite.owner==home,"native parents/owners and Scene paths never change")
	check(action.layout_size.y>0 and action.global_position.y>=hello.global_position.y+hello.layout_size.y+7.9 and middle.global_position.y>=action.global_position.y+action.layout_size.y+7.9,"borrowed Settings occupies the selected VBox slot between generated texts")
	check(sprite.position==Vector2(400,220) and sprite.get_parent()==home,"ordinary Sprite stays native free-positioned without a fabricated footprint")
	check(action.get_layout_root()==home.get_node("UI"),"borrowed subtree joins logical Entry input scope")
	await click(action)
	check(settings.clicks==1,"native pointer reaches the same scene-authored Settings handler")
	var file := FileAccess.open("res://geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"settings_id":settings.get_instance_id(),"native_parent":str(settings.get_parent().get_path()),"owner":str(settings.owner.get_path()),"logical_parent":str(Hosts.projected_parent(settings).get_path()),"hello":{"position":str(hello.global_position),"size":str(hello.layout_size)},"settings":{"position":str(action.global_position),"size":str(action.layout_size)},"after":{"position":str(middle.global_position),"size":str(middle.layout_size)},"sprite":{"position":str(sprite.position)}}))
	file.close()
	await capture("projected")
	var settings_id: int = settings.get_instance_id()
	home.single = true
	await frames()
	check(Hosts.get("projections").size()==1 and settings.get_node("View/Action")==action and settings.get_parent()==home,"a single native Node expression borrows the same child without literal get_children special-casing")
	home.single = false
	await frames()
	var record = State.get("records")[home.get_instance_id()]
	for tick in range(1,4):
		home.tick = tick
		await frames()
	check(home.get_node("Settings")==settings and settings.get_node("View/Action")==action and settings.clicks==1 and home.get_child_count()==3,"second and later get_children exclude managed output and retain authored instances/state")
	var runs: int = record.runs
	settings.caption = "Settings\nTwo lines"
	await frames()
	check(record.runs==runs and middle.global_position.y>=action.global_position.y+action.layout_size.y+7.9,"child bindable growth reflows logical parent without recomposing Home")
	var old_y: float = settings.position.y
	home.alternate = true
	await frames()
	check(settings.position.y>old_y and settings.get_instance_id()==settings_id and settings.get_parent()==home,"moving expression to another slot retains native identity/parent")
	home.show_children = false
	await frames()
	check(settings.position==Vector2(90,100) and settings.owner==home and is_instance_valid(action) and Hosts.projected_parent(settings)==null,"conditional removal restores placement and preserves user subtree")
	check(action.get_layout_root()==null,"conditional release detaches logical pointer/layout scope")
	home.show_children = true
	home.alternate = false
	await frames()
	home.replace_root = true
	await frames()
	check(home.get_node_or_null("UI")==null and home.get_node("Settings")==settings and action.get_layout_root()==home.get_node("Other"),"managed root replacement never frees borrowed nodes")
	home.replace_root = false
	await frames()
	var extra = load("res://app/generated/Settings.gd").new()
	extra.name = "Extra"
	home.add_child(extra)
	extra.owner = home
	await frames()
	check(Hosts.projected_parent(extra)==home.get_node("UI/Column") and extra.get_node("View/Action").layout_size.y>0,"native scene child addition schedules projection after owner assignment")
	var extra_y: float = extra.position.y
	home.move_child(extra,0)
	await frames()
	check(extra.position.y<settings.position.y and extra.position.y<extra_y,"native child order reorders logical slots without moving physical parents")
	var stray := Node2D.new()
	home.add_child(stray)
	await frames()
	check(Hosts.projected_parent(stray)==null and stray.owner==null,"mixed unowned runtime child remains outside projection")
	home.remove_child(extra)
	extra.free()
	await frames()
	check(Hosts.get("projections").size()==2 and home.get_node("UI/Column").get_child_count()==2,"native deletion releases borrowed record without damaging GGX tree")
	sprite.position = Vector2(390,210)
	home.tick += 1
	await frames()
	check(sprite.position==Vector2(390,210),"native nonparticipant property edits remain authoritative")
	var packed := PackedScene.new()
	check(packed.pack(home)==OK and packed.get_state().get_node_count()==3,"PackedScene retains authored nodes and excludes transient output")
	check(ResourceSaver.save(packed,"res://Reload.tscn")==OK,"active projected scene saves")
	home.free()
	await frames()
	check(State.get("records").is_empty() and Hosts.get("projections").is_empty() and Hosts.get("orders").is_empty() and Hosts.get("hosts").is_empty() and State.get("managed").is_empty(),"native free clears weak composition/projection/layout ownership records")
	var saved: PackedScene = load("res://Reload.tscn")
	home = saved.instantiate()
	root.add_child(home)
	await frames()
	settings = home.get_node("Settings")
	action = settings.get_node("View/Action")
	check(home.get_child_count()==3 and settings.owner==home and action.layout_size.y>0 and action.get_layout_root()==home.get_node("UI"),"save/reload remounts once with the same authored scene structure")
	var before_runs: int = State.get("records")[home.get_instance_id()].runs
	var before_flush: int = home.get_node("UI").layout.flush_count
	await frames()
	check(State.get("records")[home.get_instance_id()].runs==before_runs and home.get_node("UI").layout.flush_count==before_flush,"idle has no composition/layout polling")
	await edges(home)
	await frames()
	await empty_host()
	await independent_entry()
	await spatial()
	print("E08_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("E08_RUNTIME_OK")
	quit(1 if failed else 0)
func spatial() -> void:
	var home = load("res://app/generated/Spatial.gd").new()
	home.position = Vector3(10,20,30)
	var child = preload("res://addons/estragon/runtime/node/component_3d.gd").new()
	child.set_extent(Vector3(5,6,7))
	child.position = Vector3(90,100,110)
	home.add_child(child)
	child.owner = home
	root.add_child(home)
	await frames()
	check(child.position==Vector3(7,4,5) and child.layout_size==Vector3(5,6,7) and child.owner==home and child.get_parent()==home,"3D borrowed participant converts logical slot to unchanged native parent coordinates")
	home.tick += 1
	await frames()
	check(home.get_child_count()==2 and child.get_layout_root()==home.get_node("UI"),"3D later composition excludes framework root")
	home.free()
	await frames()
func edges(home: Node2D) -> void:
	var settings = home.get_node("Settings")
	var action = settings.get_node("View/Action")
	home.position = Vector2(40,30)
	home.rotation = 0.2
	home.scale = Vector2(1.1,1.1)
	settings.rotation = 0.1
	settings.scale = Vector2(1.2,1.2)
	home.tick += 1
	await frames()
	var column = home.get_node("UI/Column")
	var local: Vector3 = State.get("records")[settings.get_instance_id()].layout_host.layout.model.offset
	check(settings.global_position.is_equal_approx(column.to_global(Vector2(local.x,local.y))) and is_equal_approx(settings.rotation,0.1) and settings.scale==Vector2(1.2,1.2),"transformed native parent maps logical translation once and retains rotation/scale")
	var before: Vector2 = settings.global_position
	home.get_node("UI").position += Vector2(20,30)
	column.gap = 9
	await frames()
	check(not settings.global_position.is_equal_approx(before) and settings.global_position.is_equal_approx(column.to_global(Vector2(local.x,local.y+1))),"eventful ancestor arrange refreshes borrowed translation even when physical parent does not move")
	# Native participant reorder must work even without a Gogo moved callback.
	var first = preload("res://addons/estragon/runtime/node/component_2d.gd").new()
	var second = preload("res://addons/estragon/runtime/node/component_2d.gd").new()
	first.set_extent(Vector2(10,10))
	second.set_extent(Vector2(10,10))
	home.add_child(first)
	first.owner = home
	home.add_child(second)
	second.owner = home
	await frames()
	home.move_child(second,0)
	await frames()
	check(second.position.y<first.position.y,"native participant reorder observes host child-order notification on both engines")
	first.free()
	second.free()
	await frames()
	# Nested authored scenes preserve their separate ownership chain.
	var nested = load("res://app/generated/Nested.gd").new()
	nested.name = "Nested"
	var inner = load("res://app/generated/Settings.gd").new()
	inner.name = "Inner"
	nested.add_child(inner)
	inner.owner = nested
	var scene := PackedScene.new()
	scene.pack(nested)
	nested.free()
	nested = scene.instantiate()
	home.add_child(nested)
	nested.owner = home
	await frames()
	inner = nested.get_node("Inner")
	check(inner.owner==nested and nested.owner==home and inner.get_node("View/Action").layout_size.y>0 and inner.get_node("View/Action").get_layout_root()==home.get_node("UI"),"nested host/scene ownership and logical layout/input scopes remain distinct and continuous")
	var adapter = preload("res://addons/estragon/runtime/node/native_2d.gd").new()
	adapter.name = "Adapter"
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-2,-1),Vector2(2,-1),Vector2(2,1),Vector2(-2,1)])
	adapter.add_child(visual)
	home.add_child(adapter)
	adapter.owner = home
	visual.owner = home
	await frames()
	var offset: Vector3 = adapter.layout.model.offset
	var origin: Vector2 = Vector2(adapter.bounds.origin.x,adapter.bounds.origin.y)
	check(adapter.get_native_bounds_status()==OK and adapter.layout_size==Vector2(4,2) and (adapter.position+origin).is_equal_approx(home.to_local(column.to_global(Vector2(offset.x,offset.y)))) and visual.position==Vector2.ZERO,"explicit native adapter measures geometry and normalizes origin at the borrowed logical slot")
	# Reparent through native APIs; former owner must not later free/adopt it.
	var other := Build.scene()
	other.name = "OtherHome"
	root.add_child(other)
	await frames()
	var retained: int = settings.get_instance_id()
	home.remove_child(settings)
	other.add_child(settings)
	settings.owner = other
	await frames()
	check(settings.get_instance_id()==retained and settings.owner==other and Hosts.projected_parent(settings)==other.get_node("UI/Column") and action.get_layout_root()==other.get_node("UI"),"native reparent transfers borrowing to the new host without a stale logical edge")
	home.free() # Caller owns a fresh replacement below; test old-owner teardown.
	await frames()
	check(is_instance_valid(settings) and settings.get_parent()==other and action.layout_size.y>0,"old host disposal cannot delete a reparented authored child")
	other.free()
	await frames()
func negatives() -> void:
	var home := Build.scene()
	root.add_child(home)
	await frames()
	var settings = home.get_node("Settings")
	var action = settings.get_node("View/Action")
	var view = home.get_node("UI")
	var position: Vector2 = settings.position
	var record = State.get("records")[home.get_instance_id()]
	var runs: int = record.runs
	home.repeat_children = true
	await frames()
	check(record.runs==runs and home.get_node("UI")==view and settings.position==position and settings.owner==home and settings.get_node("View/Action")==action,"duplicate projections reject atomically before mutating previous native tree")
	home.repeat_children = false
	home.tick += 1
	await frames()
	check(record.runs==runs+1 and settings.get_node("View/Action")==action,"repair recovers existing projection")
	var foreign := Node2D.new()
	root.add_child(foreign)
	foreign.owner = root
	var Element = preload("res://addons/estragon/runtime/composition/element.gd")
	check(record._normalize(Element.new("Node2D",{}, {},[foreign],"negative.gogo:1:1"))==null and foreign.get_parent()==root,"external native reference is rejected without parent/owner mutation")
	foreign.free()
	var detached := Node2D.new()
	detached.name = "Detached"
	check(record._normalize(Element.new("Node2D",{}, {},[detached],"detached.gogo:1:1"))==null and detached.get_parent()==null,"detached reference rejects cleanly without asking Godot for an invalid tree path")
	detached.free()
	home.free()
	await frames()
	print("E08_NEGATIVE_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("E08_NEGATIVE_OK")
	quit(1 if failed else 0)
func empty_host() -> void:
	var home = load("res://app/generated/Home.gd").new()
	root.add_child(home)
	await frames()
	var child = load("res://app/generated/Settings.gd").new()
	child.name = "Settings"
	home.add_child(child)
	child.owner = home
	await frames()
	check(child.get_node("View/Action").layout_size.y>0 and home.get_child_count()==2,"an initially empty native child expression observes later scene addition without polling")
	var held_id: int = child.get_instance_id()
	root.remove_child(home)
	await frames()
	check(Hosts.projected_parent(child)==null and child.get_parent()==home,"native detach releases logical projection without changing scene ancestry")
	root.add_child(home)
	await frames()
	check(child.get_instance_id()==held_id and child.get_node("View/Action").get_layout_root()==home.get_node("UI"),"native reentry restores logical placement/input on the same instances")
	home.free()
	await frames()
func independent_entry() -> void:
	var home := Build.scene()
	var entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	entry.position = Vector2(300,200)
	entry.set_extent(Vector2(50,50))
	home.add_child(entry)
	entry.owner = home
	root.add_child(home)
	await frames()
	check(entry.position==Vector2(300,200) and entry.get_layout_root()==entry,"a borrowed explicit Entry remains independently positioned and scoped")
	entry.position = Vector2(310,210)
	home.show_children = false
	await frames()
	check(entry.position==Vector2(310,210),"release does not restore or seize independent Entry translation")
	home.free()
	await frames()
