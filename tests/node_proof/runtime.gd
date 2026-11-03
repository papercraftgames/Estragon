extends SceneTree
const Build = preload("res://examples/node_proof/build.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var failures: int = 0
var assertions: int = 0

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("B1 ASSERTION FAILED: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"), "external toolchain unavailable")
	var built := Build.build()
	check(built.ok, "native build")
	if not built.ok:
		printerr(built)
		quit(1)
		return
	var first: String = built.compilation.code
	var second := Build.Proof.compile(FileAccess.get_file_as_string(Build.INPUT), Build.INPUT, Build.TYPES)
	check(first == second.code, "deterministic emission")
	check(built.compilation.source_map.serialize() == second.source_map.serialize(), "deterministic maps")
	var detached_compilation := Build.Proof.compile("extends Node\nvar calls: int = 0\nfunc record(value: int): calls += value\nfunc make(): return <Node2D><Timer name=\"Pulse\" timeout={record.bind(3)}/><Node3D name=\"Child\"/></Node2D>\n", "detached.gogo")
	var detached_build := Build.publish(detached_compilation, "res://tests/node_proof/Detached.gd")
	check(detached_build.ok, "detached subtree compiles")
	var maker: Node = detached_build.script.new()
	var detached: Node2D = maker.make()
	check(detached.owner == null and detached.get_node("Child").owner == detached, "generated descendant ownership is limited to new root")
	detached.get_node("Pulse").timeout.emit()
	check(maker.calls == 3, "bound Callable value invokes exactly once")
	maker.free()
	check(detached.get_node("Pulse").timeout.get_connections().is_empty(), "native free of external target disconnects live source")
	detached.get_node("Pulse").timeout.emit()
	detached.free()
	var scene: Node2D = built.script.new()
	scene.compose()
	check(scene.evaluations == ["root", "custom2d", "timer", "custom3d"], "source ordered exactly-once evaluation")
	var composition: Node2D = scene.get_node("Composition")
	check(composition.get_children().map(node_name) == ["Panel", "Pulse", "Boundary"], "native child order")
	check(composition.get_node("Panel").get_script() == Build.TYPES.Probe2D, "custom Node2D script")
	check(composition.get_node("Boundary/Space").get_script() == Build.TYPES.Probe3D, "custom Node3D script")
	check(composition.get_node("Panel").amount == 7.0 and composition.get_node("Boundary/Space").amount == 9.0, "typed custom props")
	check(composition.get_node("Panel").palette == scene.palette, "Resource identity as property value")
	check(composition.get_node("Boundary/Space/Mesh").mesh is BoxMesh, "native Mesh Resource expression")
	var timer: Timer = composition.get_node("Pulse")
	check(timer.wait_time == 0.5 and timer.one_shot, "typed native values")
	check(timer.timeout.get_connections().size() == 1, "one generated connection")
	timer.timeout.emit()
	check(scene.ticks == 1, "native Node signal invokes named handler once")
	root.add_child(scene)
	await process_frame
	check(composition.get_node("Panel/Nested2D").global_position == Vector2(63, 74), "2D transform chain")
	check(composition.get_node("Boundary/Reset2D").global_position == Vector2(5, 6), "plain Node breaks CanvasItem ancestry")
	check(composition.get_node("Boundary/Space/Nested3D").global_position == Vector3(11, 22, 33), "3D transform chain")
	check(composition.get_node("Boundary/Space/ResetBoundary/Reset3D").global_position == Vector3(4, 5, 6), "plain Node breaks Node3D ancestry")
	var palette: Gradient = scene.palette
	check(palette.changed.get_connections().size() == 1, "non-Node Object signal subscribed once")
	palette.emit_changed()
	check(scene.changes == 1, "referenced Object signal invokes named handler")
	root.remove_child(scene)
	check(is_instance_valid(scene), "remove_child detaches without freeing")
	check(palette.changed.get_connections().is_empty(), "external Object disconnect on exit")
	root.add_child(scene)
	check(palette.changed.get_connections().size() == 1, "reentry reconnects once")
	palette.emit_changed()
	check(scene.changes == 2, "Object signal preserved after reentry")
	var moving: Node2D = composition.get_node("Panel/Nested2D")
	var identity := moving.get_instance_id()
	moving.get_parent().remove_child(moving)
	check(is_instance_valid(moving), "native removal retains Node")
	composition.add_child(moving)
	check(moving.get_instance_id() == identity, "native reparent retains identity")
	check(moving.global_position == Vector2(43, 64), "new parent transforms apply")
	moving.owner = scene # Native reparent clears invalid old owner; persistence is explicit.
	var external := Node.new()
	external.name = "External"
	composition.add_child(external)
	check(external.owner == null, "external Nodes are not accidentally owned")
	var packed := PackedScene.new()
	check(packed.pack(scene) == OK, "pack generated owned scene")
	check(ResourceSaver.save(packed, "res://tests/node_proof/Persisted.tscn") == OK, "save scene")
	var loaded: PackedScene = ResourceLoader.load("res://tests/node_proof/Persisted.tscn", "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var restored: Node2D = loaded.instantiate()
	check(not restored.has_node("Composition/External"), "unowned external Node excluded from persistence")
	check(restored.get_node("Composition/Panel").amount == 7.0, "custom exported properties persisted")
	check(restored.get_node("Composition/Panel").palette == restored.palette, "Resource sharing persisted")
	var restored_timer: Timer = restored.get_node("Composition/Pulse")
	check(restored_timer.timeout.get_connections().size() == 1, "CONNECT_PERSIST retained")
	restored_timer.timeout.emit()
	check(restored.ticks == 1 and scene.ticks == 1, "restored signal targets restored root")
	check(restored.get_node("Composition").owner == restored, "restored scene owner")
	root.add_child(restored)
	await process_frame
	check(restored.get_child_count() == 1, "ready does not duplicate saved hierarchy")
	var restored_palette: Gradient = restored.palette
	# Loaded resources may be shared with the live original; test target cleanup.
	var before: int = restored_palette.changed.get_connections().size()
	restored.free()
	check(restored_palette.changed.get_connections().size() == before - 1, "free disconnects Object target")
	var timer_id := timer.get_instance_id()
	var scene_id := scene.get_instance_id()
	scene.queue_free()
	await process_frame
	check(not is_instance_id_valid(scene_id) and not is_instance_id_valid(timer_id), "native freeing recursively cleans nodes/signals")
	palette.emit_changed() # No stale target invocation after free.
	# Existing compiler stays separate and old examples still compile/execute.
	for example in ["compiled/Layout", "mixed/Mixed", "counter/Counter"]:
		var input: String = "res://examples/" + example + ".gogo"
		var compilation := Compiler.compile(FileAccess.get_file_as_string(input), input)
		check(compilation.ok, "legacy default compile " + example)
		var output: String = input.get_base_dir().path_join("generated/" + input.get_file().trim_suffix(".gogo") + ".gd")
		var result := Build.publish(compilation, output)
		check(result.ok, "legacy semantic validation " + example)
		if result.ok:
			var host: Node = result.script.new()
			root.add_child(host)
			if example == "counter/Counter":
				host.increment()
				check(host.count == 1 and host.get_root().get_children()[1].text == "Count: 1", "old Counter increments")
				host.reset_count()
				check(host.count == 0 and host.get_root().get_children()[1].text == "Count: 0", "old Counter resets")
			host.free()
	print("B1_RUNTIME_ASSERTIONS ", assertions)
	if failures == 0: print("GGX_B1_RUNTIME_OK")
	quit(1 if failures else 0)

func node_name(node: Node) -> String:
	return str(node.name)
