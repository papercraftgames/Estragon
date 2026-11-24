@tool
extends RefCounted
const Profile = preload("../../composition/profile.tres")
## Native event/lifetime adapter shared by both spatial branches. No layout math.
const Core = preload("layout_core.gd")
const CompositionHosts = preload("composition_hosts.tres")
const META := "_estragon_b2_coordinator"
enum Mode { PROOF, PARTICIPANT, ENTRY, COMPOSITION, CONTROL }
var control_adapter
var managed_root: WeakRef
var _mode: int
var model := Core.new()
var active: bool = false
var flush_count: int = 0
var _host: WeakRef
var _dimension: int
var _queued: bool = false
var _viewport: Viewport
var _root_offset := Vector3.ZERO

func _init(host: Node, dimension: int, mode: int = Mode.PROOF) -> void:
	_mode = mode
	_host = weakref(host)
	_dimension = dimension
	model.dimension_budget_enabled = dimension==2
	if _mode == Mode.PROOF: host.set_meta(META, weakref(self))
	model.invalidated.connect(_invalidated)
	model.placed.connect(_place)
	model.arranged.connect(_arranged)

func parent_coordinator():
	var host = _host.get_ref()
	if host == null or _mode == Mode.ENTRY: return null
	var projected = CompositionHosts.projected_parent(host)
	return participant(projected if projected != null else host.get_parent())

func participant(node: Node, acquire_control := false):
	if node == null: return null
	if node is Control and CompositionHosts.control_exiting(node): return null
	var found
	if _mode == Mode.PROOF:
		if not node.has_meta(META): return null
		found = node.get_meta(META).get_ref()
	else:
		# Runtime references must never be serialized as Node metadata.
		found = node._get_layout_coordinator() if node.has_method("_get_layout_coordinator") else CompositionHosts.find(node)
		if found == null and acquire_control and _dimension == 2 and node is Control and node.is_inside_tree():
			found = get_script().new(node,2,Mode.CONTROL)
			CompositionHosts.add_control(node,found)
			found.start()
	return found if found != null and found.active and found._dimension == _dimension else null

func scope_root():
	if not active: return null
	var current = self
	while current != null:
		if current._mode == Mode.ENTRY: return current
		var parent = current.parent_coordinator()
		if current._mode == Mode.PROOF and parent == null: return current
		current = parent
	return null

func root_host() -> Node:
	var found = scope_root()
	return found._host.get_ref() if found != null else null

func start() -> void:
	active = true
	var host: Node = _host.get_ref()
	if _mode == Mode.CONTROL:
		control_adapter = preload("control_participant.gd").new(host,self)
		control_adapter.start()
		return
	# PackedScene restores metadata after construction. Refresh the proof-only
	# weak registry at entry; C1 resolves the live script field instead.
	if _mode == Mode.PROOF: host.set_meta(META, weakref(self))
	if _dimension==2 and host is CanvasItem: host.visibility_changed.connect(_visibility_changed)
	host.child_entered_tree.connect(_child_entered)
	host.child_exiting_tree.connect(_child_exiting)
	if host.has_signal("child_order_changed"): host.connect("child_order_changed", _sync)
	if _mode in [Mode.PROOF,Mode.ENTRY]:
		_viewport = host.get_viewport()
		_viewport.size_changed.connect(_viewport_changed)
	_sync()
	var parent = parent_coordinator()
	if parent != null: parent._sync()
	_invalidated()

func stop() -> void:
	active = false
	var host: Node = _host.get_ref()
	if _mode == Mode.CONTROL:
		if control_adapter != null: control_adapter.stop()
		model.set_children([])
		return
	if _dimension==2 and host is CanvasItem and host.visibility_changed.is_connected(_visibility_changed): host.visibility_changed.disconnect(_visibility_changed)
	if host.child_entered_tree.is_connected(_child_entered): host.child_entered_tree.disconnect(_child_entered)
	if host.child_exiting_tree.is_connected(_child_exiting): host.child_exiting_tree.disconnect(_child_exiting)
	if host.has_signal("child_order_changed") and host.is_connected("child_order_changed", _sync): host.disconnect("child_order_changed", _sync)
	if _viewport != null and _viewport.size_changed.is_connected(_viewport_changed): _viewport.size_changed.disconnect(_viewport_changed)
	_viewport = null
	model.set_children([])
	var parent = parent_coordinator()
	if parent != null: parent._sync()

func _visibility_changed() -> void:
	var parent = parent_coordinator()
	while parent!=null:
		parent._sync()
		if parent._mode!=Mode.COMPOSITION: break
		parent = parent.parent_coordinator()

func participates() -> bool:
	var host = _host.get_ref()
	if host==null or _dimension==2 and host is CanvasItem and not host.is_visible_in_tree(): return false
	if _mode==Mode.ENTRY: return false
	if _mode==Mode.CONTROL: return control_adapter.participates()
	if _mode==Mode.COMPOSITION:
		var root = managed_root.get_ref() if managed_root!=null else null
		var target = participant(root)
		return target!=null and target.participates()
	return true

func _child_entered(child: Node) -> void:
	if child is Control: CompositionHosts.enter_control(child)
	_sync()

func _child_exiting(child: Node) -> void:
	if child is Control: CompositionHosts.block_control(child)
	_sync()

func order_moved() -> void:
	var parent = parent_coordinator()
	if parent != null: parent._sync()

func _sync() -> void:
	if not active or _mode == Mode.CONTROL: return
	var values: Array = []
	var host: Node = _host.get_ref()
	var children: Array = (host._layout_children() if host.has_method("_layout_children") else host.get_children()) if _mode != Mode.COMPOSITION else []
	if _mode == Mode.COMPOSITION and managed_root != null and managed_root.get_ref() != null: children.append(managed_root.get_ref())
	children = CompositionHosts.children(host,children)
	for child in children:
		# Native child-entered signals can precede internal-child bookkeeping.
		# Runtime GUI endpoints/decorations never become layout participants.
		if host.has_method("_composition_is_private") and host._composition_is_private(child): continue
		if _dimension==2 and child is CanvasItem and not child.is_visible_in_tree(): continue
		var found = participant(child,true)
		if found != null and found._mode != Mode.ENTRY:
			if _dimension==2 and not found.participates(): continue
			found.model.set_placement(CompositionHosts.get_placement(child))
			values.append(found.model)
	var participation_changed := model.children != values
	var error := model.set_children(values)
	if error != OK: push_error("Estragon layout model ownership: " + error_string(error))
	if participation_changed and _mode==Mode.COMPOSITION:
		var parent = parent_coordinator()
		if parent!=null: parent._sync()

func changed() -> void:
	var host = _host.get_ref()
	if host == null: return
	if host.has_method("_layout_options"):
		var options: Dictionary = host._layout_options()
		model.set_scroll_axes(options.get("scroll_axes",Vector2.ZERO) if _dimension==2 else Vector2.ZERO)
		model.set_strategy(options.get("strategy","stack") if _dimension==2 else "stack",options.get("align_content","start"),options.get("grid",{}))
		model.set_policy(options.get("alignment",["start","start","start"]))
		model.set_align_self(host.align_self if _dimension==2 and "align_self" in host else "auto")
		if "lengths" in host:
			for property in host._get_property_list():
				if not property.name in Core.Length.VisualStyle.RADII and not Core.Length.domain(property.name).is_empty() and not host.lengths.specs.has(property.name): host.lengths.assign(property.name,host.get(property.name),Core.Length.domain(property.name,host.get_script()))
			model.set_lengths(host.lengths.specs,host.grow,host.stretch,host.pixels_per_unit if _dimension==3 else 1.0,options.axis,host._default_padding() if host.has_method("_default_padding") else Vector4.ZERO)
		model.configure(host.requested_extent(),model.gap,host.center,options.axis,options.fill,options.intrinsic,model.padding if "lengths" in host else options.get("padding",Vector4.ZERO),model.margin if "lengths" in host else options.get("margin",Vector4.ZERO))
	else: model.configure(host.requested_extent(), host.gap, host.center)
	if active: _sync()

func _viewport_changed() -> void:
	var host = _host.get_ref()
	if host == null or parent_coordinator() != null: return
	model.invalidate()

func _invalidated() -> void:
	if Profile.is_enabled(): Profile.add("layout_invalidations")
	if not active or _queued or parent_coordinator() != null or _mode in [Mode.PARTICIPANT,Mode.COMPOSITION,Mode.CONTROL]: return
	_queued = true
	call_deferred("_flush")

func _flush() -> void:
	_queued = false
	if not active or parent_coordinator() != null or _mode in [Mode.PARTICIPANT,Mode.COMPOSITION,Mode.CONTROL]: return
	var host = _host.get_ref()
	if host == null or host.is_queued_for_deletion(): return
	flush_count += 1
	if Profile.is_enabled(): Profile.add("layout_flushes")
	var visible := _viewport.get_visible_rect().size if _viewport!=null else Vector2.ZERO
	# An independent 2D Entry has a native containing rectangle even without
	# an Estragon parent. Use the visible logical viewport for every eligible
	# root percentage, including insets/gap/offsets; child preparation remains
	# exclusively the core's immediate-content responsibility. No 3D Z inference.
	var reference := Vector3(visible.x,visible.y,-1) if _mode==Mode.ENTRY and _dimension==2 else Vector3(-1,-1,-1)
	model.prepare(reference,visible)
	var available: Vector3 = model.measure()
	model.arrange(available)
	if host is Node2D:
		host.position += Vector2(model.length_offset.x-_root_offset.x,model.length_offset.y-_root_offset.y)
	elif host is Node3D: host.position += model.length_offset-_root_offset
	_root_offset = model.length_offset
	CompositionHosts.refresh_positions(self)

func _place(offset: Vector3) -> void:
	if _mode == Mode.CONTROL:
		control_adapter.place(offset)
		return
	var host = _host.get_ref()
	if host == null: return
	if host.has_method("apply_layout_position"): host.apply_layout_position(offset)
	elif _dimension == 2: host.position = Vector2(offset.x, offset.y)
	else: host.position = offset
	var projected = CompositionHosts.projected_parent(host)
	if projected != null:
		# Apply the participant/adapter's own origin policy first, then convert
		# its logical position using Godot transforms (including top_level).
		if host is Node2D and projected is Node2D: host.global_position = projected.to_global(host.position)
		elif host is Node3D and projected is Node3D: host.global_position = projected.to_global(host.position)

func _arranged(size: Vector3) -> void:
	if _mode == Mode.CONTROL:
		control_adapter.arrange(size)
		return
	var host = _host.get_ref()
	if host != null and _mode != Mode.COMPOSITION: host.apply_layout_size(size)
