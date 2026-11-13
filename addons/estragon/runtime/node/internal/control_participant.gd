@tool
extends RefCounted
## Native Control minimum/outer-rect bridge. Container internals remain opaque.
const Hosts = preload("composition_hosts.tres")
var host: WeakRef
var coordinator: WeakRef
var original: Rect2
var native_parent: WeakRef
var assigned: Rect2
var allocated := false
var active := false
var queued := false
var writing := false
var reason := ""
var minimum_reads := 0
var refreshes := 0
var native_writes := 0
var subscribed := false
var included := false

func _init(node: Control, layout: RefCounted) -> void:
	host = weakref(node)
	coordinator = weakref(layout)
	original = Rect2(node.position,node.size)
	assigned = original

func start() -> void:
	active = true
	var node = host.get_ref()
	for event in ["minimum_size_changed","theme_changed","size_flags_changed","visibility_changed"]:
		node.connect(event,changed)
	node.resized.connect(rect_changed)
	node.item_rect_changed.connect(rect_changed)
	node.tree_exiting.connect(exiting)
	subscribed = true
	refresh()

func stop() -> void:
	if not active: return
	active = false
	var node = host.get_ref()
	if node == null: return
	for event in ["minimum_size_changed","theme_changed","size_flags_changed","visibility_changed"]:
		if node.is_connected(event,changed): node.disconnect(event,changed)
	for event in ["resized","item_rect_changed"]:
		if node.is_connected(event,rect_changed): node.disconnect(event,rect_changed)
	if node.tree_exiting.is_connected(exiting): node.tree_exiting.disconnect(exiting)
	subscribed = false
	restore()

func exiting() -> void:
	var node = host.get_ref()
	var layout = coordinator.get_ref()
	var parent = layout.parent_coordinator() if layout != null else null
	if node != null:
		Hosts.block_control(node)
		Hosts.release_control(node)
	# Native child_exiting_tree can precede actual removal. Reconcile the core
	# after that removal, never reacquire an exiting Control in its callback.
	if parent != null: parent._sync.call_deferred()

func changed() -> void:
	if not active or queued: return
	queued = true
	refresh.call_deferred()

func rect_changed() -> void:
	if writing or not active: return
	var node = host.get_ref()
	if node == null: return
	if not allocated or limitation() != reason or not node.position.is_equal_approx(assigned.position) or not node.size.is_equal_approx(assigned.size): changed()

func logical_parent() -> Node:
	var node = host.get_ref()
	if node == null: return null
	var projected = Hosts.projected_parent(node)
	return projected if projected != null else node.get_parent()

func limitation() -> String:
	var node = host.get_ref()
	var parent = logical_parent()
	if node == null or not node.is_inside_tree(): return "outside the native tree"
	if node.get_parent() is Container: return "native Container owns its direct children's rectangles"
	if node.is_set_as_top_level(): return "top_level Control uses independent native coordinates"
	if node.anchor_left != 0 or node.anchor_top != 0 or node.anchor_right != 0 or node.anchor_bottom != 0: return "nonzero anchors compete with Box allocation"
	if not is_zero_approx(node.rotation) or not node.scale.is_equal_approx(Vector2.ONE) or not node.pivot_offset.is_zero_approx(): return "local rotation/scale/pivot requires explicit positioning"
	if not parent is CanvasItem: return "no compatible CanvasItem layout parent"
	if parent.get_viewport() != node.get_viewport() or parent.get_canvas() != node.get_canvas(): return "different native viewport/CanvasLayer"
	# CanvasItem's native parent-item getter is not a public Script API.
	# The local/global matrices expose the same parent basis without traversal.
	var basis: Transform2D = node.get_global_transform()*node.get_transform().affine_inverse()
	if is_zero_approx(basis.x.cross(basis.y)): return "singular native parent transform"
	var relative: Transform2D = basis.affine_inverse()*parent.get_global_transform()
	if not relative.x.is_equal_approx(Vector2.RIGHT) or not relative.y.is_equal_approx(Vector2.DOWN): return "borrowed logical/native parent bases differ"
	return ""

func participates() -> bool:
	var node = host.get_ref()
	return active and node != null and node.is_visible_in_tree() and limitation().is_empty()

func refresh() -> void:
	queued = false
	if not active: return
	var node = host.get_ref()
	var layout = coordinator.get_ref()
	if node == null or layout == null: return
	refreshes += 1
	var next := limitation()
	if next != reason and not next.is_empty(): push_warning("Estragon native Control layout skipped: "+str(node.get_path())+": "+next)
	reason = next
	var next_included := participates()
	var inclusion_changed := included != next_included
	included = next_included
	minimum_reads += 1
	var minimum: Vector2 = node.get_combined_minimum_size()
	var fills := Vector3(1 if node.size_flags_horizontal == Control.SIZE_EXPAND_FILL else 0,1 if node.size_flags_vertical == Control.SIZE_EXPAND_FILL else 0,0)
	layout.model.allocation_minimum = Vector3(minimum.x,minimum.y,0)
	layout.model.configure(Vector3(-1,-1,0),0,false,0,fills,Vector3(minimum.x,minimum.y,0))
	if inclusion_changed: layout.model.invalidate()
	if not participates(): restore()
	elif allocated and (not node.position.is_equal_approx(assigned.position) or not node.size.is_equal_approx(assigned.size)): layout.model.invalidate()
	var parent = layout.parent_coordinator()
	if parent != null: parent._sync()

func restore() -> void:
	if not allocated: return
	var node = host.get_ref()
	if node != null and native_parent != null and node.get_parent() == native_parent.get_ref():
		writing = true
		node.position = original.position
		node.size = original.size
		writing = false
	allocated = false

func place(offset: Vector3) -> void:
	if not participates(): return
	var node = host.get_ref()
	if not allocated:
		# Capture after native add/reparent/theme initialization completes, not
		# inside child_entered_tree halfway through that native transaction.
		original = Rect2(node.position,node.size)
		native_parent = weakref(node.get_parent())
	var parent: CanvasItem = logical_parent()
	var point: Vector2 = parent.get_global_transform()*Vector2(offset.x,offset.y)
	writing = true
	if not node.global_position.is_equal_approx(point):
		node.global_position = point
		native_writes += 1
	assigned.position = node.position
	writing = false
	allocated = true

func arrange(size: Vector3) -> void:
	if not participates(): return
	var layout = coordinator.get_ref()
	place(layout.model.offset)
	var node = host.get_ref()
	var wanted := Vector2(size.x,size.y)
	writing = true
	if not node.size.is_equal_approx(wanted):
		node.size = wanted
		native_writes += 1
	assigned.size = node.size
	writing = false
