extends SceneTree
const Component = preload("res://addons/estragon/runtime/node/component_2d.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const NativeButton = preload("res://addons/estragon/runtime/node/button.gd")
var failed: int = 0
var assertions: int = 0
var activations: int = 0
func check(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failed += 1
		printerr("C3 ASSERTION FAILED: "+label)
func settle() -> void:
	for index in range(5): await process_frame
func _initialize() -> void:
	call_deferred("run")
func mouse(point: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)
	await process_frame
func click(button: Node2D) -> void:
	var point: Vector2 = button.get_global_transform_with_canvas() * (button.layout_size*0.5)
	await mouse(point,true)
	await mouse(point,false)
	await settle()
func on_pressed() -> void:
	activations += 1
func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"),"Godot-only runtime")
	check(OS.get_name()=="Linux","acceptance uses Linux")
	root.size = Vector2i(640,420)
	var entry := Entry.new()
	entry.width = 100
	var column := VBox.new()
	column.fill_width = true
	column.gap = 3
	var row := HBox.new()
	row.fill_width = true
	row.gap = 2
	var a := Rect.new()
	a.width = 10
	a.height = 5
	var b := Rect.new()
	b.fill_width = true
	b.height = 7
	row.add_child(a)
	row.add_child(b)
	var footer := Rect.new()
	footer.width = 30
	footer.height = 4
	column.add_child(row)
	column.add_child(footer)
	entry.add_child(column)
	root.add_child(entry)
	await settle()
	var participant: Node = a
	check(participant is Node2D and participant is Component and not participant is Control,"production components are native Node2D participants")
	check(row.layout_size==Vector2(100,7) and b.layout_size==Vector2(88,7),"nested main/cross fill allocation")
	check(column.layout_size==Vector2(100,14) and footer.position==Vector2(0,10),"shared vertical measurement and arrangement")
	check(b.position==Vector2(12,0),"horizontal gap and order")
	var idle := [entry.get_layout_stats(),column.get_layout_stats(),row.get_layout_stats(),a.get_layout_stats(),b.get_layout_stats()]
	await settle()
	check(idle==[entry.get_layout_stats(),column.get_layout_stats(),row.get_layout_stats(),a.get_layout_stats(),b.get_layout_stats()],"zero idle layout work")
	var flushes: int = entry.layout.flush_count
	var cached: int = footer.layout.model.measure_count
	for value in [12,13,14]: a.width = value
	await settle()
	check(entry.layout.flush_count==flushes+1 and footer.layout.model.measure_count==cached,"affected property writes coalesce and sibling measurements stay cached")
	check(b.layout_size.x==84,"fill uses remaining allocation after reflow")
	a.width = -2
	row.gap = NAN
	check(a.width==14 and row.gap==2,"invalid sizes retain prior state")
	var text := Text.new()
	text.text = "Hello\nGodot"
	row.add_child(text)
	await settle()
	check(text.layout_size.y==text.font.get_height(text.font_size)*2 and text.layout_size.x>0,"real native font multiline measurement")
	var size := text.layout_size
	text.font_size = 30
	await settle()
	check(text.layout_size.y>size.y,"font size invalidates measure")
	var font_size: int = text.font_size
	text.font_size = 0
	text.font = null
	check(text.font_size==font_size and text.font!=null,"invalid font inputs retain valid state")
	idle = [entry.get_layout_stats(),text.get_layout_stats()]
	text.color = Color.RED
	a.fill = Color.BLUE
	await settle()
	check(idle==[entry.get_layout_stats(),text.get_layout_stats()],"paint-only edits do not remeasure")
	var font: Font = text.font
	check(font.changed.is_connected(text._content_changed),"font subscription active")
	row.remove_child(text)
	check(not font.changed.is_connected(text._content_changed),"font subscription cleaned on native removal")
	text.free()
	entry.free()
	# Actual native input routing and visual Counter behavior.
	var scene: Node = load("res://examples/counter/Counter.tscn").instantiate()
	root.add_child(scene)
	await settle()
	var plus = scene.ui.get_node("Panel/Actions/Increment")
	var reset = scene.ui.get_node("Panel/Actions/Reset")
	var label = scene.ui.get_node("Panel/Count")
	var original_ids: Array = []
	for node in [scene.ui,plus,reset,label]: original_ids.append(node.get_instance_id())
	check(plus is NativeButton,"Button uses the production Node2D widget")
	check(label.text=="Count: 0" and reset.disabled,"native Counter initializes and disables Reset")
	check(plus.pressed.get_connections().size()==1,"GGX connects named native handler once")
	await click(reset)
	check(scene.count==0,"disabled button cannot activate")
	await click(plus)
	check(scene.count==1 and label.text=="Count: 1" and not reset.disabled,"native press/release increments visible retained Counter")
	await click(plus)
	check(scene.count==2,"subsequent input emits once")
	await click(reset)
	check(scene.count==0 and label.text=="Count: 0" and reset.disabled,"Reset native signal updates label and disabled state")
	var point: Vector2 = plus.get_global_transform_with_canvas() * (plus.layout_size*0.5)
	await mouse(point,true)
	await mouse(Vector2(630,410),false)
	check(scene.count==0,"release outside cancels activation")
	await mouse(point,true)
	plus.disabled = true
	await mouse(point,false)
	check(scene.count==0,"disable while held cancels capture")
	plus.disabled = false
	await mouse(point,true)
	root.focus_exited.emit()
	await mouse(point,false)
	check(scene.count==0,"window focus loss cancels capture")
	var old_width: float = plus.layout_size.x
	root.size = Vector2i(800,480)
	await settle()
	check(plus.layout_size.x>old_width and scene.ui.get_node("Panel/Accent").layout_size.x==720,"viewport resize reflows nested fill stacks")
	var ids: Array = []
	for node in [scene.ui,plus,reset,label]: ids.append(node.get_instance_id())
	check(ids==original_ids and plus.pressed.get_connections().size()==1,"resize retains native identity and subscriptions")
	idle = [scene.ui.get_layout_stats(),plus.get_layout_stats(),label.get_layout_stats()]
	await settle()
	check(idle==[scene.ui.get_layout_stats(),plus.get_layout_stats(),label.get_layout_stats()],"Counter has zero idle layout work")
	var packed := PackedScene.new()
	check(packed.pack(scene)==OK,"native Counter packs authored host separately from transient output")
	scene.free()
	var restored: Node = packed.instantiate()
	root.add_child(restored)
	await settle()
	check(restored.ui.get_node("Panel/Actions/Increment").pressed.get_connections().size()==1,"saved native signal graph restores without duplication")
	await click(restored.ui.get_node("Panel/Actions/Increment"))
	check(restored.count==1,"restored Counter remains interactive")
	restored.free()
	print("C3_RUNTIME_ASSERTIONS ",assertions," failures=",failed)
	if failed==0: print("C3_RUNTIME_OK")
	quit(0 if failed==0 else 1)
