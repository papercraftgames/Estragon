@tool
class_name EstragonBox
extends "component_2d.gd"
## Constructible horizontal Box. VBox selects the vertical axis.
var padding: Variant = 0.0:
	set(value):
		if is_same(padding,value) or not lengths.assign("padding",value): return
		padding = value
		_changed()
var padding_top: Variant = "auto":
	set(value):
		if is_same(padding_top,value) or not lengths.assign("padding_top",value): return
		padding_top = value
		_changed()
var padding_right: Variant = "auto":
	set(value):
		if is_same(padding_right,value) or not lengths.assign("padding_right",value): return
		padding_right = value
		_changed()
var padding_bottom: Variant = "auto":
	set(value):
		if is_same(padding_bottom,value) or not lengths.assign("padding_bottom",value): return
		padding_bottom = value
		_changed()
var padding_left: Variant = "auto":
	set(value):
		if is_same(padding_left,value) or not lengths.assign("padding_left",value): return
		padding_left = value
		_changed()
func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = super._get_property_list()
	result.append_array(Length.properties(["padding","padding_top","padding_right","padding_bottom","padding_left"]))
	return result

func _padding_insets() -> Vector4:
	layout.model.prepare(layout.model.parent_reference,layout.model.viewport_size)
	return layout.model.padding
