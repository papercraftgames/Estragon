extends SceneTree
var pressed := 0
func hit(): pressed += 1
func event(point: Vector2, down: bool):
	var e := InputEventMouseButton.new()
	e.position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	root.push_input(e,true)
func _initialize(): run.call_deferred()
func run():
	var clip := Control.new()
	clip.size = Vector2(100,100)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var button := Button.new()
	button.text = "Capture"
	button.size = Vector2(100,300)
	button.pressed.connect(hit)
	clip.add_child(button)
	root.add_child(clip)
	for i in range(5): await process_frame
	event(Vector2(30,30),true)
	event(Vector2(30,200),false)
	for i in range(5): await process_frame
	print("NATIVE_CAPTURE pressed=",pressed)
	clip.free()
	# This is the unguarded native-engine limitation, not the scrolling component gate.
	# scroll_native.gd proves the product's scoped guard prevents activation.
	if pressed==1: print("UX01_NATIVE_CAPTURE_LIMITATION_CONFIRMED")
	quit(0 if pressed==1 else 1)
