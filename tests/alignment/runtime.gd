extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Spatial = preload("res://addons/estragon/runtime/node/component_3d.gd")
var checks := 0
var failed := false
var edits: Array = []
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L08_RUNTIME_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(8): await process_frame
func edited(_previous: bool, value: bool) -> void: edits.append(value)
func click(button: Node) -> void:
	var extent: Vector2 = button.size if button is Control else button.layout_size
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(extent*Vector2(0.99,0.5))
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var entry := Entry.new()
	entry.width = 400
	entry.height = 200
	var box := Box.new()
	box.width = 340
	box.height = 120
	box.padding = 10
	box.border_width = 10
	box.gap = 10
	box.horizontal_align = "space-between"
	box.vertical_align = "center"
	var a := Rect.new()
	a.width = 40
	a.height = 30
	a.margin_left = 3
	a.margin_right = 7
	a.margin_top = 2
	a.margin_bottom = 4
	a.x = 5
	a.y = 7
	var b := Rect.new()
	b.width = 60
	b.height = 40
	box.add_child(a)
	box.add_child(b)
	entry.add_child(box)
	root.add_child(entry)
	await frames()
	check(box.get_content_rect()==Rect2(20,20,300,80) and a.position==Vector2(28,51) and b.position==Vector2(260,40),"border/padding/margins/uneven extents/gap and additive x/y once after slots")
	box.center = true
	await frames()
	check(a.position.x==118 and b.position.x==170,"legacy center=true overrides main space-between without changing cross alignment")
	box.center = false
	a.width = "50%"
	a.align_self = "stretch"
	a.height = "auto"
	await frames()
	check(a.layout_size==Vector2(150,74),"auto cross stretch includes margins and preserves explicit percentage main width")
	a.height = "50%"
	await frames()
	check(a.layout_size==Vector2(150,40),"explicit percentage cross axis is never stretched")
	a.height = "auto"
	a.min_height = 100
	await frames()
	check(a.layout_size.y==100 and a.position.y==29,"cross floor overflows deterministically with leading margin/additive offset")
	a.min_height = 0
	a.stretch = 1
	for own in ["start","center","end","auto"]:
		a.align_self = own
		await frames()
		check(a.layout_size.y==(74 if own=="auto" else 0),"explicit self override beats old stretch, auto restores it "+own)
	var descendant := Rect.new()
	descendant.width = "100%"
	descendant.height = "100%"
	a.add_child(descendant)
	a.align_self = "stretch"
	await frames()
	check(descendant.layout_size==a.layout_size,"self stretch supplies existing definite percentage authority to descendants")
	a.align_self = "start"
	await frames()
	check(a.layout_size.y==0 and descendant.layout_size.y==0,"explicit self start removes old stretch percentage authority without churn")
	entry.free()
	await frames()
	var minimum_entry := Entry.new()
	minimum_entry.width = 100
	minimum_entry.height = 50
	minimum_entry.gap = 10
	minimum_entry.horizontal_align = "space-between"
	var native_first := Button.new()
	var native_second := Button.new()
	native_first.custom_minimum_size = Vector2(70,20)
	native_second.custom_minimum_size = Vector2(20,20)
	native_first.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	native_second.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimum_entry.add_child(native_first)
	minimum_entry.add_child(native_second)
	root.add_child(minimum_entry)
	for extent in [100,120,80]:
		minimum_entry.width = extent
		await frames()
		check(native_first.size.x==70 and native_second.size.x==(40 if extent==120 else 20) and native_second.position.x==80,"native Control floor/growth precedes distribution even under overflow width"+str(extent))
	minimum_entry.free()
	await frames()
	var control := Button.new()
	check(not "align_self" in control,"ordinary native Control receives no align_self API")
	control.free()
	var spatial := Spatial.new()
	check(not "align_self" in spatial,"3D public component API remains unchanged")
	spatial.free()
	var host = load("res://app/generated/AlignmentGallery.gd").new()
	var borrowed := Button.new()
	borrowed.name = "Borrowed"
	borrowed.text = "Borrowed native Control"
	host.add_child(borrowed)
	borrowed.owner = host
	root.add_child(host)
	await frames()
	var ui = host.get_node("UI")
	var content = ui.get_node("Content")
	var header = content.get_node("Header")
	var even = content.get_node("Even")
	var row = content.get_node("Configurable")
	var button = row.get_node("Action")
	var toggle = row.get_node("Enabled")
	var native = row.get_node("Native")
	var nested = content.get_node("Nested")
	var body = nested.get_node("Body")
	var tile_ids := {}
	for key in ["a","b","c"]: tile_ids[key] = even.get_node(key).get_instance_id()
	var record = State.records[host.get_instance_id()]
	var ids = [button.get_instance_id(),toggle.get_instance_id(),native.get_instance_id(),body.get_instance_id(),borrowed.get_instance_id(),borrowed.owner]
	toggle.value_changed.connect(edited)
	for extent in [Vector2i(640,480),Vector2i(1000,800)]:
		root.size = extent
		await frames()
		var width: float = even.layout_size.x
		check(ui.layout_size==Vector2(extent) and width==extent.x-24 and even.get_node("a").position.x==(width-120)/4 and even.get_node("b").position.x==(width-120)/2+40 and even.get_node("c").position.x==3*(width-120)/4+80,"real HBox evenly positions at "+str(extent))
		check(even.get_node("a").position.y==33 and even.get_node("b").position.y==66,"align_self=end overrides parent center on cross axis only")
		check(body.global_position.x==content.global_position.x+(content.layout_size.x-body.layout_size.x) and body.layout_size.x==content.layout_size.x/2,"nested Gogo root forwards explicit self/end and percentage width through transparent host")
		for target in [header.get_node("Close"),button,toggle,native]: click(target)
		await frames()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://alignment-"+str(extent.x)+".png")
		check(image.get_pixelv(Vector2i(header.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc")),"native rendered header border remains in border-box")
	check(host.clicks==4 and host.native_clicks==2 and edits==[true,false],"distributed full outer hit targets/native Control/controlled Toggle exactly once")
	host.child_props = {"align_self":"end","min_width":"10vw","min_height":"10vh"}
	for extent in [Vector2i(640,480),Vector2i(1000,800)]:
		root.size = extent
		await frames()
		check(even.get_node("b").layout_size==Vector2(extent.x*0.1,extent.y*0.1) and even.get_node("b").position.y==96-extent.y*0.1,"responsive minima update self placement with retained slots "+str(extent))
	host.order = ["c","a","b"]
	host.show_extra = false
	await frames()
	check(even.get_child(0).name==&"c" and even.get_child(1).name==&"a" and ["a","b","c"].all(func(key): return even.get_node(key).get_instance_id()==tile_ids[key]) and not content.has_node("Extra"),"keyed reorder and conditional removal use retained native output")
	check(ids==[button.get_instance_id(),toggle.get_instance_id(),native.get_instance_id(),body.get_instance_id(),borrowed.get_instance_id(),borrowed.owner] and borrowed.get_parent()==host,"identity/owners/borrowed boundary and subscriptions persist")
	host.child_props = {}
	await frames()
	check(even.get_node("b").align_self=="auto" and even.get_node("b").position.y==33,"omitted spread align_self clears to auto on retained child")
	var old_id: int = row.get_instance_id()
	host.policy = {"direction":"column","horizontal_align":"center","vertical_align":"space-between"}
	await frames()
	check(row.get_instance_id()==old_id and row.direction=="column" and row.vertical_align=="space-between" and button.position.x==(row.layout_size.x-16-button.layout_size.x)/2+8,"direction plus axis policies commit atomically on retained Box")
	host.policy = {"direction":"row","horizontal_align":"space-around","vertical_align":"end"}
	await frames()
	check(row.direction=="row" and button.position.y==row.layout_size.y-8-button.layout_size.y,"physical policies transpose back without replacing native nodes")
	var before_native: int = record.runs
	body.align_self = "start"
	await frames()
	check(body.global_position.x==content.global_position.x and record.runs==before_native,"native nested override invalidates parent placement without composition")
	var idle := [record.runs,record.writes,row.get_layout_stats(),even.get_layout_stats(),button.get_layout_stats(),button.get_visual_style_stats(),button.lengths.parse_count]
	host.policy = host.policy
	body.align_self = "start"
	await frames()
	check(idle==[record.runs,record.writes,row.get_layout_stats(),even.get_layout_stats(),button.get_layout_stats(),button.get_visual_style_stats(),button.lengths.parse_count],"equal native/reactive updates and idle frames have no reflow/repaint/reparse/recomposition")
	print("L08_COUNTERS ",JSON.stringify(idle))
	host.free()
	await frames()
	check(State.records.is_empty() and State.managed.is_empty(),"teardown cleans records/subscriptions and borrowed owner safely")
	print("L08_RUNTIME_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L08_RUNTIME_OK")
	quit(1 if failed else 0)
