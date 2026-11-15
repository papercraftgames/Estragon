@tool
class_name EstragonBox
extends "component_2d.gd"
## Constructible horizontal Box. VBox selects the vertical axis.
const ESTRAGON_STACK_POLICY := true
const StackContract = preload("internal/stack_contract.gd")
@export_enum("row", "column") var direction: String = "row":
	set(value):
		if value==direction: return
		var message := StackContract.error("direction",value,value,StackContract.preset(get_script()))
		if message.is_empty():
			message = StackContract.error("horizontal_align",horizontal_align,value)
			if message.is_empty(): message = StackContract.error("vertical_align",vertical_align,value)
		if not message.is_empty():
			push_error("Estragon Box: "+message)
			return
		direction = value
		_changed()
@export_enum("start", "center", "end", "stretch") var horizontal_align: String = "start":
	set(value):
		if value==horizontal_align or not _valid_alignment("horizontal_align",value): return
		horizontal_align = value
		_changed()
@export_enum("start", "center", "end", "stretch") var vertical_align: String = "start":
	set(value):
		if value==vertical_align or not _valid_alignment("vertical_align",value): return
		vertical_align = value
		_changed()
func _valid_alignment(property: String, value) -> bool:
	var message := StackContract.error(property,value,"row" if _layout_axis()==0 else "column")
	if not message.is_empty(): push_error("Estragon Box: "+message)
	return message.is_empty()
func _layout_axis() -> int:
	return 0 if direction=="row" else 1
func _layout_options() -> Dictionary:
	var result := super._layout_options()
	result["alignment"] = [horizontal_align,vertical_align,"start"]
	return result
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
