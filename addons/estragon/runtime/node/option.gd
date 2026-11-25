@tool
class_name EstragonOption
extends Node
## Nonvisual authored option identity; no layout participant or selected Bool.
const ESTRAGON_OPTION := true
@export var value: String = "":
	set(next):
		var select = _select_owner()
		if next.is_empty() or not _identity_commit and select!=null and not select._accepts_option(self,next):
			push_error("Estragon Option.value requires a nonempty unique String identifier")
			return
		if value==next: return
		value = next
		_changed()
@export var text: String = "":
	set(next):
		if text==next: return
		text = next
		_changed()
@export var disabled := false:
	set(next):
		if disabled==next: return
		disabled = next
		_changed()
@export var hidden := false:
	set(next):
		if hidden==next: return
		hidden = next
		_changed()
var _identity_commit := false
func _select_owner():
	var parent := get_parent()
	while parent!=null:
		if parent.has_method("_select_options"): return parent
		parent = parent.get_parent()
	return null
func _apply_option_identity(next: String) -> void:
	_identity_commit = true
	value = next
	_identity_commit = false
func _changed() -> void:
	var select = _select_owner()
	if select!=null: select._queue_options()
