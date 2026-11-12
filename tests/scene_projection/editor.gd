@tool
extends EditorPlugin
var interface: EditorInterface
var plugin: EditorPlugin
var failed := false
var checks := 0
var timer: Timer
var home: Node
const HOME := "res://app/Home.gogo"
const SETTINGS := "res://app/Settings.gogo"
const OUTPUT := "res://app/generated/Settings.gd"
func _enter_tree() -> void:
	interface = get_editor_interface()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	run.call_deferred()
func check(value: bool, message: String) -> void:
	checks += 1
	print("E08_EDITOR_CHECK ",message,": ",value)
	if not value: failed = true
func until(condition: Callable, message: String) -> bool:
	var deadline := Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,message)
	return false
func find_plugin() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node != self and node.get_script()!=null and node.get_script().resource_path=="res://addons/estragon/editor/plugin.gd": plugin = node
	return plugin != null and plugin.last_report.get("ok",false) and not plugin._extensions_pending
func current(path: String):
	for entry in plugin._services.entries.values():
		var code = entry.code.get_ref()
		if code!=null and entry.path==path and code.is_visible_in_tree(): return code
	return null
func settle() -> void:
	for attempt in range(30):
		await until(func(): return not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(),"native filesystem/build settles")
		var busy := false
		for dialog in get_tree().root.find_children("*","ProgressDialog",true,false):
			if not dialog.find_children("*","ProgressBar",true,false).is_empty(): busy = true
		if busy: await get_tree().process_frame; continue
		var count: int = plugin.build_count
		timer.start(0.15)
		await timer.timeout
		if count==plugin.build_count and plugin._timer.is_stopped(): return
	check(false,"bounded native editor progress")
func play(mode: String, caption: String) -> void:
	await settle()
	if FileAccess.file_exists("res://.godot/e08-game.json"): DirAccess.remove_absolute("res://.godot/e08-game.json")
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(func(): return FileAccess.file_exists("res://.godot/e08-game.json"),mode+" actual child layout proof"):
		var proof = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/e08-game.json"))
		check(proof.caption==caption and proof.button_height>0 and proof.button_y>=proof.hello_end and proof.middle_y>=proof.button_y+proof.button_height and proof.children==3 and proof.native_parent and proof.owner and proof.persisted==42 and proof.clicks==1 and proof.sprite,mode+" rendered nested views have correct slots, no duplicates and latest saved child source")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"native child stops")
func run() -> void:
	if not await until(find_plugin,"installed addon activates"): finish(); return
	var prefs := interface.get_editor_settings()
	prefs.set_setting("run/auto_save/save_before_running",false)
	prefs.set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"native saved host scene opens")
	home = interface.get_edited_scene_root()
	if FileAccess.file_exists("res://.godot/e08-restart"):
		await play("main","Settings edited")
		finish(); return
	await author_scene()
	await play("main","Settings")
	await play("current","Settings")
	await plugin._navigation.open(SETTINGS)
	if not await until(func(): return current(SETTINGS)!=null,"native authored Settings opens"): finish(); return
	var source: CodeEdit = current(SETTINGS)
	var original := source.text
	source.text = original.replace('caption: String = "Settings"','caption: String = "Settings edited"')
	await play("main","Settings edited")
	await play("current","Settings edited")
	check(FileAccess.get_file_as_string(SETTINGS).contains('caption: String = "Settings edited"'),"both Play paths forced-save unsaved Gogo dependency")
	await settle()
	var bytes := FileAccess.get_file_as_bytes(OUTPUT)
	var maps := FileAccess.get_file_as_bytes(OUTPUT+".map.json")
	var stamp := FileAccess.get_modified_time(OUTPUT)
	var cached: Script = load(OUTPUT)
	var uid := FileAccess.get_file_as_bytes(OUTPUT+".uid") if FileAccess.file_exists(OUTPUT+".uid") else PackedByteArray()
	source.text = source.text.replace('</VBox>','</Wrong>')
	if FileAccess.file_exists("res://.godot/e08-game.json"): DirAccess.remove_absolute("res://.godot/e08-game.json")
	interface.play_main_scene()
	await get_tree().create_timer(0.8).timeout
	check(not interface.is_playing_scene() and not plugin.last_report.ok and not FileAccess.file_exists("res://.godot/e08-game.json"),"invalid child Gogo blocks native Play")
	check(FileAccess.get_file_as_bytes(OUTPUT)==bytes and FileAccess.get_file_as_bytes(OUTPUT+".map.json")==maps and FileAccess.get_modified_time(OUTPUT)==stamp and load(OUTPUT)==cached,"failed source reload retains maps/bytes/timestamps/Script identity")
	check((FileAccess.get_file_as_bytes(OUTPUT+".uid") if FileAccess.file_exists(OUTPUT+".uid") else PackedByteArray())==uid,"failed source reload retains native UID")
	source.text = original.replace('caption: String = "Settings"','caption: String = "Settings edited"')
	check(plugin._build_sources(),"source repair recovers existing native compiler")
	await play("current","Settings edited")
	await settle()
	check(interface.save_scene()==OK,"native authored host scene saves without transient views")
	var scene: PackedScene = load("res://app/Home.tscn")
	check(scene.get_state().get_node_count()==3,"saved scene persists Home/Settings/Sprite only, with no transient output")
	var file := FileAccess.open("res://.godot/e08-restart",FileAccess.WRITE)
	file.store_string("restart")
	file.close()
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://editor.png")
	finish()
func finish() -> void:
	print("E08_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("E08_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
func history() -> UndoRedo:
	var undo := plugin.get_undo_redo()
	return undo.get_history_undo_redo(undo.get_object_history_id(home))
func select(node: Node) -> void:
	interface.get_selection().clear()
	interface.get_selection().add_node(node)
	interface.edit_node(node)
func author_scene() -> void:
	var service = plugin._scene_components
	select(home)
	await settle()
	service.choose("add",weakref(home))
	await until(func(): return service.picker.visible,"native Gogo child picker opens")
	var selected := -1
	for index in range(service.list.item_count):
		if service.list.get_item_metadata(index)==SETTINGS: selected = index
	check(selected>=0,"Settings authored source offered through existing native scene integration")
	if selected<0: return
	service.list.select(selected)
	service.list.item_selected.emit(selected)
	service.picker.confirmed.emit()
	await until(func(): return home.has_node("Settings"),"native scene transaction inserts Settings")
	var settings := home.get_node("Settings")
	check(settings.get_script()==load(OUTPUT) and settings.owner==home and settings.get_parent()==home,"actual Settings native instance has authored association/owner")
	check(history().undo() and settings.get_parent()==null,"native Undo removes Settings without deleting the retained instance")
	check(history().redo() and home.get_node("Settings")==settings,"native Redo restores the same Settings instance")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.position = Vector2(400,220)
	var texture := GradientTexture2D.new()
	texture.width = 24
	texture.height = 24
	sprite.texture = texture
	var undo := plugin.get_undo_redo()
	undo.create_action("Add native Sprite2D",UndoRedo.MERGE_DISABLE,home)
	undo.add_do_method(home,"add_child",sprite,true)
	undo.add_do_property(sprite,"owner",home)
	undo.add_undo_method(home,"remove_child",sprite)
	undo.add_do_reference(sprite)
	undo.commit_action()
	check(sprite.owner==home and sprite.get_parent()==home,"native scene API authors owned Sprite2D alongside Gogo child")
	undo.create_action("Edit Settings property",UndoRedo.MERGE_DISABLE,home)
	undo.add_do_property(settings,"persisted",42)
	undo.add_undo_property(settings,"persisted",17)
	undo.commit_action()
	check(settings.get("persisted")==42,"native authored exported property is editable")
	select(settings)
	await settle()
	check(interface.save_scene()==OK,"native authored children save before Play")
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://scene-dock.png")
	# Deletion and Undo use the stock editor history and preserve owner/state.
	undo.create_action("Delete scene Settings",UndoRedo.MERGE_DISABLE,home)
	undo.add_do_method(home,"remove_child",settings)
	undo.add_undo_method(home,"add_child",settings,true)
	undo.add_undo_property(settings,"owner",home)
	undo.add_undo_reference(settings)
	undo.commit_action()
	check(not home.has_node("Settings") and is_instance_valid(settings),"native scene deletion retains undo reference")
	check(history().undo() and home.get_node("Settings")==settings and settings.owner==home and settings.get("persisted")==42,"Undo deletion restores exact instance, exported state and ownership")
	check(history().redo() and not home.has_node("Settings"),"Redo deletion removes only authored child")
	check(history().undo() and home.get_node("Settings")==settings,"second Undo repairs scene before Play")
	select(home)
	await settle()
	check(interface.save_scene()==OK,"scene saves after delete/undo/redo")
