@tool
extends EditorProperty
const Length = preload("../runtime/node/internal/length.gd")
var input := LineEdit.new()
func _init() -> void:
	input.placeholder_text = "200, 50%, 2.5in, auto"
	add_child(input)
	add_focusable(input)
	input.text_submitted.connect(_submit)
func _submit(text: String) -> void:
	var name := str(get_edited_property())
	var value: Variant = float(text) if text.is_valid_float() else text
	var parsed := Length.parse(value,Length.domain(name))
	if parsed.has("error"):
		input.tooltip_text = parsed.error
		input.modulate = Color(1,0.5,0.5)
		return
	input.modulate = Color.WHITE
	input.tooltip_text = ""
	emit_changed(get_edited_property(),value)
func _update_property() -> void:
	input.text = str(get_edited_object().get(get_edited_property()))
