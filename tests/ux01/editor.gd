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
	print("UX01_EDITOR_CHECK ",label,": ",ok)
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
		if item.path=="res://app/UXGallery.gogo" and value!=null and value.is_visible_in_tree(): return value
	return null
func game_ready() -> bool:
	var file := "res://.godot/ux01-game.json"
	if not FileAccess.file_exists(file): return false
	var parser := JSON.new()
	return parser.parse(FileAccess.get_file_as_string(file))==OK and parser.data is Dictionary and not parser.data.is_empty()
func play(mode: String) -> void:
	await settle()
	var file := "res://.godot/ux01-game.json"
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(game_ready,"actual native UX01 game"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(file))
		check(result.ok and result.clicks==8 and result.edits==[true,false,true,false] and result.samples.size()==12,mode+" actual rendered UX01/minimum/native input/controlled Toggle at two sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func run() -> void:
	if not await until(ready,"installed addon ready"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/UXGallery.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/UXGallery.tscn","authored scene opens")
	await settle()
	await inspector_proof()
	check(interface.get_edited_scene_root().get_script().resource_path=="res://app/generated/UXGallery.gd","real native authored UX01 scene imports")
	if not FileAccess.file_exists("res://.godot/ux01-restart"):
		await plugin._navigation.open("res://app/UXGallery.gogo")
		await until(func(): return code()!=null,"exact associated source CodeEdit opens")
		await settle()
		var buffer := code()
		var source := buffer.text
		check(buffer.syntax_highlighter!=null,"native Gogo highlighter attached to actual UX01 source")
		var output := "res://app/generated/UXGallery.gd"
		for mode in ["current","main"]:
			var bytes := FileAccess.get_file_as_bytes(output)
			var maps := FileAccess.get_file_as_bytes(output+".map.json")
			var timestamp := FileAccess.get_modified_time(output)
			var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
			var cached = load(output)
			print("UX01_EXPECTED_PLAY_REJECTION_BEGIN")
			buffer.text = source.replace('<HBox name="Wrap" wrap','<HBox name="Wrap" width') if mode=="current" else source.replace('Hello {self.username}!','Hello {42}!')
			if mode=="main": interface.play_main_scene()
			else: interface.play_current_scene()
			await wait(0.8)
			check(not interface.is_playing_scene() and not plugin.last_report.ok and str(plugin.last_report.diagnostics).contains("app/UXGallery.gogo:"),mode+" invalid unsaved UX01 blocks stale Play with authored diagnostic")
			check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==timestamp and (not FileAccess.file_exists(output+".uid") or FileAccess.get_file_as_bytes(output+".uid")==uid) and load(output)==cached,mode+" invalid UX01 retains code/map/UID/timestamp/cached Script")
			print("UX01_EXPECTED_PLAY_REJECTION_END")
			buffer.text = source+"\n# UX01 repaired latest source\n"
			await play(mode)
			check(FileAccess.get_file_as_string("res://app/UXGallery.gogo").contains("# UX01 repaired latest source"),mode+" repair saves latest authored Gogo before actual Play")
		var marker := FileAccess.open("res://.godot/ux01-restart",FileAccess.WRITE)
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
	print("UX01_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UX01_EDITOR_OK")
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
	node.height = 300
	node.name = "InspectorScroll"
	entry.add_child(node)
	node.owner = scene
	interface.inspect_object(node)
	await until(func(): return inspector_field("vertical_scroll")!=null,"native scrolling component Inspector")
	for name in ["horizontal_scroll","vertical_scroll","scroll_offset","max_width","max_height"]:
		check(inspector_field(name)!=null,"scrolling component native Inspector "+name)
	var field := inspector_field("vertical_scroll")
	field.property_changed.emit("vertical_scroll",true,"",false)
	await wait()
	var manager := get_undo_redo()
	var history := manager.get_history_undo_redo(manager.get_object_history_id(node))
	check(node.vertical_scroll and history.undo() and not node.vertical_scroll and history.redo() and node.vertical_scroll,"scrolling component Inspector edit/undo/redo")
	inspector_field("max_height").property_changed.emit("max_height","380px","",false)
	await wait()
	check(node.max_height=="380px" and history.undo() and node.max_height=="auto" and history.redo() and node.max_height=="380px","max Length Inspector edit/undo/redo")
	var content = preload("res://addons/estragon/runtime/node/rect.gd").new()
	content.height = 900
	node.add_child(content)
	content.owner = scene
	await wait()
	inspector_field("scroll_offset").property_changed.emit("scroll_offset",Vector2(0,160),"",false)
	await wait()
	check(node.scroll_offset==Vector2(0,160) and history.undo() and node.scroll_offset==Vector2.ZERO and history.redo() and node.scroll_offset==Vector2(0,160),"inherited offset Inspector edit/undo/redo")
	interface.inspect_object(scene)
	scene.remove_child(entry)
	entry.free()
	await wait()
	var box = preload("res://addons/estragon/runtime/node/hbox.gd").new()
	scene.add_child(box)
	box.owner = scene
	interface.inspect_object(box)
	await until(func(): return inspector_field("wrap")!=null,"native Wrap Inspector")
	inspector_field("wrap").property_changed.emit("wrap",true,"",false)
	await wait()
	history = manager.get_history_undo_redo(manager.get_object_history_id(box))
	check(box.wrap and history.undo() and not box.wrap and history.redo() and box.wrap,"Wrap Inspector edit/undo/redo")
	interface.inspect_object(scene)
	scene.remove_child(box)
	box.free()
	await wait()
