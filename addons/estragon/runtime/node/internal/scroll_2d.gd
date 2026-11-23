@tool
extends RefCounted
## Lazy native viewport decoration. One owner coordinator; no child layout policy.
const Hosts = preload("composition_hosts.tres")
const Pointer = preload("pointer_2d.gd")
const Focus = preload("focus.tres")
var owner_ref: WeakRef
var host:
	get: return owner_ref.get_ref()
var _clip: Control
var _content: Node2D
var _horizontal: HScrollBar
var _vertical: VScrollBar
var _updating := false
var _input_guard = preload("scroll_input.gd").new()
func _init(owner: Node2D) -> void:
	owner_ref = weakref(owner)
static func valid_offset(value) -> bool:
	return value is Vector2 and is_finite(value.x) and is_finite(value.y) and value.x>=0 and value.y>=0
func _ensure_viewport() -> void:
	if is_instance_valid(_clip):
		Hosts.add(_content,host.layout)
		if clipping(): _input_guard.start(_content)
		return
	_clip = host.get_node_or_null("_EstragonViewport")
	if _clip==null:
		_clip = Control.new()
		_clip.name = "_EstragonViewport"
		_clip.clip_contents = true
		_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(_clip,false,Node.INTERNAL_MODE_BACK)
	_content = _clip.get_node_or_null("_EstragonContent")
	if _content==null:
		_content = Node2D.new()
		_content.name = "_EstragonContent"
		_clip.add_child(_content,false,Node.INTERNAL_MODE_BACK)
	Hosts.add(_content,host.layout)
	_input_guard.start(_content)
	if not _content.child_entered_tree.is_connected(host.layout._child_entered): _content.child_entered_tree.connect(host.layout._child_entered)
	if not _content.child_exiting_tree.is_connected(host.layout._child_exiting): _content.child_exiting_tree.connect(host.layout._child_exiting)
	_content.child_entered_tree.connect(_children_changed)
	_content.child_exiting_tree.connect(_children_changed)
	_horizontal = HScrollBar.new()
	_vertical = VScrollBar.new()
	host.add_child(_horizontal,false,Node.INTERNAL_MODE_BACK)
	# BACK appends internal children after the clip/content branch. FRONT is
	# the beginning of SceneTree order and would let native Controls win GUI
	# picking over this scrollbar, regardless of how the bar appears to paint.
	host.add_child(_vertical,false,Node.INTERNAL_MODE_BACK)
	_horizontal.step = 0
	_vertical.step = 0
	_horizontal.custom_step = 40
	_vertical.custom_step = 40
	_horizontal.value_changed.connect(_horizontal_changed)
	_vertical.value_changed.connect(_vertical_changed)
func is_private(child: Node) -> bool:
	return child==_clip or child==_horizontal or child==_vertical
func _children_changed(_child: Node) -> void:
	if host!=null: host._layout_children_changed.emit()
func _remember_owners(node: Node, values: Dictionary) -> void:
	if node.owner!=null: values[node] = node.owner
	for child in node.get_children(): _remember_owners(child,values)
func _adopt_content(child: Node) -> void:
	if child.get_parent()!=host or is_private(child): return
	var owners := {}
	_remember_owners(child,owners)
	var scene_owner := child.owner
	var focus: Control = host.get_viewport().gui_get_focus_owner() if host.is_inside_tree() else null
	host.remove_child(child)
	_content.add_child(child)
	if scene_owner!=null:
		# Native scene persistence includes the necessary private ancestry only
		# for an authored persistent root. Generated owner-null views serialize
		# neither helpers nor content; descriptions remount after reload.
		_clip.owner = scene_owner
		_content.owner = scene_owner
	for node in owners:
		if owners[node].is_ancestor_of(node): node.owner = owners[node]
	if is_instance_valid(focus) and focus.is_inside_tree(): focus.grab_focus()
	host.layout._sync()
func start() -> void:
	if not clipping() and not is_instance_valid(_clip) and host.get_node_or_null("_EstragonViewport")==null: return
	_ensure_viewport()
	for child in host.get_children():
		if not is_private(child): _adopt_content(child)
	if not host.child_entered_tree.is_connected(_external_child): host.child_entered_tree.connect(_external_child)
	_clip.clip_contents = clipping()
	if clipping(): _input_guard.start(_content)
	else: _input_guard.stop()
	# Re-entry/scene reload must retain offsets until children and the existing
	# coordinator are active again. Their arranged signal refreshes the viewport.
	if host.layout.active: _refresh_viewport()
func children() -> Array:
	var values: Array = _content.get_children() if is_instance_valid(_content) else []
	for child in host.get_children():
		if not is_private(child): values.append(child)
	return values
func child_parent() -> Node:
	return _content
func enabled() -> bool:
	return host.horizontal_scroll or host.vertical_scroll
func clipping() -> bool:
	return host.clip_content or enabled()
func _external_child(child: Node) -> void:
	if not is_private(child) and not host._composition_is_private(child): _adopt_later.call_deferred(weakref(child))
func _adopt_later(reference: WeakRef) -> void:
	var child = reference.get_ref()
	if child!=null and host!=null and host.is_inside_tree(): _adopt_content(child)
func stop() -> void:
	_input_guard.stop()
	if host.child_entered_tree.is_connected(_external_child): host.child_entered_tree.disconnect(_external_child)
	if is_instance_valid(_content): Hosts.remove(_content,host.layout)
func refresh() -> void:
	_refresh_viewport()
func offset_changed() -> void:
	if not host.layout.model.is_layout_dirty(): _update_scroll()
func _refresh_viewport() -> void:
	if not is_instance_valid(_clip): return
	var rect: Rect2 = host.get_content_rect()
	_clip.position = rect.position
	_clip.size = rect.size
	host._content_extent = host.layout.model.content_extent()
	host._scroll_range = Vector2(maxf(0,host.content_extent.x-rect.size.x) if host.horizontal_scroll else 0,maxf(0,host.content_extent.y-rect.size.y) if host.vertical_scroll else 0)
	_update_scroll()
func _update_scroll() -> void:
	if _updating or not is_instance_valid(_content): return
	_updating = true
	host.scroll_offset = Vector2(clampf(host.scroll_offset.x,0,host.scroll_range.x),clampf(host.scroll_offset.y,0,host.scroll_range.y))
	if _content.position!=-host.get_content_rect().position-host.scroll_offset:
		_input_guard.cancel()
		var entry = host.get_layout_root()
		if entry!=null and entry.has_method("_get_pointer_router"): entry._get_pointer_router().cancel()
	_content.position = -host.get_content_rect().position-host.scroll_offset
	var rect: Rect2 = host.get_content_rect()
	_horizontal.visible = host.scroll_range.x>0
	_vertical.visible = host.scroll_range.y>0
	_horizontal.position = rect.position+Vector2(0,maxf(0,rect.size.y-12))
	_horizontal.size = Vector2(maxf(0,rect.size.x-(12 if _vertical.visible else 0)),12)
	_vertical.position = rect.position+Vector2(maxf(0,rect.size.x-12),0)
	_vertical.size = Vector2(12,maxf(0,rect.size.y-(12 if _horizontal.visible else 0)))
	_horizontal.max_value = host.content_extent.x
	_horizontal.page = rect.size.x
	_horizontal.value = host.scroll_offset.x
	_vertical.max_value = host.content_extent.y
	_vertical.page = rect.size.y
	_vertical.value = host.scroll_offset.y
	_updating = false
	Focus.refresh()
func _horizontal_changed(value: float) -> void:
	if not _updating: host.scroll_offset = Vector2(value,host.scroll_offset.y)
func _vertical_changed(value: float) -> void:
	if not _updating: host.scroll_offset = Vector2(host.scroll_offset.x,value)
func pointer_allowed(position: Vector2) -> bool:
	if not enabled(): return true
	for bar in [_horizontal,_vertical]:
		if is_instance_valid(bar) and bar.is_visible_in_tree():
			var point: Vector2 = bar.get_global_transform_with_canvas().affine_inverse()*position
			if Rect2(Vector2.ZERO,bar.size).has_point(point): return false
	return true
func input(event: InputEvent) -> void:
	if not enabled() or Engine.is_editor_hint() or not host.is_visible_in_tree() or not (event is InputEventMouse or event is InputEventPanGesture): return
	var point: Vector2 = host.get_global_transform_with_canvas().affine_inverse()*event.position
	if not host.get_content_rect().has_point(point) or not Pointer.inside_clips(host,event.position): return
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
	var next := Vector2(clampf(host.scroll_offset.x+delta.x,0,host.scroll_range.x),clampf(host.scroll_offset.y+delta.y,0,host.scroll_range.y))
	if next==host.scroll_offset: return # An exhausted nested viewport bubbles naturally.
	host.scroll_offset = next
	var entry = host.get_layout_root()
	if entry!=null and entry.has_method("_get_pointer_router"): entry._get_pointer_router().cancel()
	host.get_viewport().set_input_as_handled()
