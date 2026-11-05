extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
var failures: int = 0
var assertions: int = 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("C2 ASSERTION FAILED: " + message)
func settle() -> void:
	for index in range(6): await process_frame
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(OS.get_environment("PATH").ends_with("no-tools"),"no external compiler tools")
	for name in ["TwoD","ThreeD"]:
		var source_path: String = "examples/ggx/"+name+".gogo"
		var text := FileAccess.get_file_as_string("res://"+source_path)
		var a := Compiler.compile(text,source_path)
		var b := Compiler.compile(text,source_path)
		check(a.ok and b.ok and a.code == b.code and a.source_map.serialize() == b.source_map.serialize(),"regular compiler deterministic native code/maps")
		check(a.code.contains("_GogoElement_0.new") and not a.code.contains(".add_child("),"sole description lowering leaves native attachment to reconciler")
		var scene: Node = load("res://examples/ggx/"+name+".tscn").instantiate()
		root.add_child(scene)
		await settle()
		var entry = scene.entry
		var first = entry.get_node("First")
		var second = entry.get_node("Second")
		var visual = first.get_node("Visual")
		var identity: int = visual.get_instance_id()
		check(scene.evaluations == ["root","gap","first","custom"],"expressions evaluated once in source traversal order")
		check(first.get_layout_root() == entry and second.get_layout_root() == entry,"authored Gogo executes C1 layout")
		var initial_x: float = second.position.x
		var pulse: Timer = entry.get_node("Pulse")
		check(pulse.timeout.get_connections().size()==1,"one persistent named native signal connection")
		pulse.timeout.emit()
		await settle()
		check(scene.count == 1 and scene.object_events == 1,"native Node and referenced non-Node Resource signals execute")
		check(second.position.x > initial_x and visual.get_instance_id() == identity,"native signal reflows retained C1 Nodes")
		var custom = entry.get_node("Custom" if name=="TwoD" else "Boundary/Custom")
		check(custom.amount==7 and custom.palette==scene.palette,"preload custom Node typed props and Resource value")
		check(custom.get_node("Nested").global_position.is_equal_approx(custom.to_global(custom.get_node("Nested").position)),"native custom spatial transforms")
		check(entry.owner==null and visual.owner==null,"all described output is transient, separate from native scene owners")
		var stable = [entry.get_layout_stats(),first.bounds.snapshots,first.bounds.notifications]
		await settle()
		check(stable==[entry.get_layout_stats(),first.bounds.snapshots,first.bounds.notifications],"no idle reconstruction/polling/feedback")
		var packed_host := PackedScene.new()
		check(packed_host.pack(scene)==OK,"authored Gogo host packs independently of transient view")
		var restored_host: Node = packed_host.instantiate()
		root.add_child(restored_host)
		await settle()
		check(restored_host.get_node("Entry/Pulse").timeout.get_connections().size()==1 and restored_host.get_node("Entry")==restored_host.entry,"native host reload recomposes one signal graph")
		check(restored_host.get_node("Entry/First/Visual").owner==null,"reload leaves dynamic output transient")
		restored_host.entry.get_node("Pulse").timeout.emit()
		check(restored_host.count==1 and restored_host.object_events==1,"named native and scoped Object signals execute after reload")
		restored_host.free()
		var palette: Gradient = scene.palette
		var callback := Callable(scene,"on_palette_changed")
		scene.free()
		check(not palette.changed.is_connected(callback),"authored non-Node subscriptions clean up on exit")
	# Native registry accepts other real Godot Nodes and registered C1 types too.
	for source in ['extends Node\nfunc make(): return <Marker2D />\n','extends Node\nfunc make(): return <Estragon2D />\n']:
		check(Compiler.compile(source,"test.gogo").ok,"general native/registered type resolution")
	var negative := {
		"native-name-conflict":"extends Node\nconst Button = preload(\"res://examples/ggx/probe_2d.gd\")\nfunc make(): return <Button />\n",
		"non-node":"extends Node\nfunc make(): return <Gradient />\n",
		"unknown":"extends Node\nfunc make(): return <NoSuchC2Node />\n",
		"duplicate":"extends Node\nfunc make(): return <Node name=\"a\" name=\"b\" />\n",
		"property":"extends Node\nfunc make(): return <Node imaginary={1} />\n",
		"reserved":"extends Node\nfunc make(): return <Node owner={self} />\n",
		"signal":"extends Node\nfunc make(): return <Timer timeout=\"on_timeout\" />\n",
		"lambda":"extends Node\nfunc make(): return <Timer timeout={func(): pass} />\n",
		"adoption":"extends Node\nfunc make(): return <Node>{Node.new()}</Node>\n",
		"typed-literal":"extends Node\nfunc make(): return <Node2D position=\"wrong\" />\n",
		"resource-alias":"extends Node\nconst Data = preload(\"res://tests/ggx/data.gd\")\nfunc make(): return <Data />\n",
		"required-constructor":"extends Node\nconst Required = preload(\"res://tests/ggx/required.gd\")\nfunc make(): return <Required />\n",
		"ambiguous":"extends Node\nconst Node2D = preload(\"res://examples/ggx/probe_2d.gd\")\nfunc make(): return <Node2D />\n"
	}
	for label in negative:
		var result := Compiler.compile(negative[label],"negative.gogo")
		check(not result.ok and not result.diagnostics.is_empty() and result.diagnostics[0].span.start.line>=2 and result.code.is_empty(),"original-source fail-closed diagnostic: "+label)
		if not result.diagnostics.is_empty(): print("C2_NEGATIVE ",label," ",result.diagnostics[0].format())
	# Editing a cached authored import must not make metadata or cache stale.
	var imported_path := "res://examples/ggx/probe_2d.gd"
	var imported: GDScript = load(imported_path)
	var imported_source: String = imported.source_code
	var import_file := FileAccess.open(imported_path,FileAccess.WRITE)
	import_file.store_string(imported_source+"\n@export var fresh_field: float = 0.0\n")
	import_file.close()
	var fresh := Compiler.compile('extends Node\nconst Fresh = preload("res://examples/ggx/probe_2d.gd")\nfunc make(): return <Fresh fresh_field={2.0} />\n',"fresh.gogo")
	check(not fresh.ok and fresh.diagnostics[0].message.contains("unsynchronized disk/cache"),"stale external import is diagnosed instead of trusting stale metadata")
	check(load(imported_path)==imported and imported.source_code==imported_source,"metadata does not take over or mutate application Script cache")
	# A native user/editor reload retains Script identity and supplies fresh metadata.
	imported.source_code = imported_source+"\n@export var fresh_field: float = 0.0\n"
	check(imported.reload(true)==OK,"ordinary native Script reload")
	check(Compiler.compile('extends Node\nconst Fresh = preload("res://examples/ggx/probe_2d.gd")\nfunc make(): return <Fresh fresh_field={2.0} />\n',"fresh.gogo").ok,"reloaded native import metadata recovers")
	import_file = FileAccess.open(imported_path,FileAccess.WRITE)
	import_file.store_string(imported_source)
	import_file.close()
	imported.source_code = imported_source
	check(imported.reload(true)==OK and load(imported_path)==imported,"native cache identity restored after import probe")
	# No-op publication retains paths, bytecode resource identity, code/maps/UID.
	var output := "res://examples/ggx/generated/TwoD.gd"
	var normalized := Build.run_build()
	check(normalized.ok,"normal native build establishes canonical bytes after first editor import")
	print("C2_POST_IMPORT_BUILD ",normalized)
	var cached = load(output)
	var bytes := FileAccess.get_file_as_bytes(output)
	var map := FileAccess.get_file_as_bytes(output+".map.json")
	var rebuilt := Build.run_build()
	print("C2_NOOP report=",rebuilt," identity=",load(output)==cached," code=",FileAccess.get_file_as_bytes(output)==bytes," map=",FileAccess.get_file_as_bytes(output+".map.json")==map)
	check(rebuilt.ok and load(output)==cached and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==map,"normal publication no-op cache/bytes/map identity")
	print("C2_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("GGX_C2_RUNTIME_OK")
	quit(0 if failures==0 else 1)
