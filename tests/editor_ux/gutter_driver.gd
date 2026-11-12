@tool
extends "chain_driver.gd"
const SETTINGS := "res://app/Screens/Settings.gogo"
const ROSE := "res://app/Screens/Rose.gogo"
func chain_source() -> String:
	return Fixture.header(HOME,"Node2D",["Element","Entry2D","VBox","Text"])+'''func exit() -> void:
	get_tree().qu
func build_view() -> Element:
	return <Entry2D name="UI"><VBox name="Column" gap={4.0}><Text name="Hello" text="Hello World!" /><Text text="This is fun!" /><Settings name="Settings" /><Rose name="Rose" /></VBox></Entry2D>
func _ready() -> void:
	if OS.get_environment("ESTRAGON_E10_GAME")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var button = get_node("UI/Column/Settings/Row/Exit")
	var rose = get_node("UI/Column/Rose/Caption")
	get_viewport().get_texture().get_image().save_png("res://e02-gutter-game.png")
	print("E11_GAME_GEOMETRY ",button.global_position," ",button.layout_size," Rose ",rose.global_position," ",rose.layout_size)
	if button.layout_size.y<=0 or rose.global_position.y<button.global_position.y+button.layout_size.y: push_error("E11 button layout failed"); return
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
'''
func phase(code: CodeEdit, label: String) -> void:
	var gutters: Array = []
	for index in range(code.get_gutter_count()): gutters.append({"index":index,"name":code.get_gutter_name(index),"type":code.get_gutter_type(index),"draw":code.is_gutter_drawn(index)})
	print("E11_PHASE ",label," ",JSON.stringify({"lines":code.get_line_count(),"gutters":gutters,"editable":code.editable,"script":str(code.get_script())}))
func native_tab(path: String) -> CodeEdit:
	interface.edit_script(load(path))
	interface.set_main_screen_editor("Script")
	await frames(10)
	return interface.get_script_editor().get_current_editor().get_base_editor() as CodeEdit
func _run() -> void:
	if not await until(find_plugin,"addon activates for E11"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	code_source = chain_source().replace('get_tree().qu','var file := FileAccess.open("res://.godot/e10-exited",FileAccess.WRITE)\n\tfile.store_string("exit")\n\tfile.close()\n\tget_tree().quit()')
	Fixture.write(HOME,code_source)
	Fixture.write(SETTINGS,Fixture.header(SETTINGS,"Node2D",["Element","HBox","UiButton"])+'''func exit() -> void:
	var file := FileAccess.open("res://.godot/e10-exited",FileAccess.WRITE)
	file.store_string("exit")
	file.close()
	get_tree().quit()
func build_view() -> Element:
	return <HBox name="Row"><UiButton name="Exit" text="Exit" pressed={self.exit} /></HBox>
''')
	Fixture.write(ROSE,Fixture.header(ROSE,"Node2D",["Element","Text"])+'''func build_view() -> Element:
	return <Text name="Caption" text="Rose is cute!" />
''')
	interface.get_resource_filesystem().scan()
	await native_turn()
	check(plugin._build_sources(),"E11 fixture builds")
	interface.get_resource_filesystem().scan()
	await native_turn()
	for path in [HOME,SETTINGS,ROSE]:
		await plugin._navigation.open(path)
		if not await until(func(): return current(path)!=null,"native source tab opens"): finish(); return
		var code := current(path)
		phase(code,path)
		for iteration in range(3):
			code.text += "# E11 edit\n"
			code.set_line_as_breakpoint(1,true)
			code.set_line_as_bookmarked(2,true)
			await frames(5)
			check(plugin._build_sources(),"source edit/save rebuild "+str(iteration))
		phase(code,"edited "+path)
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"Home for completion")
	home = current(HOME)
	await accepts(code_source.replace("get_tree().quit()","get_tree().qu§"),"quit","get_tree().quit()","E11 native quit completion")
	home.text = code_source
	check(plugin._build_sources(),"restore source after completion")
	var output := "res://app/Screens/generated/Settings.gd"
	var generated := await native_tab(output)
	await frames(10)
	phase(generated,"generated read-only")
	generated.set_line_as_breakpoint(2,true)
	check(not generated.editable and generated.get_breakpointed_lines().has(2),"generated protection retains native breakpoint")
	await plugin._navigation.open(SETTINGS)
	await until(func(): return current(SETTINGS)!=null,"Settings rebuild")
	current(SETTINGS).text += "# refresh generated view\n"
	check(plugin._build_sources(),"generated no-op/changed native view refresh")
	generated = await native_tab(output)
	phase(generated,"generated refreshed")
	var ordinary_path := "res://app/Ordinary.gd"
	Fixture.write(ordinary_path,"extends Node2D\nfunc demo():\n\tget_tree()\n")
	var ordinary := await native_tab(ordinary_path)
	phase(ordinary,"ordinary native script")
	ordinary.set_line_as_breakpoint(1,true)
	await frames(5)
	check(not plugin._services.entries.has(ordinary.get_instance_id()),"ordinary native tab has no Gogo service")
	for iteration in range(3):
		for path in [HOME,ROSE,SETTINGS]:
			await plugin._navigation.open(path)
			await until(func(): return current(path)!=null,"tab switch "+path)
			phase(current(path),"switch "+str(iteration))
		await native_tab(output)
	await plugin._navigation.open(SETTINGS)
	await until(func(): return current(SETTINGS)!=null,"Settings completion/source navigation")
	var authored := current(SETTINGS)
	var settings_text := authored.text
	home = authored
	await accepts(settings_text.replace("get_tree().quit()","get_tree().qu§"),"quit","get_tree().quit()","E11 Settings quit completion")
	check(home.get_caret_line()>=0 and home.text==settings_text,"Settings completion/UndoRedo preserves exact GGX buffer")
	check(plugin._build_sources(),"completed Settings source saves/builds")
	# Syntax markers are separate from native breakpoint/bookmark gutters.
	authored.text += "func invalid(\n"
	plugin._services._analyze()
	var index: int = plugin._services._gutter_index(authored)
	check(index>=0,"diagnostic gutter is located by its owned name")
	phase(authored,"syntax diagnostic")
	authored.text = settings_text
	plugin._services._analyze()
	check(plugin._build_sources(),"repair diagnostic source")
	# Short buffer detach/remove must preserve source/undo/native marks.
	var short_path := "res://app/Short.gogo"
	Fixture.write(short_path,"extends Node2D")
	interface.get_resource_filesystem().scan()
	await native_turn()
	await plugin._navigation.open(short_path)
	if not await until(func(): return current(short_path)!=null,"one-line source opens"): finish(); return
	var short_code := current(short_path)
	phase(short_code,"one-line source")
	var short_text := short_code.text
	# Repeat lifetime on the same native tabs; only the dedicated gutter removed.
	current_code(HOME).set_line_as_breakpoint(1,true)
	interface.set_plugin_enabled(PLUGIN,false)
	await frames(8)
	phase(current_code(HOME),"services stopped Home")
	check(short_code.text==short_text and short_code.get_gutter_count()==3,"one-line detach preserves buffer and all native gutters")
	check(current_code(HOME).get_breakpointed_lines().has(1),"native breakpoint survives diagnostic cleanup")
	home = current_code(HOME)
	# Full plugin disable/re-enable owns normal restoration/reattachment.
	plugin = null
	interface.set_plugin_enabled(PLUGIN,true)
	if not await until(find_plugin,"addon reactivates"): finish(); return
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"source reassociates")
	home = current(HOME)
	phase(home,"reactivated")
	home.text = code_source
	check(plugin._build_sources(),"re-enabled source builds")
	await native_turn()
	var node := Node2D.new()
	node.name = "Home"
	node.set_script(load(OUTPUT))
	var packed := PackedScene.new()
	packed.pack(node)
	ResourceSaver.save(packed,"res://app/Home.tscn")
	node.free()
	ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
	ProjectSettings.save()
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"host scene opens")
	for mode in ["main","current"]: await exit_play(mode)
	await capture("gutters")
	finish()
func current_code(path: String) -> CodeEdit:
	for editor in interface.get_script_editor().get_open_script_editors():
		var code := editor.get_base_editor() as CodeEdit
		if code != null and code.get_meta("estragon_gogo_path","")==path: return code
	return null
