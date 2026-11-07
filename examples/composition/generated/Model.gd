extends RefCounted
signal title_changed(previous: String, value: String)
var title: String = "Native composition":
	set(_gogo_incoming_title):
		if is_same(title, _gogo_incoming_title): return
		var _gogo_previous_title: String = title
		title = _gogo_incoming_title
		title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
		return title

signal width_changed(previous: float, value: float)
var width: float = 120.0:
	set(_gogo_incoming_width):
		if is_same(width, _gogo_incoming_width): return
		var _gogo_previous_width: float = width
		width = _gogo_incoming_width
		width_changed.emit(_gogo_previous_width, _gogo_incoming_width)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"width_changed")
		return width


