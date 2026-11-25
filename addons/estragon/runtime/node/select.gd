@tool
class_name EstragonSelect
extends "internal/value_control.gd"
signal value_changed(previous: String, value: String)
const ESTRAGON_SELECT := true
const _GOGO_BINDABLE_PROPERTIES_NATIVE := {"value":"String"}
const State = preload("../composition/state.tres")
@export var value: String = "":
	set(next):
		if value==next: return
		_close_endpoint()
		var previous := value
		value = next
		_project_selection()
		value_changed.emit(previous,next)
	get:
		State.observe(self,&"value_changed")
		return value
@export var placeholder: String = "Choose…":
	set(next):
		placeholder = next
		_project_selection()
var _queued := false
var _ids: Array[String] = []
var _projection: Array = []
func _make_endpoint() -> Control:
	var button := preload("internal/select_control.gd").new()
	button.item_selected.connect(_selected)
	button.get_popup().about_to_popup.connect(_opening)
	button.get_popup().popup_hide.connect(_popup_closed)
	return button
func _enter_tree() -> void:
	super._enter_tree()
	get_tree().tree_changed.connect(_queue_options)
	_queue_options()
func _exit_tree() -> void:
	get_tree().tree_changed.disconnect(_queue_options)
	_ids.clear()
	_projection.clear()
	super._exit_tree()
func _collect(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child.has_method("_select_options"): continue
		if child.has_method("_select_owner"): result.append(child)
		_collect(child,result)
func _select_options() -> Array:
	var result: Array = []
	_collect(self,result)
	return result
func _accepts_option(option: Node, identity: String) -> bool:
	for other in _select_options():
		if other!=option and other.value==identity: return false
	return true
func _queue_options() -> void:
	_close_endpoint()
	if _queued: return
	_queued = true
	_refresh_options.call_deferred()
func _refresh_options() -> void:
	_queued = false
	if not is_instance_valid(_endpoint): return
	var next: Array = []
	var known := {}
	for option in _select_options():
		if option.value.is_empty() or known.has(option.value):
			push_error("Estragon Select: option identifiers must be nonempty and unique")
			return
		known[option.value] = true
		next.append([option.value,option.text,option.disabled,option.hidden])
	if next==_projection: return
	_close_endpoint()
	_projection = next
	_endpoint.clear()
	_ids.clear()
	for item in next:
		if item[3]: continue
		var index := _ids.size()
		_endpoint.add_item(item[1])
		_endpoint.set_item_disabled(index,item[2])
		_ids.append(item[0])
	_project_selection()
func _project_selection() -> void:
	if not is_instance_valid(_endpoint): return
	var index := _ids.find(value)
	if index>=0 and _endpoint.is_item_disabled(index): index = -1
	_endpoint.select(index)
	if index<0: _endpoint.text = placeholder
func _selected(index: int) -> void:
	if disabled or read_only or not Focus.eligible(_focus_endpoint) or index<0 or index>=_ids.size() or _endpoint.is_item_disabled(index):
		_project_selection()
		return
	value = _ids[index]
func _opening() -> void:
	if disabled or read_only or not Focus.eligible(_focus_endpoint): _endpoint.get_popup().hide.call_deferred()
func _popup_closed() -> void:
	if is_instance_valid(_focus_endpoint) and Focus.eligible(_focus_endpoint): grab_focus()
func _sync_endpoint(_size: Vector2 = Vector2.ZERO) -> void:
	super._sync_endpoint(_size)
	if not is_instance_valid(_endpoint): return
	_endpoint.disabled = disabled or read_only
	# The closed trigger uses its stable host allocation, not the longest label.
	_endpoint.fit_to_longest_item = false
	if disabled or read_only: _close_endpoint()
