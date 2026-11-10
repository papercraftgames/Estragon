@tool
extends "project_driver.gd"
const Build = preload("res://addons/estragon/editor/build_service.gd")
var compiled: CodeEdit
func append_compiled(text: String) -> void:
	compiled.set_caret_line(compiled.get_line_count()-1)
	compiled.set_caret_column(compiled.get_line(compiled.get_caret_line()).length())
	compiled.insert_text_at_caret(text,0)
	await frames()
func compiled_tab(path: String) -> CodeEdit:
	var scripts := interface.get_script_editor()
	if scripts.get_current_script() == null or scripts.get_current_script().resource_path != path: return null
	var editor := scripts.get_current_editor()
	return editor.get_base_editor() as CodeEdit if editor != null else null
func show_script(path: String, line: int = 1) -> CodeEdit:
	await native_turn()
	interface.edit_script(load(path),line,0)
	interface.set_main_screen_editor("Script")
	await until(func(): return compiled_tab(path)!=null,"native compiled Script tab opens")
	await frames()
	return compiled_tab(path)
func type_character(code: CodeEdit) -> void:
	code.get_window().grab_focus()
	code.grab_focus()
	await frames()
	var event := InputEventKey.new()
	var window := code.get_window()
	var native_window := window.has_method("get_window_id")
	if native_window: event.window_id = window.call("get_window_id")
	event.keycode = KEY_X
	event.unicode = 120
	event.pressed = true
	if native_window: Input.parse_input_event(event)
	else: window.push_input(event,true)
	await frames()
	event = event.duplicate()
	event.pressed = false
	if native_window: Input.parse_input_event(event)
	else: window.push_input(event,true)
	await frames()
func generated_row(menu: PopupMenu, index: int) -> void:
	# Locate the row by native hover feedback, without hardcoded theme metrics.
	var native_window := menu.has_method("get_window_id")
	if not native_window:
		# Baseline Window has no public OS window id. Its embedded popup receives
		# normal main-window keyboard input; activate the focused native row.
		menu.set_focused_item(index)
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = true
		Input.parse_input_event(key)
		await frames()
		key = key.duplicate()
		key.pressed = false
		Input.parse_input_event(key)
		await frames()
		return
	menu.set_focused_item(-1)
	var point := Vector2(24,8)
	var found := false
	for y in range(8,menu.size.y-4,4):
		point.y = y
		var motion := InputEventMouseMotion.new()
		if native_window: motion.window_id = menu.call("get_window_id")
		motion.position = point
		motion.global_position = Vector2(menu.position)+point
		motion.relative = Vector2(0,4)
		motion.velocity = Vector2(0,240)
		if native_window: Input.parse_input_event(motion)
		else: menu.push_input(motion,true)
		Input.flush_buffered_events()
		if menu.get_focused_item() == index:
			found = true
			break
	check(found,"native hover locates component menu row")
	if not found: return
	var event := InputEventMouseButton.new()
	if native_window: event.window_id = menu.call("get_window_id")
	event.position = point
	event.global_position = Vector2(menu.position)+point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	if native_window: Input.parse_input_event(event)
	else: menu.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	if native_window: Input.parse_input_event(event)
	else: menu.push_input(event,true)
	await frames()
func generated_action(id: int) -> void:
	var menu: MenuButton = plugin._generated_editors.panel
	var picked := []
	var record := func(item): picked.append(item)
	menu.get_popup().id_pressed.connect(record)
	await click(menu)
	await until(func(): return menu.get_popup().visible,"generated view native menu opens")
	RenderingServer.force_draw(false)
	menu.get_popup().get_texture().get_image().save_png("res://e02-generated-menu.png")
	await generated_row(menu.get_popup(),menu.get_popup().get_item_index(id))
	check(picked.has(id),"native generated menu selects requested action "+str(id))
	menu.get_popup().id_pressed.disconnect(record)
func _run() -> void:
	if not await until(find_plugin,"installed addon activates for E09"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	var output: String = Build.output_for(Fixture.SETTINGS)
	if FileAccess.file_exists("res://.godot/e09-restart"):
		interface.open_scene_from_path("res://app/Home.tscn")
		await until(func(): return interface.get_edited_scene_root()!=null,"native restart scene/layout restores before selecting a Script")
		compiled = await show_script(output)
		if compiled == null: check(false,"restart keeps selected native Script tab"); finish(); return
		check(not compiled.editable and plugin._generated_editors.panel.visible,"restart restores generated protection and visible origin")
		check(not plugin._generated_editors.panel.get_popup().is_item_disabled(plugin._generated_editors.panel.get_popup().get_item_index(2)),"persistent recovery remains discoverable after restart")
		await generated_action(2)
		check(plugin._generated_editors.preview.text.contains("# previously dirty"),"restart recovery retains exact edited bytes")
		RenderingServer.force_draw(false)
		plugin._generated_editors.viewer.get_texture().get_image().save_png("res://e02-generated-recovery-view.png")
		plugin._generated_editors.viewer.hide()
		await capture("generated-restart")
		finish(); return
	Fixture.install()
	interface.get_resource_filesystem().scan()
	await native_turn()
	check(plugin._build_sources(),"owner Home/Settings direct tags compile cold")
	await native_turn()
	var root := Node2D.new()
	root.name = "Home"
	root.set_script(load(OUTPUT))
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed,"res://app/Home.tscn")
	root.free()
	ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
	ProjectSettings.save()
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"attached native Home scene opens")
	app = interface.get_edited_scene_root()
	# Native Script resource selection/navigation, including inspect/debug line
	# requests, must keep the compiled tab available rather than redirecting it.
	interface.inspect_object(app)
	await frames()
	check(button("Open Gogo Source")!=null,"attached component Inspector exposes original source")
	var script_button: Button
	for picker in interface.get_inspector().find_children("*","EditorResourcePicker",true,false):
		if picker.get_edited_resource() != app.get_script(): continue
		for candidate in picker.find_children("*","Button",true,false):
			if candidate.text == "Home.gd": script_button = candidate
	check(script_button != null,"native Inspector Script field identifies actual generated Home resource")
	if script_button != null:
		await click(script_button)
		check(await until(func(): return compiled_tab(OUTPUT)!=null,"Inspector Script click opens compiled Home"),"native Inspector Script click keeps generated inspection available")
	# Authenticate pre-hash v1 maps without requiring a source rewrite/build.
	var old_map := FileAccess.get_file_as_string(output+".map.json")
	var legacy: Dictionary = JSON.parse_string(old_map)
	legacy.erase("generatedHash")
	Fixture.write(output+".map.json",JSON.stringify(legacy))
	check(plugin._generated_editors._verified(output)==Fixture.SETTINGS,"legacy v1 map authentication verifies deterministic emitted content")
	Fixture.write(output+".map.json",old_map)
	compiled = await show_script(output,3)
	var guard = plugin._generated_editors
	check(not compiled.editable and guard.panel.visible and guard.panel.text.contains("Settings.gogo"),"generated Settings tab visibly identifies authored source and is read-only")
	check(interface.get_script_editor().get_current_script().resource_path==output,"native inspect/debug navigation stays on compiled Script")
	var before: String = compiled.text
	await type_character(compiled)
	check(compiled.text==before,"real native key input cannot modify protected generated buffer")
	await capture("generated-protected")
	await generated_action(1)
	check(await until(func(): return current(Fixture.SETTINGS)!=null,"source action opens Settings.gogo"),"visible action navigates to exact authored source")
	settings = current(Fixture.SETTINGS)
	if settings == null:
		finish(); return
	check(settings.editable and not guard.panel.visible,"authored Gogo remains editable without generated banner")
	await plugin._services.navigate({"source":Fixture.SETTINGS,"line":4,"column":1})
	check(settings.get_caret_line()==3 and settings.editable,"source-map diagnostic navigation retains editable authored target/caret")
	# Select the exact native script-list entry, not a basename guess.
	var selected_script := false
	for list in interface.get_script_editor().find_children("*","ItemList",true,false):
		for index in range(list.item_count):
			if list.get_item_tooltip(index) != output: continue
			list.select(index)
			list.item_selected.emit(index)
			selected_script = true
	await frames()
	check(selected_script and compiled_tab(output)==compiled and not compiled.editable,"native script-list selection retains protected compiled inspection")
	var original_settings: String = settings.text
	settings.text += "\n# authored edit\n"
	check(plugin._build_sources(),"source rebuild while generated tab is open succeeds")
	await native_turn()
	check(compiled.text.contains("# authored edit") and compiled.text==FileAccess.get_file_as_string(output) and load(output).source_code==compiled.text,"compiled view refresh matches disk/cache")
	settings.text = original_settings
	check(plugin._build_sources(),"authored repair rebuild")
	await native_turn()
	var prior_recovery: String = guard.entries[compiled.get_instance_id()].recovery
	Fixture.write(Fixture.SETTINGS,original_settings.replace("\n","\r\n"))
	check(plugin._compile() and compiled.text==FileAccess.get_file_as_string(output).replace("\r\n","\n") and guard.entries[compiled.get_instance_id()].recovery==prior_recovery,"native CRLF display normalization does not manufacture a dirty recovery")
	Fixture.write(Fixture.SETTINGS,original_settings)
	check(plugin._compile(),"restore source line endings after normalization proof")
	await native_turn()
	await open_home()
	for mode in ["main","current"]: await play(mode)
	# Simulate a previously dirty generated buffer before protection is adopted.
	interface.set_plugin_enabled(PLUGIN,false)
	await frames()
	check(compiled.editable,"addon unload restores original generated CodeEdit editability")
	var edited: String = compiled.text+"\n# previously dirty Ω\n"
	await append_compiled("\n# previously dirty Ω\n")
	check(compiled.get_version()!=compiled.get_saved_version(),"disabled addon dirty-buffer fixture is genuinely unsaved")
	plugin = null
	interface.set_plugin_enabled(PLUGIN,true)
	await until(find_plugin,"addon re-enable adopts dirty native Script buffer")
	guard = plugin._generated_editors
	check(not compiled.editable and compiled.text!=edited,"dirty generated view becomes protected")
	var entry: Dictionary = guard.entries[compiled.get_instance_id()]
	check(FileAccess.get_file_as_bytes(entry.recovery)==edited.to_utf8_buffer(),"prior dirty edit is durably preserved byte-for-byte before reset")
	compiled = await show_script(output)
	check(not guard.panel.get_popup().is_item_disabled(guard.panel.get_popup().get_item_index(2)),"recovery is visibly discoverable on the compiled tab")
	await generated_action(2)
	check(guard.viewer.visible and guard.preview.text==edited,"visible recovered-edit viewer exposes all preserved text")
	await capture("generated-recovery")
	guard.viewer.get_texture().get_image().save_png("res://e02-generated-recovery-view.png")
	guard.viewer.hide()
	# Programmatic/native third-party changes cannot bypass preservation.
	await append_compiled("\n# late generated edit\n")
	check(FileAccess.get_file_as_string(entry.recovery).contains("# late generated edit") and compiled.text==FileAccess.get_file_as_string(output),"generated edit signal preserves bytes before synchronization")
	# Restore the first recovered text as the newest content for restart proof.
	await append_compiled("\n# previously dirty Ω\n")
	# A failed recovery must preserve the visible bytes and block publication.
	var recovery_dir: String = guard.RECOVERY
	DirAccess.rename_absolute(recovery_dir,recovery_dir+".held")
	Fixture.write(recovery_dir,"temporary obstruction")
	var blocked_text: String = compiled.text+"\n# cannot preserve yet\n"
	await append_compiled("\n# cannot preserve yet\n")
	check(not plugin._build_sources() and compiled.text==blocked_text and compiled.get_version()!=compiled.get_saved_version(),"recovery write failure blocks build without erasing dirty bytes")
	DirAccess.remove_absolute(recovery_dir)
	DirAccess.rename_absolute(recovery_dir+".held",recovery_dir)
	check(guard.prepare() and compiled.text!=blocked_text,"recovery repair preserves pending edit then restores compiled view")
	await append_compiled("\n# previously dirty Ω\n")
	settings = current(Fixture.SETTINGS)
	if settings == null:
		await plugin._navigation.open(Fixture.SETTINGS)
		await until(func(): return current(Fixture.SETTINGS)!=null,"authored settings reopens")
		settings = current(Fixture.SETTINGS)
	var bytes := FileAccess.get_file_as_bytes(output)
	var map := FileAccess.get_file_as_bytes(output+".map.json")
	var stamp := FileAccess.get_modified_time(output)
	var cached: Script = load(output)
	var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
	settings.text = Fixture.settings().replace('</Entry2D>','</Wrong>')
	check(not plugin._build_sources(),"invalid Gogo rebuild fails closed with protected generated tab")
	check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==map and FileAccess.get_modified_time(output)==stamp and load(output)==cached and cached.source_code==bytes.get_string_from_utf8() and compiled.text==bytes.get_string_from_utf8(),"failed rebuild preserves compiled view, disk, maps and Script identity")
	check((FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray())==uid,"failed rebuild preserves UID")
	await native_turn()
	interface.play_main_scene()
	await get_tree().create_timer(0.8).timeout
	check(not interface.is_playing_scene() and not plugin.last_report.ok,"invalid source also blocks native main Play with compiled tab open")
	settings.text = Fixture.settings()
	check(plugin._build_sources(),"source repair recovers with generated protection")
	await native_turn()
	# Unrelated scripts remain ordinary native editors, even beside a bogus map.
	for path in ["res://app/Ordinary.gd","res://app/unrelated/generated/Normal.gd"]:
		Fixture.write(path,"extends Node2D\nvar value: int = 1\n")
		Fixture.write(path+".map.json",'{"format":"estragon.gogo.source-map","version":1,"sourceName":"app/Screens/Settings.gogo"}')
		var ordinary := await show_script(path)
		check(ordinary.editable and not guard.panel.visible,"ordinary/unrelated generated-folder Script remains editable: "+path)
		await type_character(ordinary)
		check(ordinary.text!=FileAccess.get_file_as_string(path),"ordinary native input still edits: "+path)
		ordinary.text = FileAccess.get_file_as_string(path)
		ordinary.tag_saved_version()
	var unowned := "res://unowned/generated/Normal.gd"
	Fixture.write("res://unowned/Normal.gogo","extends Node2D\n")
	Fixture.write(unowned,"extends Node2D\n# hand authored\n")
	Fixture.write(unowned+".map.json",JSON.stringify({"format":"estragon.gogo.source-map","version":1,"sourceName":"unowned/Normal.gogo","sourceContent":"extends Node2D\n","segments":[],"generatedHash":"mismatched"}))
	check((await show_script(unowned)).editable,"correct-looking but content-mismatched source map never protects an ordinary Script")
	var orphan := "res://unowned/generated/Missing.gd"
	Fixture.write(orphan,"extends Node2D\n")
	Fixture.write(orphan+".map.json",JSON.stringify({"format":"estragon.gogo.source-map","version":1,"sourceName":"unowned/Missing.gogo","sourceContent":"extends Node2D\n","segments":[],"generatedHash":"invalid"}))
	check((await show_script(orphan)).editable and guard.panel.text=="Gogo source missing","missing source on first open gives a non-destructive unverified status")
	compiled = await show_script(output)
	# Known authenticated tabs retain a useful status when provenance disappears;
	# new tabs with broken maps are never adopted.
	DirAccess.rename_absolute(Fixture.SETTINGS,Fixture.SETTINGS+".missing")
	guard.prepare()
	check(guard.panel.tooltip_text.contains("missing") and guard.panel.get_popup().is_item_disabled(1),"missing source gives useful status and disables nonexistent navigation")
	DirAccess.rename_absolute(Fixture.SETTINGS+".missing",Fixture.SETTINGS)
	var map_text := FileAccess.get_file_as_string(output+".map.json")
	Fixture.write(output+".map.json","{}")
	guard.prepare()
	check(guard.panel.tooltip_text.contains("unavailable") and not guard.entries.is_empty(),"known compiled view reports broken association without erasing text")
	Fixture.write(output+".map.json",map_text)
	guard.prepare()
	# Exact source-qualified Unicode association, independent of shared basename.
	home.text = Fixture.home().replace("func build_view()",'const Settings = preload("Settings.gd")\nfunc build_view()')
	var unicode_source := "res://app/设置/Settings.gogo"
	Fixture.write(unicode_source,"extends Node2D\nvar marker: int = 7\n")
	check(plugin._build_sources(),"Unicode same-name component builds with exact source identity")
	await native_turn()
	var unicode_code := await show_script(Build.output_for(unicode_source))
	check(not unicode_code.editable and guard.entries[unicode_code.get_instance_id()].source==unicode_source,"Unicode duplicate basename protection uses exact source path")
	await generated_action(1)
	check(await until(func(): return current(unicode_source)!=null,"exact Unicode authored source opens"),"Unicode source action never chooses sibling Settings")
	compiled = await show_script(output)
	await native_turn()
	compiled.set_line_as_breakpoint(2,true)
	plugin._generated_editors.refresh()
	check(compiled.get_breakpointed_lines().has(2) and not compiled.editable and interface.get_script_editor().get_current_script().resource_path==output,"native breakpoint/debugger inspection and no-op refresh remain available on read-only output")
	await capture("generated-final")
	Fixture.write("res://.godot/e09-restart","restart")
	finish()
