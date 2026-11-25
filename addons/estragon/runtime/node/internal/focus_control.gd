@tool
extends Control
## Transparent native keyboard/focus endpoint, never a layout or mouse owner.
const Focus = preload("focus.tres")
var held_key := 0
func _estragon_focus_host(): return get_parent()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_entered.connect(_entered)
	focus_exited.connect(_exited)
	visibility_changed.connect(_visibility)
func _entered() -> void:
	var host = _estragon_focus_host()
	if not Focus.eligible(self): release_focus(); return
	host._queue_style_redraw()
	host.focus_entered.emit()
func _exited() -> void:
	cancel()
	var host = _estragon_focus_host()
	host._cancel_pointer()
	host._queue_style_redraw()
	host.focus_exited.emit()
func _visibility() -> void:
	if not is_visible_in_tree(): cancel()
func cancel() -> void:
	held_key = 0
	var host = _estragon_focus_host()
	host._keyboard_held = false
	host._queue_style_redraw()
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not Focus.eligible(self): cancel(); release_focus(); return
	var target = _estragon_focus_host()
	if target.has_method("_focus_key") and target._focus_key(event):
		accept_event()
		return
	if event.is_action("ui_cancel"):
		cancel()
		accept_event()
		return
	if not event.is_action("ui_accept"): return
	accept_event()
	var host = _estragon_focus_host()
	if event.echo: return
	if event.pressed:
		if held_key==0:
			held_key = event.keycode
			host._keyboard_held = true
			host._queue_style_redraw()
	elif held_key==event.keycode:
		cancel()
		if Focus.eligible(self) and has_focus(): host.pressed.emit()
