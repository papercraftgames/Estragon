@tool
extends EditorPlugin
## Research only: preserve FAIL when hidden association is unavailable.

const Highlighter = preload("res://addons/estragon/editor/highlighter.gd")
const Association = preload("res://addons/estragon/editor/highlighter_association.gd")
var interface: EditorInterface
var scripts: ScriptEditor
var association: RefCounted
var factory: EditorSyntaxHighlighter
var failed: bool = false
var checks: int = 0


func check(condition: bool, message: String) -> void:
	checks += 1
	print("E01_COMPAT_CHECK ", message, ": ", condition)
	failed = failed or not condition

func wait() -> void:
	await get_tree().create_timer(0.5).timeout

func _enable() -> void:
	factory = Highlighter.new()
	scripts.register_syntax_highlighter(factory)
	association = Association.new()
	association.start(interface)

func _disable() -> void:
	association.stop()
	scripts.unregister_syntax_highlighter(factory)
	association = null
	factory = null

func _open(path: String) -> CodeEdit:
	var dock := interface.get_file_system_dock()
	dock.navigate_to_path(path)
	await wait()
	for tree in dock.find_children("*", "Tree", true, false):
		var selected: TreeItem = tree.get_selected()
		if selected != null and selected.get_metadata(0) is String and selected.get_metadata(0) == path:
			tree.item_activated.emit()
	await wait()
	var editor := scripts.get_current_editor()
	return editor.get_base_editor() as CodeEdit if editor != null else null

func _colored(code: CodeEdit, context: String) -> void:
	check(code != null, context + " editor exists")
	if code == null: return
	check(code.syntax_highlighter.get_script() == Highlighter, context + " Gogo attached automatically")
	var declaration := code.syntax_highlighter.get_line_syntax_highlighting(0)
	check(declaration.has(0) and declaration[0].color == Highlighter.KEYWORD, context + " declaration color")
	var tag_found := false
	for line in range(code.get_line_count()):
		var column := code.get_line(line).find("<VBox")
		if column >= 0:
			var spans := code.syntax_highlighter.get_line_syntax_highlighting(line)
			tag_found = spans.has(column) and spans[column].color == Highlighter.TAG
	check(tag_found, context + " markup color")


func _enter_tree() -> void:
	interface = get_editor_interface()
	scripts = interface.get_script_editor()
	_run.call_deferred()

func _filter() -> LineEdit:
	for edit in scripts.find_children("*", "LineEdit", true, false):
		if edit.placeholder_text == "Filter Scripts": return edit
	return null

func _listed(path: String) -> CodeEdit:
	for editor in scripts.get_open_script_editors():
		var tabs := editor.get_parent() as TabContainer
		if tabs == null: continue
		for list in scripts.find_children("*", "ItemList", true, false):
			for item in range(list.item_count):
				var index: Variant = list.get_item_metadata(item)
				if index is int and index >= 0 and index < tabs.get_tab_count() and tabs.get_tab_control(index) == editor and list.get_item_tooltip(item) == path:
					return editor.get_base_editor() as CodeEdit
	return null

func _identity(code: CodeEdit) -> void:
	for editor in scripts.get_open_script_editors():
		if editor.get_base_editor() != code: continue
		var resource: Resource
		if code.syntax_highlighter.has_method("_get_edited_resource"):
			resource = code.syntax_highlighter.call("_get_edited_resource") as Resource
		var fields := {}
		for property in editor.get_property_list():
			if "resource" in str(property.name) or "path" in str(property.name):
				fields[str(property.name)] = str(editor.get(property.name))
		print("E01_F_IDENTITY ", JSON.stringify({
			"editor_class": editor.get_class(), "open_script_count": scripts.get_open_scripts().size(), "editor_meta": editor.get_meta_list(),
			"native_path_meta": editor.get_meta("_edit_res_path", ""),
			"resource_getter_bound": editor.has_method("get_edited_resource"),
			"resource_properties": fields, "highlighter_resource": str(resource),
			"adapter_path_without_cache": association._path(editor, code, false),
			"cached_gogo_path": code.get_meta("estragon_gogo_path", "")}))

func _run() -> void:
	await wait()
	while interface.get_resource_filesystem().is_scanning(): await wait()
	await wait()
	var restart := FileAccess.file_exists("res://restart.txt")
	print("E01_F_ENGINE ", Engine.get_version_info().string, " restart=", restart)
	var settings := interface.get_editor_settings()
	var key := "docks/filesystem/textfile_extensions"
	if not restart:
		settings.set_setting(key, str(settings.get_setting(key)) + ",gogo")
		if settings.has_method("mark_setting_changed"): settings.call("mark_setting_changed", key)
		get_tree().root.propagate_notification(EditorSettings.NOTIFICATION_EDITOR_SETTINGS_CHANGED)
		await wait()
		await _open("res://examples/counter/Counter.gogo")
		await _open("res://examples/counter/Background.gogo")
		await _open("res://examples/counter/Counter.gogo.txt")
	var a := _listed("res://examples/counter/Counter.gogo")
	var b := _listed("res://examples/counter/Background.gogo")
	var other := _listed("res://examples/counter/Counter.gogo.txt")
	check(a != null and b != null and other != null, "exact native list/tab identity before filtering")
	if a == null or b == null or other == null:
		get_tree().quit(1)
		return
	check(a.syntax_highlighter.get_script() == null and b.syntax_highlighter.get_script() == null, "both never-associated Plain Text before enable, including restart")
	check(not b.has_meta("estragon_gogo_path"), "no earlier association or stale Gogo path metadata")
	var original_text := b.text
	var original_version := b.get_version()
	var other_highlighter := other.syntax_highlighter
	var preference: Variant = settings.get_setting(key)
	var filter := _filter()
	check(filter != null, "native filter exists")
	if filter == null:
		get_tree().quit(1)
		return
	filter.text = "~e01-f-no-match~"
	filter.text_changed.emit(filter.text)
	await wait()
	check(_listed("res://examples/counter/Background.gogo") == null, "never-associated background genuinely filtered out")
	_enable()
	await wait()
	_identity(b)
	var hidden_ok: bool = b.syntax_highlighter.get_script() == Highlighter
	print("E01_F_HIDDEN_ACCEPTANCE ", "PASS" if hidden_ok else "FAIL")
	check(filter.text == "~e01-f-no-match~", "association leaves filter unchanged")
	check(b.text == original_text and b.get_version() == original_version, "hidden text and edit version unchanged")
	check(other.syntax_highlighter == other_highlighter, "identical-content unrelated txt unchanged while hidden")
	filter.text = ""
	filter.text_changed.emit(filter.text)
	await wait()
	print("E01_F_REVEALED_BEFORE_ACTIVATION ", b.syntax_highlighter.get_script() == Highlighter)
	await _open("res://examples/counter/Counter.gogo")
	await _open("res://examples/counter/Background.gogo")
	_colored(a, "revealed Counter")
	_colored(b, "revealed Background")
	check(a.syntax_highlighter != b.syntax_highlighter, "independent highlighters")
	filter.text = "~e01-f-no-match~"
	filter.text_changed.emit(filter.text)
	await wait()
	_colored(b, "previously associated filtered Background")
	check(filter.text == "~e01-f-no-match~", "known association leaves filter unchanged")
	filter.text = ""
	filter.text_changed.emit(filter.text)
	_disable()
	_enable()
	await wait()
	_colored(b, "re-enabled Background")
	check(other.syntax_highlighter == other_highlighter, "unrelated txt unchanged after lifecycle")
	check(settings.get_setting(key) == preference, "association preserves preferences")
	check(b.text == original_text and b.get_version() == original_version, "source unchanged after lifecycle")
	var marker := FileAccess.open("res://restart.txt", FileAccess.WRITE)
	marker.store_string("ready")
	marker.close()
	print("E01_F_INVARIANTS ", checks, " ", "FAIL" if failed else "PASS")
	print("E01_F_RESULT ", "PASS" if hidden_ok and not failed else "FAIL")
	get_tree().quit(1 if failed else 0)
