@tool
extends "../component_2d.gd"
## Shared native GUI delegation, local skin and lifetime for value controls.
signal focus_entered
signal focus_exited
const Focus = preload("focus.tres")
@export var disabled := false:
	set(next):
		if disabled==next: return
		disabled = next
		_sync_endpoint()
@export var read_only := false:
	set(next):
		if read_only==next: return
		read_only = next
		_sync_endpoint()
@export_enum("None","Click","All") var focus_mode: int = Control.FOCUS_ALL:
	set(next):
		if next<Control.FOCUS_NONE or next>Control.FOCUS_ALL: return
		focus_mode = next
		_sync_endpoint()
@export var font_size: int = 20:
	set(next):
		if next<=0 or next==font_size: return
		font_size = next
		_changed()
		_sync_endpoint()
@export var color := Color.WHITE:
	set(next):
		color = next
		_sync_endpoint()
@export var invalid := false:
	set(next):
		invalid = next
		queue_redraw()
var _theme_key: Array = []
var _endpoint: Control
var _focus_endpoint: Control
func _init() -> void:
	background_color = Color("#383838")
	padding = 8
func _make_endpoint() -> Control: return null
func _measure_native() -> Vector2: return Vector2(200,maxf(32,ThemeDB.fallback_font.get_height(font_size)+8))
func _enter_tree() -> void:
	super._enter_tree()
	if Engine.is_editor_hint(): return
	_install_endpoint()
	layout_applied.connect(_sync_endpoint)
	visibility_changed.connect(_sync_endpoint)
	Focus.geometry_changed.connect(_sync_endpoint)
func _install_endpoint() -> void:
	_endpoint = _make_endpoint()
	_endpoint.name = "_EstragonValue"
	add_child(_endpoint,false,Node.INTERNAL_MODE_BACK)
	_focus_endpoint = _endpoint.get_line_edit() if _endpoint is SpinBox else _endpoint
	if _endpoint is SpinBox: _focus_endpoint.set_script(preload("number_line.gd"))
	_focus_endpoint.focus_entered.connect(_entered)
	_focus_endpoint.focus_exited.connect(_exited)
	_sync_endpoint()
func _remove_endpoint() -> void:
	if not is_instance_valid(_endpoint): return
	_close_endpoint()
	remove_child(_endpoint)
	_endpoint.free()
	_endpoint = null
	_theme_key.clear()
	_focus_endpoint = null
func _exit_tree() -> void:
	if layout_applied.is_connected(_sync_endpoint): layout_applied.disconnect(_sync_endpoint)
	if visibility_changed.is_connected(_sync_endpoint): visibility_changed.disconnect(_sync_endpoint)
	if Focus.geometry_changed.is_connected(_sync_endpoint): Focus.geometry_changed.disconnect(_sync_endpoint)
	_remove_endpoint()
	super._exit_tree()
func _composition_is_private(child: Node) -> bool:
	return child==_endpoint or super._composition_is_private(child)
func _native_value_key(event: InputEventKey) -> bool:
	return event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_HOME,KEY_END,KEY_PAGEUP,KEY_PAGEDOWN,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_ESCAPE]
func _input_disabled() -> bool: return disabled
func _sync_endpoint(_size: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(_endpoint): return
	var content := get_content_rect()
	_endpoint.position = content.position
	_endpoint.size = content.size
	_endpoint.visible = content.size.x>0 and content.size.y>=1
	_focus_endpoint.focus_mode = Control.FOCUS_NONE if disabled else focus_mode
	_endpoint.modulate = Color(1,1,1,0.5) if disabled else Color.WHITE
	if _theme_key!=[font_size,color]:
		_theme_key = [font_size,color]
		_endpoint.add_theme_font_size_override("font_size",font_size)
		_endpoint.add_theme_color_override("font_color",color)
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color.TRANSPARENT
		skin.content_margin_left = 0
		skin.content_margin_right = 0
		for state in ["normal","disabled","focus","read_only"]: _endpoint.add_theme_stylebox_override(state,skin)
		for state in ["hover","pressed"]:
			var feedback := skin.duplicate()
			feedback.bg_color = Color("#505050") if state=="hover" else Color("#252525")
			_endpoint.add_theme_stylebox_override(state,feedback)
	var minimum := _endpoint.get_combined_minimum_size()
	_endpoint.visible = content.size.x>0 and content.size.y>0 and content.size.x>=minimum.x and content.size.y>=minimum.y
	if not Focus.eligible(_focus_endpoint):
		_close_endpoint()
		_focus_endpoint.release_focus()
	queue_redraw()
func _binding_replaced() -> void: _close_endpoint()
func _close_endpoint() -> void:
	if _endpoint is OptionButton: _endpoint.get_popup().hide()
func _entered() -> void:
	if not Focus.eligible(_focus_endpoint): _focus_endpoint.release_focus(); return
	queue_redraw()
	focus_entered.emit()
func _exited() -> void:
	queue_redraw()
	focus_exited.emit()
func grab_focus() -> void:
	if is_instance_valid(_focus_endpoint) and Focus.eligible(_focus_endpoint): _focus_endpoint.grab_focus()
func release_focus() -> void:
	if is_instance_valid(_focus_endpoint): _focus_endpoint.release_focus()
func has_focus() -> bool: return is_instance_valid(_focus_endpoint) and _focus_endpoint.has_focus()
func get_focus_control() -> Control: return _focus_endpoint
func get_native_control() -> Control: return _endpoint
func _draw() -> void:
	if (has_focus() or invalid) and layout_size.x>4 and layout_size.y>4:
		draw_rect(Rect2(Vector2(2,2),layout_size-Vector2(4,4)),Color("#f17b83") if invalid else Color("#cccccc"),false,2)
