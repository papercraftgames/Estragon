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
	print("LAYOUT01_EDITOR_CHECK ",label,": ",ok)
	if not ok: failed = true
func wait(seconds: float = 0.15) -> void: await get_tree().create_timer(seconds).timeout
func until(condition: Callable, label: String, timeout_ms: int = 60000) -> bool:
	var deadline := Time.get_ticks_msec()+timeout_ms
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
		if item.path=="res://examples/constraint_layout/Constraints.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/layout01-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty()
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/layout01-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(game_ready,"actual native LAYOUT01 game",60000):
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.checks==30 and result.identity,mode+" actual rendered layout game and native input at two sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func run() -> void:
	if not await until(ready,"installed addon ready",120000): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://examples/constraint_layout/Constraints.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://examples/constraint_layout/Constraints.tscn","authored scene opens")
	await settle()

	check(interface.get_edited_scene_root().get_script().resource_path=="res://examples/constraint_layout/generated/Constraints.gd","real native authored LAYOUT01 scene imports")
	if not FileAccess.file_exists("res://.godot/layout01-restart"):
		await plugin._navigation.open("res://examples/constraint_layout/Constraints.gogo")
		await until(func(): return code()!=null,"exact associated source CodeEdit opens")
		await settle()
		var buffer := code()
		var source := buffer.text
		await completion_proof(buffer,source)
		check(buffer.syntax_highlighter!=null,"native Gogo highlighter attached to actual LAYOUT01 source")
		var output := "res://examples/constraint_layout/generated/Constraints.gd"
		for mode in ["current","main"]:
			var bytes := FileAccess.get_file_as_bytes(output)
			var maps := FileAccess.get_file_as_bytes(output+".map.json")
			var timestamp := FileAccess.get_modified_time(output)
			var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
			var cached = load(output)
			var property := source.replace('<Grid name="Grid"','<Grid bad_constraint_property="bad" name="Grid"')
			var typed_data := source.replace('<Grid name="Grid" width="100%"', '<Grid name="Grid" width="invalid-length"')
			for broken in [property,typed_data]:
				print("LAYOUT01_EXPECTED_PLAY_REJECTION_BEGIN")
				buffer.text = broken
				if mode=="main": interface.play_main_scene()
				else: interface.play_current_scene()
				await wait(0.8)
				check(not interface.is_playing_scene() and not plugin.last_report.ok and str(plugin.last_report.diagnostics).contains("examples/constraint_layout/Constraints.gogo:"),mode+" invalid unsaved LAYOUT01 blocks stale Play with authored diagnostic")
				check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==timestamp and (not FileAccess.file_exists(output+".uid") or FileAccess.get_file_as_bytes(output+".uid")==uid) and load(output)==cached,mode+" invalid LAYOUT01 retains code/map/UID/timestamp/cached Script")
				print("LAYOUT01_EXPECTED_PLAY_REJECTION_END")
			buffer.text = source+"\n# LAYOUT01 repaired latest source\n"
			await play(mode)
			check(FileAccess.get_file_as_string("res://examples/constraint_layout/Constraints.gogo").contains("# LAYOUT01 repaired latest source"),mode+" repair saves latest authored Gogo before actual Play")
		var marker := FileAccess.open("res://.godot/layout01-restart",FileAccess.WRITE)
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
	print("LAYOUT01_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("LAYOUT01_EDITOR_OK")
	get_tree().quit(1 if failed else 0)

func completion_proof(buffer: CodeEdit,source: String) -> void:
	buffer.text = source
	buffer.set_caret_line(buffer.get_line_count()-1)
	buffer.set_caret_column(buffer.get_line(buffer.get_line_count()-1).length())
	buffer.begin_complex_operation()
	buffer.insert_text_at_caret("\n# LAYOUT01 source undo proof\n")
	buffer.end_complex_operation()
	check(buffer.text.contains("# LAYOUT01 source undo proof"),"native authored buffer edit")
	buffer.undo()
	check(buffer.text==source,"native source edit undo preserves call-site source")
	buffer.redo()
	check(buffer.text.contains("# LAYOUT01 source undo proof"),"native source edit redo")
	buffer.text = source
	await wait()
