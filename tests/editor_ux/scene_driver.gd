@tool
extends "driver.gd"
## E05 scoped stock-editor workflow; shared native input/navigation helpers.
var app: Node
var _save_timer: Timer
func native_turn() -> void:
	# Native 4.0 save progress pumps Main::iteration and disallows the message
	# queue. A one-shot Timer stops before timeout emission, preventing reentry
	# into completed process_frame awaits (SceneTreeTimer stops after emission).
	if _save_timer == null:
		_save_timer = Timer.new()
		_save_timer.one_shot = true
		add_child(_save_timer)
	_save_timer.start(0.05)
	await _save_timer.timeout
	# Keep the stopped emitter until plugin teardown: subsequent native Play
	# can pump the message queue before this timeout emission unwinds.
func save_scene() -> Error:
	await native_turn()
	return interface.save_scene()
func play(mode: String) -> void:
	await native_turn()
	await super.play(mode)
func blocked(mode: String, unsavable: bool = false) -> void:
	await native_turn()
	await super.blocked(mode,unsavable)
func click(control: Control) -> void:
	check(is_instance_valid(control),"native control available for input")
	if not is_instance_valid(control): return
	var window := control.get_window()
	var point := control.global_position+control.size/2
	var action: String = control.text if control is Button and control.text in ["Attach/Change Gogo Component…","Add Gogo Child…","Open Gogo Source"] else ""
	window.grab_focus()
	await frames(2)
	if not action.is_empty():
		var current_button := button(action)
		if current_button == null: check(false,"Inspector action persists after focus"); return
		point = current_button.global_position+current_button.size/2
	var motion := InputEventMouseMotion.new()
	var native_window := window.has_method("get_window_id")
	if native_window: motion.window_id = window.call("get_window_id")
	motion.position = point
	motion.relative = Vector2(1,1)
	motion.velocity = Vector2(60,60)
	if native_window: Input.parse_input_event(motion)
	else: window.push_input(motion,true)
	var event := InputEventMouseButton.new()
	event.window_id = motion.window_id
	event.position = motion.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	if native_window: Input.parse_input_event(event)
	else: window.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	if native_window: Input.parse_input_event(event)
	else: window.push_input(event,true)
	await frames(4)
func button(text: String) -> Button:
	for candidate in interface.get_inspector().find_children("*","Button",true,false):
		if candidate.text == text and candidate.is_visible_in_tree(): return candidate
	return null
func inspect(node: Node) -> void:
	interface.get_selection().clear()
	interface.get_selection().add_node(node)
	interface.edit_node(node)
	await frames(10)
	await until(func(): return button("Attach/Change Gogo Component…") != null,"native Inspector component actions appear for selected node")
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
	if source == HOME and not FileAccess.file_exists("res://e02-scene-source-picker.png"):
		await frames()
		RenderingServer.force_draw(false)
		service.picker.get_texture().get_image().save_png("res://e02-scene-source-picker.png")
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
func native_add(source: String = HOME, insert: bool = true) -> void:
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
	if insert: await click(add)
	elif add != null: add.pressed.emit()
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
	search.text = source.get_file().get_basename()
	search.text_changed.emit(search.text)
	await frames(10)
	var selected: TreeItem
	var options: Tree
	for tree in dialog.find_children("*","Tree",true,false):
		var item := find_item(tree.get_root(),plugin._scene_components.items[source].label)
		if item != null: options = tree; selected = item; break
	check(selected != null,"native search includes Home Gogo component registration")
	if selected == null: dialog.hide(); return
	if not insert:
		dialog.get_cancel_button().pressed.emit()
		return
	selected.select(0)
	options.item_selected.emit()
	await frames()
	RenderingServer.force_draw(false)
	dialog.get_texture().get_image().save_png("res://e02-native-create-node.png")
	var count := app.get_child_count()
	await click(dialog.get_ok_button())
	check(await until(func(): return app.get_child_count()==count+1,"native Create Node inserts component"),"native node insertion")
	var associated := false
	for child in app.get_children(): associated = associated or plugin._scene_components.source_for(child.get_script()) == source and child.owner == app
	check(associated,"native custom type creates owned child with authored association")
func more_checks() -> void:
	var service = plugin._scene_components
	var spatial_path := "res://app/Screens/World.gogo"
	write(spatial_path,preload("res://addons/estragon/editor/new_script.gd").template(spatial_path,true))
	write("res://app/Other/Home.gogo","extends Node2D\n")
	write("res://app/Model.gogo","extends RefCounted\nvar value: int = 3\n")
	write("res://app/Required.gogo","extends Node2D\nfunc _init(value: int) -> void:\n\tposition.x = value\n")
	write("res://app/NoConstruct.gogo",'extends Node2D\nfunc _init() -> void:\n\tpush_error("CATALOG_MUST_NOT_CONSTRUCT_AUTHORED_NODE")\n')
	check(plugin._build_sources(),"new component/model files compile without construction")
	check(service.items.has(spatial_path) and not service.items.has("res://app/Model.gogo") and not service.items.has("res://app/Required.gogo"),"registry excludes data models and required constructors")
	check(service.items[HOME].label != service.items["res://app/Other/Home.gogo"].label and service.items[HOME].label.contains("app/Screens"),"duplicate component names are source-qualified")
	await native_add("res://app/Other/Home.gogo",false)
	await inspect(app)
	var version := history().get_version()
	var previous = app.get_script()
	await click(button("Attach/Change Gogo Component…"))
	await pick(spatial_path)
	check(await until(func(): return service.error.visible,"incompatible host visibly rejected"),"wrong-dimension validation")
	check(app.get_script() == previous and history().get_version() == version,"wrong dimension preserves Script/scene history")
	service.error.hide()
	await inspect(app)
	await click(button("Add Gogo Child…"))
	await pick(spatial_path)
	var world: Node
	await until(func(): return app.find_child("World",false,false)!=null,"3D component can be added as native child")
	world = app.find_child("World",false,false)
	check(world is Node3D and world.owner == app and service.source_for(world.get_script()) == spatial_path,"native 3D creation uses matching host/owner")
	check(history().undo() and not world.is_inside_tree(),"3D addition supports native undo")
	# A normal .gd script is preserved until explicit confirmation; undo restores
	# both its Script identity and stored exported values, without helper callbacks.
	write("res://app/OrdinaryScene.gd","extends Node2D\n@export var marker: int = 7\n")
	var normal: Script = load("res://app/OrdinaryScene.gd")
	var preserved := app.get_node("Preserved")
	preserved.set_script(normal)
	preserved.set("marker",13)
	check(await save_scene() == OK,"ordinary Script setup saved")
	await inspect(preserved)
	version = history().get_version()
	await click(button("Attach/Change Gogo Component…"))
	await pick(HOME)
	check(await until(func(): return service.replace.visible,"ordinary Script replacement asks confirmation"),"replacement confirmation visible")
	service.replace.get_cancel_button().pressed.emit()
	await frames()
	check(preserved.get_script() == normal and preserved.get("marker") == 13 and history().get_version() == version,"replacement cancel preserves old Script/values/history")
	await inspect(preserved)
	await click(button("Attach/Change Gogo Component…"))
	await pick(HOME)
	if await until(func(): return service.replace.visible,"replacement reopens"):
		await click(service.replace.get_ok_button())
	check(await until(func(): return service.source_for(preserved.get_script()) == HOME,"replacement attaches selected Gogo"),"ordinary-to-Gogo replacement")
	check(history().undo() and preserved.get_script() == normal and preserved.get("marker") == 13,"undo restores ordinary Script identity and exported value")
	check(history().redo() and service.source_for(preserved.get_script()) == HOME,"redo restores replacement")
	# Rename/delete never-opened source to avoid unrelated TextFile reload prompts.
	var old := "res://app/MoveMe.gogo"
	var moved := "res://app/Relocated.gogo"
	write(old,"extends Node2D\n")
	check(plugin._build_sources(),"new source refreshes registry")
	await inspect(preserved)
	await click(button("Attach/Change Gogo Component…"))
	await pick(old)
	if await until(func(): return service.replace.visible,"Gogo-to-Gogo replacement confirmation"):
		await click(service.replace.get_ok_button())
	check(await until(func(): return service.source_for(preserved.get_script()) == old,"Gogo replacement applied"),"Gogo-to-Gogo replacement")
	DirAccess.rename_absolute(old,moved)
	check(plugin._build_sources() and service.items.has(moved) and not service.items.has(old),"move updates registry without silently retargeting scene")
	check(not plugin._build() and service.source_for(preserved.get_script()) == old,"missing attached source blocks stale generated Play")
	check(await save_scene() == OK,"save changed component before native Play gate")
	interface.play_main_scene()
	await get_tree().create_timer(0.5).timeout
	check(not interface.is_playing_scene() and not plugin.last_report.ok,"actual main Play rejects missing authored component")
	await inspect(preserved)
	await click(button("Attach/Change Gogo Component…"))
	await pick(moved)
	if await until(func(): return service.replace.visible,"repair missing source via normal picker"):
		await click(service.replace.get_ok_button())
	check(await until(func(): return service.source_for(preserved.get_script()) == moved,"repair selects authored moved source"),"reattach repairs missing association")
	DirAccess.remove_absolute(moved)
	check(plugin._build_sources() and not service.items.has(moved) and not plugin._build(),"deleted source removed and scene Play gate fails closed")
	write(moved,"extends Node2D\n")
	check(plugin._build(),"source restoration/regeneration repairs scene gate")
	var output: String = preload("res://addons/estragon/editor/build_service.gd").output_for(moved)
	DirAccess.remove_absolute(output)
	check(plugin._build() and FileAccess.file_exists(output),"missing generated Script regenerates through existing build transaction")
	# Real Play invalid-buffer guard + rollback retains the attached Script.
	await plugin._navigation.open(HOME)
	await until(func(): return current(HOME)!=null,"return to authored source for invalid Play")
	home = current(HOME)
	home.text = original+"\n# unsaved source edit\n"
	check(not service.registered.has(HOME),"editing source immediately suspends stale native creation entry")
	check(plugin._compile() and not service.registered.has(HOME),"disk-only refresh cannot re-register dirty source")
	check(plugin._build_sources() and service.registered.has(HOME),"saved validated source restores native registration")
	await blocked("main")
	home.text = original
	check(plugin._build(),"repair invalid source preserves attachment and recovers Play")
	check(await save_scene() == OK,"save repaired association before current Play")
	await play("current")
	# All history methods target native objects, so pending undo remains valid
	# while the addon is disabled. Registry and owned Inspector UI are removed.
	var count: int = service.registered.size()
	var attached = app.get_script()
	var scene_history := history()
	interface.set_plugin_enabled(PLUGIN,false)
	await frames(5)
	check(app.get_script() == attached and button("Attach/Change Gogo Component…") == null,"disable preserves native Script and removes owned Inspector controls")
	check(service.registered.is_empty(),"disable unregisters all owned custom types")
	check(scene_history.undo() and service.source_for(preserved.get_script()) == old,"native replacement undo remains valid while addon disabled")
	check(scene_history.redo() and service.source_for(preserved.get_script()) == moved,"native replacement redo remains valid while addon disabled")
	plugin = null
	interface.set_plugin_enabled(PLUGIN,true)
	check(await until(find_plugin,"re-enable rebuilds one native registry"),"plugin re-enable")
	check(plugin._scene_components.registered.size() == count,"re-enable has no duplicate registrations")
	await inspect(app)
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
			var children := 0
			for child in app.get_children():
				if plugin._scene_components.source_for(child.get_script()) == HOME and child.owner == app: children += 1
			check(children >= 2,"native-dialog and Inspector-created children retain ownership/source after save/restart")
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
	check(await save_scene() == OK,"native scene save")
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
	await more_checks()
	check(await save_scene() == OK,"save ordinary/native component children")
	write("res://.godot/e05-restart","restart")
	await capture("scene-final")
	finish()
