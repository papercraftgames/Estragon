extends SceneTree
const Demo = preload("res://examples/node_runtime/demo.gd")
const Native2D = preload("res://addons/estragon/runtime/node/native_2d.gd")
const Native3D = preload("res://addons/estragon/runtime/node/native_3d.gd")
var failures: int = 0
var assertions: int = 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("C1 ASSERTION FAILED: " + message)

func settle() -> void:
	for index in range(6): await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"), "native-only environment")
	for dimension in [2,3]:
		await exercise_components(dimension)
		var entry = Demo.make_entry(dimension)
		root.add_child(entry)
		await settle()
		var adapter = entry.get_node("NativeA")
		var sibling = entry.get_node("NativeB")
		var visual = adapter.get_node("Visual")
		var identity: int = visual.get_instance_id()
		var native_transform = visual.transform
		check(adapter.bounds.status == OK, "appropriate native provider %d" % dimension)
		check(adapter.layout.model.measured == adapter.bounds.extent, "native bounds supply natural extent")
		check((adapter.position + (Vector2(adapter.bounds.origin.x,adapter.bounds.origin.y) if dimension == 2 else adapter.bounds.origin)).is_equal_approx(Vector2.ZERO if dimension == 2 else Vector3.ZERO), "negative/local origins normalized in parent axes")
		check(is_equal_approx(sibling.layout.model.offset.x, adapter.bounds.extent.x + entry.gap), "next allocation follows transformed bounds")
		check(visual.transform == native_transform, "layout never rewrites native child transform")
		var before := counters(entry, adapter)
		await settle()
		check(counters(entry, adapter) == before, "zero idle snapshot/measure/arrange/reflow/notifications")
		var sibling_before: int = sibling.layout.model.measure_count
		var snapshots: int = adapter.bounds.snapshots
		var flushes: int = entry.layout.flush_count
		for index in range(3):
			visual.scale *= 1.1
			adapter.invalidate_native()
		await settle()
		check(adapter.bounds.snapshots == snapshots + 1 and entry.layout.flush_count == flushes + 1, "explicit geometry batch snapshots/reflows once")
		check(sibling.layout.model.measure_count == sibling_before, "unaffected branch cached")
		check(visual.get_instance_id() == identity, "identity retained across geometry reflow")
		# Known transformed bounds, including adapter basis and native offset.
		adapter.observe_native = false
		adapter.rotation = PI / 2 if dimension == 2 else Vector3(0,0,PI / 2)
		visual.rotation = 0.0 if dimension == 2 else Vector3.ZERO
		visual.scale = Vector2.ONE if dimension == 2 else Vector3.ONE
		if dimension == 2:
			visual.polygon = PackedVector2Array([Vector2(-2,-1),Vector2(2,-1),Vector2(2,1),Vector2(-2,1)])
			visual.position = Vector2(3,4)
		else:
			visual.mesh.size = Vector3(4,2,6)
			visual.position = Vector3(3,4,5)
		adapter.invalidate_native()
		await settle()
		check(adapter.bounds.extent.is_equal_approx(Vector3(2,4,0) if dimension == 2 else Vector3(2,4,6)), "rotated AABB numerical extent")
		check(adapter.bounds.origin.is_equal_approx(Vector3(-5,1,0) if dimension == 2 else Vector3(-5,1,2)), "rotated AABB numerical origin")
		var origin_before: Vector3 = adapter.bounds.origin
		var extent_before: Vector3 = adapter.bounds.extent
		visual.position += Vector2(1,0) if dimension == 2 else Vector3(1,0,0)
		adapter.invalidate_native()
		await settle()
		check(adapter.bounds.extent.is_equal_approx(extent_before) and not adapter.bounds.origin.is_equal_approx(origin_before), "origin-only update keeps extent and refreshes placement")
		check((adapter.position + (Vector2(adapter.bounds.origin.x,adapter.bounds.origin.y) if dimension == 2 else adapter.bounds.origin)).is_equal_approx(Vector2.ZERO if dimension == 2 else Vector3.ZERO), "origin-only movement normalized even without size change")
		var cached: Vector3 = adapter.bounds.extent
		visual.scale *= 2
		await settle()
		check(adapter.bounds.extent == cached, "snapshot policy ignores unrequested native animation")
		adapter.invalidate_native()
		await settle()
		check(adapter.bounds.extent.is_equal_approx(cached * 2), "explicit transform snapshot updates")
		adapter.width = 7
		adapter.height = 9
		if dimension == 3: adapter.depth = 11
		await settle()
		check(adapter.layout.model.measured == Vector3(7,9,0 if dimension == 2 else 11), "explicit allocation overrides native extent without stretching")
		check(visual.scale == (Vector2(2,2) if dimension == 2 else Vector3(2,2,2)), "allocation does not resize native geometry")
		adapter.width = -2
		check(adapter.width == 7, "invalid allocation rejected retaining value")
		adapter.observe_native = true
		adapter.invalidate_native()
		await settle()
		var source: Object = visual if dimension == 2 else visual.mesh
		var signal_name: StringName = &"item_rect_changed" if dimension == 2 else &"changed"
		check(source.is_connected(signal_name, adapter.bounds._native_changed), "native signal subscription")
		before = counters(entry, adapter)
		for index in range(3):
			if dimension == 2:
				visual.offset.x += 1
				visual.item_rect_changed.emit()
			else: visual.mesh.size.x += 1
		await settle()
		check(adapter.bounds.snapshots == before[3] + 1 and adapter.bounds.notifications > before[4], "native resource signals coalesce without feedback")
		print("C1_COUNTERS ", dimension, " before=", before, " after=", counters(entry,adapter))
		before = counters(entry,adapter)
		await settle()
		check(counters(entry,adapter) == before, "signal reflow settles completely")
		# Remove/re-add visual: disconnect old source and reject missing provider.
		adapter.remove_child(visual)
		await settle()
		check(adapter.bounds.status == ERR_INVALID_PARAMETER and not source.is_connected(signal_name, adapter.bounds._native_changed), "native removal unsubscribes")
		adapter.add_child(visual)
		await settle()
		check(adapter.bounds.status == OK and visual.get_instance_id() == identity, "native re-add retains identity and resubscribes")
		var old_bounds = adapter.bounds
		var destination = Demo.make_entry(dimension)
		destination.name = "Destination"
		root.add_child(destination)
		entry.remove_child(adapter)
		check(not source.is_connected(signal_name,old_bounds._native_changed), "exit unsubscribes synchronously")
		destination.add_child(adapter)
		await settle()
		check(adapter.layout.parent_coordinator() == destination.layout and visual.get_instance_id() == identity, "native reparent transfers layout and identity")
		adapter.free()
		await settle()
		check(not is_instance_valid(visual) and not source.is_connected(signal_name,old_bounds._native_changed) if dimension == 3 else not is_instance_valid(visual), "free cleans visual and subscriptions")
		old_bounds = null
		destination.free()
		entry.free()
		# Generic native Nodes are never magically measurable; multiple children rejected.
		var invalid = Native2D.new() if dimension == 2 else Native3D.new()
		var generic: Node = Node2D.new() if dimension == 2 else Node3D.new()
		invalid.add_child(generic)
		root.add_child(invalid)
		await settle()
		check(invalid.bounds.status == ERR_INVALID_PARAMETER and invalid.bounds.extent == Vector3.ZERO, "unsupported generic native bounds rejected")
		invalid.add_child(Node.new())
		await settle()
		check(invalid.bounds.status == ERR_INVALID_PARAMETER, "multiple children rejected")
		invalid.free()
		var malformed = Demo.make_entry(dimension)
		var broken = malformed.get_node("NativeA")
		var broken_visual = broken.get_node("Visual")
		if dimension == 2: broken_visual.polygon = PackedVector2Array([Vector2(NAN,0)])
		else: broken_visual.mesh = null
		root.add_child(malformed)
		await settle()
		check(broken.bounds.status == ERR_INVALID_PARAMETER and broken.bounds.extent == Vector3.ZERO, "non-finite geometry / absent mesh rejected")
		malformed.free()
	# Native PackedScene ownership plus actual editor reopen in subsequent runner stages.
	for dimension in [2,3]:
		var scene: Node = load("res://examples/node_runtime/TwoD.tscn" if dimension == 2 else "res://examples/node_runtime/ThreeD.tscn").instantiate()
		root.add_child(scene)
		await settle()
		var unowned := Node.new()
		unowned.name = "UnownedRuntimeChild"
		scene.add_child(unowned)
		var packed := PackedScene.new()
		check(packed.pack(scene) == OK, "native owner-aware pack")
		check(ResourceSaver.save(packed,"res://tests/node_runtime/Persisted%d.tscn" % dimension) == OK, "native save")
		scene.free()
		var restored: Node = load("res://tests/node_runtime/Persisted%d.tscn" % dimension).instantiate()
		root.add_child(restored)
		await settle()
		check(restored.get_node("Entry/NativeA/Visual").owner == restored, "native scene ownership restored")
		check(restored.get_node_or_null("UnownedRuntimeChild") == null, "native pack excludes unowned runtime nodes")
		check(restored.get_node("Entry/NativeA").get_child_count() == 1, "reload never duplicates visual")
		var restored_entry = restored.get_node("Entry")
		var restored_reentry = restored_entry.get_node("Boundary/Reentry")
		var restored_participant = restored_reentry.get_node("Participant")
		check(restored_entry.get_node("NativeA").get_layout_root() == restored_entry and restored_participant.get_layout_root() == restored_reentry, "serialized scene re-establishes live runtime membership")
		check(restored_participant.layout_size == (Vector2(70,40) if dimension == 2 else Vector3(1,0.7,0.7)), "serialized participant recomputes allocation")
		check(not FileAccess.get_file_as_string("res://tests/node_runtime/Persisted%d.tscn" % dimension).contains("Object(WeakRef"), "runtime scope references never serialize as metadata")
		restored.free()
	print("GGX_C1_RUNTIME_OK" if failures == 0 else "GGX_C1_RUNTIME_FAILED")
	print("C1 assertions=",assertions," failures=",failures)
	quit(0 if failures == 0 else 1)

func counters(entry: Node, adapter: Node) -> Array:
	return [entry.layout.flush_count,adapter.layout.model.measure_count,adapter.layout.model.arrange_count,adapter.bounds.snapshots,adapter.bounds.notifications]

var component_events: int = 0
func on_component_layout(_size) -> void:
	component_events += 1

func exercise_components(dimension: int) -> void:
	var entry_script = load("res://addons/estragon/runtime/node/estragon_%dd.gd" % dimension)
	var component_script = load("res://addons/estragon/runtime/node/component_%dd.gd" % dimension)
	var entry = entry_script.new()
	var a = component_script.new()
	var b = component_script.new()
	a.name = "A"
	b.name = "B"
	a.set_extent(Vector2(10,5) if dimension == 2 else Vector3(10,5,3))
	b.set_extent(Vector2(20,7) if dimension == 2 else Vector3(20,7,4))
	entry.gap = 2
	entry.position = Vector2(50,60) if dimension == 2 else Vector3(5,6,7)
	entry.add_child(a)
	entry.add_child(b)
	check(a.owner == null and b.owner == null, "native add never assigns scene owner")
	a.layout_applied.connect(on_component_layout)
	var identity: int = a.get_instance_id()
	root.add_child(entry)
	await settle()
	check(entry.get_layout_root() == entry and a.get_layout_root() == entry, "explicit active runtime scope")
	check(entry.layout.model.measured == Vector3(32,7,0 if dimension == 2 else 4), "shared row numerical measurement")
	check(b.position == (Vector2(12,0) if dimension == 2 else Vector3(12,0,0)), "row numerical position")
	check(b.global_position.is_equal_approx(entry.to_global(b.position)), "native spatial transform inheritance")
	var idle := [entry.get_layout_stats(),a.get_layout_stats(),b.get_layout_stats()]
	await settle()
	check([entry.get_layout_stats(),a.get_layout_stats(),b.get_layout_stats()] == idle, "public stats prove zero idle work")
	var previous = a.requested_extent()
	check(a.set_extent(Vector2(99,NAN) if dimension == 2 else Vector3(99,8,NAN)) == ERR_INVALID_PARAMETER and a.requested_extent() == previous, "invalid extent rejected atomically")
	a.width = -2
	a.height = INF
	entry.gap = NAN
	entry.viewport_width_scale = -1
	await settle()
	check(a.requested_extent() == previous and entry.gap == 2 and entry.viewport_width_scale == 0, "bad individual setters retain prior state")
	check([entry.get_layout_stats(),a.get_layout_stats(),b.get_layout_stats()] == idle, "rejected writes cause no layout work")
	a.width = a.width
	await settle()
	check(a.get_layout_stats() == idle[1], "equal writes do not invalidate")
	var flushes: int = entry.layout.flush_count
	var sibling_measures: int = b.layout.model.measure_count
	for value in [14,15,16]: a.width = value
	await settle()
	check(entry.layout.flush_count == flushes + 1 and b.layout.model.measure_count == sibling_measures, "property batch coalesces and sibling measure stays cached")
	check(a.get_instance_id() == identity and a.layout_applied.is_connected(on_component_layout), "retained identity and authored signal")
	check(component_events > 0, "layout result signal executes")
	# Restore layout-owned position without modifying native basis.
	a.rotation = 0.3 if dimension == 2 else Vector3(0.1,0.2,0.3)
	a.scale = Vector2(2,3) if dimension == 2 else Vector3(2,3,4)
	var rotation = a.rotation
	var scale = a.scale
	a.position = Vector2(999,999) if dimension == 2 else Vector3(999,999,999)
	a.invalidate_layout()
	await settle()
	check(a.position.is_equal_approx(Vector2.ZERO if dimension == 2 else Vector3.ZERO), "explicit invalidation restores parent translation authority")
	check(a.rotation == rotation and a.scale == scale, "layout preserves native rotation and scale")
	entry.move_child(b,0)
	await settle()
	check(b.position.is_equal_approx(Vector2.ZERO if dimension == 2 else Vector3.ZERO) and is_equal_approx(a.position.x,22), "native reorder updates layout order")
	# Ordinary Node and spatial boundaries never tunnel participation.
	for spatial in [false,true]:
		var boundary: Node = (Node2D.new() if dimension == 2 else Node3D.new()) if spatial else Node.new()
		boundary.name = "SpatialBoundary" if spatial else "PlainBoundary"
		var stray = component_script.new()
		stray.set_extent(Vector2(1000,1000) if dimension == 2 else Vector3(1000,1000,1000))
		stray.position = Vector2(8,9) if dimension == 2 else Vector3(8,9,10)
		boundary.add_child(stray)
		entry.add_child(boundary)
		var reentry = entry_script.new()
		reentry.position = Vector2(11,12) if dimension == 2 else Vector3(11,12,13)
		var rechild = component_script.new()
		rechild.set_extent(Vector2(3,4) if dimension == 2 else Vector3(3,4,5))
		reentry.add_child(rechild)
		boundary.add_child(reentry)
		await settle()
		check(stray.get_layout_root() == null and not stray.get_layout_stats().active and stray.get_layout_stats().measure == 0, "component below ordinary Node has no implicit entry")
		check(rechild.get_layout_root() == reentry and reentry.layout.parent_coordinator() == null, "explicit entry re-enters boundary independently")
		if not spatial: check(rechild.global_position.is_equal_approx(reentry.position), "plain Node breaks native spatial inheritance")
		var outer_before = entry.get_layout_stats()
		stray.width = 1001
		rechild.width = 9
		await settle()
		check(entry.get_layout_stats() == outer_before, "boundary invalidation does not reach outer root")
		boundary.free()
	var independent = entry_script.new()
	independent.width = 500
	entry.add_child(independent)
	var opposite = load("res://addons/estragon/runtime/node/component_%dd.gd" % (3 if dimension == 2 else 2)).new()
	entry.add_child(opposite)
	await settle()
	check(independent.get_layout_root() == independent and not entry.layout.model.children.has(independent.layout.model), "direct nested entry is independent scope")
	check(opposite.get_layout_root() == null, "opposite dimension does not implicitly participate")
	# Move an existing participant through a boundary and back, without disposal.
	a.owner = entry
	entry.remove_child(a)
	check(a.owner == null and not a.layout.active and not a.child_entered_tree.is_connected(a.layout._child_entered) and not a.child_exiting_tree.is_connected(a.layout._child_exiting), "remove clears invalid native owner and scoped subscriptions")
	check(a.layout_applied.is_connected(on_component_layout), "native authored connections survive removal")
	var detached_before = a.get_layout_stats()
	a.width = 18
	await settle()
	check(a.get_layout_stats() == detached_before, "detached changes do not run layout")
	independent.add_child(a)
	await settle()
	check(a.get_instance_id() == identity and a.get_layout_root() == independent, "reparent transfers layout without replacing Node")
	check(a.owner == null, "reparent never implicitly restores scene ownership")
	var weak: WeakRef = weakref(a)
	a.queue_free()
	await settle()
	check(weak.get_ref() == null and independent.layout.model.children.is_empty(), "queue_free releases native node and model membership")
	# Entry viewport subscription belongs to tree lifetime, not saved-scene owner.
	check(root.size_changed.is_connected(entry.layout._viewport_changed), "entry observes its viewport")
	entry.viewport_width_scale = 1 if dimension == 2 else 0.01
	var old_size := root.size
	root.size = Vector2i(800,420)
	await settle()
	check(is_equal_approx(entry.layout.model.size.x,800 if dimension == 2 else 8), "explicit viewport allocation per entry")
	root.remove_child(entry)
	check(not root.size_changed.is_connected(entry.layout._viewport_changed), "entry exit disconnects viewport")
	root.add_child(entry)
	await settle()
	check(entry.get_layout_root() == entry and b.get_layout_root() == entry, "entry re-add restores retained participants")
	entry.free()
	var pending = entry_script.new()
	root.add_child(pending)
	pending.width = 123
	var pending_bridge = pending.layout
	pending.queue_free()
	await settle()
	check(not pending_bridge.active and pending_bridge.flush_count == 0 and pending_bridge.root_host() == null, "pending deferred flush is harmless after native queue_free")
	pending_bridge = null
	root.size = old_size
	await settle()
