@tool
extends EditorPlugin
const Highlighter = preload("res://addons/estragon/editor/highlighter.gd")
const Services = preload("res://addons/estragon/editor/language_services.gd")
var interface: EditorInterface
var plugin: EditorPlugin
var home: CodeEdit
var original := ""
var e03_screen := ""
var failed := false
var checks := 0
var expected_text := "Hello Gogo"
var expected_base := ""
var creation_only := OS.get_environment("ESTRAGON_EDITOR_CREATION_ONLY") == "1"
const HOME := "res://app/Screens/Home.gogo"
const OUTPUT := "res://app/Screens/generated/Home.gd"
const PLUGIN := "res://addons/estragon/editor/plugin.cfg"
func _enter_tree() -> void:
	interface = get_editor_interface()
	_run.call_deferred()
func check(value: bool, label: String) -> void:
	checks += 1
	print("E02_EDITOR_CHECK ",label,": ",value)
	if not value: failed = true
func until(condition: Callable, label: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec() < deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,label)
	return false
func frames(count: int = 3) -> void:
	for index in range(count): await get_tree().process_frame
func capture(label: String) -> void:
	# Stock editors can stop drawing an unchanged viewport under native popups.
	# Request a synchronous frame rather than waiting forever for a future draw.
	await frames()
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://e02-"+label+".png")
func find_plugin() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node.get_script() != null and node.get_script().resource_path == PLUGIN.get_base_dir().path_join("plugin.gd"): plugin = node
	return plugin != null and plugin.last_report.get("ok",false) and not plugin._filesystem_busy() and not plugin._extensions_pending
func current(path: String) -> CodeEdit:
	if plugin == null or plugin._services == null: return null
	for entry in plugin._services.entries.values():
		var code = entry.code.get_ref()
		if entry.path == path and code != null and code.is_visible_in_tree(): return code
	return null
func tools_action(spatial: bool = false) -> bool:
	for menu in interface.get_base_control().find_children("*","PopupMenu",true,false):
		for index in range(menu.item_count):
			if menu.get_item_text(index) == "New Gogo Component ("+("3D" if spatial else "2D")+")…":
				menu.index_pressed.emit(index)
				return true
	return false
func create(path: String, spatial: bool = false) -> CodeEdit:
	var project_before := FileAccess.get_file_as_string("res://project.godot")
	var roots_before := FileAccess.get_file_as_string("res://gogo.config.json")
	if plugin._creation_menu != null:
		await filesystem_action(path.get_base_dir()+"/",false,2,spatial)
	else:
		interface.get_file_system_dock().navigate_to_path(path.get_base_dir()+"/")
		await frames()
		check(tools_action(spatial),"Project > Tools native action exists")
	if not await until(func(): return plugin._new_script.dialog.visible,"native file dialog visible"): return null
	check(plugin._new_script.dialog.current_dir.trim_suffix("/") == path.get_base_dir(),"creation retains exact selected directory")
	if path == HOME: await capture("creation")
	var dialog = plugin._new_script.dialog
	check(plugin._new_script.dimension.selected == (1 if spatial else 0),"creation action preselects requested 2D/3D host")
	dialog.current_path = path
	dialog.get_line_edit().text = path.get_file().get_basename() if path == HOME else path.get_file()
	dialog.get_ok_button().pressed.emit()
	if not await until(func(): return FileAccess.file_exists(path) and current(path) != null,"created source opens in stock ScriptEditor"): return null
	check(current(path).text == "extends "+("Node3D" if spatial else "Node2D")+"\n","new source is blank with no content, layout or unused imports")
	check(current(path).syntax_highlighter.get_script() == Highlighter and current(path).code_completion_enabled and plugin._services._gutter_index(current(path)) >= 0,"created authored source immediately has Gogo highlighting/completion/diagnostics")
	check(plugin._build(),"new component compiles without manual changes")
	var output: String = preload("res://addons/estragon/editor/build_service.gd").output_for(path)
	var script: Script = load(output)
	# Non-tool authored scripts cannot instantiate in editor context; actual
	# instantiation is proved separately by headless templates and child Play.
	check(script != null and script.get_instance_base_type() == ("Node3D" if spatial else "Node2D") and not script.get_script_method_list().any(func(method): return method.name == "build_view"),"blank component generated native metadata loads without a composition entry")
	check(FileAccess.get_file_as_string("res://project.godot") == project_before and FileAccess.get_file_as_string("res://gogo.config.json") == roots_before,"creation preserves project settings and configured source roots")
	return current(path)

# Test-only public control/input driving. Production registers the supported
# context slot and never searches or edits Godot's PopupMenus.
func menu_key(menu: PopupMenu, key: Key) -> void:
	var event := InputEventKey.new()
	event.window_id = menu.get_window_id()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()
func menu_click(menu: PopupMenu, index: int) -> void:
	# Locate the row by native hover feedback, without hardcoded theme metrics.
	menu.set_focused_item(-1)
	var point := Vector2(24,8)
	var found := false
	for y in range(8,menu.size.y-4,4):
		point.y = y
		var motion := InputEventMouseMotion.new()
		motion.window_id = menu.get_window_id()
		motion.position = point
		motion.global_position = Vector2(menu.position)+point
		motion.relative = Vector2(0,4)
		motion.velocity = Vector2(0,240)
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
		if menu.get_focused_item() == index:
			found = true
			break
	check(found,"native hover locates component menu row")
	if not found: return
	var event := InputEventMouseButton.new()
	event.window_id = menu.get_window_id()
	event.position = point
	event.global_position = Vector2(menu.position)+point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()
func filesystem_action(directory: String, empty: bool = false, expected_count: int = 2, spatial: bool = false) -> void:
	var dock := interface.get_file_system_dock()
	dock.navigate_to_path(directory)
	await frames(8)
	var tree: Tree
	for candidate in dock.find_children("*","Tree",true,false):
		var item: TreeItem = candidate.get_selected()
		if candidate.is_visible_in_tree() and item != null and str(item.get_metadata(0)).trim_suffix("/") == directory.trim_suffix("/"):
			tree = candidate
			break
	check(tree != null,"exact FileSystem folder selected for context input")
	if tree == null: return
	tree.get_window().grab_focus()
	if tree.has_method("scroll_to_item"): tree.call("scroll_to_item",tree.get_selected())
	else: tree.ensure_cursor_is_visible()
	await frames()
	# Authenticate the input row after layout/scroll changes (e.g. child Play
	# opens the Output panel). Never assume an unscrolled rectangle is clickable.
	var point := Vector2(tree.size.x/2,-1)
	for y in range(8,int(tree.size.y)-12,2):
		if tree.get_item_at_position(Vector2(point.x,y)) == tree.get_selected():
			point.y = y+2
			break
	check(point.y >= 0,"native hit testing locates selected folder row")
	if point.y < 0: return
	if empty:
		# Make genuinely empty space, independent of folder count/scroll position.
		tree.get_selected().collapsed = true
		await frames()
		point = Vector2(tree.size.x/2,tree.size.y-24)
		check(tree.get_item_at_position(point) == null,"empty-space input misses every tree item")
	var motion := InputEventMouseMotion.new()
	motion.position = tree.global_position+point
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(5)
	var popup: PopupMenu
	for candidate in dock.find_children("*","PopupMenu",true,false):
		if candidate.visible: popup = candidate; break
	check(popup != null,"native FileSystem right-click opens menu")
	if popup == null: return
	if not empty:
		var submenu := -1
		for index in range(popup.item_count):
			if popup.get_item_text(index).begins_with("Create New"): submenu = index
		check(submenu >= 0,"native Create New submenu present")
		if submenu < 0: popup.hide(); return
		popup.set_focused_item(submenu)
		await menu_key(popup,KEY_RIGHT)
		popup = popup.get_node(NodePath(popup.get_item_submenu(submenu)))
		if not await until(func(): return popup.visible,"native Create New submenu opens"): return
	var matches: Array[int] = []
	var ordinary_script := false
	var ordinary_text := false
	for index in range(popup.item_count):
		var label := popup.get_item_text(index)
		if label in ["Gogo Component (2D)…","New Gogo Component (2D)…","Gogo Component (3D)…","New Gogo Component (3D)…"]: matches.append(index)
		ordinary_script = ordinary_script or label in ["Script...","New Script..."]
		ordinary_text = ordinary_text or label in ["TextFile...","New TextFile..."]
	check(matches.size() == expected_count,"exactly expected owned creation actions")
	check(ordinary_script and ordinary_text,"native Script and TextFile actions preserved")
	await capture("filesystem-"+("empty" if empty else "folder")+"-"+str(expected_count))
	# PopupMenus are separate native windows and absent from the main viewport.
	popup.get_texture().get_image().save_png("res://e02-native-menu-"+("empty" if empty else "folder")+"-"+str(expected_count)+".png")
	if matches.size() != 2: popup.hide(); return
	var chosen := -1
	for index in matches:
		if popup.get_item_text(index).contains("(3D)" if spatial else "(2D)"): chosen = index
	check(chosen >= 0,"native menu contains requested dimension action")
	if chosen < 0: popup.hide(); return
	await menu_click(popup,chosen)
	if await until(func(): return plugin._new_script.dialog.visible,"native menu activates shared component dialog"):
		check(plugin._new_script.dialog.current_dir.trim_suffix("/") == ("res:/" if empty else directory.trim_suffix("/")),"context callback uses actual folder/root")
func set_source(code: CodeEdit, text: String) -> void:
	var marker := text.find("§")
	var left := text.left(marker)
	code.text = text.replace("§","")
	code.set_caret_line(left.count("\n"))
	code.set_caret_column(left.get_slice("\n",left.count("\n")).length())
	code.grab_focus()
func complete(text: String, option: String, inserted: String, label: String, selected_prefix: bool = false) -> void:
	set_source(home,text)
	if selected_prefix: home.select(home.get_caret_line(),home.get_caret_column()-2,home.get_caret_line(),home.get_caret_column())
	await frames()
	home.request_code_completion(true)
	if not await until(func(): return not home.get_code_completion_options().is_empty(),label+" popup opens"): return
	var options := home.get_code_completion_options()
	var selected := -1
	for index in range(options.size()):
		if options[index].display_text == option or options[index].display_text.begins_with(option+" "): selected = index
	check(selected >= 0,label+" native popup contains expected candidate")
	if selected < 0: return
	if label == "imported tag": await capture("completion")
	var before := home.text
	var before_row := home.get_caret_line()
	var before_column := home.get_caret_column()
	home.set_code_completion_selected_index(selected)
	if label == "E03 Text import":
		await action("ui_down")
		check(home.get_code_completion_selected_index()!=selected,"native popup keyboard navigation")
		await action("ui_up")
		check(home.get_code_completion_selected_index()==selected,"native popup keyboard selection restored")
		await action("ui_text_completion_accept")
	else: home.confirm_code_completion()
	check(home.text.contains(inserted),label+" native confirmation inserts correct text")
	home.undo()
	check(home.text == before,label+" insertion/imports are one undoable operation")
	check(home.get_caret_line()==before_row and home.get_caret_column()==before_column,label+" undo restores caret")
	if selected_prefix: check(home.has_selection() and home.get_selected_text()=="Te","undo restores selected prefix")
	home.redo()
	check(home.text.contains(inserted),label+" insertion redo")
func color(code: CodeEdit, row: int, column: int) -> Color:
	var colors: Dictionary = code.syntax_highlighter.get_line_syntax_highlighting(row)
	var keys := colors.keys()
	keys.sort()
	var result := Color.WHITE
	for key in keys:
		if key <= column: result = colors[key].color
	return result
func native_reference(text: String, row: int, column: int) -> Color:
	var edit := TextEdit.new()
	edit.text = text
	edit.syntax_highlighter = ClassDB.instantiate("GDScriptSyntaxHighlighter")
	var colors := edit.syntax_highlighter.get_line_syntax_highlighting(row)
	var keys := colors.keys()
	keys.sort()
	var result := Color.WHITE
	for key in keys:
		if key <= column: result = colors[key].color
	edit.free()
	return result
func authored_view() -> String:
	# Deliberately authored test UI, independent of the blank creation service.
	var body := 'extends Node2D\n\nfunc build_view() -> Element:\n\treturn <Entry2D name="UI" viewport_width_scale={0.9}>\n\t\t<Text name="Greeting" text="Hello Gogo" />\n\t</Entry2D>\n'
	var plan := preload("res://addons/estragon/editor/completion.gd").new().import_plan(body,HOME)
	var lines := body.split("\n")
	lines.insert(plan.row,plan.text.trim_suffix("\n"))
	return "\n".join(lines)
func attach_home(text: String) -> void:
	home.text = text
	check(plugin._build(),"native save/build before scene attachment")
	var host := Node2D.new()
	host.name = "Home"
	host.set_script(load(OUTPUT))
	var packed := PackedScene.new()
	packed.pack(host)
	ResourceSaver.save(packed,"res://app/Home.tscn")
	host.free()
	ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
	ProjectSettings.save()
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/Home.tscn","attached scene opens")
func blank_play() -> void:
	# The observer is a sibling, leaving the generated component untouched.
	for path in [HOME,"res://app/Screens/Nested/Spatial.gogo"]:
		var output: String = preload("res://addons/estragon/editor/build_service.gd").output_for(path)
		var spatial: bool = path != HOME
		var host: Node = Node3D.new() if spatial else Node2D.new()
		host.name = "Component"
		host.set_script(load(output))
		var scene := Node.new()
		scene.name = "Blank"
		scene.add_child(host)
		host.owner = scene
		var observer := Node.new()
		observer.name = "Observer"
		observer.set_script(preload("blank_game.gd"))
		scene.add_child(observer)
		observer.owner = scene
		var packed := PackedScene.new()
		packed.pack(scene)
		var scene_path := "res://app/Blank"+("3D" if spatial else "2D")+".tscn"
		ResourceSaver.save(packed,scene_path)
		scene.free()
		ProjectSettings.set_setting("application/run/main_scene",scene_path)
		ProjectSettings.save()
		interface.open_scene_from_path(scene_path)
		await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path==scene_path,"blank component scene opens")
		expected_text = "blank"
		expected_base = "Node3D" if spatial else "Node2D"
		for mode in ["main","current"]: await play(mode)
	expected_text = "Hello Gogo"
	expected_base = ""
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return to newly created blank source after Play")
	home = current(HOME)
	check(home.text == "extends Node2D\n" and plugin._build(),"untouched blank source saves/builds after native Play")
func proof() -> bool:
	if not FileAccess.file_exists("res://.godot/e02-game.json"): return false
	var json := JSON.new()
	return json.parse(FileAccess.get_file_as_string("res://.godot/e02-game.json")) == OK and json.data is Dictionary and json.data.get("text") == expected_text and (expected_text != "blank" or json.data.get("children") == 0 and json.data.get("base") == expected_base)
func play(mode: String) -> void:
	if FileAccess.file_exists("res://.godot/e02-game.json"): DirAccess.remove_absolute("res://.godot/e02-game.json")
	if mode == "main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(proof,mode+" child game runs created Gogo",20): check(interface.is_playing_scene(),mode+" native child active")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"child stopped")
func blocked(mode: String, unsavable: bool = false) -> void:
	if unsavable: print("E02_EXPECTED_UNSAVABLE_BEGIN")
	var bytes := FileAccess.get_file_as_bytes(OUTPUT)
	var maps := FileAccess.get_file_as_bytes(OUTPUT+".map.json")
	var stamp := FileAccess.get_modified_time(OUTPUT)
	var uid := FileAccess.get_file_as_bytes(OUTPUT+".uid") if FileAccess.file_exists(OUTPUT+".uid") else PackedByteArray()
	var cached = load(OUTPUT)
	var source: String = cached.source_code
	home.text = original+"\n# edited unsavable buffer\n" if unsavable else original.replace('</Entry>','</Wrong>').replace('</Entry2D>','</Wrong>')
	if mode == "main": interface.play_main_scene()
	else: interface.play_current_scene()
	await get_tree().create_timer(0.8).timeout
	check(not interface.is_playing_scene() and not plugin.last_report.ok,mode+(" unsavable" if unsavable else " invalid")+" source blocks Play")
	check(FileAccess.get_file_as_bytes(OUTPUT)==bytes and FileAccess.get_file_as_bytes(OUTPUT+".map.json")==maps and FileAccess.get_modified_time(OUTPUT)==stamp,"failed Play preserves bytes/maps/timestamp")
	check((FileAccess.get_file_as_bytes(OUTPUT+".uid") if FileAccess.file_exists(OUTPUT+".uid") else PackedByteArray())==uid and load(OUTPUT)==cached and cached.source_code==source,"failed Play preserves UID/Script identity")
	if unsavable: print("E02_EXPECTED_UNSAVABLE_END")
func action(name: String) -> void:
	for event in InputMap.action_get_events(name):
		if event is InputEventKey:
			var key = event.duplicate()
			key.pressed = true
			Input.parse_input_event(key)
			await frames()
			key.pressed = false
			Input.parse_input_event(key)
			return
	check(false,"native key binding available: "+name)
func _e03() -> String:
	color(home,0,0)
	var capabilities := {"engine":Engine.get_version_info().string,"native_highlighter_class":ClassDB.class_exists("GDScriptSyntaxHighlighter"),"native_highlighter_available":ClassDB.class_exists("GDScriptSyntaxHighlighter") and ClassDB.can_instantiate("GDScriptSyntaxHighlighter"),"native_highlighter_used":home.syntax_highlighter.uses_native(),"acceptance_virtual_attached":home.get_script()!=null,"native_analyzer":ClassDB.class_has_method("GDScript","complete_code"),"cached_reference_api":ResourceLoader.has_method("get_cached_ref"),"symlink_api":DirAccess.open("res://").has_method("is_link")}
	var file := FileAccess.open("res://e03-editor-capabilities.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(capabilities,"\t"))
	file.close()
	print("E03_EDITOR_CAPABILITIES ",JSON.stringify(capabilities))
	check(capabilities.native_highlighter_used==capabilities.native_highlighter_available,"native GDScript highlighter reused where exposed")
	var blank := 'extends Node2D\n\nfunc build_view() -> Element:\n\treturn <Te§ name="Greeting" text="Hello Gogo" />\n'
	set_source(home,blank)
	await frames()
	var unchanged := home.text
	home.request_code_completion(true)
	if await until(func(): return not home.get_code_completion_options().is_empty(),"E03 installed Text discoverable before any import"):
		check(home.get_code_completion_options().any(func(o): return o.display_text.begins_with("Text — EstragonText")),"Text catalog identifies actual Estragon widget")
		check(home.text == unchanged and not home.text.contains("preload("),"candidate display never inserts imports")
		home.cancel_code_completion()
		check(home.text == unchanged,"cancel never edits source")
	var source := 'extends Node2D\n\nfunc build_view() -> Element:\n\treturn <Ent§ name="UI" viewport_width_scale={0.9}>\n\t\t<VB name="Box">\n\t\t\t<Te name="Greeting" text="Hello Gogo" />\n\t\t</VBox>\n\t</Entry2D>\n'
	await complete(source,"Entry2D","<Entry2D name=","E03 entry and Element automatic imports")
	check(home.text.contains("const Entry2D = preload(") and home.text.contains("const Element = preload("),"entry acceptance imports real layout and Element")
	await complete(home.text.replace('<VB name=','<VB§ name='),"VBox","<VBox name=","E03 VBox import")
	await complete(home.text.replace('<Te name=','<Te§ name='),"Text","<Text name=","E03 Text import")
	var screen := home.text
	check(screen.count("const Text = preload(")==1 and screen.count("const Element = preload(")==1 and not screen.contains('res://addons/estragon'),"first screen resolves installed resources without manual paths")
	await capture("imports")
	await complete(screen.replace('</VBox>','<Te§ name="Second" text="Again" />\n\t\t</VBox>'),"Text","<Text name=\"Second\"","E03 repeated component")
	check(home.text.count("const Text = preload(")==1,"repeated acceptance reuses import")
	home.symbol_lookup.emit("Text",0,0)
	if await until(func(): return interface.get_script_editor().get_current_script()!=null and interface.get_script_editor().get_current_script().resource_path.ends_with("/runtime/node/text.gd"),"E03 alias lookup opens its real Script"):
		check(interface.get_script_editor().get_current_script().resource_path.contains("node_modules/"),"alias navigation targets direct installation")
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return from alias definition")
	home = current(HOME)
	var manual := screen.replace('const Text =','const FancyText =').replace('<Text name=','<FancyText name=')
	await complete(manual.replace('<FancyText name=','<Te§ name='),"Text","<FancyText name=","E03 manual alias reuse")
	check(home.text.count("const FancyText = preload(")==1 and not home.text.contains("const Text ="),"manual preload reused without duplicate")
	await complete(blank.replace('func build_view()', 'var Text: int = 1\nfunc build_view()'),"Text","<EstragonText name=","E03 collision chooses explicit canonical alias")
	check(home.text.contains("var Text: int = 1") and home.text.contains("const EstragonText = preload("),"collision preserves authored declaration")
	set_source(home,'extends Node2D\nfunc view():\n\treturn <Re§ />\n')
	home.request_code_completion(true)
	check(home.get_code_completion_options().any(func(o): return o.display_text=="Rect — project Node"),"unrelated project global class remains discoverable")
	home.cancel_code_completion()
	await complete('extends Node2D\nfunc build_view() -> Element:\n\treturn <Re§ name="Box" />\n',"Rect (as EstragonRect)","<EstragonRect name=","E03 project global collision")
	check(home.text.contains("const EstragonRect = preload(") and not home.text.contains("const Rect ="),"project global collision keeps explicit distinct imports")
	await complete('extends Node2D\nfunc build_view() -> Ele§:\n\treturn null\n',"Element","-> Element:","E03 explicit Element type import")
	set_source(home,'extends Node2D\nfunc view():\n\treturn <Bu§ />\n')
	home.request_code_completion(true)
	if await until(func(): return not home.get_code_completion_options().is_empty(),"native Button catalog"):
		check(home.get_code_completion_options().any(func(o): return o.display_text.begins_with("Button — Godot")),"Godot Button remains native, not UiButton")
	home.cancel_code_completion()
	await complete('extends Node2D\nconst Example = preload("res://app/Ord§")\n', '"res://app/Ordinary.gd"','preload("res://app/Ordinary.gd")',"E03 real resource path")
	set_source(home,'extends Node2D\nvar arbitrary = "res://app/Ord§"\n')
	home.request_code_completion(true)
	check(home.get_code_completion_options().is_empty(),"ordinary strings do not get resource candidates")
	set_source(home,'extends Node2D\nfunc demo():\n\trotate(§)\n')
	await frames()
	check(plugin._services.entries[home.get_instance_id()].hint.contains("radians: float"),"native ClassDB callable signature displayed")
	await capture("call-hint")
	await complete('extends Node2D\nvar offset: Vec§\n',"Vector2","offset: Vector2","E03 engine builtin type names")
	await complete('extends Node2D\nfunc demo(camera: Camera2D):\n\tvar local: Camera2D\n\tlocal.zo§\n',"zoom","local.zoom","E03 typed local variable")
	# Other authenticated unsaved Gogo source is authoritative, without new().
	# A code-only model starts as code-only source. Native class-removal cache
	# behavior is independently reproduced by probe.gd, without cache repair.
	var model_file := FileAccess.open("res://app/Screens/LiveModel.gogo",FileAccess.WRITE)
	model_file.store_string("extends Node2D\nvar saved_speed: float = 1.0\n")
	model_file.close()
	interface.get_resource_filesystem().scan()
	await until(func(): return not plugin._filesystem_busy(),"code-only model filesystem scan")
	await plugin._navigation.open("res://app/Screens/LiveModel.gogo")
	await until(func(): return current("res://app/Screens/LiveModel.gogo")!=null,"code-only model opens")
	var model := current("res://app/Screens/LiveModel.gogo")
	if model != null:
		model.text = 'extends Node2D\n@export var unsaved_speed: float = 1.0\nfunc _init():\n\tpush_error("AUTHORED_MODEL_MUST_NOT_EXECUTE_FOR_COMPLETION")\n'
		await plugin._navigation.open(HOME)
		await until(func(): return current(HOME)!=null,"return from live model")
		home = current(HOME)
		await complete('extends Node2D\nconst Model = preload("LiveModel.gd")\nvar model: Model\nfunc demo():\n\tmodel.uns§\n',"unsaved_speed","model.unsaved_speed","E03 other unsaved Gogo metadata")
		await complete('extends Node2D\nconst Custom = preload("LiveModel.gd")\nfunc build_view() -> Element:\n\treturn <Cu§ />\n',"Custom","<Custom />","E03 explicit custom Node tag without constructor execution")
		# Restore a harmless valid source before the existing save/Play checks.
		model.text = 'extends Node2D\nvar saved_speed: float = 1.0\n'
	await complete('@tool\nextends Node2D\n# copyright café 😀\nfunc build_view() -> Element:\n\treturn <Te§ text="Unicode" />\n',"Text","<Text text=","E03 Unicode selection/import placement",true)
	check(home.text.begins_with("@tool\nextends Node2D\nconst Element") and home.text.contains("# copyright café 😀"),"imports preserve annotations/header/comments")
	set_source(home,blank)
	await frames()
	# Explicit public Tools action also repairs typed, unbound component names.
	home.text = blank.replace("§","").replace("<Te ","<Text ")
	var before_fix := home.text
	for menu in interface.get_base_control().find_children("*","PopupMenu",true,false):
		for index in range(menu.item_count):
			if menu.get_item_text(index)=="Add Missing Gogo Imports": menu.index_pressed.emit(index)
	check(home.text.contains("const Text = preload(") and home.text.contains("const Element = preload("),"explicit missing-import action")
	home.undo()
	check(home.text==before_fix,"explicit import repair is one undoable operation")
	home.text = screen
	return screen
func _run() -> void:
	if not await until(find_plugin,"installed addon activated"): finish(); return
	var editor_settings := interface.get_editor_settings()
	if creation_only:
		# Isolated test preference: allow normal saved-source refresh on focus.
		editor_settings.set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if editor_settings.has_setting("run/window_placement/game_embed_mode"):
		editor_settings.set_setting("run/window_placement/game_embed_mode",-1)
		get_tree().root.propagate_notification(EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED)
		await frames()
	if FileAccess.file_exists("res://.godot/e02-restart.request"):
		if plugin._creation_menu != null:
			await filesystem_action("res://app/Screens/")
			plugin._new_script.dialog.hide()
		await plugin._navigation.open(HOME)
		if await until(func(): return current(HOME)!=null,"restart authenticates restored Gogo tab"):
			home = current(HOME)
			original = home.text
			await complete(original.replace('return <Entry','self.glo§\n\treturn <Entry'),"global_position","self.global_position","restart completion")
			home.text = original
			await play("main")
		finish()
		return
	interface.get_editor_settings().set_setting("run/auto_save/save_before_running",false)
	check((plugin._creation_menu != null) == plugin.has_method("add_context_menu_plugin"),"native hook availability matches engine; 4.0 uses Tools fallback")
	home = await create(HOME)
	if home == null: finish(); return
	await capture("blank-source")
	# Cancel and rejected paths exercise the native dialog without touching source.
	check(tools_action(),"creation menu can be reopened")
	plugin._new_script.dialog.current_path = "res://app/Screens/Cancelled.gogo"
	plugin._new_script.dialog.get_cancel_button().pressed.emit()
	await frames()
	check(not FileAccess.file_exists("res://app/Screens/Cancelled.gogo"),"cancel creates no source")
	check(tools_action(true),"Tools exposes separate 3D creation action")
	check(plugin._new_script.dimension.selected == 1,"Tools 3D action preselects Node3D")
	plugin._new_script.dialog.get_cancel_button().pressed.emit()
	if plugin._creation_menu != null:
		await filesystem_action("res://",true)
		plugin._new_script.dialog.get_cancel_button().pressed.emit()
		await filesystem_action("res://")
		plugin._new_script.dialog.get_cancel_button().pressed.emit()
	for rejected in ["res://app/Existing.gogo","res://tests/Rejected.gogo","res://app/Screens/Bad.txt"]:
		var existing := FileAccess.get_file_as_string("res://app/Existing.gogo")
		tools_action()
		plugin._new_script.dialog.current_path = rejected
		plugin._new_script.dialog.get_line_edit().text = rejected.get_file()
		plugin._new_script.dialog.get_ok_button().pressed.emit()
		await frames()
		# 4.0 FileDialog lacks the overwrite-warning toggle. Accept its native
		# warning and prove Estragon still refuses to write existing source.
		if rejected.ends_with("Existing.gogo") and plugin._new_script.dialog is FileDialog:
			for warning in plugin._new_script.dialog.find_children("*","ConfirmationDialog",true,false):
				if warning.visible: warning.get_ok_button().pressed.emit()
			await frames()
		check(plugin._new_script.error.visible,"existing/ignored creation visibly rejected")
		check(FileAccess.get_file_as_string("res://app/Existing.gogo")==existing and not FileAccess.file_exists("res://tests/Rejected.gogo"),"rejected creation preserves source")
		check(not FileAccess.file_exists("res://app/Screens/Bad.txt") and not FileAccess.file_exists("res://app/Screens/Bad.txt.gogo"),"bad extension leaves no source or silently suffixed file")
		plugin._new_script.error.hide()
		plugin._new_script.dialog.hide()
	var spatial := await create("res://app/Screens/Nested/Spatial.gogo",true)
	check(spatial != null and spatial.text == "extends Node3D\n","second Gogo tab is a blank spatial component")
	await capture("blank-spatial-source")
	if creation_only: await blank_play()
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return to Home tab")
	home = current(HOME)
	original = authored_view()
	home.text = original
	check(plugin._build(),"developer can author a root view after blank creation")
	e03_screen = original if creation_only else await _e03()
	home.text = original
	check(original.contains('build_view() -> Element') and not original.contains('res://addons/estragon'),"explicitly authored view imports actual installation relatively")
	var model := original.replace('func build_view()', 'var greeting: String = "Hello"\nvar camera: Camera2D\nsignal accepted\nfunc build_view()')
	await complete(model.replace('<Text name=', '<Te§ name='),"Text","<Text name=","imported tag")
	await complete(model.replace('viewport_width_scale','view§'),"viewport_width_scale","viewport_width_scale","known attribute")
	await complete(model.replace('return <Entry', 'self.glo§\n\treturn <Entry'),"global_position","self.global_position","self native member")
	await complete(model.replace('text="Hello Gogo"','text={self.gree§}'),"greeting","self.greeting","GGX expression member")
	await complete(model.replace('return <Entry','camera.zo§\n\treturn <Entry'),"zoom","camera.zoom","typed native member")
	await complete(model.replace('</Entry2D>','</Ent§>'),"/Entry2D","</Entry2D>","closing tag")
	set_source(home,model.replace('return <Entry','self.glo§\n\treturn <Entry'))
	await frames()
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_SPACE
	shortcut.ctrl_pressed = true
	shortcut.pressed = true
	Input.parse_input_event(shortcut)
	await until(func(): return not home.get_code_completion_options().is_empty(),"native Ctrl+Space requests completion")
	home.cancel_code_completion()
	for source in ['# <Node self.§','var text = "self.§"']:
		set_source(home,source)
		home.request_code_completion(true)
		check(home.get_code_completion_options().is_empty(),"comments/strings suppress popup")
	set_source(home,model.replace('return <Entry','self§\n\treturn <Entry'))
	home.insert_text_at_caret(".")
	if await until(func(): return not home.get_code_completion_options().is_empty(),"automatic dot completion"): home.cancel_code_completion()
	home.text = original
	await frames()
	# Live replacement, editing and undo must update the actual tab's palette.
	set_source(home,'extends Node2D\n@bindable\nvar café: Vector2 = Vector2.ZERO\nfunc view():\n\treturn <Node name={1 < 2}>{[<Node />]}<!-- comment\ncontinued --></Node>\nvar literal = "<Node />"\nvar multi = """start\n<Node />\n"""\n§')
	await frames()
	var live = home.syntax_highlighter
	var type_color: Color = native_reference("var café: Vector2 = Vector2.ZERO",0,10) if live.uses_native() else live.color("type")
	check(color(home,1,1)==live.color("annotation") and color(home,2,10)==type_color,"annotation and native/fallback type-hint theme colors")
	check(color(home,4,22)==live.color("symbol") and color(home,5,0)==live.color("comment"),"comparison remains code; multiline GGX comment")
	check(color(home,6,16)==live.color("string") and color(home,8,0)==live.color("string"),"quoted markup and multiline string stay strings")
	home.set_caret_line(8)
	home.set_caret_column(0)
	home.insert_text_at_caret('"""')
	await frames()
	check(color(home,8,3)!=live.color("string"),"live closing quote changes following scope")
	home.undo()
	await frames()
	check(color(home,8,0)==live.color("string"),"undo restores multiline scope")
	home.redo()
	await frames()
	check(color(home,8,3)!=live.color("string"),"redo updates scope again")
	home.text = original
	await frames()
	var highlighter = home.syntax_highlighter
	check(highlighter.get_script()==Highlighter,"stock authenticated tab uses Gogo highlighter")
	check(color(home,0,0)==highlighter.color("keyword"),"GDScript theme keyword color")
	check(plugin._services.entries[home.get_instance_id()].model.metadata_reads>0,"already-held Script metadata reused without authored load/new")
	var settings := interface.get_editor_settings()
	var old_color: Color = settings.get_setting("text_editor/theme/highlighting/keyword_color")
	settings.set_setting("text_editor/theme/highlighting/keyword_color",Color(0.9,0.2,0.1))
	highlighter.update_cache()
	check(color(home,0,0)==Color(0.9,0.2,0.1),"theme setting changes reflected")
	settings.set_setting("text_editor/theme/highlighting/keyword_color",old_color)
	highlighter.update_cache()
	home.text = original.replace('</Entry2D>','</Wrong>')
	if await until(func(): return home.get_line_gutter_text(home.get_line_count()-2,plugin._services._gutter_index(home))=="!","authored syntax diagnostic gutter"):
		await capture("diagnostic")
		var record: Dictionary = plugin._services.entries[home.get_instance_id()].records[0]
		plugin._diagnostics.meta_clicked.emit(record)
		await frames()
		check(home.get_caret_line()==record.line-1,"panel link navigates authored Gogo line")
	check(FileAccess.get_file_as_string(HOME)==original,"idle analysis never writes incomplete buffer")
	home.text = original
	await get_tree().create_timer(0.6).timeout
	check(plugin._services.entries[home.get_instance_id()].records.is_empty(),"repair clears markers")
	home.text = 'extends Node2D\nfunc view():\n\treturn <Node name="😀"></Wrong>\n'
	if await until(func(): return not plugin._services.entries[home.get_instance_id()].records.is_empty(),"Unicode syntax diagnostic"):
		var record: Dictionary = plugin._services.entries[home.get_instance_id()].records[0]
		await plugin._services.navigate(record)
		check(home.get_caret_column()==Services.scalar_column(home.get_line(record.line-1),record.column),"UTF-16 span navigates Unicode CodeEdit column")
		check(home.get_caret_column()<record.column-1,"non-BMP source position is converted")
	home.text = original
	interface.edit_script(load("res://app/Ordinary.gd"))
	await frames(8)
	var ordinary: CodeEdit = interface.get_script_editor().get_current_editor().get_base_editor()
	check(ordinary != home and ordinary.syntax_highlighter.get_script()!=Highlighter,"ordinary gd retains native highlighter")
	check(not plugin._services.entries.has(ordinary.get_instance_id()) and plugin._services._gutter_index(ordinary)<0,"ordinary gd has no Gogo services/gutter")
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return to Home tab")
	home = current(HOME)
	original = e03_screen
	var attached := original+'\nfunc _ready() -> void:\n\tif not Engine.is_editor_hint(): _game_proof.call_deferred()\nfunc _game_proof() -> void:\n\tawait get_tree().process_frame\n\tawait get_tree().process_frame\n\tawait RenderingServer.frame_post_draw\n\tget_viewport().get_texture().get_image().save_png(\"res://e03-game.png\")\n\tvar output := FileAccess.open("res://.godot/e02-game.json",FileAccess.WRITE)\n\toutput.store_string(JSON.stringify({"text":get_node("UI").find_child("Greeting",true,false).text}))\n\toutput.close()\n'
	await attach_home(attached)
	check(not preload("res://addons/estragon/editor/components.gd").named("Element").script.resource_path.is_empty(),"framework Script path preserved after build")

	original = attached
	for mode in ["main","current"]:
		await play(mode)
		if creation_only: continue
		await blocked(mode)
		home.text = original
		await play(mode)
		DirAccess.rename_absolute(HOME,HOME+".backup")
		DirAccess.make_dir_absolute(HOME)
		await blocked(mode,true)
		DirAccess.remove_absolute(HOME)
		DirAccess.rename_absolute(HOME+".backup",HOME)
		home.text = original
		await play(mode)
	var count := home.code_completion_requested.get_connections().size()
	interface.set_plugin_enabled(PLUGIN,false)
	await frames()
	if has_method("add_context_menu_plugin"): await filesystem_action("res://app/Screens/",false,0)
	check(not home.code_completion_enabled and home.code_completion_requested.get_connections().size()<count,"disable removes Gogo handlers/completion")
	var gutter_exists := false
	for index in range(home.get_gutter_count()): gutter_exists = gutter_exists or home.get_gutter_name(index)==Services.GUTTER
	check(not gutter_exists,"disable removes only own diagnostic gutter")
	plugin = null
	interface.set_plugin_enabled(PLUGIN,true)
	if await until(find_plugin,"re-enable reattaches editor services"):
		if plugin._creation_menu != null:
			await filesystem_action("res://app/Screens/")
			plugin._new_script.dialog.hide()
		await plugin._navigation.open(HOME)
		await until(func(): return current(HOME)!=null,"visible Gogo tab reauthenticated")
		check(home.code_completion_enabled,"re-enabled completion")
	if not failed:
		var restart := FileAccess.open("res://.godot/e02-restart.request",FileAccess.WRITE)
		restart.store_string("restart")
		restart.close()
	await capture("editor")
	finish()
func finish() -> void:
	print("E02_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("E02_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
