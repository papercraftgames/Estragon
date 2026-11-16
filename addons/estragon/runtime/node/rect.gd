@tool
class_name EstragonRect
extends "component_2d.gd"
## background_color is canonical; fill is the legacy native Color view.
const ESTRAGON_RECT_STYLE := true
var fill: Color:
	get: return _visual_style.colors.background_color
	set(value): background_color = value
func _init() -> void:
	background_color = Color.WHITE
func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = super._get_property_list()
	# Store only the canonical value, preserving its authored String/Color type.
	result.append({"name":"fill","type":TYPE_COLOR,"usage":PROPERTY_USAGE_EDITOR})
	return result
