extends RefCounted
signal width_changed(previous: float, value: float)
var width: float = 120.0:
	set(_gogo_incoming_width):
		if is_same(width, _gogo_incoming_width): return
		var _gogo_previous_width: float = width
		width = _gogo_incoming_width
		width_changed.emit(_gogo_previous_width, _gogo_incoming_width)

signal tint_changed(previous: Color, value: Color)
var tint: Color = Color(0.2,0.8,0.6):
	set(_gogo_incoming_tint):
		if is_same(tint, _gogo_incoming_tint): return
		var _gogo_previous_tint: Color = tint
		tint = _gogo_incoming_tint
		tint_changed.emit(_gogo_previous_tint, _gogo_incoming_tint)

signal title_changed(previous: String, value: String)
var title: String = "Reactive model":
	set(_gogo_incoming_title):
		if is_same(title, _gogo_incoming_title): return
		var _gogo_previous_title: String = title
		title = _gogo_incoming_title
		title_changed.emit(_gogo_previous_title, _gogo_incoming_title)


