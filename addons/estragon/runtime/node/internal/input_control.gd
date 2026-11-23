@tool
extends LineEdit
## Native editing, selection and platform text input in the host's actual rect.
const Focus = preload("focus.tres")
func _estragon_focus_host(): return get_parent()
func _ready() -> void:
	clip_contents = true
	expand_to_text_length = false
	focus_entered.connect(_entered)
	focus_exited.connect(_exited)
func _entered() -> void:
	var host = _estragon_focus_host()
	if not Focus.eligible(self): release_focus(); return
	host.queue_redraw()
	host.focus_entered.emit()
func _exited() -> void:
	var host = _estragon_focus_host()
	host.queue_redraw()
	host.focus_exited.emit()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action("ui_cancel") and event.pressed and not event.echo:
		accept_event()
		var host = _estragon_focus_host()
		host.release_focus()
		host.cancelled.emit()
