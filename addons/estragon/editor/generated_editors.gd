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
var panel: HBoxContainer
var label: Label
var open: Button
var recovered: Button
var viewer: AcceptDialog
var preview: TextEdit
var location: Label
var selected := 0
var active := true
var mutating := false
var problem := ""
func _init(owner: EditorPlugin, navigator: RefCounted, adapter: RefCounted) -> void:
	plugin = owner
	interface = owner.get_editor_interface()
	navigation = navigator
	association = adapter
	panel = HBoxContainer.new()
	panel.name = "GogoGeneratedView"
	label = Label.new()
	panel.add_child(label)
	open = Button.new()
	open.text = "Open Gogo Source"
	open.pressed.connect(_open_source)
	panel.add_child(open)
	recovered = Button.new()
	recovered.text = "View Recovered Edit"
	recovered.pressed.connect(_view_recovery)
	panel.add_child(recovered)
	plugin.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR,panel)
	panel.hide()
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
	panel.visible = selected != 0
	if selected == 0: return
	var entry: Dictionary = entries[selected]
	var exists := FileAccess.file_exists(entry.source)
	label.text = "Generated from "+entry.source.get_file()+" — read-only"
	if not exists: label.text = "Generated GDScript — Gogo source missing"
	elif _verified(entry.path).is_empty(): label.text = "Generated GDScript — source map unavailable/changed"
	if entry.blocked: label.text = "Generated edit recovery failed — Save/Play blocked"
	label.tooltip_text = entry.path+"\nEdit the Gogo source: "+entry.source
	open.disabled = not exists
	open.tooltip_text = entry.source if exists else "Restore the missing Gogo source: "+entry.source
	recovered.visible = not entry.recovery.is_empty()
	recovered.tooltip_text = "Your previous edit was preserved before synchronization: "+ProjectSettings.globalize_path(entry.recovery)
func _open_source() -> void:
	if entries.has(selected) and FileAccess.file_exists(entries[selected].source): navigation.open(entries[selected].source)
func _view_recovery() -> void:
	if not entries.has(selected): return
	var entry: Dictionary = entries[selected]
	location.text = "Preserved edit for "+entry.path+"\n"+ProjectSettings.globalize_path(entry.recovery)+"\nOlder recovered versions remain in this directory. Copy intended changes into "+entry.source+"."
	preview.text = FileAccess.get_file_as_string(entry.recovery)
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
	plugin.remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR,panel)
	panel.free()
	viewer.free()
