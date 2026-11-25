@tool
class_name EstragonIntegerInput
extends "internal/numeric_control.gd"
signal value_changed(previous: int, value: int)
const _GOGO_BINDABLE_PROPERTIES_NATIVE := {"value":"int"}
const State = preload("../composition/state.tres")
const ESTRAGON_INTEGER := true
var min_value: int = 0:
	set(next):
		if min_value==next or not _range_field("min_value",next): return
		min_value = next
		_range_changed()
var max_value: int = 100:
	set(next):
		if max_value==next or not _range_field("max_value",next): return
		max_value = next
		_range_changed()
var step: int = 1:
	set(next):
		if step==next or not _range_field("step",next): return
		step = next
		_range_changed()
var value: int = 0:
	set(next):
		var parsed := _numeric_value(next)
		if parsed.has("error") or value==parsed.value: return
		var previous := value
		value = parsed.value
		_project_numeric()
		value_changed.emit(previous,value)
	get:
		State.observe(self,&"value_changed")
		return value
