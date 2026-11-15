@tool
class_name EstragonVBox
extends "box.gd"
const STACK_DIRECTION := "column"
func _init() -> void:
	direction = "column"
## Native stack participant using the shared composed layout algorithm.
func _layout_axis() -> int:
	return 1
