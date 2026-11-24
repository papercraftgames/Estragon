@tool
extends RefCounted
## Lazy native viewport decoration. One owner coordinator; no child layout policy.
const Hosts = preload("composition_hosts.tres")
const Pointer = preload("pointer_2d.gd")
const Focus = preload("focus.tres")
const ScrollbarSkin = preload("scrollbar_style.gd")
const Geometry = preload("scrollbar_geometry.gd")
var owner_ref: WeakRef
var host:
	get: return owner_ref.get_ref()
var _clip: Control
var _content: Node2D
var _horizontal: HScrollBar
var _vertical: VScrollBar
var _corner: ColorRect
var _geometry: Dictionary = {}
var _skin_context: Array = []
var style_updates := 0
var _fit_pending := false
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
	_corner = ColorRect.new()
	_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(_corner,false,Node.INTERNAL_MODE_BACK)
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
	# Arrowless native bars: the thumb/track still own all native interaction.
	var blank := ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8))
	for bar in [_horizontal,_vertical]:
		bar.clip_contents = true # Explicit StyleBox expansion cannot paint over V.
		bar.minimum_size_changed.connect(_minimum_changed)
		for icon in ["increment","increment_highlight","increment_pressed","decrement","decrement_highlight","decrement_pressed"]: bar.add_theme_icon_override(icon,blank)
func is_private(child: Node) -> bool:
	return child==_clip or child==_horizontal or child==_vertical or child==_corner
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
	# Native reparent notifications can precede the new ancestor's coordinator
	# activation. Refresh keyboard/pointer scope after that tree transition.
	_refresh_scope.call_deferred(weakref(child))
func _refresh_scope(reference: WeakRef) -> void:
	var child = reference.get_ref()
	if host!=null and host.is_inside_tree() and child!=null and child.is_inside_tree() and _content.is_ancestor_of(child): Hosts._refresh_scope(child)
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
	_geometry = host.layout.model.scroll_geometry
	if _geometry.is_empty(): _geometry = Geometry.snapshot(host.get_content_rect(),Geometry.border_inner(host.layout_size,host.layout.model.border),Vector2(1 if host.horizontal_scroll else 0,1 if host.vertical_scroll else 0),host.lengths.specs,host.layout.model.viewport_size)
	var rect: Rect2 = _geometry.viewport
	_clip.position = rect.position
	_clip.size = rect.size
	host._content_extent = host.layout.model.content_extent()
	host._scroll_range = Vector2(maxf(0,host.content_extent.x-rect.size.x) if host.horizontal_scroll else 0,maxf(0,host.content_extent.y-rect.size.y) if host.vertical_scroll else 0)
	_update_scroll()
func refresh_style() -> void:
	if not is_instance_valid(_horizontal) or _geometry.is_empty(): return
	var context := [host.scrollbar_style,_geometry.vertical.size,_geometry.horizontal.size,host.layout.model.viewport_size]
	if context==_skin_context: return
	_skin_context = context.duplicate(true)
	style_updates += 1
	for axis in ["horizontal","vertical"]:
		var bar: ScrollBar = _horizontal if axis=="horizontal" else _vertical
		var rect: Rect2 = _geometry[axis]
		var style := ScrollbarSkin.values(host.scrollbar_style,axis)
		bar.add_theme_stylebox_override("scroll",ScrollbarSkin.box(style,"track","",rect.size,host.layout.model.viewport_size))
		for pair in [["grabber",""],["grabber_highlight","_hover"],["grabber_pressed","_pressed"]]:
			bar.add_theme_stylebox_override(pair[0],ScrollbarSkin.box(style,"thumb",pair[1],rect.size,host.layout.model.viewport_size))
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("#eeeeee")
		focus.set_border_width_all(1)
		bar.add_theme_stylebox_override("scroll_focus",focus)
	_corner.color = ScrollbarSkin.color(ScrollbarSkin.values(host.scrollbar_style,"vertical"),"corner_color")
	_fit_tracks()
func _minimum_changed() -> void:
	if _fit_pending: return
	_fit_pending = true
	_fit_tracks.call_deferred()
func _fit_tracks() -> void:
	_fit_pending = false
	if host==null or not is_instance_valid(_horizontal) or _geometry.is_empty(): return
	_place_bar(_horizontal,_geometry.horizontal)
	_place_bar(_vertical,_geometry.vertical)
func _place_bar(bar: ScrollBar, rect: Rect2) -> void:
	# There is no native hit surface for an empty strip. In particular, 4.0
	# coerces zero Control scales to epsilon; never feed that degenerate transform
	# into native minimum-size adjustment.
	if rect.size.x<=0 or rect.size.y<=0:
		bar.hide()
		return
	if bar.position!=rect.position: bar.position = rect.position
	# Custom StyleBox minimums must never enlarge the parent-owned strip.
	# Native Control hit testing follows this same transform, including drag.
	var floor := bar.get_combined_minimum_size()
	var logical := Vector2(maxf(rect.size.x,floor.x),maxf(rect.size.y,floor.y))
	if bar.size!=logical: bar.size = logical
	var native_size := Vector2(maxf(1,bar.size.x),maxf(1,bar.size.y))
	var physical_scale := rect.size/native_size
	if bar.scale!=physical_scale: bar.scale = physical_scale
func _update_scroll() -> void:
	if _updating or not is_instance_valid(_content): return
	_updating = true
	host.scroll_offset = Vector2(clampf(host.scroll_offset.x,0,host.scroll_range.x),clampf(host.scroll_offset.y,0,host.scroll_range.y))
	if _content.position!=-host.get_content_rect().position-host.scroll_offset:
		_input_guard.cancel()
		var entry = host.get_layout_root()
		if entry!=null and entry.has_method("_get_pointer_router"): entry._get_pointer_router().cancel()
	_content.position = -host.get_content_rect().position-host.scroll_offset
	if _geometry.is_empty():
		_updating = false
		return
	var rect: Rect2 = _geometry.viewport
	refresh_style()
	_horizontal.visible = host.scroll_range.x>0 and _geometry.horizontal.size.x>0 and _geometry.horizontal.size.y>0
	_vertical.visible = host.scroll_range.y>0 and _geometry.vertical.size.x>0 and _geometry.vertical.size.y>0
	_place_bar(_horizontal,_geometry.horizontal)
	_place_bar(_vertical,_geometry.vertical)
	_corner.position = _geometry.corner.position
	_corner.size = _geometry.corner.size
	_corner.visible = _corner.size.x>0 and _corner.size.y>0
	_horizontal.max_value = maxf(host.content_extent.x,rect.size.x)
	_horizontal.page = rect.size.x
	_horizontal.value = host.scroll_offset.x
	_vertical.max_value = maxf(host.content_extent.y,rect.size.y)
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
	var point: Vector2 = host.get_global_transform_with_canvas().affine_inverse()*position
	return _geometry.is_empty() or _geometry.viewport.has_point(point)
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
