@tool
extends RefCounted
## Desired values only. No native Node is allocated during description creation.
var type: Variant
var properties: Dictionary
var handlers: Dictionary
var children: Array
var source: String
func _init(native_type: Variant = null, props: Dictionary = {}, events: Dictionary = {}, descendants: Array = [], location: String = "") -> void:
	type = native_type
	properties = props
	handlers = events
	children = descendants
	source = location
