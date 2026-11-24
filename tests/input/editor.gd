@tool
extends "res://tests/layouts/editor.gd"
func settle() -> void:
	if OS.get_environment("U03_EDITOR")!="1":
		await super.settle()
		return
	var deadline := Time.get_ticks_msec()+45000
	while Time.get_ticks_msec()<deadline:
		if not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped():
			var count: int = plugin.build_count
			await wait()
			if count==plugin.build_count and not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(): return
		await get_tree().process_frame
	print("U03_SETTLE_STATE busy=",plugin._filesystem_busy()," rescan=",plugin._rescan_pending," timer=",plugin._timer.is_stopped()," report=",plugin.last_report)
	check(false,"bounded scrollbar consumer filesystem settles")
func code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var value = item.code.get_ref()
		if item.path=="res://app/Inputs.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/ui03-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty() and (OS.get_environment("U03_EDITOR")!="1" or (parser.data.get("scrollbar_checks",0)==42 and parser.data.get("scrollbar_ggx_checks",0)==7)) and (OS.get_environment("L12_EDITOR")!="1" or parser.data.get("layout_checks",0)==34)
func wait_game() -> bool:
	# The full native editing sequence includes hundreds of delivered frames
	# plus two rendered captures under the editor/debugger on Linux4.0.
	var deadline := Time.get_ticks_msec()+(90000 if OS.get_environment("U03_EDITOR")=="1" else 45000)
	while Time.get_ticks_msec()<deadline:
		if game_ready(): return true
		await get_tree().process_frame
	check(false,"bounded actual native Input game")
	return false
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/ui03-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await wait_game():
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.checks==52 and result.submits==1 and result.cancels==1,mode+" real native Input/implicit String/keyboard Play")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func wait_addon() -> bool:
	var deadline := Time.get_ticks_msec()+45000
	while Time.get_ticks_msec()<deadline:
		if ready(): return true
		await get_tree().process_frame
	print("UI03_STARTUP_REPORT ", plugin.last_report if plugin!=null else {})
	check(false,"bounded installed addon ready")
	return false
func run() -> void:
	if not await wait_addon(): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Inputs.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"authored scene opens")
	await settle()
	if not FileAccess.file_exists("res://.godot/ui03-restart"):
		if OS.get_environment("U03_EDITOR")=="1":
			var inspector_probe=load("res://tests/scrollbars/inspector.gd").new()
			await inspector_probe.run(self)
		await plugin._navigation.open("res://app/Inputs.gogo")
		if not await until(func(): return code()!=null,"authored Input source editor opens"): finish(); return
		await settle()
		var buffer := code()
		var source := buffer.text
		var output := "res://app/generated/Inputs.gd"
		var bytes := FileAccess.get_file_as_bytes(output)
		var maps := FileAccess.get_file_as_bytes(output+".map.json")
		var uid := FileAccess.get_file_as_bytes(output+".uid")
		var timestamp := FileAccess.get_modified_time(output)
		var cached = load(output)
		for mode in ["current","main"]:
			buffer.text = source.replace('value={self.model.text}','bind:value={self.model.text}') if mode=="current" else source.replace('placeholder="Your name"','placeholder={false}')
			if OS.get_environment("U03_EDITOR")=="1": buffer.text = source.replace('placeholder="Your name"','scrollbar_size="auto"' if mode=="current" else 'scrollbar_style="invalid"')
			print("UI03_EXPECTED_PLAY_REJECTION_BEGIN")
			if mode=="main": interface.play_main_scene()
			else: interface.play_current_scene()
			await wait(0.8)
			check(not interface.is_playing_scene() and not plugin.last_report.ok and str(plugin.last_report.diagnostics).contains("app/Inputs.gogo:"),mode+" invalid unsaved source blocks stale game")
			check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_file_as_bytes(output+".uid")==uid and FileAccess.get_modified_time(output)==timestamp and load(output)==cached,mode+" rollback retains code/maps/UID/timestamp/cache")
			print("UI03_EXPECTED_PLAY_REJECTION_END")
		buffer.text = source+"\n# UI03 repaired latest unsaved source\n"
		await play("current")
		await play("main")
		check(FileAccess.get_file_as_string("res://app/Inputs.gogo")==buffer.text,"native Play saved latest repaired authored buffer")
		var marker := FileAccess.open("res://.godot/ui03-restart",FileAccess.WRITE)
		marker.store_string("restart")
		marker.close()
	else: await play("main")
	check(interface.get_edited_scene_root().get_child_count()==0,"editor host persists no runtime focus/edit delegates")
	await settle()
	await wait(0.3)
	finish()
func finish() -> void:
	print("UI03_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI03_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
