@tool
class_name EstragonHBox
extends "box.gd"
const STACK_DIRECTION := "row"
func _init() -> void:
	direction = "row"
## Native stack participant using the shared composed layout algorithm.
func _layout_axis() -> int:
	return 0
