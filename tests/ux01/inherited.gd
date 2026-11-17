extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Action = preload("res://addons/estragon/runtime/node/button.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var hits := 0
func hit(): hits += 1
func check(ok: bool,label: String):
	print("U02_CHECK ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func mouse(point: Vector2, button: int = MOUSE_BUTTON_LEFT):
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = button
	event.pressed = true
	root.push_input(event,true)
	if button==MOUSE_BUTTON_LEFT:
		event = event.duplicate()
		event.pressed = false
		root.push_input(event,true)
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var entry := Entry.new()
	entry.width = 640
	entry.height = 480
	var normal := VBox.new()
	normal.width = 300
	var action := Action.new()
	action.width = 500
	action.height = 80
	action.background_color = "#00ff00"
	action.hover_background_color = "#00ff00"
	action.pressed.connect(hit)
	normal.add_child(action)
	entry.add_child(normal)
	root.add_child(entry)
	await frames()
	mouse(Vector2(450,30))
	await RenderingServer.frame_post_draw
	check(hits==1 and root.get_texture().get_image().get_pixel(450,30).g>0.9 and normal._scroll==null and normal.get_child_count(true)==1,"never-enabled normal overflow paints/hits without private helpers")
	var outer := VBox.new()
	outer.width = 300
	outer.height = 300
	outer.vertical_scroll = true
	var inner := VBox.new()
	inner.width = 300
	inner.height = 200
	inner.vertical_scroll = true
	var deep := Action.new()
	deep.height = 900
	inner.add_child(deep)
	outer.add_child(inner)
	entry.add_child(outer)
	await frames()
	check(outer.scroll_range==Vector2.ZERO and inner.scroll_range.y==700,"ancestor extent excludes a nested viewport's clipped hidden content")
	var bounded := preload("res://addons/estragon/runtime/node/native_2d.gd").new()
	bounded.width = 100
	bounded.height = 100
	bounded.vertical_scroll = true
	bounded.observe_native = true
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2.ZERO,Vector2(50,0),Vector2(50,80)])
	bounded.add_child(polygon)
	entry.add_child(bounded)
	await frames()
	check(bounded.get_native_bounds_status()==OK and bounded.get_native_bounds().size==Vector2(50,80),"bounded native geometry survives private clipping ancestry")
	polygon.polygon = PackedVector2Array([Vector2.ZERO,Vector2(60,0),Vector2(60,90)])
	polygon.item_rect_changed.emit() # Explicit native adapter notification, as in C1.
	await frames()
	check(bounded.get_native_bounds().size==Vector2(60,90),"bounded native change subscription remains live")
	entry.free()
	await frames()
	await transformed_input()
	var host = load("res://app/generated/InheritedScrolling.gd").new()
	root.add_child(host)
	await frames()
	var ui = host.get_node("UI")
	var direct = ui.get_layout_child("Direct")
	var horizontal = ui.get_layout_child("Horizontal")
	var grid = ui.get_layout_child("Cards")
	var areas = ui.get_layout_child("Areas")
	var wrapped = ui.get_layout_child("Wrapped")
	var native = ui.get_layout_child("EntryNative")
	var custom = ui.get_layout_child("EntryCustom")
	var ids: Array = []
	for child in direct.get_layout_children(): ids.append(child.get_instance_id())
	var native_id: int = native.get_instance_id()
	var card_id: int = grid.get_layout_child("Card0").get_instance_id()
	var passes: int = State.records[host.get_instance_id()].runs
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800)]:
		root.size = size
		await frames()
		check(direct.get_layout_children().size()==8 and direct.content_extent.y==900 and direct.scroll_range.y==600 and direct.layout.model.strategy=="stack","eight direct Text900/300/600 at "+str(size))
		check(is_equal_approx(horizontal.content_extent.x,624) and is_equal_approx(horizontal.scroll_range.x,624-horizontal.get_content_rect().size.x) and horizontal.layout.model.axis==0,"HBox transpose retains gaps and policy")
		check(grid.layout.model.strategy=="grid" and grid.scroll_range.y>1000 and grid.get_layout_child("Card0").layout_size.y==400 and grid.get_layout_child("Card1").position.x>0,"Grid tall direct cells retain span/track placement")
		check(areas.scroll_range.y==210 and areas.get_layout_child("Left").position.y==130 and areas.get_layout_child("Right").position.x==80,"Grid named areas/rows remain independent of scrolling")
		var tags = wrapped.get_layout_child("Tags")
		check(wrapped.layout_size.y==380 and tags.layout_size.x<=wrapped.get_content_rect().size.x and wrapped.scroll_range.y>400,"max/padding/border viewport retains nested Wrap")
		check(native.get_instance_id()==native_id and grid.get_layout_child("Card0").get_instance_id()==card_id and State.records[host.get_instance_id()].runs==passes,"resize retains identity and no recomposition")
		ui.scroll_offset = Vector2.ZERO
		await frames()
		mouse(native.get_global_transform_with_canvas()*Vector2(30,30))
		await frames()
		check(native.has_focus(),"scrolling Entry preserves native focus")
		ui.scroll_offset = Vector2(0,custom.position.y-20)
		await frames()
		mouse(custom.get_global_transform_with_canvas()*Vector2(30,30))
		await frames()
		ui.scroll_offset = Vector2(0,direct.position.y-20)
		await frames()
		var point: Vector2 = direct.get_global_transform_with_canvas()*Vector2(40,40)
		direct.scroll_offset = Vector2.ZERO
		mouse(point,MOUSE_BUTTON_WHEEL_DOWN)
		await frames()
		check(direct.scroll_offset.y==40,"deepest opted-in VBox receives wheel within transformed ancestry")
		var stats := [direct.get_layout_stats(),grid.get_layout_stats()]
		direct.scroll_offset = Vector2(0,300)
		await frames()
		check(stats==[direct.get_layout_stats(),grid.get_layout_stats()],"scroll only transforms; unrelated Grid stays quiet")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://u02-direct-"+str(size.x)+".png")
	check(host.clicks==6,"Entry custom/native clicks exactly once at all three sizes")
	host.enabled = false
	await frames()
	check(direct.scroll_offset==Vector2.ZERO and direct.scroll_range==Vector2.ZERO and not direct._scroll._clip.clip_contents,"flags off restores unclipped overflow and zero offset")
	host.enabled = true
	await frames()
	var after: Array = []
	for child in direct.get_layout_children(): after.append(child.get_instance_id())
	check(ids==after and direct.scroll_range.y==600,"flags on retains all direct nodes/order and range")
	host.props = {"horizontal_scroll":true}
	await frames()
	host.props = {}
	await frames()
	check(not direct.horizontal_scroll and direct.vertical_scroll,"spread removal restores inherited axis default")
	host.order = [8,7,0]
	await frames()
	check(grid.get_layout_children().size()==3 and grid.get_layout_child("Card0").get_instance_id()==card_id and grid.scroll_range.y<1000,"keyed Grid shrink/reorder retains identity and clamps")
	var foreign := Node2D.new()
	foreign.name = "ForeignActor"
	grid.get_layout_child("Card8").add_child(foreign)
	foreign.owner = host
	host.order = [7,0]
	await frames()
	check(is_instance_valid(foreign) and foreign.get_parent()==host and foreign.owner==host,"removing a clipped keyed branch rescues foreign native actors and owner")
	host.font_size = 40
	await frames()
	check(direct.get_layout_child("T0").font_size==40 and direct.get_layout_child("T0").get_instance_id()==ids[0],"direct Text font updates through normal retained layout")
	var idle := [ui.get_layout_stats(),direct.get_layout_stats(),grid.get_layout_stats()]
	await frames()
	check(idle==[ui.get_layout_stats(),direct.get_layout_stats(),grid.get_layout_stats()],"settled inherited layout idle quiet")
	host.free()
	await frames()
	check(State.records.is_empty(),"all inherited view records/subscriptions released")
	if not failed: print("U02_INHERITED_OK")
	quit(1 if failed else 0)

func press(point: Vector2, down: bool):
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event,true)
func transformed_input():
	var entry := Entry.new()
	entry.width = 300
	entry.height = 180
	entry.padding = 10
	entry.border_width = 2
	entry.position = Vector2(100,80)
	entry.scale = Vector2(1.2,1.25)
	entry.horizontal_scroll = true
	entry.vertical_scroll = true
	var native := Button.new()
	native.text = "Native capture and focus"
	native.custom_minimum_size = Vector2(900,900)
	native.pressed.connect(hit)
	entry.add_child(native)
	native.owner = entry
	root.add_child(entry)
	await frames()
	var before := hits
	var inside: Vector2 = entry.get_global_transform_with_canvas()*Vector2(30,30)
	press(inside,true)
	press(entry.get_global_transform_with_canvas()*Vector2(30,240),false)
	await frames()
	check(hits==before,"scaled Entry excludes captured native release outside content clip")
	mouse(inside)
	await frames()
	check(hits==before+1 and native.has_focus(),"scaled Entry native click/focus exactly once")
	mouse(inside,MOUSE_BUTTON_WHEEL_DOWN)
	await frames()
	var wheel := InputEventMouseButton.new()
	wheel.position = inside
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.shift_pressed = true
	wheel.pressed = true
	root.push_input(wheel,true)
	await frames()
	check(entry.scroll_offset==Vector2(40,40),"scaled logical wheel/Shift deltas and insets once")
	var pan := InputEventPanGesture.new()
	pan.position = inside
	pan.delta = Vector2(1,1)
	root.push_input(pan,true)
	await frames()
	check(entry.scroll_offset==Vector2(80,80),"scaled native pan both axes")
	entry.scroll_offset = Vector2.ZERO
	await frames()
	var bar: VScrollBar = entry._scroll._vertical
	var first: Vector2 = bar.get_global_transform_with_canvas()*Vector2(6,12)
	var last: Vector2 = bar.get_global_transform_with_canvas()*Vector2(6,bar.size.y-20)
	press(first,true)
	var motion := InputEventMouseMotion.new()
	motion.position = last
	motion.relative = last-first
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true)
	press(last,false)
	await frames()
	check(entry.scroll_offset.y>0 and hits==before+1,"actual scaled scrollbar drag never activates underlying Control")
	var offset: Vector2 = entry.scroll_offset
	var identity := native.get_instance_id()
	root.remove_child(entry)
	await frames()
	root.add_child(entry)
	await frames()
	check(native.get_instance_id()==identity and native.owner==entry and entry.scroll_offset==offset,"Entry re-entry retains direct child/owner/offset")
	native.grab_focus()
	var subscriptions: int = native.get_signal_connection_list("gui_input").size()
	entry.horizontal_scroll = false
	entry.vertical_scroll = false
	await frames()
	check(entry.scroll_offset==Vector2.ZERO and entry.scroll_range==Vector2.ZERO and native.has_focus() and entry._scroll._input_guard.watched.is_empty(),"both flags off preserves native focus and removes guard subscriptions")
	entry.horizontal_scroll = true
	entry.vertical_scroll = true
	await frames()
	check(native.get_signal_connection_list("gui_input").size()==subscriptions and native.get_instance_id()==identity and native.has_focus(),"flags on restores one guard without reparent/focus loss")
	entry.scroll_offset = Vector2(100,200)
	var packed := PackedScene.new()
	check(packed.pack(entry)==OK and ResourceSaver.save(packed,"res://u02-entry.tscn")==OK,"persistent direct content packs private ancestry")
	entry.free()
	await frames()
	var restored = load("res://u02-entry.tscn").instantiate()
	root.add_child(restored)
	await frames()
	check(restored.get_layout_children().size()==1 and restored.scroll_offset==Vector2(100,200),"native pack/reload restores inherited axes/offset and direct children")
	restored.free()
	await frames()
