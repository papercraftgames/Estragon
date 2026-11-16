@tool
class_name EstragonGrid
extends "component_2d.gd"
## Native 2D parent-owned track layout, using the shared mathematical core.
const ESTRAGON_GRID := true
const Definition = preload("internal/grid_definition.gd")
const CONFIG := ["columns","rows","areas","template","horizontal_align","vertical_align"]
var _committing := false
var columns: Variant = null:
	set(value):
		if is_same(columns,value): return
		if not _committing and not _accept("columns",value): return
		columns = value.duplicate(true) if value is Array else value
		if not _committing: _changed()
var rows: Variant = null:
	set(value):
		if is_same(rows,value): return
		if not _committing and not _accept("rows",value): return
		rows = value.duplicate(true) if value is Array else value
		if not _committing: _changed()
@export var areas: Array = []:
	set(value):
		if areas==value: return
		if not _committing and not _accept("areas",value): return
		areas = value.duplicate(true)
		if not _committing: _changed()
@export_multiline var template: String = "":
	set(value):
		if template==value: return
		if not _committing and not _accept("template",value): return
		template = value
		if not _committing: _changed()
@export_enum("start","center","end","stretch") var horizontal_align: String = "stretch":
	set(value):
		if value==horizontal_align: return
		if not _committing and not _accept("horizontal_align",value): return
		horizontal_align = value
		if not _committing: _changed()
@export_enum("start","center","end","stretch") var vertical_align: String = "stretch":
	set(value):
		if value==vertical_align: return
		if not _committing and not _accept("vertical_align",value): return
		vertical_align = value
		if not _committing: _changed()
func _config() -> Dictionary:
	return {"columns":columns,"rows":rows,"areas":areas,"template":template,"horizontal_align":horizontal_align,"vertical_align":vertical_align}
func _accept(key: String, value) -> bool:
	var config := _config()
	config[key] = value
	var placements: Array = []
	for child in _get_layout_coordinator().model.children: placements.append(child.placement)
	var parsed := Definition.configuration(config,placements)
	if parsed.has("error"): push_error("Estragon Grid: "+parsed.error)
	return not parsed.has("error")
# Whole-description preflight validated the final config and all placements.
func _apply_grid(values: Dictionary) -> void:
	var before := _config()
	_committing = true
	for key in CONFIG:
		if values.has(key): set(key,values[key])
	_committing = false
	if before!=_config(): _changed()
func _layout_options() -> Dictionary:
	var result := super._layout_options()
	result.strategy = "grid"
	result.grid = _config()
	result.alignment = [horizontal_align,vertical_align,"start"]
	return result

func _get_property_list() -> Array[Dictionary]:
	var result := super._get_property_list()
	for key in ["columns","rows"]: result.append({"name":key,"type":TYPE_NIL,"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_NIL_IS_VARIANT})
	return result
