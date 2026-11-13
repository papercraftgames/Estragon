@tool
class_name Estragon2D
extends "component_2d.gd"
## Explicit independent layout scope; does not assign native scene owner.
@export var viewport_width_scale: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0 or viewport_width_scale == value: return
		viewport_width_scale = value
		if layout != null: layout._invalidated()

@export var viewport_height_scale: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0 or viewport_height_scale == value: return
		viewport_height_scale = value
		if layout != null: layout._invalidated()

func _is_layout_entry() -> bool:
	return true

func _layout_viewport_scale() -> Vector2:
	return Vector2(viewport_width_scale,viewport_height_scale)

const Pointer = preload("internal/pointer_2d.gd")
var _pointer = Pointer.new(self)

func _get_pointer_router():
	return _pointer

func _enter_tree() -> void:
	_pointer.start()
	super._enter_tree()

func _exit_tree() -> void:
	_pointer.stop()
	super._exit_tree()

func _input(event: InputEvent) -> void:
	if _pointer.input(event): get_viewport().set_input_as_handled()
