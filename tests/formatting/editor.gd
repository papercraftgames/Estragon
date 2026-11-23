@tool
extends "res://tests/layouts/editor.gd"
var menus: Array = []
func menu_items() -> Array:
	var result: Array = []
	for popup in get_tree().root.find_children("*","PopupMenu",true,false):
		for index in range(popup.item_count):
			if popup.get_item_text(index)=="Format Gogo / Auto Indent": result.append({"popup":popup,"index":index})
	return result
func shortcut(meta: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_I
	event.pressed = true
	event.meta_pressed = meta
	event.ctrl_pressed = not meta
	get_tree().root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_tree().root.push_input(event,true)
	await wait()
func run() -> void:
	if not await until(ready,"installed addon ready"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	# The final authored width is two spaces; keep native generated-script
	# save conversion consistent with that setting, including editor shutdown.
	prefs.set_setting("text_editor/behavior/indent/type",1)
	prefs.set_setting("text_editor/behavior/indent/size",2)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Layouts.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"native scene opens")
	await settle()
	await plugin._navigation.open("res://app/Layouts.gogo")
	if not await until(func(): return code()!=null,"associated authored Gogo tab opens"): finish(); return
	await settle()
	var buffer := code()
	var original := buffer.text
	if not FileAccess.file_exists("res://.godot/edit01-restart"):
		await play("main") # Baseline: same native geometry, input and state as formatted Play.
		await plugin._navigation.open("res://app/Layouts.gogo")
		await wait()
		var rows := original.split("\n")
		for index in range(rows.size()):
			if rows[index].strip_edges().begins_with("<"): rows[index] = " "+rows[index].strip_edges()
		var messy := "\n".join(rows)+"\n# unsaved EDIT01\n"
		buffer.text = messy
		buffer.indent_use_spaces = true
		buffer.indent_size = 4
		buffer.set_caret_line(48)
		buffer.set_caret_column(9)
		buffer.select(48,9,49,9)
		buffer.grab_focus()
		await wait()
		# Native select() caret placement differs between 4.0 and 4.7.
		# Preserve the actual pre-command state, not a presumed endpoint.
		var caret_row := buffer.get_caret_line()
		var selection_rows := Vector2i(buffer.get_selection_from_line(),buffer.get_selection_to_line())
		var disk := FileAccess.get_file_as_bytes("res://app/Layouts.gogo")
		var output := "res://app/generated/Layouts.gd"
		var generated := FileAccess.get_file_as_bytes(output)
		var maps := FileAccess.get_file_as_bytes(output+".map.json")
		var uid := FileAccess.get_file_as_bytes(output+".uid")
		var timestamp := FileAccess.get_modified_time(output)
		var items := menu_items()
		check(items.size()==1,"one discoverable native Project Tools menu command")
		if items.size()==1: items[0].popup.index_pressed.emit(items[0].index)
		await wait()
		var formatted := buffer.text
		check(formatted!=messy and plugin._services.last_format.ok and plugin._services.last_format.changed,"native menu formats current unsaved GGX buffer")
		check(buffer.has_selection() and buffer.get_caret_line()==caret_row and buffer.get_selection_from_line()==selection_rows.x and buffer.get_selection_to_line()==selection_rows.y,"native menu retains selection and caret row")
		check(buffer.get_version()!=buffer.get_saved_version(),"native editor retains dirty state")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://format-editor.png")
		check(FileAccess.get_file_as_bytes("res://app/Layouts.gogo")==disk and FileAccess.get_file_as_bytes(output)==generated and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_file_as_bytes(output+".uid")==uid and FileAccess.get_modified_time(output)==timestamp,"format does not save or mutate generated code/maps/UID/timestamp")
		buffer.undo()
		check(buffer.text==messy,"menu formatting is one native undo")
		buffer.redo()
		check(buffer.text==formatted,"native redo restores formatting")
		var version := buffer.get_version()
		buffer.grab_focus()
		await shortcut(false)
		check(buffer.text==formatted and buffer.get_version()==version and not plugin._services.last_format.changed,"Ctrl+I repeat has no undo mutation")
		buffer.undo()
		buffer.grab_focus()
		await shortcut(true)
		check(buffer.text==formatted and plugin._services.last_format.changed,"Cmd/Meta+I uses actual focused native input path")
		buffer.indent_use_spaces = false
		buffer.grab_focus()
		await shortcut(false)
		check(buffer.text.contains("\n\treturn <Entry2D") and plugin._services.last_format.changed,"Ctrl+I honors configured tabs")
		buffer.indent_use_spaces = true
		buffer.indent_size = 2
		buffer.grab_focus()
		await shortcut(true)
		check(buffer.text.contains("\n  return <Entry2D"),"native buffer indentation width respected")
		var valid := buffer.text
		buffer.text = valid.replace("</Entry2D>","</Wrong>")
		var broken := buffer.text
		var broken_version := buffer.get_version()
		buffer.grab_focus()
		await shortcut(false)
		check(buffer.text==broken and buffer.get_version()==broken_version and not plugin._services.last_format.ok and not plugin._services.last_format.diagnostics.is_empty(),"invalid intermediate source safely refused with diagnostic")
		for mode in ["current","main"]:
			print("EDIT01_EXPECTED_PLAY_REJECTION_BEGIN")
			var cached = load(output)
			if mode=="main": interface.play_main_scene()
			else: interface.play_current_scene()
			await wait(0.8)
			check(not interface.is_playing_scene() and not plugin.last_report.ok,mode+" malformed formatted buffer blocks stale Play")
			check(FileAccess.get_file_as_bytes(output)==generated and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_file_as_bytes(output+".uid")==uid and FileAccess.get_modified_time(output)==timestamp and load(output)==cached,mode+" rejected Play preserves generated code/maps/UID/timestamp/cache")
			print("EDIT01_EXPECTED_PLAY_REJECTION_END")
		buffer.text = valid
		# A second authored tab must never receive edits intended for this one.
		await plugin._navigation.open("res://app/Header.gogo")
		await wait()
		var other = interface.get_script_editor().get_current_editor().get_base_editor()
		var other_source: String = other.text
		other.grab_focus()
		await shortcut(false)
		check(buffer.text==valid and other.text==plugin._services.Formatter.new().format_source(other_source,"Header",other.indent_use_spaces,other.indent_size).text,"multiple authored tabs format only active buffer")
		interface.edit_script(load("res://godot_button.gd"))
		await wait()
		var ordinary = interface.get_script_editor().get_current_editor().get_base_editor()
		var ordinary_text: String = ordinary.text
		ordinary.grab_focus()
		await shortcut(true)
		check(ordinary.text==ordinary_text and buffer.text==valid,"ordinary GDScript tab untouched")
		interface.edit_script(load(output))
		await wait()
		var compiled = interface.get_script_editor().get_current_editor().get_base_editor()
		var compiled_text: String = compiled.text
		compiled.grab_focus()
		await shortcut(true)
		check(compiled.text==compiled_text and FileAccess.get_file_as_bytes(output)==generated,"generated GDScript tab untouched")
		await plugin._navigation.open("res://app/Layouts.gogo")
		await wait()
		await play("current")
		await play("main")
		check(FileAccess.get_file_as_string("res://app/Layouts.gogo")==valid,"save/Play publishes latest formatted unsaved authored source")
		var map = JSON.parse_string(FileAccess.get_file_as_string(output+".map.json"))
		check(map.sourceContent==valid and FileAccess.get_file_as_bytes(output+".uid")==uid,"formatted source maps and stable authored UID after Play")
		var debug := FileAccess.open("res://edit01-final-generated.txt",FileAccess.WRITE)
		debug.store_string(FileAccess.get_file_as_string(output))
		debug.close()
		var addon: String = plugin.get_script().resource_path.get_base_dir()+"/plugin.cfg"
		interface.set_plugin_enabled(addon,false)
		await wait()
		check(menu_items().is_empty(),"disable removes native menu action")
		interface.set_plugin_enabled(addon,true)
		plugin = null
		await until(ready,"addon reenabled")
		await wait()
		check(menu_items().size()==1,"reenable installs exactly one menu action")
		var marker := FileAccess.open("res://.godot/edit01-restart",FileAccess.WRITE)
		marker.store_string("restart")
		marker.close()
	else:
		buffer.grab_focus()
		var version := buffer.get_version()
		await shortcut(false)
		check(plugin._services.last_format.ok and buffer.get_version()==version and menu_items().size()==1,"restart restores command and idempotent saved buffer")
		await play("main")
	await settle()
	await wait(0.3)
	finish()
func finish() -> void:
	print("EDIT01_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("EDIT01_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
