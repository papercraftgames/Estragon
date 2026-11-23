@tool
extends "../../addons/estragon/runtime/node/component_2d.gd"
## UI-01 prototype, NOT an Estragon Input API. Native LineEdit owns all editing,
## selection, clipboard, caret/IME and appearance. No String binding is shipped.
@export var initial_text: String = "Native editing / IME prototype"
var editor: LineEdit
func _enter_tree() -> void:
	super._enter_tree()
	if Engine.is_editor_hint(): return
	editor = LineEdit.new()
	editor.name = "NativeEditingDelegate"
	editor.text = initial_text
	add_child(editor,false,Node.INTERNAL_MODE_BACK)
	layout_applied.connect(_arrange_editor)
	_arrange_editor(layout_size)
func _exit_tree() -> void:
	if is_instance_valid(editor):
		layout_applied.disconnect(_arrange_editor)
		remove_child(editor)
		editor.free()
		editor = null
	super._exit_tree()
func _arrange_editor(extent: Vector2) -> void:
	if is_instance_valid(editor): editor.size = extent
func _measure_native() -> Vector2:
	return Vector2(260,44)
func _composition_is_private(child: Node) -> bool:
	return child==editor or super._composition_is_private(child)
