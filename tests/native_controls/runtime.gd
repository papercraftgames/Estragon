extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
var failures := 0
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	print("L04_CHECK ",label,": ",value)
	if not value: failures += 1
func frames() -> void:
	for index in range(10): await process_frame
func capture(label: String) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+label+".png")
func click(button: Control) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()
func key(code: Key, unicode: int = 0) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.unicode = unicode
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()
func adapter(node: Control): return Hosts.find(node).control_adapter
func cleared(label: String) -> void:
	check(Hosts.get("controls").is_empty() and Hosts.get("exiting_controls").is_empty() and Hosts.get("hosts").is_empty() and State.get("records").is_empty(),label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	if OS.get_environment("L04_EXAMPLES")=="1":
		await examples()
		quit(1 if failures>0 else 0)
		return
	var home = load("res://app/generated/Home.gd").new()
	root.add_child(home)
	await frames()
	var exit_button: Button = home.get_node("UI/Column/Settings/Row/Exit")
	var settings = home.get_node("UI/Column/Settings")
	var rose = home.get_node("UI/Column/Rose/Row/RoseText")
	var hello = home.get_node("UI/Column/Hello")
	var fun = home.get_node("UI/Column/Fun")
	var data := {"hello":{"position":str(hello.global_position),"size":str(hello.layout_size)},"fun":{"position":str(fun.global_position),"size":str(fun.layout_size)},"button":{"position":str(exit_button.global_position),"size":str(exit_button.size),"minimum":str(exit_button.get_combined_minimum_size())},"rose":{"position":str(rose.global_position),"size":str(rose.layout_size)}}
	print("L04_GEOMETRY ",JSON.stringify(data))
	var before := OS.get_environment("L04_BEFORE")=="1"
	var label := "before" if before else "after"
	var file := FileAccess.open("res://"+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	capture(label)
	if before:
		home.free()
		await frames()
		print("L04_BEFORE_OK")
		quit(); return
	check(exit_button.global_position.y>=fun.global_position.y+fun.layout_size.y and rose.global_position.y>=exit_button.global_position.y+exit_button.size.y,"native Button and Rose occupy distinct sequential parent slots")
	check(exit_button.get_script()==null and exit_button.get_class()=="Button" and exit_button.get_meta_list().is_empty(),"Button retains native class, GUI and no injected script/metadata")
	if OS.get_environment("L04_EXIT")=="1":
		var event := InputEventMouseButton.new()
		event.position = exit_button.get_global_transform_with_canvas()*(exit_button.size/2)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		root.push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		root.push_input(event,true)
		return
	var runs := [State.get("records")[home.get_instance_id()].runs,State.get("records")[settings.get_instance_id()].runs]
	var initial_height: float = exit_button.size.y
	var rose_measures: int = rose.layout.model.measure_count
	exit_button.text = "Exit much longer\nsecond line"
	await frames()
	check(exit_button.size.y>initial_height and rose.global_position.y>=exit_button.global_position.y+exit_button.size.y,"native text minimum change reflows nested host and subsequent sibling")
	check(runs==[State.get("records")[home.get_instance_id()].runs,State.get("records")[settings.get_instance_id()].runs],"native content signals do not reexecute Gogo functions")
	check(rose.layout.model.measure_count==rose_measures,"native minimum invalidation keeps the unchanged sibling measurement cached")
	exit_button.custom_minimum_size = Vector2(280,70)
	await frames()
	check(exit_button.size.x>=280 and exit_button.size.y>=70 and rose.global_position.y>=exit_button.global_position.y+exit_button.size.y,"native explicit minimum contributes to the parent slot")
	exit_button.custom_minimum_size = Vector2.ZERO
	exit_button.text = "Exit"
	var theme := Theme.new()
	theme.set_font_size("font_size","Button",36)
	exit_button.theme = theme
	await frames()
	check(exit_button.size.y>initial_height and rose.global_position.y>=exit_button.global_position.y+exit_button.size.y,"native theme font changes remeasure without overlap")
	var font: Font = exit_button.get_theme_font("font")
	exit_button.add_theme_font_override("font",font)
	exit_button.add_theme_font_size_override("font_size",48)
	await frames()
	check(exit_button.get_theme_font("font")==font and exit_button.size.y>=48,"native font/size overrides preserve Godot font authority")
	exit_button.visible = false
	await frames()
	check(settings.get_node("Row").layout_size==Vector2.ZERO,"hidden native Control contributes no footprint")
	exit_button.visible = true
	await frames()
	check(exit_button.size.y>=48,"visibility restores allocation through native events")
	var bridge = adapter(exit_button)
	var entry = home.get_node("UI")
	var idle := [bridge.minimum_reads,entry.layout.flush_count,entry.layout.model.measure_count,entry.layout.model.arrange_count]
	await frames()
	check(idle==[bridge.minimum_reads,entry.layout.flush_count,entry.layout.model.measure_count,entry.layout.model.arrange_count],"idle native Control screen performs zero minimum reads/measure/arrange/flush")
	var native_id: int = exit_button.get_instance_id()
	settings.framework = true
	await frames()
	var ui = settings.get_node("Row/Exit")
	check(ui.get_class()=="Node2D" and ui.layout_size.y>0 and rose.global_position.y>=ui.global_position.y+ui.layout_size.y and not Hosts.get("controls").has(native_id),"UiButton remains the independent working Estragon widget; native bridge is removed")
	settings.framework = false
	await frames()
	check(settings.get_node("Row/Exit") is Button,"native Button choice returns without remapping")
	var retained: int = settings.get_instance_id()
	home.reverse = true
	await frames()
	check(home.get_node("UI/Column/Settings").get_instance_id()==retained and settings.position.y>=home.get_node("UI/Column/Rose").position.y+rose.layout_size.y,"keyed nested native host reorder retains identity and sequential slots")
	home.reverse = false
	home.show_settings = false
	await frames()
	check(Hosts.get("controls").is_empty(),"nested native branch removal disconnects its bridges")
	home.show_settings = true
	root.size = Vector2i(800,480)
	await frames()
	exit_button = home.get_node("UI/Column/Settings/Row/Exit")
	check(home.extent==Vector2(800,480) and rose.global_position.y==480-rose.layout_size.y and rose.global_position.y>=exit_button.global_position.y+exit_button.size.y,"viewport resize and native branch reinsertion preserve bottom-aligned geometry")
	home.free()
	root.size = Vector2i(640,360)
	await frames()
	cleared("native scene free releases all Control/layout/computation records")
	await widgets()
	await borrowing()
	await boundaries()
	print("L04_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("L04_RUNTIME_OK")
	quit(1 if failures>0 else 0)

func widgets() -> void:
	var home = load("res://app/generated/Widgets.gd").new()
	root.add_child(home)
	await frames()
	var column = home.get_node("UI/Column")
	var a: Button = column.get_node("A")
	var b: Button = column.get_node("B")
	var label: Label = column.get_node("Label")
	var edit: LineEdit = column.get_node("Edit")
	var texture: TextureRect = column.get_node("Image")
	var container: HBoxContainer = column.get_node("Container")
	var left: Label = container.get_node("Left")
	var right: Label = container.get_node("Right")
	check(b.position.y>=a.position.y+a.size.y+8 and column.get_node("FrameworkText").position.y>=b.position.y+b.size.y+8,"two native Buttons and framework Text occupy nonoverlapping VBox slots")
	check(label.size==label.get_combined_minimum_size() and edit.size==edit.get_combined_minimum_size() and texture.size==Vector2(40,24),"Label/LineEdit/TextureRect use their native minimum contracts")
	check(container.size==container.get_combined_minimum_size() and right.position.x>=left.position.x+left.size.x and left.position.y==0 and not Hosts.get("controls").has(left.get_instance_id()) and not Hosts.get("controls").has(right.get_instance_id()),"Container outer participant stays opaque while Godot sorts its native children")
	var container_y: float = container.position.y
	var image := Image.create(80,32,false,Image.FORMAT_RGBA8)
	image.fill(Color.SEA_GREEN)
	texture.texture = ImageTexture.create_from_image(image)
	await frames()
	check(texture.size==Vector2(80,32) and container.position.y>=container_y+8,"native texture intrinsic change reflows following Container")
	container.custom_minimum_size = Vector2(260,60)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.text = "Native container left"
	await frames()
	check(container.size.x>=260 and left.size.x>left.get_combined_minimum_size().x and right.position.x>=left.position.x+left.size.x,"native Container retains internal flag/sorting authority in its assigned rect")
	await click(a)
	check(home.clicks==1,"one native GUI click emits one Button pressed event")
	a.disabled = true
	await click(a)
	check(home.clicks==1,"native disabled Button suppresses GUI activation")
	a.disabled = false
	a.grab_focus()
	await key(KEY_SPACE,32)
	check(home.clicks==2 and root.gui_get_focus_owner()==a,"native focused keyboard activation remains functional")
	print("L04_NATIVE_FOCUS_DEFAULT ",a.find_next_valid_focus())
	# Node2D Boxes preserve native GUI ancestry. Explicit native links cross
	# separate Control roots; no focus graph is synthesized by the bridge.
	a.focus_next = a.get_path_to(b)
	b.focus_previous = b.get_path_to(a)
	await key(KEY_TAB)
	check(root.gui_get_focus_owner()==b,"native Tab navigation follows authored native Control focus links")
	edit.grab_focus()
	await key(KEY_X,120)
	check(edit.text.contains("x"),"native LineEdit receives actual GUI text input")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	await frames()
	check(is_equal_approx(a.size.x,400) and b.size.x<a.size.x,"explicit EXPAND_FILL maps to cross-axis Box fill; default FILL remains natural")
	a.visible = false
	await frames()
	check(b.position.y==0,"hidden native child consumes no VBox gap")
	a.visible = true
	a.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home.get_node("UI").height = 50
	await frames()
	check(a.size.y>=a.get_combined_minimum_size().y and b.position.y>=a.position.y+a.size.y+8,"under-constrained flex retains native minimum sizes and sequential slots")
	var bridge = adapter(a)
	var count: int = bridge.minimum_reads
	for index in range(3):
		a.text = "Native changed "+str(index)
		a.minimum_size_changed.emit()
	await frames()
	check(bridge.minimum_reads==count+1,"batched native minimum changes coalesce into one cached measurement")
	capture("widgets")
	var direct = load("res://app/generated/NativeRoot.gd").new()
	column.add_child(direct)
	await frames()
	var leaf: Button = direct.get_node("NativeRoot")
	check(leaf.size.y>0 and direct.position.y>=container.position.y+container.size.y+8,"Gogo returning a native Control root forwards its minimum slot")
	leaf.visible = false
	await frames()
	check(Hosts.find(direct).model.measure()==Vector3.ZERO and Hosts.find(direct).model.allocation_minimum==Vector3.ZERO,"hidden native root clears the Gogo proxy minimum")
	leaf.visible = true
	await frames()
	check(Hosts.find(direct).model.measure().y>=leaf.get_combined_minimum_size().y,"native root visibility restores its proxy slot")
	var zero := Control.new()
	column.add_child(zero)
	await frames()
	check(zero.size==Vector2.ZERO,"empty native minimum stays zero without reading manual allocated size")
	home.free()
	await frames()
	cleared("native Controls and opaque Container internals clean up without retained bridges")

func borrowing() -> void:
	var home = load("res://app/generated/Borrow.gd").new()
	home.name = "Borrow"
	var button := Button.new()
	button.name = "SceneButton"
	button.text = "Borrowed button"
	button.position = Vector2(90,110)
	button.custom_minimum_size = Vector2(100,40)
	home.add_child(button)
	button.owner = home
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.position = Vector2(320,220)
	home.add_child(sprite)
	sprite.owner = home
	root.add_child(home)
	await frames()
	var after = home.get_node("UI/Column/After")
	var id: int = button.get_instance_id()
	var record = Hosts.find(button)
	check(button.get_parent()==home and button.owner==home and button.position==Vector2(30,56) and after.global_position.y>=button.global_position.y+button.size.y+8,"Scene-dock-equivalent persistent Control borrows a native rect in the chosen slot")
	check(sprite.position==Vector2(320,220) and not Hosts.get("controls").has(sprite.get_instance_id()),"borrowed plain Sprite remains free-positioned without inferred size")
	await click(button)
	check(home.clicks==1,"borrowed native Control keeps its authored GUI signal connection")
	button.position += Vector2(7,9)
	await frames()
	check(button.position==Vector2(30,56),"external rect edits are restored by the participating Box without feedback")
	home.move_child(sprite,0)
	await frames()
	var reads: int = record.control_adapter.minimum_reads
	for tick in range(1,4):
		home.tick = tick
		await frames()
	check(button.get_instance_id()==id and Hosts.find(button)==record and home.get_child_count()==3 and record.control_adapter.minimum_reads==reads,"later projections filter managed output and reuse Control identity/cache")
	home.show_children = false
	await frames()
	check(button.position==Vector2(90,110) and button.get_parent()==home and button.owner==home and not record.active and not record.control_adapter.subscribed and Hosts.get("controls").is_empty(),"conditional release restores borrowed rect and disconnects bridge without freeing user Control")
	home.show_children = true
	await frames()
	check(button.get_instance_id()==id and button.position==Vector2(30,56),"conditional restoration reuses the authored instance")
	check(button.pressed.is_connected(home.pressed),"projection release never disconnects application signals")
	var packed := PackedScene.new()
	check(packed.pack(home)==OK and packed.get_state().get_node_count()==3 and ResourceSaver.save(packed,"res://ControlsReload.tscn")==OK,"PackedScene persists authored host/Button/Sprite only")
	home.free()
	await frames()
	cleared("borrowed Control native free releases all subscriptions/registrations")
	home = load("res://ControlsReload.tscn").instantiate()
	root.add_child(home)
	await frames()
	button = home.get_node("SceneButton")
	check(button.owner==home and button.get_parent()==home and home.get_child_count()==3 and button.size.y>=40,"save/reload remounts one layout with native Control ownership intact")
	capture("borrowed")
	home.free()
	await frames()
	cleared("reloaded native scene releases external bookkeeping")

func boundaries() -> void:
	var entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	root.add_child(entry)
	var column = preload("res://addons/estragon/runtime/node/vbox.gd").new()
	entry.add_child(column)
	var unusual := Button.new()
	unusual.text = "Anchored"
	unusual.anchor_right = 0.5
	unusual.position = Vector2(70,80)
	column.add_child(unusual)
	await frames()
	check(not adapter(unusual).participates() and unusual.anchor_right==0.5 and unusual.position==Vector2(70,80),"conflicting anchors are diagnosed and retain native positioning")
	unusual.anchor_right = 0
	unusual.minimum_size_changed.emit()
	await frames()
	check(adapter(unusual).participates() and unusual.position==Vector2.ZERO,"repairing native configuration restores participation without polling")
	unusual.set_as_top_level(true)
	unusual.minimum_size_changed.emit()
	await frames()
	check(not adapter(unusual).participates(),"top_level Control stays outside Box coordinate authority")
	unusual.set_as_top_level(false)
	unusual.scale = Vector2(2,1)
	unusual.minimum_size_changed.emit()
	await frames()
	check(not adapter(unusual).participates() and unusual.scale==Vector2(2,1),"unsupported local transform retains native state without a competing allocation")
	unusual.scale = Vector2.ONE
	unusual.minimum_size_changed.emit()
	entry.rotation = 0.2
	entry.scale = Vector2(1.2,1.2)
	await frames()
	check(adapter(unusual).participates() and unusual.position==Vector2.ZERO,"shared transformed native ancestors preserve the common local coordinate basis")
	var other = preload("res://addons/estragon/runtime/node/vbox.gd").new()
	entry.add_child(other)
	unusual.reparent(other,false)
	await frames()
	check(adapter(unusual).participates() and Hosts.get("controls").size()==1,"native Control reparent reacquires exactly one bridge")
	entry.free()
	await frames()
	entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	entry.height = 100
	column = preload("res://addons/estragon/runtime/node/vbox.gd").new()
	column.fill_height = true
	entry.add_child(column)
	var tall := Control.new()
	tall.custom_minimum_size.y = 70
	tall.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var short := Control.new()
	short.custom_minimum_size.y = 10
	short.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tall)
	column.add_child(short)
	root.add_child(entry)
	await frames()
	check(tall.size.y==70 and short.size.y==30 and short.position.y==70,"native minimum floor redistributes flex space without unnecessary overflow")
	entry.free()
	await frames()
	var spatial = preload("res://addons/estragon/runtime/node/estragon_3d.gd").new()
	var button := Button.new()
	spatial.add_child(button)
	root.add_child(spatial)
	await frames()
	check(not Hosts.get("controls").has(button.get_instance_id()),"3D layout never adopts native Control pixels into world units")
	spatial.free()
	await frames()
	cleared("unsupported/cross-dimensional native boundaries leave no bridge records")

func examples() -> void:
	for name in ["NativeHome","NativeGallery"]:
		var node = load("res://examples/nested_layout/"+name+".tscn").instantiate()
		root.add_child(node)
		await frames()
		if name=="NativeHome":
			var button: Button = node.find_children("*","Button",true,false)[0]
			var texts: Array = []
			for child in node.find_children("*","",true,false):
				if child.get_script()==preload("res://addons/estragon/runtime/node/text.gd"): texts.append(child)
			check(button!=null and texts.size()==3 and texts[2].global_position.y>=button.global_position.y+button.size.y,"runnable owner native example has separated Exit/Rose")
		else:
			var borrowed: Button = node.get_node("SceneButton")
			check(borrowed.get_parent()==node and borrowed.owner==node and adapter(borrowed).participates() and borrowed.size.y>=40,"runnable gallery borrows its persistent native Control")
		capture(name)
		node.free()
		await frames()
	cleared("runnable examples release all bookkeeping")
	if failures==0: print("L04_EXAMPLES_OK")
