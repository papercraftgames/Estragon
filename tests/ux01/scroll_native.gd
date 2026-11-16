extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Scroll = preload("res://addons/estragon/runtime/node/scroll_view.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
var native_hits := 0
func native_hit(): native_hits += 1
var failed := false
func check(ok: bool, label: String):
	print("UX01_NATIVE_SCROLL ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var entry := Entry.new()
	entry.width = 640
	entry.height = 480
	var scroll := Scroll.new()
	scroll.width = 300
	scroll.height = 300
	scroll.horizontal_scroll = true
	scroll.vertical_scroll = true
	var root_box := Box.new()
	root_box.width = 900
	root_box.height = 900
	var block := Rect.new()
	block.width = 900
	block.height = 900
	block.background_color = "#bb6633"
	root_box.add_child(block)
	scroll.add_child(root_box)
	entry.add_child(scroll)
	root.add_child(entry)
	await frames()
	check(scroll.scroll_range==Vector2(600,600),"both-axis range600")
	scroll.scroll_offset = Vector2(900,900)
	check(scroll.scroll_offset==Vector2(600,600),"programmatic clamp")
	var stats := root_box.get_layout_stats()
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(40,40)
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	root.push_input(wheel,true)
	await frames()
	check(scroll.scroll_offset.y==560 and stats==root_box.get_layout_stats(),"wheel updates translation only")
	var pan := InputEventPanGesture.new()
	pan.position = Vector2(40,40)
	pan.delta = Vector2(-1,-1)
	root.push_input(pan,true)
	await frames()
	check(scroll.scroll_offset==Vector2(560,520),"trackpad pan both axes")
	root_box.width = 100
	root_box.height = 100
	block.width = 100
	block.height = 100
	await frames()
	check(scroll.scroll_range==Vector2.ZERO and scroll.scroll_offset==Vector2.ZERO,"content shrink clamps both axes, hides bars")
	var native_view := Scroll.new()
	native_view.width = 100
	native_view.height = 100
	native_view.vertical_scroll = true
	var native_button := Button.new()
	native_button.custom_minimum_size = Vector2(100,900)
	native_button.pressed.connect(native_hit)
	native_view.add_child(native_button)
	entry.add_child(native_view)
	await frames()
	var point := native_button.get_global_transform_with_canvas()*Vector2(30,30)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press,true)
	press = press.duplicate()
	press.pressed = false
	press.position.y += 170
	root.push_input(press,true)
	await frames()
	check(native_hits==0,"captured native Button release outside viewport never activates")
	entry.free()
	await frames()
	var standalone := Scroll.new()
	standalone.name = "Scroll"
	standalone.width = 300
	standalone.height = 300
	standalone.vertical_scroll = true
	var content := Box.new()
	content.name = "PersistentContent"
	content.height = 900
	standalone.add_child(content)
	content.owner = standalone
	root.add_child(standalone)
	await frames()
	var packed := PackedScene.new()
	check(packed.pack(standalone)==OK and ResourceSaver.save(packed,"res://ux01-scroll-pack.tscn")==OK,"native persistent viewport pack")
	standalone.free()
	await frames()
	standalone = load("res://ux01-scroll-pack.tscn").instantiate()
	root.add_child(standalone)
	await frames()
	check(standalone.get_content_root()!=null,"native persistent root survives pack/reload")
	standalone.free()
	await frames()
	if not failed: print("UX01_NATIVE_SCROLL_OK")
	quit(1 if failed else 0)
