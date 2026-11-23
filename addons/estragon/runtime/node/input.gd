@tool
class_name EstragonInput
extends "component_2d.gd"
## Node2D layout/skin with one private native single-line editing endpoint.
signal value_changed(previous: String, value: String)
signal submitted(value: String)
signal cancelled
signal focus_entered
signal focus_exited
const Editor = preload("internal/input_control.gd")
const Focus = preload("internal/focus.tres")
const State = preload("../composition/state.tres")
const _GOGO_BINDABLE_PROPERTIES_NATIVE := {"value":"String"}
@export var value: String = "":
	set(next):
		if value==next: return
		var previous := value
		value = next
		_project_value()
		value_changed.emit(previous,next)
	get:
		State.observe(self,&"value_changed")
		return value
@export var placeholder: String = "":
	set(next):
		if placeholder==next: return
		placeholder = next
		_sync_editor()
@export var disabled := false:
	set(next):
		if disabled==next: return
		disabled = next
		_sync_editor()
		queue_redraw()
@export var read_only := false:
	set(next):
		if read_only==next: return
		read_only = next
		_sync_editor()
@export var invalid := false:
	set(next):
		if invalid==next: return
		invalid = next
		queue_redraw()
@export_enum("None", "Click", "All") var focus_mode: int = Control.FOCUS_ALL:
	set(next):
		if next<Control.FOCUS_NONE or next>Control.FOCUS_ALL: return
		focus_mode = next
		_sync_editor()
@export var font: Font = ThemeDB.fallback_font:
	set(next):
		if next==null or next==font: return
		_disconnect_font()
		font = next
		_connect_font()
		_style_changed()
@export var font_size: int = 20:
	set(next):
		if next<=0 or font_size==next: return
		font_size = next
		_style_changed()
@export var color := Color.WHITE:
	set(next):
		if color==next: return
		color = next
		_sync_theme()
@export var focus_color := Color("#9cdcff"):
	set(next):
		focus_color = next
		queue_redraw()
@export var invalid_color := Color("#f17b83"):
	set(next):
		invalid_color = next
		queue_redraw()
var _editor: LineEdit
var _editor_skin := StyleBoxEmpty.new()
func _init() -> void:
	background_color = Color("#252d38")
	padding = 8.0
func _measure_native() -> Vector2:
	# A stable single-line viewport, not a text-dependent expanding field.
	return Vector2(200,font.get_height(font_size))
func _enter_tree() -> void:
	_connect_font()
	super._enter_tree()
	if Engine.is_editor_hint(): return
	_editor = Editor.new()
	_editor.name = "_EstragonInput"
	_editor.text = value
	add_child(_editor,false,Node.INTERNAL_MODE_BACK)
	_editor.text_changed.connect(_edited)
	_editor.text_submitted.connect(_submitted)
	layout_applied.connect(_sync_editor)
	_sync_theme()
	_sync_editor()
func _exit_tree() -> void:
	if is_instance_valid(_editor):
		layout_applied.disconnect(_sync_editor)
		remove_child(_editor)
		_editor.free()
		_editor = null
	_disconnect_font()
	super._exit_tree()
func _composition_is_private(child: Node) -> bool:
	return child==_editor or super._composition_is_private(child)
func _connect_font() -> void:
	if is_inside_tree() and not font.changed.is_connected(_style_changed): font.changed.connect(_style_changed)
func _disconnect_font() -> void:
	if font!=null and font.changed.is_connected(_style_changed): font.changed.disconnect(_style_changed)
func _style_changed() -> void:
	_changed()
	_sync_theme()
func _sync_theme() -> void:
	if not is_instance_valid(_editor): return
	# Native text/caret/selection draw in the real content rect; the host
	# supplies the local surface, border and focus/invalid outline.
	for state in ["normal","read_only","focus"]: _editor.add_theme_stylebox_override(state,_editor_skin)
	_editor.add_theme_constant_override("minimum_character_width",0)
	_editor.add_theme_font_override("font",font)
	_editor.add_theme_font_size_override("font_size",font_size)
	for key in ["font_color","font_uneditable_color","caret_color"]: _editor.add_theme_color_override(key,color)
	_editor.add_theme_color_override("font_placeholder_color",Color(color,0.5))
	_sync_editor()
func _sync_editor(_size: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(_editor): return
	var content := get_content_rect()
	_editor.visible = content.size.x>0 and content.size.y>=font.get_height(font_size)
	_editor_skin.content_margin_left = content.position.x
	_editor_skin.content_margin_top = content.position.y
	_editor_skin.content_margin_right = maxf(0,layout_size.x-content.end.x)
	_editor_skin.content_margin_bottom = maxf(0,layout_size.y-content.end.y)
	_editor.position = Vector2.ZERO
	_editor.size = layout_size
	_editor.placeholder_text = placeholder
	_editor.editable = not disabled and not read_only
	_editor.selecting_enabled = not disabled
	_editor.shortcut_keys_enabled = not disabled
	_editor.context_menu_enabled = not disabled
	_editor.focus_mode = Control.FOCUS_NONE if disabled else focus_mode
	_editor.modulate = Color(1,1,1,0.5) if disabled else Color.WHITE
	if not Focus.eligible(_editor): _editor.release_focus()
func _project_value() -> void:
	if not is_instance_valid(_editor) or _editor.text==value: return
	var caret := _editor.caret_column
	var selected := _editor.has_selection()
	var start := _editor.get_selection_from_column() if selected else 0
	var end := _editor.get_selection_to_column() if selected else 0
	_editor.text = value
	_editor.caret_column = mini(caret,value.length())
	if selected: _editor.select(mini(start,value.length()),mini(end,value.length()))
func _edited(next: String) -> void: value = next
func _submitted(next: String) -> void: submitted.emit(next)
func grab_focus() -> void:
	if is_instance_valid(_editor) and Focus.eligible(_editor): _editor.grab_focus()
func release_focus() -> void:
	if is_instance_valid(_editor): _editor.release_focus()
func has_focus() -> bool: return is_instance_valid(_editor) and _editor.has_focus()
func get_focus_control() -> Control: return _editor
func _draw() -> void:
	if (has_focus() or invalid) and layout_size.x>4 and layout_size.y>4:
		draw_rect(Rect2(Vector2(2,2),layout_size-Vector2(4,4)),invalid_color if invalid else focus_color,false,2)
