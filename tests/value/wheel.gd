extends SceneTree
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_WHEEL ",label,": ",test)
func frames():
	for i in range(8): await process_frame
func wheel(point:Vector2):
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_WHEEL_UP;event.pressed=true;event.position=point
	Input.parse_input_event(event);await frames()
func _initialize(): run.call_deferred()
func run():
	var host=load("res://examples/values/generated/Values.gd").new();root.add_child(host);await frames()
	var clip=host.get_node("UI/ClipRow/Clip");clip.scroll_offset=Vector2(0,1000);await frames()
	var slider=clip.get_layout_child("ClippedSlider");var native=slider.get_native_control()
	var before:Vector2=clip.scroll_offset
	var events:Array=[];slider.value_changed.connect(func(a,b):events.append([a,b]))
	var point:Vector2=native.get_global_rect().get_center()
	await wheel(point)
	check(absf(slider.value-0.55)<1e-7 and clip.scroll_offset==before and events.size()==1,"editable native Slider receives one real wheel edit before ancestor scroll")
	slider.read_only=true;await wheel(point)
	check(absf(slider.value-0.55)<1e-7 and clip.scroll_offset.y<before.y and events.size()==1,"read-only native Slider yields wheel to parent without numeric edit")
	host.free();await frames()
	var state=preload("res://addons/estragon/runtime/composition/state.tres")
	check(state.records.is_empty(),"wheel ownership uses existing weak lifetime registry and releases on unmount")
	print("UI05_WHEEL_ASSERTIONS ",checks," ok=",ok)
	if ok: print("UI05_WHEEL_OK")
	quit(0 if ok else 1)
