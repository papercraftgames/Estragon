extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(640,480)
	var home = load("res://app/generated/RootHome.gd").new()
	root.add_child(home)
	for frame in range(12): await process_frame
	var button: Button = home.get_node("UI/Column/Settings/Row/Exit")
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	# Return from the coroutine after synchronous native signal delivery.
	# Awaiting another frame after quit retains a suspended state on4.0.4.
	if home.get_node("UI/Column/Settings").clicks!=1:
		push_error("L07 root-percent native Exit did not receive the native click")
		quit(1)
