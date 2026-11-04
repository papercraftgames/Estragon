@tool
class_name EstragonButton2D
extends "res://addons/estragon/runtime/node/text_2d.gd"
## Native primary-pointer button. No Control widget or polling wrapper.
signal pressed
const PADDING := Vector2(14,8)
@export var disabled: bool = false:
	set(value):
		if disabled == value: return
		disabled = value
		_cancel_pointer()
		queue_redraw()
var _router: WeakRef
var _hovered: bool = false
var _held: bool = false
func _enter_tree() -> void:
	super._enter_tree()
	var entry = get_layout_root()
	if entry != null and entry.has_method("_get_pointer_router"):
		_router = weakref(entry._get_pointer_router())
		_router.get_ref().register_button(self)
	visibility_changed.connect(_cancel_pointer)
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
	queue_redraw()
func _pointer_contains(position_in_viewport: Vector2) -> bool:
	var transform := get_global_transform_with_canvas()
	if is_zero_approx(transform.determinant()): return false
	return Rect2(Vector2.ZERO,layout_size).has_point(transform.affine_inverse()*position_in_viewport)
func _measure_native() -> Vector2:
	return _measure_label()+PADDING*2
func get_background_color() -> Color:
	if disabled: return Color("38343f")
	if _held and _hovered: return Color("302440")
	return Color("705a9e") if _hovered else Color("514174")
func _draw() -> void:
	if layout_size.x <= 0 or layout_size.y <= 0: return
	draw_rect(Rect2(Vector2.ZERO,layout_size),get_background_color())
	var offset := (layout_size-_measure_label())*0.5
	offset = Vector2(maxf(0,offset.x),maxf(0,offset.y))
	_draw_label(offset,Color(1,1,1,0.5) if disabled else Color.WHITE)
