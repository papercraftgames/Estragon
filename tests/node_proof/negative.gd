extends SceneTree
const Build = preload("res://examples/node_proof/build.gd")
const Proof = preload("res://addons/estragon/compiler/node_proof/compiler.gd")
var failures: int = 0
var assertions: int = 0

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("B1 ASSERTION FAILED: " + message)

func _initialize() -> void:
	var cases := [
		["<Resource/>", "non-Node"],
		["<Node><Gradient/></Node>", "non-Node"],
		["<Node bogus={1}/>", "Unknown"],
		["<Timer unknown_signal={on_timeout}/>", "Unknown"],
		["<Node name=\"A\" name=\"B\"/>", "Duplicate"],
		["<Node owner={self}/>", "reserved"],
		["<Node script={null}/>", "reserved"],
		["<Timer timeout=\"on_timeout\"/>", "named handler"],
		["<Timer timeout={func(): pass}/>", "anonymous"],
		["<Node>{Gradient.new()}</Node>", "borrowed"],
		["<Node>{Node.new()}</Node>", "borrowed"],
		["<Node2D position=\"1\"/>", "typed values"],
	]
	for item in cases:
		var result := Proof.compile("extends Node\nfunc make():\n    return " + item[0] + "\n", "negative.gogo")
		check(not result.ok and result.code.is_empty() and result.source_map == null, "frontend fails closed " + item[0])
		if not result.diagnostics.is_empty():
			check(result.diagnostics[0].message.contains(item[1]), "specific diagnostic " + item[0])
			check(result.diagnostics[0].source_name == "negative.gogo" and result.diagnostics[0].span.start.line == 3, "original source coordinates")
	check(not Proof.compile("<Node/>", "standalone.gogo").ok, "standalone excluded explicitly")
	var invalid_type := Proof.compile("extends Node\nfunc make(): return <Wrong/>\n", "wrong.gogo", {"Wrong": preload("res://addons/estragon/compiler/source.gd")})
	check(not invalid_type.ok, "non-Node custom script excluded without instantiation")
	var quoted_func := Proof.compile("extends Node\nfunc named(): pass\nfunc make(): return <Timer timeout={Callable(self, \"named\")}/>\n", "callable.gogo")
	check(quoted_func.ok, "Callable expression allowed without anonymous declaration")
	var built := Build.build()
	check(built.ok, "positive baseline before negative publication")
	var old_code := FileAccess.get_file_as_bytes(Build.OUTPUT)
	var old_map := FileAccess.get_file_as_bytes(Build.OUTPUT + ".map.json")
	var cached: GDScript = load(Build.OUTPUT)
	var id := cached.get_instance_id()
	var live: Node = cached.new()
	live.compose()
	live.ticks = 17
	var code_time := FileAccess.get_modified_time(Build.OUTPUT)
	var map_time := FileAccess.get_modified_time(Build.OUTPUT + ".map.json")
	check(code_time == 1234567890 and map_time == 1234567890, "seeded timestamp survives no-op native build")
	var bad_sources := [
		"extends Node\nfunc make():\n    return <Node2D position={42}/>\n",
		"extends Node\nfunc make():\n    return <Timer timeout={42}/>\n",
		"extends Node\nfunc make():\n    return <Timer timeout={missing_handler}/>\n",
	]
	for index in range(bad_sources.size()):
		var compiled := Proof.compile(bad_sources[index], "semantic-%d.gogo" % index)
		check(compiled.ok, "balanced negative reaches native semantics")
		var rejected := Build.publish(compiled, Build.OUTPUT)
		check(not rejected.ok and not rejected.has("script"), "native semantic rejection exposes no executable")
		check(rejected.diagnostics[0].begins_with("semantic-%d.gogo:" % index), "semantic diagnostic original source identity")
		if Engine.get_version_info().minor >= 7:
			check(rejected.diagnostics[0].begins_with("semantic-%d.gogo:3:" % index), "Logger maps native failure to authored line")
		check(FileAccess.get_file_as_bytes(Build.OUTPUT) == old_code, "failed publication restores bytes")
		check(FileAccess.get_file_as_bytes(Build.OUTPUT + ".map.json") == old_map, "failed publication restores map")
		check(FileAccess.get_modified_time(Build.OUTPUT) == code_time and FileAccess.get_modified_time(Build.OUTPUT + ".map.json") == map_time, "failed transaction preserves timestamps")
		check(cached.get_instance_id() == id and cached.source_code == old_code.get_string_from_utf8(), "rollback retains cached identity/source")
		var recovered = cached.new()
		recovered.compose()
		check(recovered.get_node("Composition/Panel").amount == 7.0, "rollback executes previous bytecode")
		recovered.free()
		live.on_timeout()
		check(live.ticks == 18 + index, "failed reload/rollback retains live instance state and methods")
		print("B1_EXPECTED_SEMANTIC_REJECTION ", index)
	var invalid_callback := Proof.compile("extends Node\nfunc make():\n    return <Node><Timer timeout={Callable()}/></Node>\n", "invalid-callable.gogo")
	var published := Build.publish(invalid_callback, "res://tests/node_proof/InvalidCallable.gd")
	check(published.ok, "dynamic invalid Callable is a runtime guard case")
	var factory = published.script.new()
	var orphan_count := Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	check(factory.make() == null, "invalid runtime Callable fails closed")
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == orphan_count, "rejected factory frees new subtree")
	factory.free()
	print("B1_EXPECTED_CALLBACK_REJECTION")
	check(Build.build().ok and live.ticks == 20, "repair/no-op build still validates and retains live state")
	live.free()
	print("B1_NEGATIVE_ASSERTIONS ", assertions)
	if failures == 0: print("GGX_B1_NEGATIVE_OK")
	quit(1 if failures else 0)
