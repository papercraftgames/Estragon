@tool
extends "res://tests/layouts/editor.gd"
func code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var value = item.code.get_ref()
		if item.path=="res://app/Checkboxes.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/ui02-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty()
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/ui02-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(game_ready,"actual native Checkbox game"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.checks==27 and result.presses==2,mode+" real native Checkbox/implicit Bool/keyboard Play")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func run() -> void:
	if not await until(ready,"installed addon ready"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Checkboxes.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"authored scene opens")
	await settle()
	if not FileAccess.file_exists("res://.godot/ui02-restart"):
		await plugin._navigation.open("res://app/Checkboxes.gogo")
		if not await until(func(): return code()!=null,"authored Checkbox source editor opens"): finish(); return
		await settle()
		var buffer := code()
		var source := buffer.text
		var output := "res://app/generated/Checkboxes.gd"
		var bytes := FileAccess.get_file_as_bytes(output)
		var maps := FileAccess.get_file_as_bytes(output+".map.json")
		var uid := FileAccess.get_file_as_bytes(output+".uid")
		var timestamp := FileAccess.get_modified_time(output)
		var cached = load(output)
		for mode in ["current","main"]:
			buffer.text = source.replace('value={self.model.flag}','bind:value={self.model.flag}')
			print("UI02_EXPECTED_PLAY_REJECTION_BEGIN")
			if mode=="main": interface.play_main_scene()
			else: interface.play_current_scene()
			await wait(0.8)
			check(not interface.is_playing_scene() and not plugin.last_report.ok,mode+" invalid unsaved source blocks stale game")
			check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_file_as_bytes(output+".uid")==uid and FileAccess.get_modified_time(output)==timestamp and load(output)==cached,mode+" rollback retains code/maps/UID/timestamp/cache")
			print("UI02_EXPECTED_PLAY_REJECTION_END")
		buffer.text = source+"\n# UI02 repaired latest unsaved source\n"
		await play("current")
		await play("main")
		check(FileAccess.get_file_as_string("res://app/Checkboxes.gogo")==buffer.text,"native Play saved latest repaired authored buffer")
		var marker := FileAccess.open("res://.godot/ui02-restart",FileAccess.WRITE)
		marker.store_string("restart")
		marker.close()
	else: await play("main")
	check(interface.get_edited_scene_root().get_child_count()==0,"editor host persists no runtime focus/edit delegates")
	await settle()
	await wait(0.3)
	finish()
func finish() -> void:
	print("UI02_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI02_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
