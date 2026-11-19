extends RefCounted
signal value_changed(previous: int, value: int)
var value: int = 0:
	set(_gogo_incoming_value):
		if is_same(value, _gogo_incoming_value): return
		var _gogo_previous_value: int = value
		value = _gogo_incoming_value
		value_changed.emit(_gogo_previous_value, _gogo_incoming_value)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"value_changed")
		return value

signal label_changed(previous: String, value: String)
var label: String = "Flynn":
	set(_gogo_incoming_label):
		if is_same(label, _gogo_incoming_label): return
		var _gogo_previous_label: String = label
		label = _gogo_incoming_label
		label_changed.emit(_gogo_previous_label, _gogo_incoming_label)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"label_changed")
		return label

signal alternate_changed(previous: bool, value: bool)
var alternate: bool = false:
	set(_gogo_incoming_alternate):
		if is_same(alternate, _gogo_incoming_alternate): return
		var _gogo_previous_alternate: bool = alternate
		alternate = _gogo_incoming_alternate
		alternate_changed.emit(_gogo_previous_alternate, _gogo_incoming_alternate)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"alternate_changed")
		return alternate

signal note_changed(previous: String, value: String)
var note: String = "quiet":
	set(_gogo_incoming_note):
		if is_same(note, _gogo_incoming_note): return
		var _gogo_previous_note: String = note
		note = _gogo_incoming_note
		note_changed.emit(_gogo_previous_note, _gogo_incoming_note)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"note_changed")
		return note

var id: int = 0

const _GOGO_RENDER_FUNCTIONS_661832aa45b6b54d = {
"ordinary": [],
"reactive": []
}
