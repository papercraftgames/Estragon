@tool
class_name EstragonRect2D
extends "res://addons/estragon/runtime/node/component_2d.gd"
## Native rectangle drawing. Width/height are inherited layout inputs.
@export var fill := Color.WHITE:
	set(value):
		if fill == value: return
		fill = value
		queue_redraw()
func apply_layout_size(size: Vector3) -> void:
	super.apply_layout_size(size)
	queue_redraw()
func _draw() -> void:
	if layout_size.x > 0 and layout_size.y > 0:
		draw_rect(Rect2(Vector2.ZERO,layout_size),fill)
