extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failures := 0
var assertions := 0
func check(value: bool,label: String):
	assertions += 1
	print("EL02_RUNTIME ",label,": ",value)
	if not value: failures += 1
func frames():
	for i in range(10): await process_frame
func click(node):
	var event := InputEventMouseButton.new()
	event.position = node.get_global_transform_with_canvas()*Vector2(12,12)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var host = load("res://app/generated/Layouts.gd").new()
	root.add_child(host)
	await frames()
	var ui = host.get_node("UI")
	var app = ui.get_node("App")
	var header = app.get_node("Header")
	var side = app.get_node("Side")
	var body = app.get_node("Body")
	var footer = app.get_node("Footer")
	var action = body.get_node("Action")
	var toggle = body.get_node("Toggle")
	var shared = body.get_node("Imported/Shared")
	var ids := [app.get_instance_id(),header.get_instance_id(),side.get_instance_id(),action.get_instance_id(),shared.get_instance_id()]
	print("EL02_GEOMETRY ",app.layout_size," ",header.position," ",header.layout_size," ",side.position," ",side.layout_size," ",body.position," ",body.layout_size," ",footer.position," ",footer.layout_size)
	check(app.layout_size==Vector2(640,480),"root percent viewport extent")
	check(header.position==Vector2(12,12) and header.layout_size==Vector2(616,64),"Header spans two columns")
	check(side.position==Vector2(12,84) and side.layout_size==Vector2(160,384),"Side spans two rows")
	check(body.position==Vector2(180,84) and body.layout_size==Vector2(448,328) and footer.position==Vector2(180,420),"existing track/gap/padding geometry")
	check(side.get_node("Top").layout_size.x==144 and shared.get_node("Upper").layout_size.x>0,"nested original and exported Grid definitions arrange native children")
	check(host.original_side().placement.is_empty() and host.scoped_side().properties.gap=="2px","original and scoped definitions stay independent")
	check(action is Button and action.get_signal_connection_list("pressed").size()==1,"native Control preset retains type and signal")
	click(action)
	click(toggle)
	await frames()
	check(host.clicks==1 and host.selected,"native Control and controlled Toggle actual click targets")
	host.caption = "Recomposed defaults"
	host.tint = "#3c5269"
	await frames()
	check(header.title==host.caption and header.get_child(0).text==host.caption,"default getter reads drive native nested component reactivity")
	check(header.get_background_color()==Color(host.tint) and ids==[app.get_instance_id(),header.get_instance_id(),side.get_instance_id(),action.get_instance_id(),shared.get_instance_id()],"default updates preserve native identities")
	var previous_color: Color = header.get_background_color()
	print("EL02_EXPECTED_RUNTIME_REJECTION_BEGIN")
	host.caption = "Blocked while invalid"
	host.tint = "not-a-color"
	await frames()
	check(header.title=="Recomposed defaults" and header.get_background_color()==previous_color,"invalid default rejects the whole scheduled description without partial writes")
	print("EL02_EXPECTED_RUNTIME_REJECTION_END")
	host.tint = "#3c5269"
	host.caption = "Repaired defaults"
	await frames()
	check(header.title=="Repaired defaults" and header.get_instance_id()==ids[1],"signal-driven default repair retains native instance")
	var run_count: int = State.records[host.get_instance_id()].runs
	var stats: Dictionary = app.get_layout_stats()
	await frames()
	check(run_count==State.records[host.get_instance_id()].runs and stats==app.get_layout_stats(),"idle has no composition or layout work")
	host.side_mode = "column"
	await frames()
	check(side.direction=="column" and side.areas==["Top Top Top","BottomLeft BottomMiddle BottomRight"] and side.position==Vector2(12,84),"child mode changes its own arrangement, parent placement stays authoritative")
	host.side_mode = "grid"
	await frames()
	check(side.get_node("Top").layout_size.x==144,"child grid mode restores retained area topology")
	host.mode = "column"
	await frames()
	check(app.direction=="column" and app.areas==["Header Header","Side Body","Side Footer"] and app.columns==["160px","1fr"],"root mode disables but retains grid configuration")
	host.mode = "grid"
	await frames()
	check(body.position==Vector2(180,84) and side.layout_size==Vector2(160,384) and ids==[app.get_instance_id(),header.get_instance_id(),side.get_instance_id(),action.get_instance_id(),shared.get_instance_id()],"root grid geometry and identities restore")
	host.show_extra = false
	await frames()
	check(not body.has_node("Extra") and action.get_instance_id()==ids[3],"conditional sibling cleanup preserves native Control")
	host.show_extra = true
	host.options = {"height":"24px"}
	await frames()
	check(body.get_node("Extra").height=="24px","ordinary spread defaults remain reactive")
	check(footer.height=="24px","preset spread updates native default")
	host.options = {}
	await frames()
	check(footer.height=="auto" and footer.layout_size.y==48,"removed preset spread resets through existing native removal path")
	var label := Label.new()
	label.text = "Borrowed native Control"
	host.add_child(label)
	label.owner = host
	var borrowed_id := label.get_instance_id()
	host.borrowed = label
	await frames()
	check(label.get_parent()==host and preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres").projected_parent(label)==body and label.get_instance_id()==borrowed_id and label.owner==host and label.size.x>0,"borrowed scene Control uses existing adapter without a wrapper")
	host.borrowed = null
	await frames()
	check(is_instance_valid(label) and label.get_parent()==host and label.owner==host,"borrowed Control removal preserves native identity and owner")
	label.free()
	var packed := PackedScene.new()
	check(packed.pack(host)==OK,"authored host packs without transient preset instances")
	var restored = packed.instantiate()
	check(restored.get_child_count()==0,"pack reload starts with authored host only")
	restored.free()
	for size in [Vector2i(1000,800),Vector2i(640,480)]:
		root.size = size
		await frames()
		check(app.layout_size==Vector2(size) and ids==[app.get_instance_id(),header.get_instance_id(),side.get_instance_id(),action.get_instance_id(),shared.get_instance_id()],"resize retains track policy and native identities "+str(size))
		await RenderingServer.frame_post_draw
		var capture: Image = root.get_texture().get_image()
		check(capture.save_png("res://layout-"+str(size.x)+".png")==OK,"rendered capture "+str(size.x))
	var count := State.records.size()
	host.queue_free()
	await frames()
	check(State.records.size()<count,"native disposal disconnects composition scopes")
	print("EL02_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("EL02_RUNTIME_OK")
	quit(0 if failures==0 else 1)
