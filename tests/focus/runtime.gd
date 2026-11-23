extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Button2D = preload("res://addons/estragon/runtime/node/button.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
const Box = preload("res://addons/estragon/runtime/node/vbox.gd")
const Focus = preload("res://addons/estragon/runtime/node/internal/focus.tres")
var checks := 0
var failed := false
var clicks := 0
var edits := 0
var native_clicks := 0
class RawTextPrototype extends Node2D:
	# Deliberately bounded alternative: raw key-to-string is not native editing.
	var text := ""
	var keys := 0
	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed: keys += 1
		if event is InputEventKey and event.pressed and event.unicode>0: text += String.chr(event.unicode)
func check(ok: bool,label: String):
	checks += 1
	print("UI01_RUNTIME ",label,": ",ok)
	if not ok: failed = true
func frames():
	for i in range(8): await process_frame
func key(code: int,pressed: bool=true,echo: bool=false,shift: bool=false,unicode: int=0,ctrl: bool=false):
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	event.shift_pressed = shift
	event.unicode = unicode
	event.ctrl_pressed = ctrl
	root.push_input(event,true)
func tap(code: int,shift: bool=false):
	key(code,true,false,shift)
	key(code,false,false,shift)
func mouse(node: CanvasItem,pressed: bool):
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = node.get_global_transform_with_canvas()*Vector2(12,12)
	event.pressed = pressed
	root.push_input(event,true)
func click(node: CanvasItem):
	mouse(node,true)
	mouse(node,false)
func button(text: String):
	var node = Button2D.new()
	node.name = text
	node.text = text
	node.width = 160
	node.height = 44
	node.pressed.connect(func(): clicks += 1)
	return node
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,600)
	var entry = Entry.new()
	entry.width = 260
	entry.height = 560
	entry.direction = "column"
	entry.gap = 8
	var a = button("First")
	var b = Toggle.new()
	b.text = "Toggle"
	b.width = 160
	b.height = 44
	b.value_changed.connect(func(_value): edits += 1)
	var disabled = button("Disabled")
	disabled.disabled = true
	var native := Button.new()
	native.name = "Native"
	native.text = "Native Godot"
	native.custom_minimum_size = Vector2(160,44)
	native.pressed.connect(func(): native_clicks += 1)
	var text := LineEdit.new()
	text.name = "TextDelegate"
	text.custom_minimum_size = Vector2(160,44)
	text.placeholder_text = "Native text prototype"
	for node in [a,b,disabled,native,text]: entry.add_child(node)
	root.add_child(entry)
	var raw := RawTextPrototype.new()
	root.add_child(raw)
	await frames()
	check(Focus.candidates(root).size()==4,"one mixed eligible traversal across Node2D/native GUI roots, disabled skipped")
	click(a)
	check(a.has_focus() and root.gui_get_focus_owner()==a._focus_control and clicks==1,"actual pointer focuses native endpoint and emits exactly once")
	tap(KEY_TAB)
	check(b.has_focus(),"Tab from custom Button to Toggle")
	key(KEY_SPACE)
	for i in range(4): key(KEY_SPACE,true,true)
	check(b._keyboard_held and edits==0,"accept repeat stays held without duplicate user edits")
	key(KEY_SPACE,false)
	check(b.value and edits==1 and not b._keyboard_held,"accept release activates exactly once")
	key(KEY_ENTER)
	tap(KEY_ESCAPE)
	key(KEY_ENTER,false)
	check(edits==1,"Escape cancels held activation")
	key(KEY_SPACE)
	tap(KEY_TAB)
	key(KEY_SPACE,false)
	check(root.gui_get_focus_owner()==native and edits==1,"Tab skips disabled and focus loss cancels held key")
	tap(KEY_ENTER)
	check(native_clicks==1 and clicks==1,"native GUI owns native button keyboard activation without duplicates")
	tap(KEY_TAB)
	check(root.gui_get_focus_owner()==text,"Tab reaches real native text endpoint")
	key(KEY_E,true,false,false,0x00e9)
	key(KEY_E,false)
	check(text.text=="é","native delegate receives Unicode through actual viewport GUI input")
	key(KEY_A,true,false,false,0,true)
	key(KEY_A,false,false,false,0,true)
	check(text.has_selection(),"native delegate owns select-all shortcut")
	DisplayServer.clipboard_set("paste Ω")
	key(KEY_V,true,false,false,0,true)
	key(KEY_V,false,false,false,0,true)
	check(text.text=="paste Ω","native clipboard paste replaces native selection")
	check(raw.keys==0 and raw.text.is_empty(),"native editing and activation key presses do not also reach raw game key handlers")
	tap(KEY_TAB)
	check(a.has_focus(),"mixed traversal wraps")
	tap(KEY_TAB,true)
	check(root.gui_get_focus_owner()==text,"Shift-Tab reverses across native roots")
	text.focus_next = text.get_path_to(b._focus_control)
	tap(KEY_TAB)
	check(b.has_focus(),"authored native focus_next path wins over traversal order")
	text.focus_next = NodePath()
	a.focus_mode = Control.FOCUS_CLICK
	a.grab_focus()
	tap(KEY_TAB)
	check(b.has_focus() and not Focus.candidates(root).has(a.get_focus_control()),"click-only mode accepts focus but skips Tab")
	a.focus_mode = Control.FOCUS_NONE
	click(a)
	check(not a.has_focus() and clicks==2,"focus-none mode still accepts pointer activation without taking focus")
	a.focus_mode = Control.FOCUS_ALL
	b.disabled = true
	check(not b.has_focus() and root.gui_get_focus_owner()==null,"disabling focused custom target immediately releases native focus")
	b.disabled = false
	a.grab_focus()
	a.hide()
	await frames()
	check(not a.has_focus() and not Focus.candidates(root).has(a._focus_control),"hidden target releases and skips traversal")
	a.show()
	a.grab_focus()
	entry.move_child(a,entry.get_child_count()-1)
	await frames()
	tap(KEY_TAB)
	check(b.has_focus(),"native reorder is live traversal order, retained focused identity")
	entry.remove_child(b)
	await frames()
	check(root.gui_get_focus_owner()==null and not Focus.candidates(root).has(b._focus_control),"unmount drops focus and native endpoint without stale registration")
	entry.add_child(b)
	await frames()
	check(b._focus_control!=null and not b.has_focus(),"reentry creates exactly one live focus endpoint")
	# Native GUI gets first refusal even when an Estragon hit rectangle overlaps.
	var overlay := Button.new()
	overlay.text = "Native overlay"
	overlay.position = a.global_position
	overlay.size = Vector2(160,44)
	overlay.pressed.connect(func(): native_clicks += 1)
	root.add_child(overlay)
	var before := clicks
	click(a)
	check(native_clicks==2 and clicks==before and root.gui_get_focus_owner()==overlay,"native Control GUI click wins overlapping custom picker")
	overlay.queue_free()
	await frames()
	mouse(a,true)
	root.focus_exited.emit()
	mouse(a,false)
	check(clicks==before,"Window focus loss cancels pointer capture")
	a.grab_focus()
	key(KEY_ENTER)
	root.focus_exited.emit()
	key(KEY_ENTER,false)
	check(clicks==before and not a._keyboard_held,"Window focus loss cancels keyboard hold")
	a.release_focus()
	key(KEY_A,true,false,false,97)
	key(KEY_A,false)
	DisplayServer.clipboard_set("custom paste")
	key(KEY_V,true,false,false,0,true)
	key(KEY_V,false,false,false,0,true)
	check(raw.text=="a" and raw.keys>=2,"raw custom key prototype appends Unicode but provides no native clipboard/selection/IME contract")
	raw.queue_free()
	var scroll = Box.new()
	scroll.width = 180
	scroll.height = 70
	scroll.vertical_scroll = true
	var top = button("ScrollTop")
	var bottom = button("ScrollBottom")
	bottom.height = 90
	scroll.add_child(top)
	scroll.add_child(bottom)
	var second = Entry.new()
	second.position = Vector2(300,0)
	second.width = 200
	second.height = 200
	second.add_child(scroll)
	root.add_child(second)
	await frames()
	check(bottom._focus_control.size==bottom.layout_size and Focus.eligible(bottom._focus_control),"partly clipped focus rectangle equals native layout hit rectangle")
	bottom.grab_focus()
	scroll.scroll_offset = Vector2(0,44)
	await frames()
	check(not Focus.eligible(top._focus_control) and bottom.has_focus(),"scroll hides fully clipped target while retaining visible focus")
	top.grab_focus()
	check(not top.has_focus(),"fully clipped target refuses explicit focus")
	scroll.scroll_offset = Vector2.ZERO
	top.grab_focus()
	scroll.scroll_offset = Vector2(0,44)
	await frames()
	check(not top.has_focus(),"scrolling focused rectangle fully out of clip releases focus eventfully")
	b.grab_focus()
	tap(KEY_TAB)
	check(bottom.has_focus(),"one Tab crosses Entry scopes and skips fully clipped sibling")
	var isolated := SubViewport.new()
	isolated.size = Vector2i(200,100)
	root.add_child(isolated)
	var isolated_entry = Entry.new()
	isolated_entry.width = 180
	isolated_entry.height = 90
	var isolated_button = button("Isolated")
	isolated_entry.add_child(isolated_button)
	isolated.add_child(isolated_entry)
	await frames()
	isolated_button.grab_focus()
	check(isolated.gui_get_focus_owner()==isolated_button.get_focus_control() and not Focus.candidates(root).has(isolated_button.get_focus_control()) and Focus.candidates(isolated)==[isolated_button.get_focus_control()],"SubViewport uses native GUI focus and a separate traversal scope")
	isolated.queue_free()
	await frames()
	var stats := Focus.refreshes
	await frames()
	check(Focus.refreshes==stats,"idle frames perform no focus refresh work")
	bottom.grab_focus()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://focus-runtime.png")
	var packed := PackedScene.new()
	entry.owner = null
	for child in entry.get_children(): child.owner = entry
	check(packed.pack(entry)==OK,"native authored mixed controls pack")
	var copy = packed.instantiate()
	root.add_child(copy)
	await frames()
	check(copy.get_node("First")._focus_control!=null and copy.get_node("First").get_children(true).size()==1,"pack reload reconstructs one runtime-only focus endpoint")
	copy.queue_free()
	entry.queue_free()
	second.queue_free()
	await frames()
	check(Focus.viewports.is_empty() and not tree_changed.is_connected(Focus.refresh) and root.gui_get_focus_owner()==null,"all entries unmount releases shared weak registry and tree subscriptions")
	print("UI01_RUNTIME_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI01_RUNTIME_OK")
	quit(1 if failed else 0)
