@tool
extends "value_control.gd"
## Shared Range/SpinBox delegation. Public int/float fields live on typed hosts.
const Contract = preload("numeric_contract.gd")
const ESTRAGON_NUMERIC := true
var _numeric_commit := false
var _native_projection := false
func _integer() -> bool: return Contract.integer(get_script())
func _range_values() -> Dictionary:
	return {"min_value":get("min_value"),"max_value":get("max_value"),"step":get("step"),"value":get("value")}
func _range_field(field: String, next) -> bool:
	if _numeric_commit: return true
	var config := _range_values()
	config[field] = next
	var parsed := Contract.configuration(config,_integer(),false)
	if parsed.has("error"):
		push_error("Estragon numeric "+parsed.field+": "+parsed.error)
		return false
	return true
func _numeric_value(next) -> Dictionary:
	var config := _range_values()
	config.value = next
	var result := Contract.configuration(config,_integer(),false)
	if result.has("error"): push_error("Estragon numeric "+result.field+": "+result.error)
	return result
func _range_changed() -> void:
	if _numeric_commit: return
	_sync_endpoint()
	set("value",get("value"))
	_sync_endpoint()
func _apply_numeric(values: Dictionary) -> void:
	# Whole desired preflight validates final range+value before this transaction.
	var config := _range_values()
	config.merge(values,true)
	var parsed := Contract.configuration(config,_integer(),false)
	if parsed.has("error"): push_error("Estragon numeric: "+parsed.error); return
	_numeric_commit = true
	for field in ["min_value","max_value","step"]: set(field,parsed[field])
	_sync_endpoint()
	set("value",parsed.value)
	_numeric_commit = false
	_sync_endpoint()
func _is_slider() -> bool: return "orientation" in self
func _make_endpoint() -> Control:
	var control: Control
	if _is_slider():
		control = preload("slider_horizontal.gd").new() if get("orientation")=="horizontal" else preload("slider_vertical.gd").new()
		control.scrollable = true
	else:
		control = SpinBox.new()
		control.update_on_text_changed = false
		control.select_all_on_focus = false
	control.value_changed.connect(_native_value)
	return control
func _install_endpoint() -> void:
	super._install_endpoint()
	if _endpoint is SpinBox:
		_focus_endpoint.text_submitted.connect(_number_submitted)
		_focus_endpoint.focus_exited.connect(_number_focus_out)
func _measure_native() -> Vector2:
	return Vector2(24,160) if _is_slider() and get("orientation")=="vertical" else super._measure_native()
func _sync_endpoint(_size: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(_endpoint): return
	_native_projection = true
	_endpoint.set_block_signals(true)
	# Expand before shrinking, avoiding Range's intermediate min/max constraints.
	if _endpoint.min_value>float(get("min_value")): _endpoint.min_value = float(get("min_value"))
	if _endpoint.max_value<float(get("max_value")): _endpoint.max_value = float(get("max_value"))
	if _endpoint.min_value!=float(get("min_value")): _endpoint.min_value = float(get("min_value"))
	if _endpoint.max_value!=float(get("max_value")): _endpoint.max_value = float(get("max_value"))
	if _endpoint.step!=float(get("step")): _endpoint.step = float(get("step"))
	if _endpoint.rounded!=_integer(): _endpoint.rounded = _integer()
	if _endpoint.value!=float(get("value")): _endpoint.set_value_no_signal(float(get("value")))
	if _endpoint.editable!=(not disabled and not read_only): _endpoint.editable = not disabled and not read_only
	_endpoint.set_block_signals(false)
	_native_projection = false
	if _endpoint is SpinBox:
		var line: LineEdit = _endpoint.get_line_edit()
		line.editable = not disabled and not read_only
		line.selecting_enabled = not disabled
		line.context_menu_enabled = not disabled
		line.add_theme_font_size_override("font_size",font_size)
		line.add_theme_color_override("font_color",color)
		var skin := StyleBoxEmpty.new()
		for state in ["normal","focus","read_only"]: line.add_theme_stylebox_override(state,skin)
	else:
		var track := StyleBoxFlat.new()
		track.bg_color = Color("#666666")
		track.content_margin_top = 3;track.content_margin_bottom = 3
		track.content_margin_left = 3;track.content_margin_right = 3
		var fill := track.duplicate()
		fill.bg_color = Color("#cccccc")
		_endpoint.add_theme_stylebox_override("slider",track)
		for state in ["grabber_area","grabber_area_highlight"]: _endpoint.add_theme_stylebox_override(state,fill)
	super._sync_endpoint(_size)
func _project_numeric() -> void:
	if not is_instance_valid(_endpoint) or _native_projection: return
	_native_projection = true
	_endpoint.set_value_no_signal(float(get("value")))
	# Equal Range writes do not rewrite partial native text. External changes do.
	if _endpoint is SpinBox: _endpoint.get_line_edit().text = str(get("value"))
	_native_projection = false
func _native_value(next: float) -> void:
	if _native_projection: return
	if not is_finite(next):
		_sync_endpoint()
		_revert_number()
		return
	if disabled or read_only or not is_inside_tree(): _sync_endpoint(); return
	set("value",int(next) if _integer() else next)
func _number_submitted(_text: String) -> void:
	# SpinBox applies its own native expression parser. Defer final display
	# restoration until native submission has completed, never parse text here.
	_finish_number.call_deferred()
func _number_focus_out() -> void: _finish_number.call_deferred()
func _finish_number() -> void:
	if not is_instance_valid(_endpoint) or not _endpoint is SpinBox: return
	if not disabled and not read_only: _endpoint.apply()
	_revert_number()
func _revert_number() -> void:
	if _endpoint is SpinBox:
		_endpoint.set_value_no_signal(float(get("value")))
		_endpoint.get_line_edit().text = str(get("value"))
func _change_orientation() -> void:
	_changed()
	if not is_instance_valid(_endpoint): return
	var focused := has_focus()
	_remove_endpoint()
	_install_endpoint()
	if focused: grab_focus()

func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = super._get_property_list()
	result.append({"name":"_numeric_configuration","type":TYPE_DICTIONARY,"usage":PROPERTY_USAGE_STORAGE})
	for field in Contract.FIELDS: result.append({"name":field,"type":TYPE_INT if _integer() else TYPE_FLOAT,"usage":PROPERTY_USAGE_EDITOR})
	return result
func _get(property: StringName):
	if property==&"_numeric_configuration": return _range_values()
	return null
func _set(property: StringName, next) -> bool:
	if property!=&"_numeric_configuration": return false
	if not next is Dictionary:
		push_error("Estragon numeric scene configuration requires Dictionary")
		return true
	var parsed := Contract.configuration(next,_integer(),true)
	if parsed.has("error"): push_error("Estragon numeric scene: "+parsed.error)
	else: _apply_numeric(parsed)
	return true

func _remove_endpoint() -> void:
	# Removing a focused SpinBox must not commit a pending edit into a departing
	# mounted writer. Godot may apply LineEdit text during native focus exit.
	_native_projection = true
	super._remove_endpoint()
	_native_projection = false

func _owns_native_wheel(point: Vector2) -> bool:
	if disabled or read_only or not is_instance_valid(_endpoint) or not Focus.eligible(_focus_endpoint,false,false): return false
	if not preload("pointer_2d.gd").inside_clips(_endpoint,point): return false
	var transform := _endpoint.get_global_transform_with_canvas()
	if is_zero_approx(transform.x.cross(transform.y)): return false
	return Rect2(Vector2.ZERO,_endpoint.size).has_point(transform.affine_inverse()*point)
