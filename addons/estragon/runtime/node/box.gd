@tool
class_name EstragonBox
extends "component_2d.gd"
## Constructible horizontal Box. VBox selects the vertical axis.
const ESTRAGON_STACK_POLICY := true
var _policy_commit := false
const StackContract = preload("internal/stack_contract.gd")
@export_enum("row", "column") var direction: String = "row":
	set(value):
		if value==direction: return
		if _policy_commit:
			direction = value
			return
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
		if _policy_commit:
			horizontal_align = value
			return
		if value==horizontal_align or not _valid_alignment("horizontal_align",value): return
		horizontal_align = value
		_changed()
@export_enum("start", "center", "end", "stretch") var vertical_align: String = "start":
	set(value):
		if _policy_commit:
			vertical_align = value
			return
		if value==vertical_align or not _valid_alignment("vertical_align",value): return
		vertical_align = value
		_changed()
# Called only after whole-description preflight; avoids transient invalid states
# when direction and cross alignment change together in one reconciliation.
func _apply_stack_policy(values: Dictionary) -> void:
	var before := [direction,horizontal_align,vertical_align]
	_policy_commit = true
	for key in ["direction","horizontal_align","vertical_align"]:
		if values.has(key): set(key,values[key])
	_policy_commit = false
	if before!=[direction,horizontal_align,vertical_align]: _changed()
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
