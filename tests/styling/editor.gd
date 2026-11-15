@tool
extends EditorPlugin
var interface: EditorInterface
var plugin: EditorPlugin
var timer: Timer
var checks := 0
var failed := false
func _enter_tree() -> void:
	interface = get_editor_interface()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S01_EDITOR_CHECK ",label,": ",ok)
	if not ok: failed = true
func until(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,label)
	return false
func ready() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node!=self and node.get_script()!=null and node.get_script().resource_path=="res://addons/estragon/editor/plugin.gd": plugin = node
	return plugin!=null and plugin.last_report.get("ok",false) and not plugin._extensions_pending
func code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var editor = item.code.get_ref()
		if item.path=="res://app/StyleGallery.gogo" and editor!=null and editor.is_visible_in_tree(): return editor
	return null
func settle() -> void:
	for attempt in range(30):
		await until(func(): return not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(),"native filesystem settles")
		var count: int = plugin.build_count
		timer.start(0.15)
		await timer.timeout
		if count==plugin.build_count and not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(): return
	check(false,"bounded editor settle")
func play(mode: String) -> void:
	await settle()
	var path := "res://.godot/s01-game.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(func(): return FileAccess.file_exists(path),"actual styled game proof"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(result.native==2 and result.ui==2 and result.samples.size()==2 and result.samples.all(func(item): return item.root and item.half==item.content/2 and item.color),mode+" real painted game/percent content/native and Estragon clicks at two sizes")
		check(result.widgets.native==2 and result.widgets.ui==2 and result.widgets.edits==[false,true] and result.widgets.enabled and result.widgets.samples.all(func(item): return item.root and item.color),mode+" actual widget painted states/native input/controlled edit at two sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"game stops")
func field(name: String) -> EditorProperty:
	for node in interface.get_inspector().find_children("*","EditorProperty",true,false):
		if node.get_edited_property()==name: return node
	return null
func inspector() -> void:
	var scene := interface.get_edited_scene_root()
	var box = preload("res://addons/estragon/runtime/node/component_2d.gd").new()
	box.name = "StyleInspector"
	scene.add_child(box)
	box.owner = scene
	interface.inspect_object(box)
	if await until(func(): return field("background_color")!=null,"native color Inspector field"):
		var color := field("background_color")
		color.input.text_submitted.emit("#123456")
		for frame in range(5): await get_tree().process_frame
		check(box.background_color=="#123456","Inspector retains authored hex")
		var manager := get_undo_redo()
		var history := manager.get_history_undo_redo(manager.get_object_history_id(box))
		check(history.undo() and box.background_color=="transparent","Inspector color undo")
		check(history.redo() and box.background_color=="#123456","Inspector color redo")
		color = field("background_color")
		color.input.text_submitted.emit("invalid")
		check(box.background_color=="#123456" and not color.input.tooltip_text.is_empty(),"invalid Inspector color explains rejection without mutation")
		color.picker.color_changed.emit(Color.CORNFLOWER_BLUE)
		for frame in range(5): await get_tree().process_frame
		color = field("background_color")
		check(box.background_color==Color.CORNFLOWER_BLUE and color.input.modulate==Color.WHITE and color.input.tooltip_text.is_empty(),"native Color picker writes Color and clears invalid-entry feedback")
		var width := field("border_width")
		width.input.text_submitted.emit("2.5in")
		for frame in range(5): await get_tree().process_frame
		check(box.border_width=="2.5in","border Inspector reuses unit union control")
		width = field("border_width")
		width.input.text_submitted.emit("auto")
		check(box.border_width=="2.5in" and not width.input.tooltip_text.is_empty(),"uniform border auto rejects in Inspector")
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png("res://inspector.png")
	interface.inspect_object(scene)
	scene.remove_child(box)
	box.free()
func widget_inspectors() -> void:
	var scene := interface.get_edited_scene_root()
	for script in [preload("res://addons/estragon/runtime/node/text.gd"),preload("res://addons/estragon/runtime/node/rect.gd"),preload("res://addons/estragon/runtime/node/button.gd"),preload("res://addons/estragon/runtime/node/toggle.gd")]:
		var widget = script.new()
		widget.name = "WidgetInspector"
		scene.add_child(widget)
		widget.owner = scene
		interface.inspect_object(widget)
		if await until(func(): return field("background_color")!=null,"actual widget Inspector fields"):
			var previous = widget.background_color
			var color := field("background_color")
			color.input.text_submitted.emit("#123456")
			for frame in range(5): await get_tree().process_frame
			check(widget.background_color=="#123456","actual "+str(script.resource_path.get_file())+" Inspector authors shared hex")
			var manager := get_undo_redo()
			var history := manager.get_history_undo_redo(manager.get_object_history_id(widget))
			check(history.undo() and widget.background_color==previous and history.redo() and widget.background_color=="#123456","actual widget color undo/redo retains local default and authored type")
			for name in ["hover_background_color","pressed_background_color","disabled_background_color","checked_background_color"]:
				if not name in widget: continue
				color = field(name)
				check(color!=null,"actual widget Inspector exposes "+name)
				if color!=null:
					var saved = widget.get(name)
					color.input.text_submitted.emit("#abcdef")
					for frame in range(5): await get_tree().process_frame
					check(widget.get(name)=="#abcdef" and history.undo() and widget.get(name)==saved and history.redo() and widget.get(name)=="#abcdef","actual local state color Inspector edit/undo/redo "+name)
			if widget.has_method("get_label_origin") and "disabled" in widget:
				var width := field("padding")
				width.input.text_submitted.emit("10px")
				for frame in range(5): await get_tree().process_frame
				check(widget.padding=="10px" and history.undo() and widget.padding=="auto" and history.redo() and widget.padding=="10px","Button padding Inspector undo restores true asymmetric local default")
			RenderingServer.force_draw(false)
			get_viewport().get_texture().get_image().save_png("res://inspector-"+script.resource_path.get_file()+".png")
		interface.inspect_object(scene)
		scene.remove_child(widget)
		widget.free()
func run() -> void:
	if not await until(ready,"installed addon activates"): finish(); return
	interface.open_scene_from_path("res://app/StyleGallery.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"styled scene opens")
	await settle()
	await inspector()
	await widget_inspectors()
	if not FileAccess.file_exists("res://.godot/s01-restart"):
		await plugin._navigation.open("res://app/StyleGallery.gogo")
		await until(func(): return code()!=null,"authored editor opens")
		var editor := code()
		if editor!=null:
			var original := editor.text
			for fragment in ["<VBox background_c","<VBox border_left_w"]:
				editor.text = original+"\nfunc probe():\n\treturn "+fragment
				editor.set_caret_line(editor.get_line_count()-1)
				editor.set_caret_column(editor.get_line(editor.get_line_count()-1).length())
				editor.request_code_completion(true)
				for frame in range(5): await get_tree().process_frame
				var expected := "background_color" if fragment.contains("background") else "border_left_width"
				check(editor.get_code_completion_options().any(func(item): return item.insert_text.begins_with(expected)),"native CodeEdit completes "+expected)
				editor.cancel_code_completion()
				editor.text = original
			check(plugin._build_sources(),"valid styled source publishes code/maps")
			editor.text = original.replace("Local default Text stays white.","Unsaved styled view")
		await play("current")
		check(FileAccess.get_file_as_string("res://app/StyleGallery.gogo").contains("Unsaved styled view"),"current Play saves authored buffer before compilation")
		var file := FileAccess.open("res://.godot/s01-restart",FileAccess.WRITE)
		file.store_string("restart")
		file.close()
	await play("main")
	finish()
func finish() -> void:
	print("S01_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S01_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
