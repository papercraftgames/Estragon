@tool
extends RefCounted
## Reusable description defaults, not Nodes. Evaluation occurs inside the caller's
## existing composition read scope. Native types/identity/commit remain authoritative.
const ESTRAGON_PRESET := true
const Definition = preload("../node/internal/grid_definition.gd")
const Element = preload("element.gd")
var base: Variant
var defaults: Callable
var generated: Dictionary
var source: String
func _init(component, values: Callable, supplied: Dictionary, location: String) -> void:
	base = component
	defaults = values
	generated = supplied.duplicate(true)
	source = location
static func _native(value) -> bool:
	if not value is Script and not value is String: return false
	var name: String = value if value is String else value.get_instance_base_type()
	return ClassDB.class_exists(name) and ClassDB.is_parent_class(name,"Node") and ClassDB.can_instantiate(name)
static func type_of(value):
	if _native(value): return value
	if value is RefCounted and value.get_script()!=null and value.get_script().get_script_constant_map().get("ESTRAGON_PRESET",false): return type_of(value.base)
	return "Node2D"
static func apply(value, element: Element) -> Element:
	if _native(value):
		element.type = value
		return element
	if not value is RefCounted or value.get_script()==null or not value.get_script().get_script_constant_map().get("ESTRAGON_PRESET",false):
		element.attribute_error = element.source+": component preset requires a preset or native Script/class; previous tree retained"
		return element
	return value.describe(element)
func describe(instance: Element) -> Element:
	var desired := Element.new()
	desired.source = source
	apply(base,desired)
	if not desired.attribute_error.is_empty():
		instance.attribute_error = desired.attribute_error
		return instance
	if not defaults.is_valid():
		instance.attribute_error = source+": layout default scope is no longer valid; previous tree retained"
		return instance
	var merged := {}
	var locations := {}
	for group in defaults.call():
		var expanded := Element.new(desired.type)
		expanded.expand(group)
		if not expanded.attribute_error.is_empty():
			instance.attribute_error = expanded.attribute_error
			return instance
		var values: Dictionary = expanded.properties.duplicate()
		values.merge(expanded.handlers)
		for name in values:
			if merged.has(name) and (typeof(merged[name])!=typeof(values[name]) or merged[name]!=values[name]):
				instance.attribute_error = expanded.location(name)+": conflicting repeated layout default "+name+"; previous tree retained"
				return instance
			merged[name] = values[name]
			locations[name] = expanded.location(name)
	# Generated matrix/placement is a fallback. Explicit defaults and use-site
	# properties override it; named areas are logical metadata, never Node fields.
	var values := generated.duplicate(true)
	values.merge(merged,true)
	if generated.has("areas") and merged.has("template") and merged.template is String and not merged.template.is_empty():
		var parsed := Definition.template(merged.template)
		if parsed.has("error") or parsed.areas!=generated.areas:
			instance.attribute_error = locations.get("template",source)+": layout template must retain the declared area matrix; previous tree retained"
			return instance
		for name in ["columns","rows","areas"]:
			if not merged.has(name): values[name] = null if name!="areas" else []
	var ordered: Array = []
	for name in values:
		if name=="area":
			desired.placement.area = values[name]
			continue
		ordered.append([name,values[name],locations.get(name,source)])
	desired.expand(ordered)
	desired.properties.merge(instance.properties,true)
	# A caller template replaces the preset structured defaults as one native
	# config. Explicit conflicting call-site tracks still fail normal preflight.
	if Definition.marked(desired.type) and instance.properties.get("template",null) is String and not instance.properties.template.is_empty():
		for name in ["columns","rows","areas"]:
			if not instance.properties.has(name): desired.properties[name] = null if name!="areas" else []
	if Definition.marked(desired.type):
		var mode = desired.properties.get("direction","grid")
		if mode in ["row","column"]:
			var main := "horizontal_align" if mode=="row" else "vertical_align"
			if not desired.properties.has(main): desired.properties[main] = "start"
	desired.handlers.merge(instance.handlers,true)
	desired.origins.merge(instance.origins,true)
	desired.spread_properties.merge(instance.spread_properties,true)
	# Defaults from spreads must reset through the existing retained removal path.
	for name in values:
		if name!="area" and not instance.properties.has(name): desired.spread_properties[name] = true
	instance.type = desired.type
	instance.properties = desired.properties
	instance.handlers = desired.handlers
	instance.origins = desired.origins
	instance.spread_properties = desired.spread_properties
	desired.placement.merge(instance.placement,true)
	instance.placement = desired.placement
	return instance
