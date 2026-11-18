@tool
class_name EstragonGrid
extends "box.gd"
## Native 2D parent-owned track layout, using the shared mathematical core.
const ESTRAGON_GRID := true
const Definition = preload("internal/grid_definition.gd")
const CONFIG := ["columns","rows","areas","template","horizontal_align","vertical_align"]
var _committing := false
var columns: Variant = null:
	set(value):
		if typeof(columns)==typeof(value) and columns==value: return
		if not _committing and not _accept("columns",value): return
		columns = value.duplicate(true) if value is Array else value
		if not _committing: _changed()
var rows: Variant = null:
	set(value):
		if typeof(rows)==typeof(value) and rows==value: return
		if not _committing and not _accept("rows",value): return
		rows = value.duplicate(true) if value is Array else value
		if not _committing: _changed()
var areas: Array = []:
	set(value):
		if areas==value: return
		if not _committing and not _accept("areas",value): return
		areas = value.duplicate(true)
		if not _committing: _changed()
var template: String = "":
	set(value):
		if template==value: return
		if not _committing and not _accept("template",value): return
		template = value
		if not _committing: _changed()
func _init() -> void:
	_policy_commit = true
	direction = "grid"
	horizontal_align = "stretch"
	vertical_align = "stretch"
	_policy_commit = false
func _config() -> Dictionary:
	return {"columns":columns,"rows":rows,"areas":areas,"template":template,"horizontal_align":horizontal_align,"vertical_align":vertical_align}
func _accept(key: String, value) -> bool:
	var config := _config()
	config[key] = value
	if direction!="grid":
		config.horizontal_align = "stretch"
		config.vertical_align = "stretch"
	var placements: Array = []
	for child in _get_layout_coordinator().model.children: placements.append(child.placement)
	var parsed := Definition.configuration(config,placements if direction=="grid" else [])
	if parsed.has("error"): push_error("Estragon Grid: "+parsed.error)
	return not parsed.has("error")
# Whole-description preflight validated the final config and all placements.
func _apply_grid(values: Dictionary) -> void:
	var before := _config()
	_committing = true
	_policy_commit = true
	for key in CONFIG:
		if values.has(key): set(key,values[key])
	_policy_commit = false
	_committing = false
	if before!=_config(): _changed()
func _layout_options() -> Dictionary:
	var result := super._layout_options()
	if direction!="grid": return result
	result.strategy = "grid"
	result.grid = _config()
	result.alignment = [horizontal_align,vertical_align,"start"]
	return result

func _get_property_list() -> Array[Dictionary]:
	# Native inheritance already collects each base list. Store tracks before
	# dependent areas/template so PackedScene restore never validates a half config.
	var result: Array[Dictionary] = []
	for key in ["columns","rows"]: result.append({"name":key,"type":TYPE_NIL,"usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_NIL_IS_VARIANT})
	result.append({"name":"areas","type":TYPE_ARRAY,"usage":PROPERTY_USAGE_DEFAULT})
	result.append({"name":"template","type":TYPE_STRING,"hint":PROPERTY_HINT_MULTILINE_TEXT,"usage":PROPERTY_USAGE_DEFAULT})
	return result
