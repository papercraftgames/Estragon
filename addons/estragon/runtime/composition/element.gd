@tool
extends RefCounted
const Profile = preload("profile.tres")
## Desired values only. No native Node is allocated during description creation.
# Internal normalized weak reference, only populated by child normalization.
var borrowed: WeakRef
var type: Variant
var properties: Dictionary
var placement: Dictionary = {}
var bindings: Dictionary = {}
var handlers: Dictionary
var children: Array
var key: Variant
var keyed: bool
# Normalized authored child-slot/index path, external to native Nodes.
var slot: Array = []
var source: String
# Attribute provenance belongs to descriptions, never user Nodes or Dictionaries.
var origins: Dictionary = {}
var spread_properties: Dictionary = {}
var attribute_error := ""

# Snapshot at the argument evaluation point, before later expressions can mutate
# the same Dictionary. Values retain normal native reference semantics.
static func snapshot(value):
	return value.duplicate() if value is Dictionary else value

func location(name: String) -> String:
	return origins.get(name,source)

func expand(attributes: Array) -> void:
	var values := {}
	var signals := {}
	var native: String = type if type is String else type.get_instance_base_type()
	for event in ClassDB.class_get_signal_list(native): signals[str(event.name)] = true
	var script = type if type is Script else null
	while script != null:
		for event in script.get_script_signal_list(): signals[str(event.name)] = true
		script = script.get_base_script()
	for entry in attributes:
		if entry[0]!=null:
			values[entry[0]] = entry[1]
			origins[entry[0]] = entry[2]
			spread_properties.erase(entry[0])
			continue
		if not entry[1] is Dictionary:
			attribute_error = str(entry[2])+": GGX spread requires a Dictionary; previous tree retained"
			return
		for raw in entry[1]:
			if not typeof(raw) in [TYPE_STRING,TYPE_STRING_NAME] or str(raw).is_empty():
				attribute_error = str(entry[2])+": GGX spread key "+str(raw)+" requires a nonempty String/StringName; previous tree retained"
				return
			var name := str(raw)
			if name=="key" or name.begins_with("bind:"):
				attribute_error = str(entry[2])+": GGX spread key '"+name+"' must be explicitly authored; previous tree retained"
				return
			values[name] = entry[1][raw]
			origins[name] = str(entry[2])+" (spread key '"+name+"')"
			spread_properties[name] = true
	for name in values:
		if signals.has(name): handlers[name] = values[name]
		else: properties[name] = values[name]

func _init(native_type: Variant = null, props: Dictionary = {}, events: Dictionary = {}, descendants: Array = [], location: String = "", identity_key: Variant = null, has_key: bool = false) -> void:
	if Profile.is_enabled(): Profile.add("elements")
	key = identity_key
	keyed = has_key
	type = native_type
	properties = props
	handlers = events
	children = descendants
	source = location

# Called after ordered explicit/spread attributes, before desired-tree preflight.
# No conversion: a dynamic non-String rejects the entire description transaction.
func set_text_body(parts: Array) -> void:
	if not attribute_error.is_empty(): return
	if properties.has("text"):
		attribute_error = location("text")+": text property conflicts with text body; previous tree retained"
		return
	var value := ""
	for part in parts:
		if not part[0] is String:
			attribute_error = str(part[1])+": text body expression requires String; previous tree retained"
			return
		value += part[0]
	properties["text"] = value
	origins["text"] = parts[0][1] if not parts.is_empty() else source
