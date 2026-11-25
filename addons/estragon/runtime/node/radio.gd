@tool
class_name EstragonRadio
extends "button.gd"
## Option identity is separate from the enclosing group's observable selection.
const ESTRAGON_RADIO := true
var _leaving := false
var _identity_commit := false
@export var value: String = "":
	set(next):
		var group = _radio_owner()
		if next.is_empty() or not _identity_commit and group!=null and not group.accepts(self,next):
			push_error("Estragon Radio.value requires a nonempty unique String identifier")
			return
		if value==next: return
		value = next
		_identity_changed()
func _init() -> void:
	super._init()
	background_color = "transparent"
	pressed.connect(_activate_radio)
	focus_entered.connect(_radio_focused)
	focus_exited.connect(_radio_blurred)
func _enter_tree() -> void:
	_leaving = false
	super._enter_tree()
	visibility_changed.connect(_radio_visibility)
func _exit_tree() -> void:
	_leaving = true
	visibility_changed.disconnect(_radio_visibility)
	super._exit_tree()
func _radio_visibility() -> void:
	var group = _radio_owner()
	if group!=null: group._queue_options()
func _radio_focused() -> void:
	var group = _radio_owner()
	if group!=null: group._option_focused(self)
func _radio_blurred() -> void:
	var group = _radio_owner()
	if group==null: return
	if _radio_eligible() and not _leaving: group._focused = null
	else: group._queue_options()
func _apply_radio_identity(next: String) -> void:
	# The reconciler calls this only after whole desired-group validation. This
	# permits valid swaps/replacements without testing obsolete sibling IDs.
	_identity_commit = true
	value = next
	_identity_commit = false
func _identity_changed() -> void:
	var group = _radio_owner()
	if group!=null: group._queue_options()
	_queue_style_redraw()
func _focus_tab_control():
	var group = _radio_owner()
	var option = group.tab_option() if group!=null else null
	return option.get_focus_control() if option!=null else null
func _radio_owner():
	var parent := get_parent()
	while parent!=null:
		if parent.has_method("_radio_group"): return parent
		parent = parent.get_parent()
	return null
func _input_disabled() -> bool:
	var group = _radio_owner()
	return _leaving or disabled or group==null or group.disabled or not group.accepts(self,value)
func _radio_participates() -> bool:
	return not _input_disabled() and is_instance_valid(_focus_control) and Focus.eligible(_focus_control,false,false)
func _radio_eligible() -> bool:
	return not _input_disabled() and is_instance_valid(_focus_control) and Focus.eligible(_focus_control)
func _focus_tab_stop() -> bool:
	var group = _radio_owner()
	return group!=null and group.tab_option()==self
func _focus_key(event: InputEventKey) -> bool:
	var group = _radio_owner()
	return group!=null and group.navigate(self,event)
func is_selected() -> bool:
	var group = _radio_owner()
	return group!=null and group.value==value and _radio_participates()
func _activate_radio() -> void:
	if _radio_participates(): _radio_owner().value = value
func get_background_color() -> Color:
	return _visual_style.colors.disabled_background_color if _input_disabled() else super.get_background_color()
func _indicator_size() -> float:
	return maxf(16.0,float(font_size))
func _measure_native() -> Vector2:
	var label := _measure_label() if not text.is_empty() else Vector2.ZERO
	return Vector2(_indicator_size()+(8.0+label.x if not text.is_empty() else 0.0),maxf(_indicator_size(),label.y))
func get_label_origin() -> Vector2:
	var content := get_content_rect()
	return content.position+Vector2(_indicator_size()+8,maxf(0,(content.size.y-_measure_label().y)*0.5))
func _draw() -> void:
	var content := get_content_rect()
	var side := minf(_indicator_size(),minf(content.size.x,content.size.y))
	if side<=0: return
	var center := content.position+Vector2(side*0.5,content.size.y*0.5)
	var tint := Color(0.5,0.5,0.5) if _input_disabled() else Color(0.85,0.85,0.85)
	draw_circle(center,maxf(0,side*0.5-1.5),get_background_color())
	draw_arc(center,maxf(0,side*0.5-0.75),0,TAU,40,tint,1.5,true)
	if is_selected():
		var accent: Color = _visual_style.colors.border_color
		draw_circle(center,side*0.27,accent if accent.a>0 else tint)
	_draw_label(get_label_origin(),tint)
	if has_focus() and layout_size.x>4 and layout_size.y>4:
		draw_rect(Rect2(Vector2(2,2),layout_size-Vector2(4,4)),Color("#cccccc"),false,2)
