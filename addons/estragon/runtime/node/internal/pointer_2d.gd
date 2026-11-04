@tool
extends RefCounted
## Entry-scoped event routing/capture. Weak participants; no frame polling.
var _host: WeakRef
var _buttons: Array[WeakRef] = []
var _captured: WeakRef
var _window: Window
func _init(host: Node) -> void:
	_host = weakref(host)
func start() -> void:
	var host = _host.get_ref()
	_window = host.get_window()
	_window.focus_exited.connect(cancel)
func stop() -> void:
	cancel()
	if is_instance_valid(_window) and _window.focus_exited.is_connected(cancel): _window.focus_exited.disconnect(cancel)
	_window = null
	_buttons.clear()
func register_button(button: Node2D) -> void:
	for ref in _buttons:
		if ref.get_ref() == button: return
	_buttons.append(weakref(button))
func unregister_button(button: Node2D) -> void:
	if _captured != null and _captured.get_ref() == button: cancel()
	for index in range(_buttons.size()-1,-1,-1):
		if _buttons[index].get_ref() == null or _buttons[index].get_ref() == button: _buttons.remove_at(index)
func cancel() -> void:
	_captured = null
	for ref in _buttons:
		var button = ref.get_ref()
		if button != null: button._set_pointer_state(false,false)
func cancel_button(button: Node2D) -> void:
	if _captured != null and _captured.get_ref() == button: cancel()
	button._set_pointer_state(false,false)
func _z(button: CanvasItem) -> int:
	var result: int = button.z_index
	var parent: CanvasItem = button.get_parent_item()
	while button.z_as_relative and parent != null:
		result += parent.z_index
		button = parent
		parent = button.get_parent_item()
	return result
func pick(position: Vector2):
	var found
	for ref in _buttons:
		var button = ref.get_ref()
		if button == null or button.is_queued_for_deletion() or not button.is_inside_tree() or not button.is_visible_in_tree() or not button._pointer_contains(position): continue
		if found == null or _z(button) > _z(found) or _z(button) == _z(found) and button.is_greater_than(found): found = button
	return found
func input(event: InputEvent) -> bool:
	if not event is InputEventMouse: return false
	var hovered = pick(event.position)
	var held = _captured.get_ref() if _captured != null else null
	if event is InputEventMouseMotion:
		for ref in _buttons:
			var button = ref.get_ref()
			if button != null: button._set_pointer_state(button==hovered,button==held)
		return held != null
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT: return false
	if event.pressed:
		if held == null and hovered != null and not hovered.disabled:
			_captured = weakref(hovered)
			hovered._set_pointer_state(true,true)
		return hovered != null
	if held == null: return hovered != null
	_captured = null
	var activate: bool = held==hovered and not held.disabled and held.is_visible_in_tree()
	held._set_pointer_state(held==hovered,false)
	if activate: held.pressed.emit()
	return true
