@tool
class_name EstragonBox
extends "component_2d.gd"
## Constructible horizontal Box. VBox selects the vertical axis.
# -1 means an unset edge; explicit edges always override the shorthand.
@export var padding: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0 or value == padding: return
		padding = value
		_changed()
@export var padding_top: float = -1.0:
	set(value):
		if not valid_length(value) or value == padding_top: return
		padding_top = value
		_changed()
@export var padding_right: float = -1.0:
	set(value):
		if not valid_length(value) or value == padding_right: return
		padding_right = value
		_changed()
@export var padding_bottom: float = -1.0:
	set(value):
		if not valid_length(value) or value == padding_bottom: return
		padding_bottom = value
		_changed()
@export var padding_left: float = -1.0:
	set(value):
		if not valid_length(value) or value == padding_left: return
		padding_left = value
		_changed()

func _padding_insets() -> Vector4:
	return Vector4(padding_left if padding_left >= 0 else padding,padding_top if padding_top >= 0 else padding,padding_right if padding_right >= 0 else padding,padding_bottom if padding_bottom >= 0 else padding)

func _layout_options() -> Dictionary:
	var options := super._layout_options()
	options.padding = _padding_insets()
	return options
