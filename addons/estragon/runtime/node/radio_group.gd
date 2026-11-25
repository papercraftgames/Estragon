@tool
class_name EstragonRadioGroup
extends "box.gd"
## A String selection over native Radio options; Box remains the layout owner.
signal value_changed(previous: String, value: String)
const ESTRAGON_RADIO_GROUP := true
const ESTRAGON_STACK_INITIAL := "column"
const _GOGO_BINDABLE_PROPERTIES_NATIVE := {"value":"String"}
const Focus = preload("internal/focus.tres")
const State = preload("../composition/state.tres")
@export var value: String = "":
	set(next):
		if value==next: return
		var previous := value
		value = next
		_refresh_options()
		value_changed.emit(previous,next)
	get:
		State.observe(self,&"value_changed")
		return value
@export var disabled: bool = false:
	set(next):
		if disabled==next: return
		disabled = next
		_refresh_options()
var _refresh_pending := false
var _options_dirty := true
var _options: Array[WeakRef] = []
var _identity_counts: Dictionary = {}
var _focused: WeakRef
var _focused_index := 0
var _duplicate_ids: Array = []
func _init() -> void:
	direction = ESTRAGON_STACK_INITIAL
func _enter_tree() -> void:
	super._enter_tree()
	get_tree().tree_changed.connect(_queue_options)
	if not Engine.is_editor_hint(): Focus.geometry_changed.connect(_queue_options)
	visibility_changed.connect(_refresh_options)
	layout_applied.connect(_arranged)
	_queue_options()
func _exit_tree() -> void:
	get_tree().tree_changed.disconnect(_queue_options)
	if Focus.geometry_changed.is_connected(_queue_options): Focus.geometry_changed.disconnect(_queue_options)
	visibility_changed.disconnect(_refresh_options)
	layout_applied.disconnect(_arranged)
	_options.clear()
	_identity_counts.clear()
	_options_dirty = true
	_focused = null
	super._exit_tree()
func _arranged(_size: Vector2) -> void:
	_refresh_options()
func _queue_options() -> void:
	_options_dirty = true
	if _refresh_pending: return
	_refresh_pending = true
	_refresh_options.call_deferred()
func _collect_options(node: Node, output: Array) -> void:
	for child in (node._layout_children() if node.has_method("_layout_children") else node.get_children()):
		if child.has_method("_radio_group"): continue
		if child.has_method("_radio_owner"): output.append(child)
		_collect_options(child,output)
func _radio_group() -> Node:
	return self
func options() -> Array:
	if _options_dirty or not is_inside_tree():
		_options_dirty = false
		var current: Array = []
		_collect_options(self,current)
		_options.clear()
		_identity_counts.clear()
		for option in current:
			_options.append(weakref(option))
			_identity_counts[option.value] = _identity_counts.get(option.value,0)+1
	var result: Array = []
	for reference in _options:
		var option = reference.get_ref()
		if option!=null: result.append(option)
	return result
func accepts(option: Node, identity: String) -> bool:
	if identity.is_empty(): return false
	if _options_dirty or not is_inside_tree(): options()
	var count: int = _identity_counts.get(identity,0)
	return count==0 or count==1 and option.value==identity
func _refresh_options() -> void:
	_refresh_pending = false
	if not is_inside_tree(): return
	var list := options()
	var duplicates: Array = []
	var identities := {}
	for option in list:
		if option.value.is_empty() or identities.has(option.value): duplicates.append(option.value)
		identities[option.value] = true
	if duplicates!=_duplicate_ids:
		_duplicate_ids = duplicates
		if not duplicates.is_empty(): push_error("Estragon RadioGroup: option identifiers must be nonempty and unique: "+str(duplicates))
	for option in list:
		if not option._radio_participates(): option._cancel_pointer()
		option._sync_focus()
		option._queue_style_redraw()
	if _focused!=null:
		var previous = _focused.get_ref()
		if previous!=null and list.has(previous) and previous._radio_eligible(): _focused_index = list.find(previous)
		else:
			_focused = null
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner!=null and Focus.eligible(focus_owner): return
			for offset in range(list.size()):
				var candidate = list[posmod(_focused_index+offset,list.size())]
				if candidate._radio_eligible():
					candidate.grab_focus()
					break
func _option_focused(option: Node) -> void:
	_focused = weakref(option)
	_focused_index = options().find(option)
func tab_option():
	var first
	for option in options():
		if not option._radio_eligible() or option.get_focus_control().focus_mode!=Control.FOCUS_ALL: continue
		if first==null: first = option
		if option.value==value: return option
	return first
func navigate(option: Node, event: InputEventKey) -> bool:
	var backwards: int = KEY_LEFT if direction=="row" else KEY_UP
	var forwards: int = KEY_RIGHT if direction=="row" else KEY_DOWN
	if not event.keycode in [backwards,forwards,KEY_HOME,KEY_END] or event.alt_pressed or event.ctrl_pressed or event.meta_pressed: return false
	if not event.pressed or event.echo: return true
	var eligible: Array = []
	for candidate in options():
		if candidate._radio_eligible(): eligible.append(candidate)
	if eligible.is_empty(): return true
	var index: int = eligible.find(option)
	index = 0 if event.keycode==KEY_HOME else eligible.size()-1 if event.keycode==KEY_END else posmod(index+(-1 if event.keycode==backwards else 1),eligible.size())
	var next = eligible[index]
	value = next.value
	next.grab_focus()
	return true
