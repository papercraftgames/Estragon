@tool
extends "scene_driver.gd"
const Fixture = preload("project_fixture.gd")
const Context = preload("res://addons/estragon/editor/lexical_context.gd")
var code_source := ""
func chain_source() -> String:
	return Fixture.header(HOME,"Node2D",["Element","Entry2D","UiButton"])+'''var clicked := false
func exit() -> void:
	get_tree().qu
func build_view() -> Element:
	return <Entry2D name="UI"><UiButton name="Exit" text="Exit" pressed={self.exit} /></Entry2D>
func _ready() -> void:
	if OS.get_environment("ESTRAGON_E10_GAME")=="1" and not Engine.is_editor_hint(): proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://e02-chain-game.png")
	var button = get_node("UI/Exit")
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	print("E10_NATIVE_EXIT_INPUT")
	get_viewport().push_input(event,true)
'''
func candidates(partial: String) -> Array:
	set_source(home,partial)
	await frames()
	home.request_code_completion(true)
	await frames(5)
	var result := home.get_code_completion_options()
	home.cancel_code_completion()
	return result
func accepts(partial: String, name: String, result: String, label: String) -> void:
	await complete(partial,name,result,label)
func exit_play(mode: String) -> void:
	await native_turn()
	var log_path := "res://.godot/e10-exited"
	# The native Gogo handler writes a marker then executes the completed quit.
	if FileAccess.file_exists(log_path): DirAccess.remove_absolute(log_path)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	check(await until(func(): return FileAccess.file_exists(log_path),mode+" authored native Exit activated"),mode+" actual game button invoked completed quit handler")
	await until(func(): return not interface.is_playing_scene(),mode+" completed native quit exits child game")
	check(not interface.is_playing_scene(),mode+" completed quit actually stops game")
func _run() -> void:
	if not await until(find_plugin,"addon activates for E10"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	code_source = chain_source().replace('get_tree().qu','var file := FileAccess.open("res://.godot/e10-exited",FileAccess.WRITE)\n\tfile.store_string("exit")\n\tfile.close()\n\tget_tree().quit()')
	if not FileAccess.file_exists(HOME):
		Fixture.write(HOME,code_source)
		interface.get_resource_filesystem().scan()
	await native_turn()
	check(plugin._build_sources(),"chain fixture compiles")
	await plugin._navigation.open(HOME)
	if not await until(func(): return current(HOME)!=null,"authored chain source opens"): finish(); return
	home = current(HOME)
	if FileAccess.file_exists("res://.godot/e10-restart"):
		check((await candidates(code_source.replace("get_tree().quit()","get_tree().qu§"))).any(func(item): return item.display_text=="quit"),"chained native completion survives editor restart")
		home.text = code_source
		interface.open_scene_from_path("res://app/Home.tscn")
		await until(func(): return interface.get_edited_scene_root()!=null,"native restart host scene opens")
		await exit_play("main")
		finish(); return
	var partial := code_source.replace("get_tree().quit()","get_tree().qu§")
	var offered := await candidates(partial)
	check(offered.any(func(item): return item.display_text=="quit" and item.kind==CodeEdit.KIND_FUNCTION and str(item.insert_text)=="quit()"),"actual Gogo CodeEdit offers SceneTree quit invocation")
	set_source(home,partial)
	home.request_code_completion(true)
	await frames(5)
	await capture("chain-completion")
	home.cancel_code_completion()
	await accepts(partial,"quit","get_tree().quit()","native chained quit")
	check(home.text==code_source,"accepted method completion yields exact native invocation")
	check(plugin._build_sources(),"completed source compiles through existing actual-path validation")
	var header := "extends Node2D\nfunc demo(node: Node):\n\t"
	for entry in [["get_viewport().get_visible_rec§","get_visible_rect","get_viewport().get_visible_rect()"],["self.get_tree().qu§","quit","self.get_tree().quit()"],["node.get_tree().qu§","quit","node.get_tree().quit()"],["get_node(str(foo())).get_tree().qu§","quit","get_node(str(foo())).get_tree().quit()"]]:
		await accepts(header+entry[0],entry[1],entry[2],"native chain "+entry[1])
	await accepts("extends Node2D\nfunc scene() -> SceneTree:\n\treturn get_tree()\nfunc demo():\n\tscene().qu§","quit","scene().quit()","native explicitly typed return")
	check((await candidates("extends Node2D\nfunc scene(): return null\nfunc demo():\n\tscene().§")).is_empty(),"native dynamic method return has no fabricated members")
	check((await candidates(header+'# get_tree().qu§')).is_empty() and (await candidates(header+'"get_tree().qu§')).is_empty(),"native comment/string chain requests remain suppressed")
	check((await candidates(header+'return <UiButton pressed={get_tree().qu§')).any(func(item): return item.display_text=="quit"),"native GGX attribute expression retains chained methods")
	check((await candidates(header+'return <Nod§')).any(func(item): return str(item.display_text).begins_with("Node2D")),"native GGX tag completion unaffected")
	set_source(home,header+"get_tree().quit(§)")
	await frames()
	for entry in plugin._services.entries.values():
		if entry.path==HOME:
			plugin._services._hint(home.get_instance_id())
			check(str(entry.hint).begins_with("quit("),"native chained call hint uses SceneTree signature")
	home.text = code_source
	await plugin._services.navigate({"source":HOME,"line":2,"column":1})
	check(home.get_caret_line()==1 and home.editable,"source-map navigation keeps Gogo authoring/caret intact")
	# Ordinary GDScript remains managed solely by its native language editor.
	var ordinary := "res://app/Ordinary.gd"
	Fixture.write(ordinary,"extends Node2D\nfunc exit():\n\tget_tree().quit()\n")
	interface.edit_script(load(ordinary))
	interface.set_main_screen_editor("Script")
	await frames(10)
	var native_code = interface.get_script_editor().get_current_editor().get_base_editor()
	check(native_code.editable and native_code.get_script()!=preload("res://addons/estragon/editor/completion_edit.gd") and not plugin._services.entries.has(native_code.get_instance_id()),"ordinary .gd native editing/completion not replaced by Gogo adapter")
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return to authored Home")
	home = current(HOME)
	home.text = code_source
	check(plugin._build_sources(),"restore accepted executable Gogo")
	await native_turn()
	var root := Node2D.new()
	root.name = "Home"
	root.set_script(load(OUTPUT))
	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene,"res://app/Home.tscn")
	root.free()
	ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
	ProjectSettings.save()
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"native completed host scene opens")
	for mode in ["main","current"]: await exit_play(mode)
	Fixture.write("res://.godot/e10-restart","restart")
	finish()
