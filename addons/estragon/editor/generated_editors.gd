@tool
extends RefCounted
## Authenticated compiled views. Native editing/debug navigation stays native;
## only verified Estragon output is protected. Recovery precedes replacement.
const Components = preload("scene_components.gd")
const Compiler = preload("../compiler/compiler.gd")
const RECOVERY := "user://estragon/generated-edits"
var plugin: EditorPlugin
var interface: EditorInterface
var navigation: RefCounted
var association: RefCounted
var entries: Dictionary = {}
var panel: MenuButton
var viewer: AcceptDialog
var preview: TextEdit
var location: Label
var selected := 0
var active := true
var mutating := false
var problem := ""
var presentation := ""
var action: Callable
func _init(owner: EditorPlugin, navigator: RefCounted, adapter: RefCounted) -> void:
	plugin = owner
	interface = owner.get_editor_interface()
	navigation = navigator
	association = adapter
	panel = MenuButton.new()
	panel.name = "GogoGeneratedView"
	plugin.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR,panel)
	panel.hide()
	interface.get_script_editor().visibility_changed.connect(_present)
	viewer = AcceptDialog.new()
	viewer.title = "Recovered generated edit — copy changes into the Gogo source"
	viewer.min_size = Vector2i(760,460)
	var box := VBoxContainer.new()
	viewer.add_child(box)
	location = Label.new()
	location.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(location)
	preview = TextEdit.new()
	preview.editable = false
	preview.custom_minimum_size = Vector2(740,360)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(preview)
	plugin.add_child(viewer)
func _verified(path: String) -> String:
	var source := Components.source_path(path)
	if source.is_empty() or not FileAccess.file_exists(source) or not FileAccess.file_exists(path): return ""
	var map = JSON.parse_string(FileAccess.get_file_as_string(path+".map.json"))
	if not map is Dictionary: return ""
	if not map.get("sourceContent") is String or not map.get("segments") is Array: return ""
	var text := FileAccess.get_file_as_string(path)
	if map.has("generatedHash"):
		return source if map.generatedHash == text.sha256_text() else ""
	# Older v1 maps have no output hash. Authenticate by deterministic native
	# emission of their recorded source; never guess from a folder/basename.
	var result := Compiler.compile(map.sourceContent,source,path)
	return source if result.ok and result.code == text else ""
func _latest(path: String) -> String:
	var directory := DirAccess.open(RECOVERY)
	if directory == null: return ""
	var prefix := path.sha256_text()+"-"
	var latest := ""
	for name in directory.get_files():
		var file := RECOVERY.path_join(name)
		if name.begins_with(prefix) and name.ends_with(".txt") and (latest.is_empty() or name>latest.get_file()): latest = file
	return latest
func attach(editor: ScriptEditorBase, code: TextEdit, path: String) -> void:
	if not active or not code is CodeEdit: return
	_present()
	var id := code.get_instance_id()
	if entries.has(id):
		if entries[id].path == path: return
		_detach(id)
	var source := _verified(path)
	if source.is_empty(): return
	var changed := _changed.bind(id)
	var closing := _closed.bind(id)
	entries[id] = {"editor":weakref(editor),"code":weakref(code),"path":path,"source":source,"editable":code.editable,"baseline":FileAccess.get_file_as_string(path),"recovery":_latest(path),"changed":changed,"closing":closing,"blocked":false}
	code.editable = false
	code.text_changed.connect(changed)
	code.text_set.connect(changed)
	code.tree_exiting.connect(closing)
	# Includes a dirty tab restored before the addon is enabled. Native input
	# is already read-only; no byte is cleared until recovery is verified.
	_changed(id)
	_present()
func _preserve(entry: Dictionary, text: String) -> bool:
	var file := RECOVERY.path_join(entry.path.sha256_text()+"-"+str(int(Time.get_unix_time_from_system()*1000000))+"-"+text.sha256_text()+".txt")
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RECOVERY))
	if error == OK:
		var output := FileAccess.open(file,FileAccess.WRITE)
		if output != null:
			output.store_buffer(text.to_utf8_buffer())
			output.flush()
			error = output.get_error()
			output.close()
		else: error = FileAccess.get_open_error()
	if error != OK or not FileAccess.file_exists(file) or FileAccess.get_file_as_bytes(file) != text.to_utf8_buffer():
		entry.blocked = true
		problem = entry.path+": Cannot preserve edited generated buffer. Save/Play blocked; copy the visible edit before continuing. Recovery: "+ProjectSettings.globalize_path(file)
		return false
	entry.recovery = file
	entry.blocked = false
	return true
func _changed(id: int) -> void:
	if not active or mutating or not entries.has(id): return
	var entry: Dictionary = entries[id]
	var code = entry.code.get_ref()
	if code == null: return
	if code.text != entry.baseline:
		# Native external reload can already contain a newly authenticated build.
		if code.text == FileAccess.get_file_as_string(entry.path) and not _verified(entry.path).is_empty(): entry.baseline = code.text
		elif not _preserve(entry,code.text): _present(); return
		else: _replace(entry,entry.baseline)
	_present()
func _replace(entry: Dictionary, text: String) -> void:
	var code = entry.code.get_ref()
	if code == null: return
	mutating = true
	var line: int = code.get_caret_line()
	var column: int = code.get_caret_column()
	var vertical: float = code.scroll_vertical
	var horizontal: int = code.scroll_horizontal
	var breakpoints: PackedInt32Array = code.get_breakpointed_lines()
	if code.text != text: code.text = text
	for marked_line in breakpoints:
		if marked_line < code.get_line_count(): code.set_line_as_breakpoint(marked_line,true)
	code.set_caret_line(line)
	code.set_caret_column(column)
	code.scroll_vertical = vertical
	code.scroll_horizontal = horizontal
	code.tag_saved_version()
	entry.baseline = text
	mutating = false
func prepare() -> bool:
	problem = ""
	for editor in interface.get_script_editor().get_open_script_editors():
		var code = editor.get_base_editor()
		if code is CodeEdit: attach(editor,code,association._path(editor,code,false))
	for id in entries.keys():
		_changed(id)
		if entries.has(id) and entries[id].blocked:
			if problem.is_empty(): problem = entries[id].path+": Generated edit recovery failed; save/build blocked."
	_present()
	return problem.is_empty()
func refresh() -> void:
	for entry in entries.values():
		if not entry.blocked and not _verified(entry.path).is_empty(): _replace(entry,FileAccess.get_file_as_string(entry.path))
	_present()
func _present() -> void:
	if not active: return
	selected = 0
	var editor := interface.get_script_editor().get_current_editor()
	for id in entries:
		if entries[id].editor.get_ref() == editor: selected = id; break
	panel.visible = selected != 0 and interface.get_script_editor().is_visible_in_tree()
	if selected == 0:
		# A missing source cannot authorize read-only or synchronization. Still
		# explain its map claim on the selected native Script without redirecting.
		var code = editor.get_base_editor() if editor != null else null
		var source := Components.source_path(association._path(editor,code,false)) if code is CodeEdit else ""
		if not source.is_empty() and not FileAccess.file_exists(source):
			panel.visible = interface.get_script_editor().is_visible_in_tree()
			panel.text = "Gogo source missing"
			panel.tooltip_text = "Unverified source association: "+source+". Restore the source; this tab remains editable."
			if presentation != source:
				presentation = source
				var popup := panel.get_popup()
				if action.is_valid() and popup.id_pressed.is_connected(action): popup.id_pressed.disconnect(action)
				action = Callable()
				popup.clear()
				popup.add_item("Gogo source missing — restore "+source)
				popup.set_item_disabled(0,true)
		return
	var entry: Dictionary = entries[selected]
	var exists := FileAccess.file_exists(entry.source)
	panel.text = "Generated: "+entry.source.get_file()
	var status := "Read-only — edit the Gogo source"
	if not exists: status = "Gogo source missing — restore it before editing"
	elif _verified(entry.path).is_empty(): status = "Source map unavailable/changed — inspect only"
	if entry.blocked: status = "Recovery failed — Save/Play blocked"
	panel.tooltip_text = status+"\n"+entry.path+"\nGogo source: "+entry.source
	var signature: String = str(selected)+status+entry.recovery+str(exists)
	if signature == presentation: return
	presentation = signature
	var popup := panel.get_popup()
	if action.is_valid() and popup.id_pressed.is_connected(action): popup.id_pressed.disconnect(action)
	action = _action.bind(entry.source,entry.path,entry.recovery)
	popup.id_pressed.connect(action,CONNECT_DEFERRED)
	popup.clear()
	popup.add_item(status,0)
	popup.set_item_disabled(0,true)
	popup.add_item("Open Gogo Source",1)
	popup.set_item_disabled(1,not exists)
	popup.add_separator()
	popup.add_item("View Recovered Edit"+(" (preserved)" if not entry.recovery.is_empty() else ""),2)
	popup.set_item_disabled(popup.get_item_index(2),entry.recovery.is_empty())
func _action(id: int, source: String, path: String, recovery: String) -> void:
	if not active: return
	if id == 1 and FileAccess.file_exists(source):
		await navigation.open(source)
	elif id == 2 and FileAccess.file_exists(recovery):
		location.text = "Preserved edit for "+path+"\n"+ProjectSettings.globalize_path(recovery)+"\nOlder recovered versions remain in this directory. Copy intended changes into "+source+"."
		preview.text = FileAccess.get_file_as_string(recovery)
		viewer.popup_centered()
func _closed(id: int) -> void:
	if entries.has(id): _detach(id)
func _detach(id: int) -> void:
	var entry: Dictionary = entries[id]
	var code = entry.code.get_ref()
	if code != null:
		for pair in [["text_changed","changed"],["text_set","changed"],["tree_exiting","closing"]]:
			if code.is_connected(pair[0],entry[pair[1]]): code.disconnect(pair[0],entry[pair[1]])
		code.editable = entry.editable
	entries.erase(id)
func stop() -> void:
	active = false
	for id in entries.keys(): _detach(id)
	interface.get_script_editor().visibility_changed.disconnect(_present)
	if action.is_valid() and panel.get_popup().id_pressed.is_connected(action): panel.get_popup().id_pressed.disconnect(action)
	action = Callable()
	plugin.remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR,panel)
	panel.free()
	viewer.free()
