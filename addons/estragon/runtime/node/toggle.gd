@tool
class_name EstragonToggle
extends "button.gd"
## Controlled boolean input. Only pointer activation emits a user edit.
signal value_changed(value: bool)
const ESTRAGON_TOGGLE_STYLE := true
var checked_background_color: Variant = Color("#227a60"):
	set(next):
		if is_same(checked_background_color,next) or not _visual_style.assign("checked_background_color",next): return
		checked_background_color = next
		_queue_style_redraw()
func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = super._get_property_list()
	result.append_array(Length.properties(["checked_background_color"]))
	return result
@export var value: bool = false:
	set(next):
		if value == next: return
		value = next
		_queue_style_redraw()
func _init() -> void:
	super._init()
	pressed.connect(_activate)
func _activate() -> void:
	if disabled: return
	value = not value
	value_changed.emit(value)
func get_background_color() -> Color:
	if disabled: return super.get_background_color()
	return _visual_style.colors.checked_background_color if value else super.get_background_color()
func _draw() -> void:
	super._draw()
	var border: Vector4 = layout.model.border
	var inner := Rect2(Vector2(border.x,border.y),layout_size-Vector2(border.x+border.z,border.y+border.w))
	if value and inner.size.x>4 and inner.size.y>4:
		draw_line(inner.position+Vector2(2,inner.size.y-3),inner.position+Vector2(inner.size.x-2,inner.size.y-3),Color("65f4b0"),3)
