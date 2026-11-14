@tool
extends EditorPlugin
var interface: EditorInterface
var plugin: EditorPlugin
var checks := 0
var failed := false
var proof: Dictionary = {}
var timer: Timer
func _enter_tree() -> void:
	interface = get_editor_interface()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L05_EDITOR_CHECK ",label,": ",ok)
	if not ok: failed = true
func until(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,label)
	return false
func ready() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node!=self and node.get_script()!=null and node.get_script().resource_path=="res://addons/estragon/editor/plugin.gd": plugin = node
	return plugin!=null and plugin.last_report.get("ok",false) and not plugin._extensions_pending
func home_code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var code = item.code.get_ref()
		if item.path=="res://app/Home.gogo" and code!=null and code.is_visible_in_tree(): return code
	return null
func settle() -> void:
	for attempt in range(30):
		await until(func(): return not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(),"native filesystem settles")
		var count: int = plugin.build_count
		timer.start(0.15)
		await timer.timeout
		if count==plugin.build_count and not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(): return
	check(false,"bounded editor settle")
func proof_ready() -> bool:
	var path := "res://.godot/l05-game.json"
	if not FileAccess.file_exists(path): return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary or parser.data.is_empty(): return false
	proof = parser.data
	return true
func play(mode: String) -> void:
	await settle()
	var path := "res://.godot/l05-game.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(proof_ready,"actual resized game proof"):
		check(proof.width==proof.visible_width and proof.height==proof.visible_height and proof.rose_bottom==proof.visible_height and proof.rose_y>=proof.button_bottom and proof.clicks==1,mode+" native game follows both viewport axes and retains GUI input")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"native game stops")
func run() -> void:
	if not await until(ready,"installed addon activates"): finish(); return
	var prefs := interface.get_editor_settings()
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"authored scene opens")
	await settle()
	if not FileAccess.file_exists("res://.godot/l05-restart"):
		await plugin._navigation.open("res://app/Home.gogo")
		await until(func(): return home_code()!=null,"native authored source editor opens")
		var code := home_code()
		if code!=null:
			var original := code.text
			var at := original.find("viewport_height_scale")+"viewport_he".length()
			var rows := original.left(at).split("\n")
			code.set_caret_line(rows.size()-1)
			code.set_caret_column(rows[-1].length())
			code.request_code_completion(true)
			for frame in range(5): await get_tree().process_frame
			check(code.get_code_completion_options().any(func(item): return item.display_text=="viewport_height_scale — float" and item.insert_text=="viewport_height_scale"),"real CodeEdit shows the float property type and preserves plain insertion text")
			code.cancel_code_completion()
			check(code.text==original and plugin._build_sources(),"native completion preserves valid source and installed imports/maps")
		await play("current")
		var file := FileAccess.open("res://.godot/l05-restart",FileAccess.WRITE)
		file.store_string("restart")
		file.close()
	await play("main")
	check(interface.get_edited_scene_root().get_child_count()==1 and interface.get_edited_scene_root().get_node("Borrowed").owner==interface.get_edited_scene_root(),"editor scene retains only owned persistent native child")
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://editor.png")
	finish()
func finish() -> void:
	print("L05_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L05_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
