@tool
extends "res://addons/estragon/runtime/node/internal/coordinator.gd"
## Experimental proof compatibility path; implementation is shared with C1.

func _init(host: Node, dimension: int) -> void:
	super(host, dimension)
