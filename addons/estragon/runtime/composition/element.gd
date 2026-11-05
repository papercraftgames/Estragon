@tool
extends RefCounted
## Desired values only. No native Node is allocated during description creation.
var type: Variant
var properties: Dictionary
var bindings: Dictionary = {}
var handlers: Dictionary
var children: Array
var key: Variant
var keyed: bool
# Normalized authored child-slot/index path, external to native Nodes.
var slot: Array = []
var source: String
func _init(native_type: Variant = null, props: Dictionary = {}, events: Dictionary = {}, descendants: Array = [], location: String = "", identity_key: Variant = null, has_key: bool = false) -> void:
	key = identity_key
	keyed = has_key
	type = native_type
	properties = props
	handlers = events
	children = descendants
	source = location
