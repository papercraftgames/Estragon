extends SceneTree
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const NativeFields = preload("res://tests/spreads/native_fields.gd")
var checks := 0
var failed := false
var edits: Array = []
class Host extends Node:
	var desired
	func build_view(): return desired
	func _notification(what: int) -> void:
		preload("res://addons/estragon/runtime/composition/state.tres").lifecycle(self,what)
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S03_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(8): await process_frame
func click(button: Node, fraction := Vector2(0.5,0.5)) -> void:
	var extent: Vector2 = button.size if button is Control else button.layout_size
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(extent*fraction)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func edited(value: bool) -> void: edits.append(value)
func spread(type, values, explicit: Dictionary = {}) -> Element:
	var result := Element.new(type)
	var ordered: Array = [[null,values,"native-spread.gogo:9:12"]]
	for key in explicit: ordered.append([key,explicit[key],"native-spread.gogo:9:30"])
	result.expand(ordered)
	return result
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(640,480)
	var host = load("res://app/generated/SpreadGallery.gd").new()
	root.add_child(host)
	await frames()
	var panel = host.get_node("UI/Panel")
	var button = panel.get_node("Continue")
	var toggle = panel.get_node("Enabled")
	var native = panel.get_node("Native")
	var nested = panel.get_node("Nested")
	var caption = panel.get_node("Caption")
	var ids = host.find_children("*","",true,false).map(func(n): return [n.get_instance_id(),n.get_parent().get_instance_id(),n.owner])
	var record = State.records[host.get_instance_id()]
	check(panel.padding=="16px" and panel.background_color=="#252b38" and button.background_color=="#70599b","multiple spreads and explicit-before/after last wins")
	check(nested.caption=="Nested spread, retained native nodes" and nested.get_node("Body").background_color=="#30394d","project Gogo tag property metadata and nested spread composition")
	toggle.value_changed.connect(edited)
	for extent in [Vector2i(640,480),Vector2i(1000,800)]:
		root.size = extent
		await frames()
		check(host.get_node("UI").layout_size==Vector2(extent) and panel.layout_size.x==extent.x-24 and button.layout_size.x==panel.get_content_rect().size.x/2 and button.layout_size.y==36,"responsive spread/native border-box geometry "+str(extent))
		check(ids==host.find_children("*","",true,false).map(func(n): return [n.get_instance_id(),n.get_parent().get_instance_id(),n.owner]),"native identities/parents/owners retained across viewport resize")
		click(button,Vector2(0.995,0.5))
		click(native)
		click(toggle)
		await frames()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://spreads-"+str(extent.x)+".png")
		check(image.get_pixelv(Vector2i(panel.global_position+Vector2(1,8))).is_equal_approx(Color("#8295bc")),"real native border pixel at resized outer allocation")
	check(host.clicks==2 and host.native_clicks==2 and edits==[true,false],"whole outer hit area, native Control and controlled Toggle exactly once")
	var runs: int = record.runs
	host.action["disabled"] = true
	await frames()
	check(record.runs==runs and not button.disabled,"raw in-place Dictionary mutation has no implicit observer")
	var next: Dictionary = host.action.duplicate()
	next["min_width"] = "700px"
	host.action = next
	await frames()
	check(record.runs==runs+1 and button==panel.get_node("Continue") and button.disabled and button.layout_size.x==700,"bindable Dictionary reference swap recomposes once, retained constrained input")
	click(button)
	await frames()
	check(host.clicks==2,"spread disabled blocks pointer input")
	var counts = [button.get_layout_stats(),panel.get_layout_stats(),caption.get_layout_stats(),button.lengths.parse_count]
	var draw: int = button.get_visual_style_stats().draw
	next = host.action.duplicate()
	next.background_color = "#355e92"
	host.action = next
	await frames()
	check(counts==[button.get_layout_stats(),panel.get_layout_stats(),caption.get_layout_stats(),button.lengths.parse_count] and button.get_visual_style_stats().draw>draw,"spread color update repaints without length parse/layout or unrelated leaf measurement")
	next = host.action.duplicate()
	for key in ["disabled","min_width","min_height","background_color"]: next.erase(key)
	host.action = next
	await frames()
	check(not button.disabled and button.min_width==0 and button.min_height==0 and button.background_color=="#477dbb","removed spread state/minima reset while remaining explicit background remains effective")
	host.alternate = true
	await frames()
	click(button)
	await frames()
	check(host.clicks==2 and host.alternate_clicks==1 and button.get_signal_connection_list("pressed").size()==1,"signal Callable retarget disconnects old handler and connects exactly once")
	host.show_extra = false
	await frames()
	check(not panel.has_node("Extra") and button==panel.get_node("Continue") and nested==panel.get_node("Nested"),"explicit conditional/key and controlled binding coexist with spreads")
	counts = [record.runs,record.writes,button.get_layout_stats(),panel.get_layout_stats(),button.get_visual_style_stats(),button.lengths.parse_count]
	host.action = host.action
	await frames()
	check(counts==[record.runs,record.writes,button.get_layout_stats(),panel.get_layout_stats(),button.get_visual_style_stats(),button.lengths.parse_count],"equal reference writes and idle frames have zero polling/repaint/reflow/reparse/recomposition")
	print("S03_COUNTERS ",JSON.stringify(counts))
	host.free()
	await frames()
	await removals()
	check(State.records.is_empty() and State.managed.is_empty(),"native disposal removes all records and managed indices")
	print("S03_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S03_RUNTIME_OK")
	quit(1 if failed else 0)
func region(child: Element) -> Element:
	return Element.new(Entry,{"width":400,"height":300},{},[child])
func removals() -> void:
	var host := Host.new()
	host.desired = region(spread(UiButton,{"padding":"20px","disabled":true,"background_color":"#ff0000","text":"Owned"},{"name":"Retained"}))
	root.add_child(host)
	await frames()
	var node = host.get_child(0).get_child(0)
	var record = State.records[host.get_instance_id()]
	host.desired = region(spread(UiButton,{}, {"name":"Retained"}))
	record.schedule()
	await frames()
	check(node==host.get_child(0).get_child(0) and node.padding=="auto" and not node.disabled and node.text=="" and node.background_color==Color("#383838") and node.get_content_rect().position==Vector2(14,8) and node.layout_size.x==28,"spread omission restores actual Button defaults including local padding")
	host.desired = region(spread(UiButton,{"disabled":true},{"name":"Retained"}))
	record.schedule()
	await frames()
	node.disabled = false
	host.desired = region(spread(UiButton,{}, {"name":"Retained"}))
	record.schedule()
	await frames()
	check(not node.disabled,"removal does not clobber independent native change since last spread commit")
	host.desired = region(spread(UiButton,{"background_color":"#ff0000"}, {"name":"Retained"}))
	record.schedule()
	await frames()
	node.background_color = Color.BLUE
	host.desired = region(spread(UiButton,{}, {"name":"Retained"}))
	record.schedule()
	await frames()
	check(node.background_color==Color.BLUE,"removal preserves a different independent native color instead of restoring the default")
	host.desired = region(spread(Rect,{"background_color":"#ff0000"}))
	record.schedule()
	await frames()
	node = host.get_child(0).get_child(0)
	host.desired = region(spread(Rect,{}))
	record.schedule()
	await frames()
	check(node==host.get_child(0).get_child(0) and node.background_color==Color.WHITE and node.fill==Color.WHITE,"Rect canonical white _init default restored without alias conflict")
	host.desired = region(spread(NativeFields,{"caption":"Owned","visible":false,"edited":edited}))
	record.schedule()
	await frames()
	node = host.get_child(0).get_child(0)
	check(node.caption=="Owned" and not node.visible and node.is_connected("edited",edited),"script/native property and signal metadata accept normal spread values")
	host.desired = region(spread(NativeFields,{}))
	record.schedule()
	await frames()
	check(node==host.get_child(0).get_child(0) and node.caption=="initialized" and node.visible and not node.is_connected("edited",edited),"native script _init defaults and signal removal restore without probe/helper Nodes")
	host.desired = region(spread(VBox,{"padding":"20px","gap":"12px","border_width":"2px","border_left_width":"8px","min_width":"100px","horizontal_align":"center"}))
	record.schedule()
	await frames()
	node = host.get_child(0).get_child(0)
	host.desired = region(spread(VBox,{}))
	record.schedule()
	await frames()
	check(node==host.get_child(0).get_child(0) and node.padding==0 and node.gap==0 and node.border_width==0 and node.border_left_width=="auto" and node.min_width==0 and node.horizontal_align=="start" and node.get_content_rect().position==Vector2.ZERO,"Box defaults and established border-side/minimum omission rules compose atomically")
	host.desired = region(spread("Node2D",{"name":"Owned"}))
	record.schedule()
	await frames()
	node = host.get_child(0).get_child(0)
	host.desired = region(spread("Node2D",{}))
	record.schedule()
	await frames()
	check(node==host.get_child(0).get_child(0) and node.name==&"Node2D","spread-only name removal uses legitimate native class name instead of invalid empty set_name")
	var timer := Element.new("Timer")
	timer.expand([[null,{"timeout":edited.bind(true)},"signal.gogo:4:5"]])
	var before: int = edits.size()
	host.desired = region(timer)
	record.schedule()
	await frames()
	host.get_child(0).get_child(0).timeout.emit()
	check(timer.attribute_error.is_empty() and edits.size()==before+1 and edits.back()==true,"custom bound Callable connects and invokes natively without unsupported introspection")
	host.desired = region(spread(VBox,{"horizontal_align":"stretch","width":200,"height":100}))
	record.schedule()
	await frames()
	check(host.get_child(0).get_child(0).horizontal_align=="stretch","valid final cross-axis policy commits through the existing atomic policy hook")
	host.free()
	await frames()
