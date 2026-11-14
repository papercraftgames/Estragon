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

func _init(host: Node, dimension: int, mode: int = Mode.PROOF) -> void:
	_mode = mode
	_host = weakref(host)
	_dimension = dimension
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

func _viewport_scale(host: Node) -> Vector2:
	return Vector2(host.viewport_width_scale,0) if _mode == Mode.PROOF else host._layout_viewport_scale()

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
	if host.child_entered_tree.is_connected(_child_entered): host.child_entered_tree.disconnect(_child_entered)
	if host.child_exiting_tree.is_connected(_child_exiting): host.child_exiting_tree.disconnect(_child_exiting)
	if host.has_signal("child_order_changed") and host.is_connected("child_order_changed", _sync): host.disconnect("child_order_changed", _sync)
	if _viewport != null and _viewport.size_changed.is_connected(_viewport_changed): _viewport.size_changed.disconnect(_viewport_changed)
	_viewport = null
	model.set_children([])
	var parent = parent_coordinator()
	if parent != null: parent._sync()

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
	var children: Array = host.get_children() if _mode != Mode.COMPOSITION else []
	if _mode == Mode.COMPOSITION and managed_root != null and managed_root.get_ref() != null: children.append(managed_root.get_ref())
	children = CompositionHosts.children(host,children)
	for child in children:
		var found = participant(child,true)
		if found != null and found._mode != Mode.ENTRY:
			if found._mode == Mode.CONTROL and not found.control_adapter.participates(): continue
			values.append(found.model)
	var error := model.set_children(values)
	if error != OK: push_error("Estragon layout model ownership: " + error_string(error))

func changed() -> void:
	var host = _host.get_ref()
	if host == null: return
	if host.has_method("_layout_options"):
		var options: Dictionary = host._layout_options()
		model.configure(host.requested_extent(),host.gap,host.center,options.axis,options.fill,options.intrinsic,options.get("padding",Vector4.ZERO),options.get("margin",Vector4.ZERO))
	else: model.configure(host.requested_extent(), host.gap, host.center)

func _viewport_changed() -> void:
	var host = _host.get_ref()
	if host == null or parent_coordinator() != null: return
	var scale := _viewport_scale(host)
	if scale.x > 0 or scale.y > 0: _invalidated()

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
	var available: Vector3 = model.measure()
	var external_axes := Vector3.ZERO
	if _viewport != null:
		var scale := _viewport_scale(host)
		var visible := _viewport.get_visible_rect().size
		if scale.x > 0:
			available.x = visible.x * scale.x
			external_axes.x = 1
		if scale.y > 0:
			available.y = visible.y * scale.y
			external_axes.y = 1
	model.arrange(available,external_axes)
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
