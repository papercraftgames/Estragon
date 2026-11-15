@tool
extends EditorProperty
const Style = preload("../runtime/node/internal/visual_style_2d.gd")
var input := LineEdit.new()
var picker := ColorPickerButton.new()
var _updating := false
func _init() -> void:
	var row := HBoxContainer.new()
	input.placeholder_text = "#rrggbb or transparent"
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)
	row.add_child(picker)
	add_child(row)
	add_focusable(input)
	input.text_submitted.connect(_submit)
	picker.color_changed.connect(_picked)
func _submit(text: String) -> void:
	var parsed := Style.parse_color(text)
	if parsed.has("error"):
		input.tooltip_text = parsed.error
		input.modulate = Color(1,0.5,0.5)
		return
	input.modulate = Color.WHITE
	input.tooltip_text = ""
	emit_changed(get_edited_property(),text)
func _picked(value: Color) -> void:
	if not _updating: emit_changed(get_edited_property(),value)
func _update_property() -> void:
	_updating = true
	var value = get_edited_object().get(get_edited_property())
	input.text = "#"+value.to_html() if value is Color else str(value)
	var parsed := Style.parse_color(value)
	if not parsed.has("error"): picker.color = parsed.color
	_updating = false
