
extends RefCounted
signal enabled_changed(previous: bool, value: bool)
var enabled: bool = false:
	set(_gogo_incoming_enabled):
		if is_same(enabled, _gogo_incoming_enabled): return
		var _gogo_previous_enabled: bool = enabled
		enabled = _gogo_incoming_enabled
		enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
		return enabled

signal note_changed(previous: String, value: String)
var note: String = "Model is authoritative":
	set(_gogo_incoming_note):
		if is_same(note, _gogo_incoming_note): return
		var _gogo_previous_note: String = note
		note = _gogo_incoming_note
		note_changed.emit(_gogo_previous_note, _gogo_incoming_note)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"note_changed")
		return note


