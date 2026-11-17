@tool
class_name EstragonButton
extends "text.gd"
## Native primary-pointer button. No Control widget or polling wrapper.
signal pressed
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
		_queue_style_redraw()
var _router: WeakRef
var _hovered: bool = false
var _held: bool = false
func _enter_tree() -> void:
	super._enter_tree()
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
	if _router != null and _router.get_ref() != null: _router.get_ref().unregister_button(self)
	_router = null
	if visibility_changed.is_connected(_cancel_pointer): visibility_changed.disconnect(_cancel_pointer)
	_hovered = false
	_held = false
	super._exit_tree()
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
	if _held and _hovered: return _visual_style.colors.pressed_background_color
	return _visual_style.colors.hover_background_color if _hovered else super.get_background_color()
func get_label_origin() -> Vector2:
	var content := get_content_rect()
	var remaining := (content.size-_measure_label())*0.5
	return content.position+Vector2(maxf(0,remaining.x),maxf(0,remaining.y))
func _draw() -> void:
	if get_content_rect().size.x<=0 or get_content_rect().size.y<=0: return
	_draw_label(get_label_origin(),Color(1,1,1,0.5) if disabled else Color.WHITE)
