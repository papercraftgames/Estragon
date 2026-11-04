@tool
class_name Estragon2D
extends "res://addons/estragon/runtime/node/component_2d.gd"
## Explicit independent layout scope; does not assign native scene owner.
@export var viewport_width_scale: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0 or viewport_width_scale == value: return
		viewport_width_scale = value
		if layout != null: layout._invalidated()

func _is_layout_entry() -> bool:
	return true

func _layout_viewport_scale() -> float:
	return viewport_width_scale
