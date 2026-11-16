@tool
extends Node2D
var caption: String = "declaration"
signal edited(value: bool)
func _init() -> void:
	caption = "initialized"
