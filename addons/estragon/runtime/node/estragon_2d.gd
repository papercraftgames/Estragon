@tool
class_name Estragon2D
extends "box.gd"
## Explicit independent layout scope; does not assign native scene owner.
func _is_layout_entry() -> bool:
	return true

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
