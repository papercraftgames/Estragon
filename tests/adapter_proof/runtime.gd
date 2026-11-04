extends SceneTree
const Demo = preload("res://examples/adapter_proof/demo.gd")
const Native2D = preload("res://addons/estragon/adapter_proof/native_2d.gd")
const Native3D = preload("res://addons/estragon/adapter_proof/native_3d.gd")
var failures: int = 0
var assertions: int = 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("B3 ASSERTION FAILED: " + message)

func settle() -> void:
	for index in range(6): await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"), "native-only environment")
	for dimension in [2,3]:
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
		print("B3_COUNTERS ", dimension, " before=", before, " after=", counters(entry,adapter))
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
		var scene: Node = load("res://examples/adapter_proof/TwoD.tscn" if dimension == 2 else "res://examples/adapter_proof/ThreeD.tscn").instantiate()
		root.add_child(scene)
		await settle()
		var packed := PackedScene.new()
		check(packed.pack(scene) == OK, "native owner-aware pack")
		check(ResourceSaver.save(packed,"res://tests/adapter_proof/Persisted%d.tscn" % dimension) == OK, "native save")
		scene.free()
		var restored: Node = load("res://tests/adapter_proof/Persisted%d.tscn" % dimension).instantiate()
		root.add_child(restored)
		await settle()
		check(restored.get_node("Entry/NativeA/Visual").owner == restored, "native scene ownership restored")
		check(restored.get_node("Entry/NativeA").get_child_count() == 1, "reload never duplicates visual")
		restored.free()
	print("GGX_B3_RUNTIME_OK" if failures == 0 else "GGX_B3_RUNTIME_FAILED")
	print("B3 assertions=",assertions," failures=",failures)
	quit(0 if failures == 0 else 1)

func counters(entry: Node, adapter: Node) -> Array:
	return [entry.layout.flush_count,adapter.layout.model.measure_count,adapter.layout.model.arrange_count,adapter.bounds.snapshots,adapter.bounds.notifications]
