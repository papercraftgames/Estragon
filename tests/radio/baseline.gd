extends SceneTree
## Intentional failing pre-UI04 reproduction: two native Toggle booleans cannot
## provide one authoritative String selection without imperative sibling writes.
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
func _initialize(): run.call_deferred()
func frames():
	for i in range(8): await process_frame
func click(node):
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = node.get_global_transform_with_canvas()*Vector2(8,8)
		event.pressed = down
		Input.parse_input_event(event)
		await frames()
func run():
	var entry := Entry.new()
	entry.direction = "row"
	entry.gap = 12
	var a := Toggle.new()
	a.text = "Build"
	var b := Toggle.new()
	b.text = "Explore"
	entry.add_child(a); entry.add_child(b); root.add_child(entry)
	await frames()
	await click(a); await click(b)
	var single: bool = int(a.value)+int(b.value)<=1
	print("UI04_BASELINE_SINGLE_SELECTION ",single," values=",[a.value,b.value])
	entry.free()
	quit(0 if single else 1)
