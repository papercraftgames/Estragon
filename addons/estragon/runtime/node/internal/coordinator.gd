@tool
extends RefCounted
const Profile = preload("../../composition/profile.tres")
## Native event/lifetime adapter shared by both spatial branches. No layout math.
const Core = preload("layout_core.gd")
const META := "_estragon_b2_coordinator"
enum Mode { PROOF, PARTICIPANT, ENTRY }
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
	return participant(host.get_parent())

func participant(node: Node):
	if node == null: return null
	var found
	if _mode == Mode.PROOF:
		if not node.has_meta(META): return null
		found = node.get_meta(META).get_ref()
	else:
		# Runtime references must never be serialized as Node metadata.
		if not node.has_method("_get_layout_coordinator"): return null
		found = node._get_layout_coordinator()
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

func _viewport_scale(host: Node) -> float:
	return host.viewport_width_scale if _mode == Mode.PROOF else host._layout_viewport_scale()

func start() -> void:
	active = true
	var host: Node = _host.get_ref()
	# PackedScene restores metadata after construction. Refresh the proof-only
	# weak registry at entry; C1 resolves the live script field instead.
	if _mode == Mode.PROOF: host.set_meta(META, weakref(self))
	host.child_entered_tree.connect(_child_changed)
	host.child_exiting_tree.connect(_child_changed)
	if host.has_signal("child_order_changed"): host.connect("child_order_changed", _sync)
	if _mode != Mode.PARTICIPANT:
		_viewport = host.get_viewport()
		_viewport.size_changed.connect(_viewport_changed)
	_sync()
	var parent = parent_coordinator()
	if parent != null: parent._sync()
	_invalidated()

func stop() -> void:
	active = false
	var host: Node = _host.get_ref()
	if host.child_entered_tree.is_connected(_child_changed): host.child_entered_tree.disconnect(_child_changed)
	if host.child_exiting_tree.is_connected(_child_changed): host.child_exiting_tree.disconnect(_child_changed)
	if host.has_signal("child_order_changed") and host.is_connected("child_order_changed", _sync): host.disconnect("child_order_changed", _sync)
	if _viewport != null and _viewport.size_changed.is_connected(_viewport_changed): _viewport.size_changed.disconnect(_viewport_changed)
	_viewport = null
	model.set_children([])
	var parent = parent_coordinator()
	if parent != null: parent._sync()

func _child_changed(_child: Node) -> void:
	_sync()

func order_moved() -> void:
	var parent = parent_coordinator()
	if parent != null: parent._sync()

func _sync() -> void:
	if not active: return
	var values: Array = []
	var host: Node = _host.get_ref()
	for child in host.get_children():
		var found = participant(child)
		if found != null and found._mode != Mode.ENTRY: values.append(found.model)
	var error := model.set_children(values)
	if error != OK: push_error("Estragon layout model ownership: " + error_string(error))

func changed() -> void:
	var host = _host.get_ref()
	if host == null: return
	if host.has_method("_layout_options"):
		var options: Dictionary = host._layout_options()
		model.configure(host.requested_extent(),host.gap,host.center,options.axis,options.fill,options.intrinsic)
	else: model.configure(host.requested_extent(), host.gap, host.center)

func _viewport_changed() -> void:
	var host = _host.get_ref()
	if host != null and parent_coordinator() == null and _viewport_scale(host) > 0: _invalidated()

func _invalidated() -> void:
	if Profile.is_enabled(): Profile.add("layout_invalidations")
	if not active or _queued or parent_coordinator() != null or _mode == Mode.PARTICIPANT: return
	_queued = true
	call_deferred("_flush")

func _flush() -> void:
	_queued = false
	if not active or parent_coordinator() != null or _mode == Mode.PARTICIPANT: return
	var host = _host.get_ref()
	if host == null or host.is_queued_for_deletion(): return
	flush_count += 1
	if Profile.is_enabled(): Profile.add("layout_flushes")
	var available: Vector3 = model.measure()
	if _viewport_scale(host) > 0 and _viewport != null:
		available.x = _viewport.get_visible_rect().size.x * _viewport_scale(host)
	model.arrange(available)

func _place(offset: Vector3) -> void:
	var host = _host.get_ref()
	if host == null: return
	if host.has_method("apply_layout_position"): host.apply_layout_position(offset)
	elif _dimension == 2: host.position = Vector2(offset.x, offset.y)
	else: host.position = offset

func _arranged(size: Vector3) -> void:
	var host = _host.get_ref()
	if host != null: host.apply_layout_size(size)
