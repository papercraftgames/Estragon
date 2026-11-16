extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
class CountHost extends Node2D:
	const Element = preload("res://addons/estragon/runtime/composition/element.gd")
	const Scroll = preload("res://addons/estragon/runtime/node/scroll_view.gd")
	const Box = preload("res://addons/estragon/runtime/node/box.gd")
	var count := 1
	func _notification(what): State.lifecycle(self,what)
	func build_view():
		var content := []
		for i in range(maxi(0,count)): content.append(Element.new(Box))
		if count<0: content.append(Element.new("Node3D",{},{},[],"tests/ux01/rejections.gd:12:1"))
		return Element.new(Scroll,{"name":"Scroll","height":100,"width":100,"vertical_scroll":true},{},content,"tests/ux01/rejections.gd:13:1")
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
	var list = scroll.get_content_root()
	var native_id: int = list.get_node("NativeRow").get_instance_id()
	host.show_overflow = false
	await frames()
	check(not host.has_node("UI/Content/Overflow") and list.get_node("NativeRow").get_instance_id()==native_id,"conditional removal retains sibling content")
	host.show_overflow = true
	await frames()
	check(host.has_node("UI/Content/Overflow") and list.get_node("NativeRow").get_instance_id()==native_id,"conditional restoration retains sibling content")
	host.free()
	await frames()
	var counts := CountHost.new()
	root.add_child(counts)
	await frames()
	var saved := counts.get_node("Scroll")
	for invalid in [0,2,-1]:
		print("UX01_EXPECTED_BEGIN")
		counts.count = invalid
		State.records[counts.get_instance_id()].schedule()
		await frames()
		print("UX01_EXPECTED_END")
		check(counts.get_node("Scroll")==saved and saved.get_content_root()!=null,"zero/multiple/unbounded roots reject before native commit: "+str(invalid))
	counts.free()
	await frames()
	check(State.records.is_empty(),"composition subscriptions and records released")
	if not failed: print("UX01_REJECTIONS_OK")
	quit(1 if failed else 0)
