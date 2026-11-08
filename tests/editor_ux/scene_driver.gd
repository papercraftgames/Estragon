@tool
extends "driver.gd"
## E05 scoped stock-editor workflow; shared native input/navigation helpers.
var app: Node
func click(control: Control) -> void:
	check(is_instance_valid(control),"native control available for input")
	if not is_instance_valid(control): return
	var window := control.get_window()
	var point := control.global_position+control.size/2
	window.grab_focus()
	await frames(2)
	var motion := InputEventMouseMotion.new()
	motion.window_id = window.get_window_id()
	motion.position = point
	motion.relative = Vector2(1,1)
	motion.velocity = Vector2(60,60)
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.window_id = motion.window_id
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(4)
func button(text: String) -> Button:
	for candidate in interface.get_inspector().find_children("*","Button",true,false):
		if candidate.text == text and candidate.is_visible_in_tree(): return candidate
	return null
func inspect(node: Node) -> void:
	interface.get_selection().clear()
	interface.get_selection().add_node(node)
	interface.edit_node(node)
	await until(func(): return button("Attach/Change Gogo Component…") != null,"native Inspector component actions appear")
func pick(source: String) -> void:
	var service = plugin._scene_components
	if not await until(func(): return service.picker.visible,"authored-source picker opens"): return
	var index := -1
	for row in range(service.list.item_count):
		if service.list.get_item_metadata(row) == source: index = row
	check(index >= 0,"picker lists authored source: "+source)
	if index < 0: service.picker.hide(); return
	service.list.select(index)
	service.list.item_selected.emit(index)
	await click(service.picker.get_ok_button())
func history() -> UndoRedo:
	var manager := plugin.get_undo_redo()
	return manager.get_history_undo_redo(manager.get_object_history_id(app))
func find_item(item: TreeItem, text: String) -> TreeItem:
	if item == null: return null
	if item.get_text(0) == text: return item
	var child := item.get_first_child()
	while child != null:
		var found := find_item(child,text)
		if found != null: return found
		child = child.get_next()
	return null
func native_add() -> void:
	await inspect(app)
	var scene_tree: Tree
	for tree in interface.get_base_control().find_children("*","Tree",true,false):
		if tree.is_visible_in_tree() and tree.get_selected()!=null and str(tree.get_selected().get_metadata(0)) == str(app.get_path()): scene_tree = tree; break
	check(scene_tree != null,"native Scene tree identifies selected App")
	if scene_tree == null: return
	scene_tree.get_window().grab_focus()
	scene_tree.grab_focus()
	var add: Button
	for candidate in interface.get_base_control().find_children("*","Button",true,false):
		if candidate.is_visible_in_tree() and candidate.tooltip_text.begins_with("Add/Create a New Node"): add = candidate; break
	await click(add)
	await frames(8)
	var dialog: ConfirmationDialog
	for window in get_tree().root.find_children("*","ConfirmationDialog",true,false):
		if window.visible and window.title == "Create New Node": dialog = window; break
	check(dialog != null,"stock Create New Node dialog opens through native Add Child button")
	if dialog == null: return
	var search: LineEdit
	for line in dialog.find_children("*","LineEdit",true,false):
		if line.is_visible_in_tree(): search = line; break
	check(search != null,"native Create Node search control")
	if search == null: dialog.hide(); return
	search.text = "Home"
	search.text_changed.emit(search.text)
	await frames(10)
	var selected: TreeItem
	var options: Tree
	for tree in dialog.find_children("*","Tree",true,false):
		var item := find_item(tree.get_root(),plugin._scene_components.items[HOME].label)
		if item != null: options = tree; selected = item; break
	check(selected != null,"native search includes Home Gogo component registration")
	if selected == null: dialog.hide(); return
	selected.select(0)
	options.item_selected.emit()
	await frames()
	RenderingServer.force_draw(false)
	dialog.get_texture().get_image().save_png("res://e02-native-create-node.png")
	var count := app.get_child_count()
	await click(dialog.get_ok_button())
	check(await until(func(): return app.get_child_count()==count+1,"native Create Node inserts component"),"native node insertion")
	var associated := false
	for child in app.get_children(): associated = associated or plugin._scene_components.source_for(child.get_script()) == HOME and child.owner == app
	check(associated,"native custom type creates owned child with authored association")
func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
func _run() -> void:
	if not await until(find_plugin,"installed addon activates for scene authoring"): finish(); return
	interface.get_editor_settings().set_setting("text_editor/behavior/files/auto_reload_scripts_on_external_change",true)
	if interface.get_editor_settings().has_setting("run/window_placement/game_embed_mode"):
		interface.get_editor_settings().set_setting("run/window_placement/game_embed_mode",-1)
	if FileAccess.file_exists("res://.godot/e05-restart"):
		interface.open_scene_from_path("res://app/App.tscn")
		if await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/App.tscn","saved authored component scene reopens"):
			app = interface.get_edited_scene_root()
			check(plugin._scene_components.source_for(app.get_script()) == HOME,"authored association survives restart")
			await inspect(app)
			await click(button("Open Gogo Source"))
			check(await until(func(): return current(HOME)!=null,"restart opens original source"),"restart authored editor")
			await play("main")
		finish(); return
	home = await create(HOME)
	if home == null: finish(); return
	# Deliberately authored render proof, not template content.
	var source := authored_view()+'\nfunc _ready() -> void:\n\tif not Engine.is_editor_hint(): _proof.call_deferred()\nfunc _proof() -> void:\n\tawait get_tree().process_frame\n\tawait get_tree().process_frame\n\tawait RenderingServer.frame_post_draw\n\tget_viewport().get_texture().get_image().save_png("res://e02-scene-game.png")\n\tvar output := FileAccess.open("res://.godot/e02-game.json",FileAccess.WRITE)\n\toutput.store_string(JSON.stringify({"text":get_node("UI").find_child("Greeting",true,false).text}))\n\toutput.close()\n'
	home.text = source
	original = source
	check(plugin._build_sources(),"component builds for native registry")
	check(plugin._scene_components.items.has(HOME),"compiled Home registered without authored new()")
	var root := Node2D.new()
	root.name = "App"
	var preserved := Node2D.new()
	preserved.name = "Preserved"
	preserved.position = Vector2(12,34)
	root.add_child(preserved)
	preserved.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed,"res://app/App.tscn")
	root.free()
	ProjectSettings.set_setting("application/run/main_scene","res://app/App.tscn")
	ProjectSettings.save()
	interface.open_scene_from_path("res://app/App.tscn")
	if not await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/App.tscn","plain native scene opens"): finish(); return
	app = interface.get_edited_scene_root()
	await inspect(app)
	await capture("scene-inspector-before")
	await click(button("Attach/Change Gogo Component…"))
	await pick(HOME)
	if not await until(func(): return app.get_script()!=null,"authored component attaches through Inspector"): finish(); return
	check(plugin._scene_components.source_for(app.get_script()) == HOME,"native Script exposes durable authored association")
	check(app.get_node("Preserved").position == Vector2(12,34),"attachment preserves native children/transforms")
	check(history().undo(),"native scene undo attachment")
	check(app.get_script() == null,"undo restores original null Script")
	check(history().redo(),"native scene redo attachment")
	check(plugin._scene_components.source_for(app.get_script()) == HOME,"redo restores authored component")
	await inspect(app)
	if await until(func(): return button("Open Gogo Source")!=null,"Inspector exposes original source"):
		await click(button("Open Gogo Source"))
		check(await until(func(): return current(HOME)!=null,"opens .gogo rather than generated Script"),"authored source navigation")
	await capture("scene-inspector-attached")
	check(interface.save_scene() == OK,"native scene save")
	for mode in ["main","current"]: await play(mode)
	await native_add()
	await inspect(app)
	await click(button("Add Gogo Child…"))
	await pick(HOME)
	check(await until(func(): return app.find_child("Home",false,false)!=null,"Add Gogo child uses native hierarchy"),"add-child action")
	var child := app.find_child("Home",false,false)
	if child != null:
		check(child.owner == app and plugin._scene_components.source_for(child.get_script()) == HOME,"child scene owner/source association")
		check(history().undo() and not child.is_inside_tree(),"undo add removes only added child")
		check(history().redo() and child.get_parent() == app,"redo restores native child")
	# Cancel does not create a history action or replace Script.
	var before := history().get_version()
	await inspect(app)
	await click(button("Attach/Change Gogo Component…"))
	plugin._scene_components.picker.get_cancel_button().pressed.emit()
	await frames()
	check(history().get_version() == before,"cancel leaves scene history untouched")
	check(interface.save_scene() == OK,"save ordinary/native component children")
	write("res://.godot/e05-restart","restart")
	await capture("scene-final")
	finish()
