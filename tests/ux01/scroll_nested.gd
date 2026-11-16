extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Scroll = preload("res://addons/estragon/runtime/node/scroll_view.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Button2D = preload("res://addons/estragon/runtime/node/button.gd")
var failed := false
var content_hits := 0
func content_hit(): content_hits += 1
func check(ok: bool, label: String):
	print("UX01_NESTED ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func event(button: int, point: Vector2):
	var input := InputEventMouseButton.new()
	input.position = point
	input.button_index = button
	input.pressed = true
	root.push_input(input,true)
	if button==MOUSE_BUTTON_LEFT:
		input = input.duplicate()
		input.pressed = false
		root.push_input(input,true)
func _initialize(): run.call_deferred()
func run():
	var entry := Entry.new()
	entry.width = 640
	entry.height = 480
	var outer := Scroll.new()
	outer.width = 300
	outer.height = 300
	outer.vertical_scroll = true
	var column := VBox.new()
	column.width = 300
	column.height = 900
	var inner := Scroll.new()
	inner.width = 300
	inner.height = 200
	inner.vertical_scroll = true
	var item := Button2D.new()
	item.width = 300
	item.height = 900
	item.pressed.connect(content_hit)
	inner.add_child(item)
	column.add_child(inner)
	outer.add_child(column)
	entry.add_child(outer)
	root.add_child(entry)
	await frames()
	event(MOUSE_BUTTON_WHEEL_DOWN,Vector2(40,40))
	await frames()
	check(inner.scroll_offset.y==40 and outer.scroll_offset.y==0,"nested wheel chooses inner")
	inner.scroll_offset = Vector2(0,700)
	event(MOUSE_BUTTON_WHEEL_DOWN,Vector2(40,40))
	await frames()
	check(inner.scroll_offset.y==700 and outer.scroll_offset.y==40,"exhausted inner bubbles outer")
	outer.scroll_offset = Vector2.ZERO
	inner.scroll_offset = Vector2.ZERO
	event(MOUSE_BUTTON_LEFT,Vector2(294,175))
	await frames()
	check(inner.scroll_offset.y>0 and content_hits==0,"real native scrollbar click over Estragon content without activating content")
	var offset: Vector2 = inner.scroll_offset
	entry.remove_child(outer)
	await frames()
	entry.add_child(outer)
	await frames()
	check(inner.scroll_range.y==700 and inner.scroll_offset==offset,"remove/re-entry keeps viewport identity, range and position")
	item.height = 100
	await frames()
	check(inner.scroll_range.y==0 and inner.scroll_offset==Vector2.ZERO,"dynamic content shrink clamps and hides scrollbar")
	entry.free()
	await frames()
	if not failed: print("UX01_NESTED_OK")
	quit(1 if failed else 0)
