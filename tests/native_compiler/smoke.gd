extends SceneTree
## Tiny cold headless sanity check. No editor, import pass, rendering or Play.
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var failed := false
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var source := 'extends RefCounted\n@bindable var count: int = 0\n'
	var result := Compiler.compile(source, "smoke.gogo")
	check(result.ok, "typed bindable compiles")
	if result.ok:
		check(result.code == Compiler.compile(source, "smoke.gogo").code, "deterministic source")
		var script := GDScript.new()
		script.resource_path = "res://_gogo_memory_%d.gd" % script.get_instance_id()
		script.source_code = result.code
		check(script.reload() == OK, "generated native GDScript loads")
		if not failed:
			var model = script.new()
			var changes: Array = []
			model.count_changed.connect(func(previous, value): changes.append([previous, value]))
			model.count = 2
			model.count = 2
			check(changes == [[0, 2]], "native per-property change/equality behavior")
	var node := Compiler.compile('extends Node\nfunc view(): return <Node2D name="smoke"><Timer wait_time={0.5} /></Node2D>\n', "node.gogo")
	check(node.ok, "native Node descriptions compile cold")
	check(not Compiler.compile('extends Node\nfunc view(): return <RefCounted />\n', "bad.gogo").ok, "non-Node composition rejected")
	if not failed: print("ROUTINE_SMOKE_OK")
	quit(1 if failed else 0)
