@tool
extends EditorPlugin
## Correct native editor context for every shipped @tool script/highlighter.
var _failed := false

func _enter_tree() -> void:
	_run.call_deferred()

func _run() -> void:
	while get_editor_interface().get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	var paths = JSON.parse_string(FileAccess.get_file_as_string("res://shipped-scripts.json"))
	for path in paths:
		var script = load(path)
		if not script is GDScript or script.reload() != OK:
			_failed = true
			push_error("Invalid shipped script: " + str(path))
	var highlighter = load("res://addons/estragon/editor/highlighter.gd").new()
	var edit := CodeEdit.new()
	edit.text = "extends RefCounted\n"
	edit.syntax_highlighter = highlighter
	var spans: Dictionary = highlighter.get_line_syntax_highlighting(0)
	if not spans.has(0) or spans[0].color != highlighter.KEYWORD:
		_failed = true
		push_error("Native editor highlighter cannot instantiate/color")
	edit.free()
	print("C01_H_SHIPPED_SCRIPTS ", paths.size())
	if not _failed: print("C01_H_EDITOR_CONTEXT_OK")
	get_tree().quit(1 if _failed else 0)
