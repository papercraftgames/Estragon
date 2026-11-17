@tool
extends EditorPlugin
var interface: EditorInterface
var plugin: EditorPlugin
var checks := 0
var failed := false
func _enter_tree() -> void:
	interface = get_editor_interface()
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("D07_EDITOR_CHECK ",label,": ",ok)
	if not ok: failed = true
func wait(seconds: float = 0.15) -> void: await get_tree().create_timer(seconds).timeout
func until(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,label)
	return false
func ready() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node!=self and node.get_script()!=null and node.get_script().resource_path.ends_with("/addons/estragon/editor/plugin.gd"): plugin = node
	return plugin!=null and plugin.last_report.get("ok",false) and not plugin._extensions_pending
func settle() -> void:
	for attempt in range(30):
		await until(func(): return not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(),"filesystem settles")
		var count: int = plugin.build_count
		await wait()
		if count==plugin.build_count and not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(): return
	check(false,"bounded native settle")
func code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var value = item.code.get_ref()
		if item.path=="res://app/Buttons.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/d07-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty()
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/d07-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(game_ready,"actual native D07 game"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.clicks==3 and result.native_clicks==3 and result.unimported_clicks==3 and result.resource,mode+" actual rendered native surface game and input at three sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func run() -> void:
	if not await until(ready,"installed addon ready"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Buttons.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/Buttons.tscn","authored scene opens")
	await settle()
	await inspector_proof()
	check(interface.get_edited_scene_root().get_script().resource_path=="res://app/generated/Buttons.gd","real native authored D07 scene imports")
	if not FileAccess.file_exists("res://.godot/d07-restart"):
		await plugin._navigation.open("res://app/Buttons.gogo")
		await until(func(): return code()!=null,"exact associated source CodeEdit opens")
		await settle()
		var buffer := code()
		var source := buffer.text
		await completion_proof(buffer,source)
		check(buffer.syntax_highlighter!=null,"native Gogo highlighter attached to actual D07 source")
		var output := "res://app/generated/Buttons.gd"
		for mode in ["current","main"]:
			var bytes := FileAccess.get_file_as_bytes(output)
			var maps := FileAccess.get_file_as_bytes(output+".map.json")
			var timestamp := FileAccess.get_modified_time(output)
			var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
			var cached = load(output)
			var missing := source.replace('const Button = preload(', 'const Button = preload("res://missing_button.gd")\nconst Duplicate = preload(')
			var duplicate := source+'\nconst Button=preload("res://addons/estragon/runtime/node/button.gd")\n'
			var resource := source.replace('const Button = preload(', 'const Button = preload("res://app/panel_gradient.tres")\nconst Duplicate = preload(')
			var typed := source+'\nfunc d07_bad() -> Button: return 12\n'
			for broken in [missing,duplicate,resource,typed]:
				print("D07_EXPECTED_PLAY_REJECTION_BEGIN")
				buffer.text = broken
				if mode=="main": interface.play_main_scene()
				else: interface.play_current_scene()
				await wait(0.8)
				check(not interface.is_playing_scene() and not plugin.last_report.ok and str(plugin.last_report.diagnostics).contains("app/Buttons.gogo:"),mode+" invalid unsaved D07 blocks stale Play with authored diagnostic")
				check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==timestamp and (not FileAccess.file_exists(output+".uid") or FileAccess.get_file_as_bytes(output+".uid")==uid) and load(output)==cached,mode+" invalid D07 retains code/map/UID/timestamp/cached Script")
				print("D07_EXPECTED_PLAY_REJECTION_END")
			buffer.text = source+"\n# D07 repaired latest source\n"
			await play(mode)
			check(FileAccess.get_file_as_string("res://app/Buttons.gogo").contains("# D07 repaired latest source"),mode+" repair saves latest authored Gogo before actual Play")
		var marker := FileAccess.open("res://.godot/d07-restart",FileAccess.WRITE)
		marker.store_string("restart")
		marker.close()
	else: await play("main")
	check(interface.get_edited_scene_root().get_child_count()==0,"native editor scene has no transient managed output persisted")
	# Stop/Inspector notifications and queued native rendering cleanup must finish
	# before the isolated editor exits; assertion success alone is not shutdown.
	await settle()
	await wait(0.3)
	finish()
func finish() -> void:
	print("D07_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("D07_EDITOR_OK")
	get_tree().quit(1 if failed else 0)

func inspector_field(property: String) -> EditorProperty:
	for node in interface.get_inspector().find_children("*","EditorProperty",true,false):
		if node.get_edited_property()==property: return node
	return null
func inspector_proof() -> void:
	var scene := interface.get_edited_scene_root()
	var node = preload("res://addons/estragon/runtime/node/button.gd").new()
	scene.add_child(node)
	node.owner = scene
	interface.inspect_object(node)
	await until(func(): return inspector_field("background_color")!=null,"native Button Inspector")
	var manager := get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(node))
	for pair in [["background_color",Color("#383838")],["hover_background_color",Color("#505050")],["pressed_background_color",Color("#252525")],["disabled_background_color",Color("#303030")]]:
		check(node.get(pair[0])==pair[1] and inspector_field(pair[0])!=null,"initial Inspector charcoal "+pair[0])
		inspector_field(pair[0]).property_changed.emit(pair[0],Color("#aa3322"),"",false)
		await wait()
		check(node.get(pair[0])==Color("#aa3322") and history.undo() and node.get(pair[0])==pair[1] and history.redo() and node.get(pair[0])==Color("#aa3322"),"native Inspector color edit/undo/redo "+pair[0])
		history.undo()
	var packed := PackedScene.new()
	check(packed.pack(node)==OK and ResourceSaver.save(packed,"res://inspected-button.tscn")==OK,"native inspected Button saves")
	var reloaded = load("res://inspected-button.tscn").instantiate()
	# Native 4.0 text scenes round serialized Color floats to six decimals.
	# Fresh instance properties/pixels are checked exactly in runtime.gd.
	check(reloaded.background_color.is_equal_approx(Color("#383838")) and reloaded.hover_background_color.is_equal_approx(Color("#505050")) and reloaded.pressed_background_color.is_equal_approx(Color("#252525")) and reloaded.disabled_background_color.is_equal_approx(Color("#303030")) and reloaded._visual_style.colors.hover_background_color.is_equal_approx(reloaded.hover_background_color),"Inspector undo defaults survive native scene reload and initial cache")
	reloaded.free()
	interface.inspect_object(scene)
	scene.remove_child(node)
	node.free()
	await wait()
func completion_proof(buffer: CodeEdit,source: String) -> void:
	for origin in ["Godot","Estragon native"]:
		buffer.text = "extends Node2D\nfunc view(): return <Bu />\n"
		buffer.set_caret_line(1)
		buffer.set_caret_column(23)
		await wait()
		buffer.request_code_completion(true)
		await until(func(): return not buffer.get_code_completion_options().is_empty(),"actual Button completion popup")
		var before := buffer.text
		var selected := -1
		var options := buffer.get_code_completion_options()
		for i in range(options.size()):
			if str(options[i].display_text).begins_with("Button —") and str(options[i].display_text).contains(origin): selected = i
		check(selected>=0,"popup distinguishes "+origin)
		if selected>=0:
			buffer.set_code_completion_selected_index(selected)
			buffer.confirm_code_completion()
			await wait()
			check(buffer.text.contains("<Button />") and buffer.text.contains("const Button = preload(")== (origin=="Estragon native"),"real completion native/import selection "+origin)
			buffer.undo()
			check(buffer.text==before,"completion and import are one undo "+origin)
			buffer.redo()
			check(buffer.text.contains("<Button />"),"completion redo "+origin)
	buffer.text = source
	await wait()
