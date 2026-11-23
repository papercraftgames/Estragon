@tool
class_name Estragon2D
extends "box.gd"
## Explicit independent layout scope; does not assign native scene owner.
func _is_layout_entry() -> bool:
	return true

const Pointer = preload("internal/pointer_2d.gd")
const Focus = preload("internal/focus.tres")
var _pointer = Pointer.new(self)

func _get_pointer_router():
	return _pointer

func _enter_tree() -> void:
	_pointer.start()
	super._enter_tree()
	Focus.add(self)

func _exit_tree() -> void:
	Focus.remove(self)
	_pointer.stop()
	super._exit_tree()

func _input(event: InputEvent) -> void:
	super._input(event)
	if get_viewport().is_input_handled(): return
	if Focus.key(get_viewport(),event): get_viewport().set_input_as_handled()
	# Native GUI may consume a release before unhandled delivery. Drop any old
	# capture after that event without routing a click through a native Control.
	if event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _pointer.has_capture(): _pointer.cancel.call_deferred()
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or get_viewport().is_input_handled(): return
	if event is InputEventMouse and Focus.pointer_entry(get_viewport(),event.position)!=self: return
	if _pointer.input(event): get_viewport().set_input_as_handled()
