@tool
class_name EstragonToggle
extends "button.gd"
## Controlled boolean input. Only pointer activation emits a user edit.
signal value_changed(value: bool)
@export var value: bool = false:
	set(next):
		if value == next: return
		value = next
		queue_redraw()
func _init() -> void:
	pressed.connect(_activate)
func _activate() -> void:
	if disabled: return
	value = not value
	value_changed.emit(value)
func get_background_color() -> Color:
	if disabled: return super.get_background_color()
	return Color("227a60") if value else super.get_background_color()
func _draw() -> void:
	super._draw()
	if value and layout_size.x>0 and layout_size.y>0:
		draw_line(Vector2(2,layout_size.y-3),Vector2(layout_size.x-2,layout_size.y-3),Color("65f4b0"),3)
