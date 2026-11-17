@tool
class_name EstragonBox
extends "component_2d.gd"
## Constructible horizontal Box. VBox selects the vertical axis.
const ESTRAGON_STACK_POLICY := true
@export var wrap: bool = false:
	set(value):
		if value==wrap: return
		wrap = value
		_changed()
@export_enum("start","center","end","space-between","space-around","space-evenly","stretch") var align_content: String = "start":
	set(value):
		if value==align_content: return
		var message := StackContract.error("align_content",value,"")
		if not message.is_empty():
			push_error("Estragon Box: "+message)
			return
		align_content = value
		_changed()
var _policy_commit := false
const StackContract = preload("internal/stack_contract.gd")
@export_enum("row", "column", "grid") var direction: String = "row":
	set(value):
		if value==direction: return
		if _policy_commit:
			direction = value
			return
		# Grid's default stretch becomes a legal main-axis start on mode change.
		# Track/area/template values remain untouched and can be restored.
		if direction=="grid" and value in ["row","column"] and StackContract.grid_capable(get_script()):
			_policy_commit = true
			if value=="row" and horizontal_align=="stretch": horizontal_align = "start"
			if value=="column" and vertical_align=="stretch": vertical_align = "start"
			_policy_commit = false
		var message := StackContract.error("direction",value,value,StackContract.preset(get_script()),StackContract.grid_capable(get_script()))
		if message.is_empty():
			message = StackContract.error("horizontal_align",horizontal_align,value,"",StackContract.grid_capable(get_script()))
			if message.is_empty(): message = StackContract.error("vertical_align",vertical_align,value,"",StackContract.grid_capable(get_script()))
		if not message.is_empty():
			push_error("Estragon Box: "+message)
			return
		direction = value
		_changed()
@export_enum("start", "center", "end", "stretch", "space-between", "space-around", "space-evenly") var horizontal_align: String = "start":
	set(value):
		if _policy_commit:
			horizontal_align = value
			return
		if value==horizontal_align or not _valid_alignment("horizontal_align",value): return
		horizontal_align = value
		_changed()
@export_enum("start", "center", "end", "stretch", "space-between", "space-around", "space-evenly") var vertical_align: String = "start":
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
	var message := StackContract.error(property,value,direction,"",StackContract.grid_capable(get_script()))
	if not message.is_empty(): push_error("Estragon Box: "+message)
	return message.is_empty()
func _layout_axis() -> int:
	return 0 if direction=="row" else 1
func _layout_options() -> Dictionary:
	var result := super._layout_options()
	result["alignment"] = [horizontal_align,vertical_align,"start"]
	result["strategy"] = "wrap" if wrap else "stack"
	result["align_content"] = align_content
	return result
