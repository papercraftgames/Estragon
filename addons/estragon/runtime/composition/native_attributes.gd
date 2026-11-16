@tool
extends RefCounted
## Native writable-property metadata, shared by compiler and description preflight.
# 4.0 lacks ClassDB's setter introspection. Its official 4.0.4 class reference
# declares these getter-only Node properties with setter="". This small bridge
# rejects them without probe Nodes or speculative setter-name inference. Newer
# engines use their actual ClassDB metadata, including newly introduced classes.
const BASELINE_READ_ONLY := {
	"AnimationPlayer":["current_animation_length","current_animation_position"],
	"Node":["multiplayer"],
	"ShapeCast2D":["collision_result"],
	"ShapeCast3D":["collision_result"],
	"Timer":["time_left"],
}
static func writable(native: String, script, name: String, property: Dictionary) -> bool:
	if name in ["owner","script"] or name.contains("/"): return false
	if int(property.usage)&(PROPERTY_USAGE_READ_ONLY|PROPERTY_USAGE_CATEGORY|PROPERTY_USAGE_GROUP|PROPERTY_USAGE_SUBGROUP): return false
	# Source-resolved Gogo fields belong to the authored subtype, not the native
	# base Script used for metadata lookup. They have ordinary GDScript setters.
	if property.get("source_writable",false): return true
	while script is Script:
		for field in script.get_script_property_list():
			if str(field.name)==name: return true
		script = script.get_base_script()
	if ClassDB.has_method("class_get_property_setter"):
		return not str(ClassDB.call("class_get_property_setter",native,name)).is_empty()
	for base in BASELINE_READ_ONLY:
		if name in BASELINE_READ_ONLY[base] and ClassDB.is_parent_class(native,base): return false
	return true
