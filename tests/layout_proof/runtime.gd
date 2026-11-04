extends SceneTree
const Build = preload("res://examples/layout_proof/build.gd")
const Entry2D = preload("res://addons/estragon/layout_proof/entry_2d.gd")
const Entry3D = preload("res://addons/estragon/layout_proof/entry_3d.gd")
var failures: int = 0
var assertions: int = 0
var events: int = 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("B2 ASSERTION FAILED: " + message)

func settle() -> void:
	for index in range(4): await process_frame

func on_layout() -> void:
	events += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"), "no external compiler tools")
	root.size = Vector2i(640,360)
	var result := Build.build()
	check(result.ok, "B1 native compiler builds B2 GGX")
	if not result.ok:
		printerr(result)
		quit(1)
		return
	var repeated := Build.Proof.compile(FileAccess.get_file_as_string(Build.INPUT), Build.INPUT, Build.TYPES)
	check(result.compilation.code == repeated.code and result.compilation.source_map.serialize() == repeated.source_map.serialize(), "native code/maps deterministic")
	var factory: Node = result.script.new()
	for dimension in [2,3]:
		var entry = factory.make_2d() if dimension == 2 else factory.make_3d()
		root.add_child(entry)
		await settle()
		var left = entry.get_node("Left")
		var branch = entry.get_node("Branch")
		var inner = branch.get_node("InnerA")
		var boundary = entry.get_node("NativeBoundary")
		var reentry = boundary.get_node("Reentry")
		var independent = reentry.get_node("Independent")
		var expected_width: float = 640 if dimension == 2 else 8.0
		check(is_equal_approx(entry.layout.model.size.x, expected_width), "root viewport input %d" % dimension)
		check(entry.layout.model.children.size() == 2 and branch.layout.model.children.size() == 2, "only immediate same-dimensional participation")
		check(reentry.layout.parent_coordinator() == null and independent.layout.parent_coordinator() == reentry.layout, "explicit reentry independent root")
		check(entry.layout.model.measured.x < expected_width, "viewport allocation independent of natural width")
		var original_boundary = boundary.position
		var original_entry = entry.position
		var before := snapshot(entry)
		var reentry_before := snapshot(reentry)
		await settle()
		check(snapshot(entry) == before and snapshot(reentry) == reentry_before, "zero idle measure/arrange/flush work")
		print("B2_IDLE_COUNTERS ", dimension, " before=", before, " after=", snapshot(entry))
		print("B2_DPI_SIGNAL_AVAILABLE ", root.has_signal("dpi_changed"))
		if root.has_signal("dpi_changed"):
			root.emit_signal("dpi_changed")
			await settle()
			check(snapshot(entry) == before, "DPI signal alone is not assumed to resize viewport")
		var original_width: float = left.width
		left.width = -2
		left.gap = -1
		await settle()
		check(left.width == original_width and left.gap == 0 and snapshot(entry) == before, "invalid inputs retain valid state without scheduling")
		if dimension == 2:
			check(left.position == Vector2(205,0) and branch.position == Vector2(325,0), "exact 2D local arrangement")
			check(independent.global_position == Vector2(30,230), "native spatial boundary preserves Godot transform chain")
		else:
			check(left.position.is_equal_approx(Vector3(2.15,0,0)) and branch.position.is_equal_approx(Vector3(4.05,0,0)), "exact 3D local arrangement")
			check(independent.global_position.is_equal_approx(Vector3(-3.4,-2,0)), "native 3D boundary preserves Godot transform chain")
		# A plain Node interrupts native spatial transforms too, independently
		# from its role as an Estragon layout boundary.
		var plain := Node.new()
		entry.add_child(plain)
		var plain_entry = Entry2D.new() if dimension == 2 else Entry3D.new()
		plain_entry.width = 4
		plain_entry.height = 3
		if dimension == 3: plain_entry.depth = 2
		plain_entry.position = Vector2(7,9) if dimension == 2 else Vector3(7,9,11)
		plain.add_child(plain_entry)
		await settle()
		check(plain_entry.layout.parent_coordinator() == null, "plain Node permits explicit independent reentry")
		check(plain_entry.global_position == plain_entry.position, "plain Node interrupts native spatial ancestry")
		check(plain_entry.owner == null and plain.owner == null, "layout does not acquire unrelated scene ownership")
		var ids := [entry.get_instance_id(),left.get_instance_id(),branch.get_instance_id(),inner.get_instance_id()]
		left.layout_applied.connect(on_layout)
		var branch_measures: int = branch.layout.model.measure_count
		var inner_measures: int = inner.layout.model.measure_count
		var branch_arranges: int = branch.layout.model.arrange_count
		var flushed: int = entry.layout.flush_count
		var old_x: float = branch.position.x
		left.width += 10.0 if dimension == 2 else 0.5
		left.width += 10.0 if dimension == 2 else 0.5
		left.height += 1.0 if dimension == 2 else 0.1
		await settle()
		check(entry.layout.flush_count == flushed + 1, "multiple writes coalesce to one root flush")
		check(branch.layout.model.measure_count == branch_measures and inner.layout.model.measure_count == inner_measures, "unaffected branch measurement cached")
		check(branch.layout.model.arrange_count == branch_arranges, "unaffected branch local arrangement cached")
		print("B2_REFLOW_COUNTERS ", dimension, " root_flush_delta=", entry.layout.flush_count-flushed, " sibling_measure_delta=", branch.layout.model.measure_count-branch_measures, " sibling_arrange_delta=", branch.layout.model.arrange_count-branch_arranges)
		check(branch.position.x > old_x and events > 0, "actual positions and signal update")
		check([entry.get_instance_id(),left.get_instance_id(),branch.get_instance_id(),inner.get_instance_id()] == ids, "layout retains native IDs")
		check(left.layout_applied.is_connected(on_layout), "layout retains signal subscription")
		check(boundary.position == original_boundary and entry.position == original_entry, "ordinary native transforms and root transform untouched")
		check(snapshot(reentry) == reentry_before, "no invalidation tunnels across native boundary")
		var prior_left_x: float = left.position.x
		entry.move_child(branch, 0)
		await settle()
		check(entry.layout.model.children[0] == branch.layout.model and left.position.x > prior_left_x, "native move_child preserves authored row order")
		entry.move_child(left, 0)
		await settle()
		var measure_before: int = branch.layout.model.measure_count
		flushed = entry.layout.flush_count
		root.size = Vector2i(800,400)
		await settle()
		check(entry.layout.flush_count == flushed + 1 and is_equal_approx(entry.layout.model.size.x, 800 if dimension == 2 else 10.0), "viewport resize event allocation")
		check(branch.layout.model.measure_count == measure_before, "resize preserves unaffected measurement cache")
		check(snapshot(reentry) == reentry_before, "non-viewport entry not dirtied by viewport")
		# Native changes to rotation/scale are not overwritten or observed.
		if dimension == 2:
			left.rotation = 0.2
			left.scale = Vector2(1.1,0.9)
		else:
			left.rotation = Vector3(0,0.2,0)
			left.scale = Vector3(1.1,0.9,1)
		var rotation = left.rotation
		var scale_value = left.scale
		left.width += 1.0
		await settle()
		check(left.rotation == rotation and left.scale == scale_value, "layout authority excludes native rotation/scale")
		# Direct participant moves use native remove/add, identity remains.
		var moving_id: int = inner.get_instance_id()
		branch.remove_child(inner)
		entry.add_child(inner)
		await settle()
		check(inner.get_instance_id() == moving_id and inner.layout.parent_coordinator() == entry.layout, "native reparent transfers participation without reconstruction")
		check(not branch.layout.model.children.has(inner.layout.model) and entry.layout.model.children.has(inner.layout.model), "no stale old-parent measurement")
		check(inner.owner == null, "native owner clearing not overridden by layout")
		# Move the same participant beneath a native boundary: new independent entry.
		entry.remove_child(inner)
		boundary.add_child(inner)
		await settle()
		check(inner.layout.parent_coordinator() == null and not entry.layout.model.children.has(inner.layout.model), "native boundary terminates participation")
		var foreign = Entry3D.new() if dimension == 2 else Entry2D.new()
		entry.add_child(foreign)
		await settle()
		check(not entry.layout.model.children.has(foreign.layout.model) and foreign.layout.parent_coordinator() == null, "opposite-dimensional boundary")
		var native_viewport: Viewport = entry.get_viewport()
		var connections_before: int = native_viewport.size_changed.get_connections().size()
		var total = snapshot(entry)
		await settle()
		check(snapshot(entry) == total, "no feedback loop after transforms/tree changes")
		entry.free()
		await settle()
		check(not is_instance_id_valid(moving_id), "native free cleans participant subtree")
		check(native_viewport.size_changed.get_connections().size() < connections_before, "free disconnects viewport subscriptions")
		root.size = Vector2i(640,360)
		await settle()
	factory.free()
	print("B2_RUNTIME_ASSERTIONS ", assertions)
	if failures == 0: print("GGX_B2_RUNTIME_OK")
	quit(1 if failures else 0)

func snapshot(entry: Node) -> Array:
	return [entry.layout.model.measure_count,entry.layout.model.arrange_count,entry.layout.flush_count]
