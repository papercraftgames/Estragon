@tool
extends LineEdit
func _estragon_focus_host(): return get_parent().get_parent()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action("ui_cancel") and event.pressed and not event.echo:
		accept_event()
		var host = _estragon_focus_host()
		host._revert_number()
		host.release_focus()
