extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
class CountHost extends Node2D:
	const Element = preload("res://addons/estragon/runtime/composition/element.gd")
	const Scroll = preload("res://addons/estragon/runtime/node/vbox.gd")
	const Box = preload("res://addons/estragon/runtime/node/box.gd")
	const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
	var count := 1
	var extent := 100
	var requested := Vector2(0,250)
	func _notification(what): State.lifecycle(self,what)
	func build_view():
		var content := []
		for i in range(maxi(0,count)): content.append(Element.new(Box,{"height":900}))
		if count<0: content.append(Element.new("Node3D",{},{},[],"tests/ux01/rejections.gd:12:1"))
		var view := Element.new(Scroll,{"name":"Scroll","scroll_offset":requested,"height":extent,"width":100,"vertical_scroll":true},{},content,"tests/ux01/rejections.gd:16:1")
		return Element.new(Entry,{"name":"UI","width":100,"height":400},{},[view])
var failed := false
func check(ok: bool, label: String):
	print("UX01_REJECTION ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var host = load("res://app/generated/UXGallery.gd").new()
	root.add_child(host)
	await frames()
	var scroll = host.get_node("UI/Content/Scroll")
	var identity: int = scroll.get_instance_id()
	var before: Vector2 = scroll.layout_size
	for invalid in [{"max_height":"-1px"},{"max_width":"2em"},{"scroll_offset":Vector2(-1,0)},{"scroll_offset":Vector2(INF,0)},{"vertical_scroll":1},{"scroll_range":Vector2.ZERO},{"content_extent":Vector2.ZERO}]:
		print("UX01_EXPECTED_BEGIN")
		host.extra = invalid
		await frames()
		print("UX01_EXPECTED_END")
		check(scroll.get_instance_id()==identity and scroll.layout_size==before and scroll.vertical_scroll,"invalid whole view retains tree/geometry: "+str(invalid))
	host.extra = {"max_width":"100px"}
	await frames()
	check(scroll.layout_size.x==100,"valid dynamic cap")
	host.extra = {}
	await frames()
	check(scroll.max_width=="auto" and scroll.layout_size==before,"omitted max resets auto and repairs")
	var list = scroll
	var native_id: int = list.get_layout_child("NativeRow").get_instance_id()
	host.show_overflow = false
	await frames()
	check(not host.has_node("UI/Content/Overflow") and list.get_layout_child("NativeRow").get_instance_id()==native_id,"conditional removal retains sibling content")
	host.show_overflow = true
	await frames()
	check(host.has_node("UI/Content/Overflow") and list.get_layout_child("NativeRow").get_instance_id()==native_id,"conditional restoration retains sibling content")
	host.free()
	await frames()
	var counts := CountHost.new()
	root.add_child(counts)
	await frames()
	var saved := counts.get_node("UI/Scroll")
	check(saved.scroll_offset==Vector2(0,250),"declarative initial offset survives mount before natural measurement")
	counts.extent = 300
	counts.requested = Vector2(0,1000)
	State.records[counts.get_instance_id()].schedule()
	await frames()
	check(saved.scroll_offset==Vector2(0,600),"changed viewport clamps authored offset against new range")
	counts.extent = 100
	counts.requested = Vector2(0,750)
	State.records[counts.get_instance_id()].schedule()
	await frames()
	check(saved.scroll_offset==Vector2(0,750),"offset-first attributes restore against enlarged new range")
	for count in [0,2]:
		counts.count = count
		State.records[counts.get_instance_id()].schedule()
		await frames()
		check(counts.get_node("UI/Scroll")==saved and saved.get_layout_children().size()==count,"zero/multiple direct children keep container and normal policy: "+str(count))
	counts.free()
	await frames()
	check(State.records.is_empty(),"composition subscriptions and records released")
	if not failed: print("UX01_REJECTIONS_OK")
	quit(1 if failed else 0)
