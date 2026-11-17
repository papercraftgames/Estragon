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
	print("S04_EDITOR_CHECK ",label,": ",ok)
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
		if item.path=="res://app/SurfaceGallery.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/s04-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty()
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/s04-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(game_ready,"actual native S04 game"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.clicks==4 and result.resource,mode+" actual rendered native surface game and input at three sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func run() -> void:
	if not await until(ready,"installed addon ready"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/SurfaceGallery.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/SurfaceGallery.tscn","authored scene opens")
	await settle()
	await inspector_proof()
	check(interface.get_edited_scene_root().get_script().resource_path=="res://app/generated/SurfaceGallery.gd","real native authored S04 scene imports")
	if not FileAccess.file_exists("res://.godot/s04-restart"):
		await plugin._navigation.open("res://app/SurfaceGallery.gogo")
		await until(func(): return code()!=null,"exact associated source CodeEdit opens")
		await settle()
		var buffer := code()
		var source := buffer.text
		check(buffer.syntax_highlighter!=null,"native Gogo highlighter attached to actual S04 source")
		var output := "res://app/generated/SurfaceGallery.gd"
		for mode in ["current","main"]:
			var bytes := FileAccess.get_file_as_bytes(output)
			var maps := FileAccess.get_file_as_bytes(output+".map.json")
			var timestamp := FileAccess.get_modified_time(output)
			var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
			var cached = load(output)
			print("S04_EXPECTED_PLAY_REJECTION_BEGIN")
			buffer.text = source.replace('corner_radius={self.radius}','corner_radius="-1px"') if mode=="current" else source.replace('background_texture_mode="tile"','background_texture_mode="cover"')
			if mode=="main": interface.play_main_scene()
			else: interface.play_current_scene()
			await wait(0.8)
			check(not interface.is_playing_scene() and not plugin.last_report.ok and str(plugin.last_report.diagnostics).contains("app/SurfaceGallery.gogo:"),mode+" invalid unsaved S04 blocks stale Play with authored diagnostic")
			check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==timestamp and (not FileAccess.file_exists(output+".uid") or FileAccess.get_file_as_bytes(output+".uid")==uid) and load(output)==cached,mode+" invalid S04 retains code/map/UID/timestamp/cached Script")
			print("S04_EXPECTED_PLAY_REJECTION_END")
			buffer.text = source+"\n# S04 repaired latest source\n"
			await play(mode)
			check(FileAccess.get_file_as_string("res://app/SurfaceGallery.gogo").contains("# S04 repaired latest source"),mode+" repair saves latest authored Gogo before actual Play")
		var marker := FileAccess.open("res://.godot/s04-restart",FileAccess.WRITE)
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
	print("S04_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S04_EDITOR_OK")
	get_tree().quit(1 if failed else 0)

func inspector_field(property: String) -> EditorProperty:
	for node in interface.get_inspector().find_children("*","EditorProperty",true,false):
		if node.get_edited_property()==property: return node
	return null
func inspector_proof() -> void:
	var scene := interface.get_edited_scene_root()
	var entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	entry.width = 400
	entry.height = 400
	scene.add_child(entry)
	entry.owner = scene
	var node = preload("res://addons/estragon/runtime/node/vbox.gd").new()
	node.width = 300
	node.height = 160
	entry.add_child(node)
	node.owner = scene
	interface.inspect_object(node)
	await until(func(): return inspector_field("corner_radius")!=null,"native inherited surface Inspector")
	for name in ["corner_radius","corner_radius_top_left","background_texture","background_texture_mode","clip_content"]:
		check(inspector_field(name)!=null,"native Inspector "+name)
	var manager := get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(node))
	for pair in [["corner_radius","18px"],["corner_radius_top_left","5%"],["background_texture_mode","tile"],["clip_content",true],["background_texture",load("res://app/panel_gradient.tres")]]:
		var before = node.get(pair[0])
		inspector_field(pair[0]).property_changed.emit(pair[0],pair[1],"",false)
		await wait()
		check(is_same(node.get(pair[0]),pair[1]) and history.undo() and is_same(node.get(pair[0]),before) and history.redo() and is_same(node.get(pair[0]),pair[1]),"surface Inspector edit/undo/redo "+pair[0])
	interface.inspect_object(scene)
	scene.remove_child(entry)
	entry.free()
	await wait()
