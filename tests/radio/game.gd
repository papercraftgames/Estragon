extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
const Group = preload("res://addons/estragon/runtime/node/radio_group.gd")
const Focus = preload("res://addons/estragon/runtime/node/internal/focus.tres")
const Radio = preload("res://addons/estragon/runtime/node/radio.gd")
class KeyFallback:
	extends Node
	var arrows := 0
	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: arrows += 1
var checks := 0
var ok := true
func check(test: bool, label: String):
	checks += 1
	print("UI04_GAME_CHECK ",label,": ",test)
	ok = ok and test
func frames(tree: SceneTree):
	for i in range(8): await tree.process_frame
func key(tree: SceneTree, code: int, shift: bool = false):
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		event.shift_pressed = shift
		Input.parse_input_event(event)
		await frames(tree)
func mouse(node: Node2D, down: bool, offset: Vector2 = Vector2(8,8)):
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = node.get_global_transform_with_canvas()*offset
	event.pressed = down
	Input.parse_input_event(event)
	await frames(node.get_tree())
func click(node: Node2D):
	await mouse(node,true)
	await mouse(node,false)
func run(host: Node):
	var tree := host.get_tree()
	await frames(tree)
	var old_a := Toggle.new()
	var old_b := Toggle.new()
	old_a.value = true
	old_b.value = true
	check(old_a.value and old_b.value,"baseline: independent Toggle booleans permit two selected options")
	old_a.free(); old_b.free()
	var row = host.get_node("UI/Grid/Row")
	var column = host.get_node("UI/Grid/Column")
	var a = row.get_node("Optiona")
	var b = row.get_node("Optionb")
	var c = row.get_node("Optionc")
	var d = row.get_node("Optiond")
	var x = column.get_node("X")
	var y = column.get_node("Y")
	var before = host.get_node("UI/Before")
	var scope = State.records[host.get_instance_id()]
	check(row.direction=="row" and column.direction=="column" and row.value=="b" and b.is_selected() and not a.is_selected() and not c.is_selected(),"row has exactly one initial model-derived selection; column defaults vertical")
	check(column.value=="" and not x.is_selected() and column.tab_option()==x,"empty group selects nothing with first eligible Tab stop")
	check(row.layout_size.x>0 and a.layout_size.x>28 and a.get_focus_control().size==a.layout_size and b.position.x>a.position.x,"native Box row geometry and native border-box endpoint")
	var events: Array = []
	var writes: Array = []
	row.value_changed.connect(func(previous,next): events.append([previous,next]))
	host.model.choice_changed.connect(func(previous,next): writes.append([previous,next]))
	await click(a)
	check(row.value=="a" and host.model.choice=="a" and a.is_selected() and not b.is_selected() and events==[["b","a"]] and writes==events,"pointer selects once and writes one model transition")
	await click(b)
	await click(b)
	check(events==[["b","a"],["a","b"]] and writes==events and b.has_focus(),"same selected click has no extra change; real focus owner follows pointer")
	var count := events.size()
	row.value = "c"
	check(host.model.choice=="c" and events.size()==count+1,"independent programmatic group write synchronously notifies source")
	await frames(tree)
	host.model.choice = "a"
	await frames(tree)
	check(a.is_selected() and writes.size()==count+2 and events.size()==count+2,"model projection emits once without source feedback")
	row.value = "a"
	await frames(tree)
	check(events.size()==count+2,"equal group assignment is quiet")
	var fallback := KeyFallback.new()
	tree.root.add_child(fallback)
	before.grab_focus()
	await key(tree,KEY_TAB)
	check(a.has_focus(),"Tab enters selected eligible option as one logical stop")
	await key(tree,KEY_TAB)
	check(x.has_focus(),"Tab leaves whole row for first vertical option")
	await key(tree,KEY_TAB,true)
	check(a.has_focus(),"Shift Tab returns once to selected row option")
	await key(tree,KEY_RIGHT)
	check(b.has_focus() and row.value=="b","row Right selects and moves native focus")
	await key(tree,KEY_RIGHT)
	await key(tree,KEY_RIGHT)
	check(a.has_focus() and row.value=="a" and d.disabled,"row wraps and skips authored disabled option")
	await key(tree,KEY_LEFT)
	check(c.has_focus() and row.value=="c","row Left wraps to last eligible")
	await key(tree,KEY_HOME)
	check(a.has_focus() and row.value=="a","Home chooses first eligible")
	await key(tree,KEY_END)
	check(c.has_focus() and row.value=="c","End chooses last eligible")
	x.grab_focus()
	var calls: int = host.calls
	await key(tree,KEY_DOWN)
	check(y.has_focus() and column.value=="y" and host.column=="y","column Down selects second native endpoint")
	await key(tree,KEY_DOWN)
	await key(tree,KEY_UP)
	check(y.has_focus() and column.value=="y","column arrows wrap and skip disabled")
	count = events.size()
	await key(tree,KEY_SPACE)
	check(column.value=="y" and events.size()==count,"accept on selected option emits no extra choice")
	check(fallback.arrows==0,"consumed Radio arrow press/release never reaches game unhandled keys")
	fallback.free()
	row.disabled = true
	await click(a)
	check(not a.has_focus() and row.value=="c" and not a.disabled and d.disabled and not c.is_selected(),"effective group disable blocks pointer/focus and preserves authored flags/value")
	row.disabled = false
	await frames(tree)
	check(c.is_selected() and d.disabled,"reenable restores selected visual and authored disabled option")
	c.grab_focus()
	c.hide()
	await frames(tree)
	check(row.value=="c" and not c.is_selected() and a.has_focus(),"hide retains pending value and falls focus to next eligible")
	c.show()
	await frames(tree)
	check(c.is_selected(),"show restores selection without mutating model")
	var identity: int = b.get_instance_id()
	b.grab_focus()
	host.items.move(1,0)
	await frames(tree)
	check(row.options()[0]==b and b.get_instance_id()==identity and b.has_focus(),"keyed collection reorder retains native identity/focus and logical order")
	await key(tree,KEY_RIGHT)
	check(a.has_focus() and row.value=="a","arrow follows reordered logical order")
	host.model.choice = "b"
	await frames(tree)
	host.items.remove_at(0)
	await frames(tree)
	check(row.value=="b" and not a.is_selected() and not c.is_selected(),"remove selected option retains valid pending model String")
	host.items.insert(0,{"id":"b","label":"Restored"})
	await frames(tree)
	b = row.get_node("Optionb")
	check(b.is_selected() and b.get_instance_id()!=identity,"restored identifier restores selected visual on new native option")
	var snapshot = host.get_node("UI/Scroll").get_layout_child("Snapshot")
	snapshot.value = "a"
	await frames(tree)
	check(host.model.choice=="b" and snapshot.value=="a","local snapshot is one-way despite group String signal")
	host.revision += 1
	await frames(tree)
	check(snapshot.value=="b","next relevant render projects snapshot model authority")
	var repair: Callable = func(_old,next):
		if next=="a": host.model.choice = "b"
	host.model.choice_changed.connect(repair)
	await click(a)
	check(host.model.choice=="b" and row.value=="b" and b.is_selected(),"reentrant model repair restores mounted group through existing projection guard")
	host.model.choice_changed.disconnect(repair)
	var old_model = host.model
	host.replace()
	await frames(tree)
	await click(c)
	check(host.model!=old_model and host.model.choice=="c" and old_model.choice=="b","source replacement disconnects old String writer")
	await mouse(a,true)
	await mouse(c,false)
	check(row.value=="c","mismatched release cancels hold without selection")
	var overlay := Button.new()
	overlay.text = "Native occlusion"
	overlay.position = a.get_global_transform_with_canvas()*Vector2.ZERO
	overlay.size = a.layout_size
	tree.root.add_child(overlay)
	await frames(tree)
	await click(a)
	check(row.value=="c","overlapping native Control wins GUI pointer precedence")
	overlay.free()
	var foreign = host.get_node("UI/NativeEdit")
	foreign.grab_focus()
	foreign.caret_column = 0
	await key(tree,KEY_RIGHT)
	check(foreign.has_focus() and foreign.caret_column==1 and row.value=="c","foreign LineEdit arrows remain native and do not select Radio")
	before.grab_focus()
	before.get_focus_control().caret_column = 0
	await key(tree,KEY_RIGHT)
	check(before.has_focus() and before.get_focus_control().caret_column==1,"Estragon Input arrows remain native")
	var foreign_button = host.get_node("UI/Native")
	foreign_button.grab_focus()
	await key(tree,KEY_TAB)
	check(foreign.has_focus(),"shared Tab leaves native Godot Button for native LineEdit")
	await key(tree,KEY_TAB,true)
	check(foreign_button.has_focus(),"shared Shift Tab preserves foreign native Controls")
	var snapshot_group = host.get_node("UI/Scroll").get_layout_child("Snapshot")
	var scroll = host.get_node("UI/Scroll")
	var clipped = snapshot_group.get_node("C")
	check(not clipped._radio_eligible() and not clipped.is_selected(),"fully clipped option has no focus or selected display")
	snapshot_group.value = "c"
	scroll.scroll_offset = Vector2(0,1000)
	await frames(tree)
	clipped.grab_focus()
	check(clipped.has_focus() and clipped.is_selected(),"scroll reveal restores pending selection and native focus")
	scroll.scroll_offset = Vector2.ZERO
	await frames(tree)
	check(not clipped.has_focus() and not clipped.is_selected() and snapshot_group.value=="c","scrolling focused option out of clip releases stale focus and retains selection String")
	scroll.scroll_offset = Vector2(0,1000)
	await frames(tree)
	check(clipped.is_selected(),"revealing again restores selected state through shared geometry refresh")
	scroll.scroll_offset = Vector2.ZERO
	c.grab_focus()
	c.disabled = true
	await frames(tree)
	check(row.value=="c" and not c.has_focus() and not c.is_selected() and b.has_focus(),"individual disable retains value and falls focus forward")
	await key(tree,KEY_TAB,true)
	check(before.has_focus(),"fallback option remains one logical Tab stop even without eligible selected option")
	c.disabled = false
	await frames(tree)
	check(c.is_selected() and before.has_focus(),"restoration does not steal unrelated Input focus")
	await mouse(a,true)
	row.disabled = true
	check(not row.get_layout_root()._get_pointer_router().has_capture(),"group disable cancels native pointer capture immediately")
	await mouse(a,false)
	row.disabled = false
	a.focus_mode = Control.FOCUS_NONE
	await click(a)
	check(row.value=="a" and a.is_selected() and not a.has_focus(),"focus-none option remains a pointer-selectable native Button")
	a.focus_mode = Control.FOCUS_ALL
	await click(c)
	var old_size := tree.root.size
	tree.root.size = Vector2i(560,720)
	await frames(tree)
	check(row.layout_size.x>0 and c.get_focus_control().size==c.layout_size and host.get_node("UI/Grid").layout_size.x==528,"alternate viewport keeps percent/Grid/wrapped native geometry")
	await click(a)
	check(row.value=="a","resized wrapped option remains clickable")
	await click(c)
	tree.root.size = old_size
	await frames(tree)
	var geometry_refreshes: int = Focus.refreshes
	var pixels: Image
	await RenderingServer.frame_post_draw
	pixels = tree.root.get_texture().get_image()
	pixels.save_png("res://radio-gallery.png")
	var center: Vector2 = c.get_global_transform_with_canvas()*(c.get_content_rect().position+Vector2(c._indicator_size()*0.5,c.get_content_rect().size.y*0.5))
	check(pixels.get_pixelv(Vector2i(center)).r>0.6,"actual selected indicator center is rendered")
	var empty_center: Vector2 = a.get_global_transform_with_canvas()*(a.get_content_rect().position+Vector2(a._indicator_size()*0.5,a.get_content_rect().size.y*0.5))
	check(pixels.get_pixelv(Vector2i(empty_center)).r<0.4,"actual unselected indicator center remains hollow")
	check(column.global_position.x+column.layout_size.x<=tree.root.size.x-16 and column.global_position.x>row.global_position.x,"both physical direction groups are visible within Grid tracks")
	check(pixels.get_pixelv(Vector2i(center)).r==pixels.get_pixelv(Vector2i(center)).b,"neutral default selected indicator")
	calls = host.calls
	var measures: int = row.layout.model.measure_count
	for i in range(20): row.value = row.value
	await frames(tree)
	check(host.calls==calls and row.layout.model.measure_count==measures and Focus.refreshes==geometry_refreshes,"idle and repeated equal writes cause no Gogo render or layout work")
	var nested = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	nested.width = 180
	nested.height = 100
	nested.x = 450
	nested.y = 500
	var nested_group := Group.new()
	var nested_a := Radio.new()
	nested_a.value = "one"
	nested_a.text = "Nested one"
	var nested_b := Radio.new()
	nested_b.value = "two"
	nested_b.text = "Nested two"
	nested_group.add_child(nested_a)
	nested_group.add_child(nested_b)
	var ornament := Node.new()
	nested_group.add_child(ornament)
	nested.add_child(nested_group)
	host.get_node("UI").add_child(nested)
	await frames(tree)
	nested_a.grab_focus()
	await key(tree,KEY_DOWN)
	check(nested_b.has_focus() and nested_group.value=="two" and row.value=="c" and nested_group.options().size()==2,"nested independent Entry deduplicates shared key routing; non-Radio children are ignored")
	nested.free()
	await frames(tree)
	var group := Group.new()
	group.name = "MovedGroup"
	group.position = Vector2(500,500)
	group.width = 200
	group.height = 80
	var entry = host.get_node("UI")
	entry.add_child(group)
	var moved := Radio.new()
	moved.value = "move"
	moved.text = "Moved"
	row.add_child(moved)
	await frames(tree)
	row.remove_child(moved)
	group.add_child(moved)
	await frames(tree)
	group.value = "move"
	check(moved._radio_owner()==group and moved.is_selected() and row.value=="c","reparent joins nearest new group without stale selection callbacks")
	group.remove_child(moved)
	entry.add_child(moved)
	await frames(tree)
	check(moved._radio_owner()==null and not moved.is_selected() and moved._input_disabled(),"orphan Radio has no independent model or activation")
	moved.free(); group.free()
	var packed := PackedScene.new()
	var editor_flag := OS.get_environment("UI04_EDITOR")
	OS.set_environment("UI04_EDITOR","0")
	check(packed.pack(host)==OK,"Gogo host packs with transient output excluded")
	var reopened = packed.instantiate()
	tree.root.add_child(reopened)
	OS.set_environment("UI04_EDITOR",editor_flag)
	await frames(tree)
	var restored = reopened.get_node("UI/Grid/Row")
	check(restored.options().size()==4 and restored.value=="b" and restored.get_node("Optionb").is_selected(),"pack/reopen reconstructs one selection and endpoints from authored defaults")
	reopened.free()
	await frames(tree)
	var value: String = row.value
	host.show = false
	await frames(tree)
	check(not is_instance_valid(row),"conditional unmount frees options and group")
	host.show = true
	await frames(tree)
	row = host.get_node("UI/Grid/Row")
	check(row.value==value and row.options().size()==4,"remount projects current model with one option set")
	return {"ok":ok,"checks":checks}
