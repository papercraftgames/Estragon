@tool
class_name EstragonText
extends "component_2d.gd"
## Native Font measure/draw, explicit lines only. No wrapping or rich text.
@export var text: String = "":
	set(value):
		if text == value: return
		text = value
		_content_changed()
@export var font: Font = ThemeDB.fallback_font:
	set(value):
		if value == null or value == font: return
		_disconnect_font()
		font = value
		_connect_font()
		_content_changed()
@export var font_size: int = 20:
	set(value):
		if value <= 0 or value == font_size: return
		font_size = value
		_content_changed()
@export var color := Color.WHITE:
	set(value):
		if color == value: return
		color = value
		queue_redraw()
var _label_cache := Vector2.ZERO
var _label_dirty: bool = true

func _enter_tree() -> void:
	_connect_font()
	super._enter_tree()
func _exit_tree() -> void:
	_disconnect_font()
	super._exit_tree()
func _connect_font() -> void:
	if is_inside_tree() and font != null and not font.changed.is_connected(_content_changed): font.changed.connect(_content_changed)
func _disconnect_font() -> void:
	if font != null and font.changed.is_connected(_content_changed): font.changed.disconnect(_content_changed)
func _content_changed() -> void:
	_label_dirty = true
	_changed()
	queue_redraw()
func _measure_label() -> Vector2:
	if not _label_dirty: return _label_cache
	var size := Vector2.ZERO
	if font == null: return size
	for line in text.split("\n"):
		size.x = maxf(size.x,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
		size.y += font.get_height(font_size)
	_label_cache = size
	_label_dirty = false
	return size
func _measure_native() -> Vector2:
	return _measure_label()
func apply_layout_size(size: Vector3) -> void:
	super.apply_layout_size(size)
	queue_redraw()
func _draw_label(offset: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> void:
	if font == null: return
	for line in text.split("\n"):
		if not line.is_empty(): draw_string(font,offset+Vector2(0,font.get_ascent(font_size)),line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color*tint)
		offset.y += font.get_height(font_size)
func _draw() -> void:
	if layout_size.x <= 0 or layout_size.y <= 0: return
	_draw_label()
