@tool
class_name EstragonScrollView
extends "component_2d.gd"
## One authored content root, one existing layout model. Native Control supplies
## rectangular clipping/GUI exclusion; Node2D supplies local scroll translation.
const ESTRAGON_SCROLL_VIEW := true
const Hosts = preload("internal/composition_hosts.tres")
const Pointer = preload("internal/pointer_2d.gd")
@export var horizontal_scroll: bool = false:
	set(value):
		if horizontal_scroll==value: return
		horizontal_scroll = value
		_changed()
@export var vertical_scroll: bool = false:
	set(value):
		if vertical_scroll==value: return
		vertical_scroll = value
		_changed()
@export var scroll_offset := Vector2.ZERO:
	set(value):
		if not valid_offset(value):
			push_error("Estragon ScrollView scroll_offset requires a finite nonnegative Vector2")
			return
		scroll_offset = value
		_update_scroll()
var scroll_range: Vector2:
	get: return _scroll_range
	set(_value): push_error("Estragon ScrollView scroll_range is read-only")
var content_extent: Vector2:
	get: return _content_extent
	set(_value): push_error("Estragon ScrollView content_extent is read-only")
var _scroll_range := Vector2.ZERO
var _content_extent := Vector2.ZERO
var _clip: Control
var _content: Node2D
var _horizontal: HScrollBar
var _vertical: VScrollBar
var _updating := false
var _input_guard = preload("internal/scroll_input.gd").new()
static func valid_offset(value) -> bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y) and value.x>=0 and value.y>=0
func _ensure_viewport() -> void:
	if is_instance_valid(_clip):
		Hosts.add(_content,layout)
		_input_guard.start(_content)
		return
	_clip = get_node_or_null("_EstragonViewport")
	if _clip==null:
		_clip = Control.new()
		_clip.name = "_EstragonViewport"
		_clip.clip_contents = true
		_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_clip,false,Node.INTERNAL_MODE_BACK)
	_content = _clip.get_node_or_null("_EstragonContent")
	if _content==null:
		_content = Node2D.new()
		_content.name = "_EstragonContent"
		_clip.add_child(_content,false,Node.INTERNAL_MODE_BACK)
	Hosts.add(_content,layout)
	_input_guard.start(_content)
	if not _content.child_entered_tree.is_connected(layout._child_entered): _content.child_entered_tree.connect(layout._child_entered)
	if not _content.child_exiting_tree.is_connected(layout._child_exiting): _content.child_exiting_tree.connect(layout._child_exiting)
	_horizontal = HScrollBar.new()
	_vertical = VScrollBar.new()
	add_child(_horizontal,false,Node.INTERNAL_MODE_BACK)
	add_child(_vertical,false,Node.INTERNAL_MODE_FRONT)
	_horizontal.step = 0
	_vertical.step = 0
	_horizontal.value_changed.connect(_horizontal_changed)
	_vertical.value_changed.connect(_vertical_changed)
func _composition_child_parent() -> Node:
	_ensure_viewport()
	return _content
func _layout_children() -> Array:
	return _content.get_children() if is_instance_valid(_content) else []
func get_content_root() -> Node:
	return _content.get_child(0) if is_instance_valid(_content) and _content.get_child_count()>0 else null
func _layout_options() -> Dictionary:
	var result := super._layout_options()
	result.strategy = "scroll"
	result.grid = {"horizontal_scroll":horizontal_scroll,"vertical_scroll":vertical_scroll}
	return result
func _composition_is_private(child: Node) -> bool:
	return child==_clip or child==_horizontal or child==_vertical
func _remember_owners(node: Node, values: Dictionary) -> void:
	if node.owner!=null: values[node] = node.owner
	for child in node.get_children(): _remember_owners(child,values)
func _adopt_content(child: Node) -> void:
	if child.get_parent()!=self or _composition_is_private(child): return
	if _content.get_child_count()>0:
		push_error("Estragon ScrollView requires one content root; wrap siblings in VBox/Grid")
		return
	var owners := {}
	_remember_owners(child,owners)
	var scene_owner := child.owner
	remove_child(child)
	_content.add_child(child)
	if scene_owner!=null:
		# Native scene persistence includes the necessary private ancestry only
		# for an authored persistent root. Generated owner-null views serialize
		# neither helpers nor content; descriptions remount after reload.
		_clip.owner = scene_owner
		_content.owner = scene_owner
	for node in owners:
		if owners[node].is_ancestor_of(node): node.owner = owners[node]
	layout._sync()
func _enter_tree() -> void:
	_ensure_viewport()
	for child in get_children():
		if not _composition_is_private(child): _adopt_content(child)
	super._enter_tree()
	if not child_entered_tree.is_connected(_external_child): child_entered_tree.connect(_external_child)
func _external_child(child: Node) -> void:
	if not _composition_is_private(child): _adopt_later.call_deferred(weakref(child))
func _adopt_later(reference: WeakRef) -> void:
	var child = reference.get_ref()
	if child!=null and is_inside_tree(): _adopt_content(child)
func _exit_tree() -> void:
	_input_guard.stop()
	if child_entered_tree.is_connected(_external_child): child_entered_tree.disconnect(_external_child)
	super._exit_tree()
	if is_instance_valid(_content): Hosts.remove(_content,layout)
func apply_layout_size(extent: Vector3) -> void:
	super.apply_layout_size(extent)
	_refresh_viewport()
func _refresh_viewport() -> void:
	if not is_instance_valid(_clip): return
	var rect := get_content_rect()
	_clip.position = rect.position
	_clip.size = rect.size
	_content_extent = Vector2.ZERO
	if not layout.model.children.is_empty():
		var extent: Vector3 = layout.model.children[0].overflow_extent()
		_content_extent = Vector2(extent.x,extent.y)
	_scroll_range = Vector2(maxf(0,content_extent.x-rect.size.x) if horizontal_scroll else 0,maxf(0,content_extent.y-rect.size.y) if vertical_scroll else 0)
	_update_scroll()
func _update_scroll() -> void:
	if _updating or not is_instance_valid(_content): return
	_updating = true
	scroll_offset = Vector2(clampf(scroll_offset.x,0,scroll_range.x),clampf(scroll_offset.y,0,scroll_range.y))
	if _content.position!=-scroll_offset:
		_input_guard.cancel()
		var entry = get_layout_root()
		if entry!=null and entry.has_method("_get_pointer_router"): entry._get_pointer_router().cancel()
	_content.position = -scroll_offset
	var rect := get_content_rect()
	_horizontal.visible = scroll_range.x>0
	_vertical.visible = scroll_range.y>0
	_horizontal.position = rect.position+Vector2(0,maxf(0,rect.size.y-12))
	_horizontal.size = Vector2(maxf(0,rect.size.x-(12 if _vertical.visible else 0)),12)
	_vertical.position = rect.position+Vector2(maxf(0,rect.size.x-12),0)
	_vertical.size = Vector2(12,maxf(0,rect.size.y-(12 if _horizontal.visible else 0)))
	_horizontal.max_value = content_extent.x
	_horizontal.page = rect.size.x
	_horizontal.value = scroll_offset.x
	_vertical.max_value = content_extent.y
	_vertical.page = rect.size.y
	_vertical.value = scroll_offset.y
	_updating = false
func _horizontal_changed(value: float) -> void:
	if not _updating: scroll_offset = Vector2(value,scroll_offset.y)
func _vertical_changed(value: float) -> void:
	if not _updating: scroll_offset = Vector2(scroll_offset.x,value)
func _content_pointer_allowed(position: Vector2) -> bool:
	for bar in [_horizontal,_vertical]:
		if is_instance_valid(bar) and bar.is_visible_in_tree():
			var point: Vector2 = bar.get_global_transform_with_canvas().affine_inverse()*position
			if Rect2(Vector2.ZERO,bar.size).has_point(point): return false
	return true
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree() or not (event is InputEventMouse or event is InputEventPanGesture): return
	var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
	if not get_content_rect().has_point(point) or not Pointer.inside_clips(self,event.position): return
	var delta := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN: delta.y = 40*event.factor
			MOUSE_BUTTON_WHEEL_UP: delta.y = -40*event.factor
			MOUSE_BUTTON_WHEEL_RIGHT: delta.x = 40*event.factor
			MOUSE_BUTTON_WHEEL_LEFT: delta.x = -40*event.factor
		if event.shift_pressed: delta = Vector2(delta.y,delta.x)
	elif event is InputEventPanGesture: delta = event.delta*40
	else: return
	var next := Vector2(clampf(scroll_offset.x+delta.x,0,scroll_range.x),clampf(scroll_offset.y+delta.y,0,scroll_range.y))
	if next==scroll_offset: return # An exhausted nested viewport bubbles naturally.
	scroll_offset = next
	var entry = get_layout_root()
	if entry!=null and entry.has_method("_get_pointer_router"): entry._get_pointer_router().cancel()
	get_viewport().set_input_as_handled()
