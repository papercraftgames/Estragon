@tool
class_name EstragonButton
extends "text.gd"
## Native pointer/drawing with a transparent native GUI keyboard endpoint.
signal pressed
signal focus_entered
signal focus_exited
const FocusControl = preload("internal/focus_control.gd")
const Focus = preload("internal/focus.tres")
@export_enum("None", "Click", "All") var focus_mode: int = Control.FOCUS_ALL:
	set(value):
		if value<Control.FOCUS_NONE or value>Control.FOCUS_ALL: return
		focus_mode = value
		_sync_focus()
var _focus_control: Control
var _keyboard_held := false
const ESTRAGON_BUTTON_STYLE := true
var hover_background_color: Variant = Color("#505050"):
	set(value):
		if is_same(hover_background_color,value) or not _visual_style.assign("hover_background_color",value): return
		hover_background_color = value
		_queue_style_redraw()
var pressed_background_color: Variant = Color("#252525"):
	set(value):
		if is_same(pressed_background_color,value) or not _visual_style.assign("pressed_background_color",value): return
		pressed_background_color = value
		_queue_style_redraw()
var disabled_background_color: Variant = Color("#303030"):
	set(value):
		if is_same(disabled_background_color,value) or not _visual_style.assign("disabled_background_color",value): return
		disabled_background_color = value
		_queue_style_redraw()
func _init() -> void:
	background_color = Color("#383838")
	padding = "auto"
func _default_padding() -> Vector4:
	return Vector4(14,8,14,8)
func _get_property_list() -> Array[Dictionary]:
	var result: Array[Dictionary] = super._get_property_list()
	result.append_array(Length.properties(["hover_background_color","pressed_background_color","disabled_background_color"]))
	return result
@export var disabled: bool = false:
	set(value):
		if disabled == value: return
		disabled = value
		_cancel_pointer()
		_sync_focus()
		_queue_style_redraw()
var _router: WeakRef
var _hovered: bool = false
var _held: bool = false
func _enter_tree() -> void:
	super._enter_tree()
	if not Engine.is_editor_hint():
		_focus_control = FocusControl.new()
		_focus_control.name = "_EstragonFocus"
		add_child(_focus_control,false,Node.INTERNAL_MODE_BACK)
		layout_applied.connect(_sync_focus)
		get_window().focus_exited.connect(_focus_control.cancel)
		_sync_focus()
	_layout_scope_changed()
	visibility_changed.connect(_cancel_pointer)
func _layout_scope_changed() -> void:
	var entry = get_layout_root()
	var next = entry._get_pointer_router() if entry != null and entry.has_method("_get_pointer_router") else null
	if _router != null and _router.get_ref() == next: return
	if _router != null and _router.get_ref() != null: _router.get_ref().unregister_button(self)
	_router = null
	if entry != null and entry.has_method("_get_pointer_router"):
		_router = weakref(entry._get_pointer_router())
		_router.get_ref().register_button(self)
func _exit_tree() -> void:
	if is_instance_valid(_focus_control):
		if get_window().focus_exited.is_connected(_focus_control.cancel): get_window().focus_exited.disconnect(_focus_control.cancel)
		layout_applied.disconnect(_sync_focus)
		remove_child(_focus_control)
		_focus_control.free()
		_focus_control = null
	if _router != null and _router.get_ref() != null: _router.get_ref().unregister_button(self)
	_router = null
	if visibility_changed.is_connected(_cancel_pointer): visibility_changed.disconnect(_cancel_pointer)
	_hovered = false
	_held = false
	super._exit_tree()
func _composition_is_private(child: Node) -> bool:
	return child==_focus_control or super._composition_is_private(child)
func _sync_focus(_size: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(_focus_control): return
	_focus_control.size = layout_size
	_focus_control.focus_mode = Control.FOCUS_NONE if disabled else focus_mode
	if not Focus.eligible(_focus_control):
		_focus_control.cancel()
		_focus_control.release_focus()
func grab_focus() -> void:
	if is_instance_valid(_focus_control) and Focus.eligible(_focus_control): _focus_control.grab_focus()
func release_focus() -> void:
	if is_instance_valid(_focus_control): _focus_control.release_focus()
func has_focus() -> bool:
	return is_instance_valid(_focus_control) and _focus_control.has_focus()
func get_focus_control() -> Control:
	return _focus_control
func _cancel_pointer() -> void:
	if _router != null and _router.get_ref() != null: _router.get_ref().cancel_button(self)
func _set_pointer_state(hovered: bool, held: bool) -> void:
	if _hovered == hovered and _held == held: return
	_hovered = hovered
	_held = held
	_queue_style_redraw()
func _pointer_contains(position_in_viewport: Vector2) -> bool:
	var transform := get_global_transform_with_canvas()
	# Transform2D.determinant() is absent from the 4.0 public API.
	if is_zero_approx(transform.x.cross(transform.y)): return false
	return Rect2(Vector2.ZERO,layout_size).has_point(transform.affine_inverse()*position_in_viewport)
func get_background_color() -> Color:
	if disabled: return _visual_style.colors.disabled_background_color
	if _held and _hovered or _keyboard_held: return _visual_style.colors.pressed_background_color
	return _visual_style.colors.hover_background_color if _hovered else super.get_background_color()
func get_label_origin() -> Vector2:
	var content := get_content_rect()
	var remaining := (content.size-_measure_label())*0.5
	return content.position+Vector2(maxf(0,remaining.x),maxf(0,remaining.y))
func _draw() -> void:
	if get_content_rect().size.x>0 and get_content_rect().size.y>0:
		_draw_label(get_label_origin(),Color(1,1,1,0.5) if disabled else Color.WHITE)
	if has_focus() and layout_size.x>4 and layout_size.y>4:
		draw_rect(Rect2(Vector2(2,2),layout_size-Vector2(4,4)),Color("#9cdcff"),false,2)
