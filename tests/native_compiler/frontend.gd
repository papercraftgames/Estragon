extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Manager = preload("res://addons/estragon/runtime/composition/state.tres")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var examples := [
		'extends Node\nfunc make(): return <EstragonVBox><EstragonText text="native" /><EstragonButton text="framework" /></EstragonVBox>\n',
		'extends Node\nfunc make(): return <Button text="Godot" />\n',
		'extends Node\nfunc make(): return <Node name="root"><Node2D position={Vector2(1,2)} /><Timer wait_time={0.5} /></Node>\n',
		'extends Node\n# <ignored/>\nvar text = "<ignored>"\nvar multi = """<ignored>\n# quoted\n"""\nfunc make():\n\treturn <Node name={"a" if 1 < 2 else "b"} />\n',
		'extends Node\nfunc make():\n\tvar create := func(value: String): return <Node name={value} />\n\treturn create.call("lambda")\n',
		'extends Node\nfunc make(): return <Node name={str({"nested": <Node name="inside" />}.size())} />\n',
		'extends RefCounted\nvar value: float = 1.25e-2\nfunc count() -> int: return 7\n',
		'extends RefCounted\nvar number: int = 9007199254740993\n',
		'extends Node\r\nfunc make():\r\n    return <Node name="CRLF" />\r\n'
	]
	for source in examples:
		var first := Compiler.compile(source,"test.gogo")
		var second := Compiler.compile(source,"test.gogo")
		check(first.ok,"valid lexical/native expression: "+str(first.diagnostics))
		if not first.ok: continue
		check(first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"deterministic code/maps")
		if source.contains('<Button '): check(first.code.contains('.new("Button",') and not first.code.contains('.new("EstragonButton",'),"Button retains ordinary Godot class meaning")
		check(not first.code.contains("!= OK:\n\t\t\tpush_error(\"test.gogo:1"),"no obsolete Error-returning child attachment")
		var script := GDScript.new()
		script.resource_path = "res://_gogo_memory_%d.gd" % script.get_instance_id()
		script.source_code = first.code
		check(script.reload()==OK,"native semantic acceptance of valid generated code")
		if source.contains('9007199254740993'):
			check(first.code.contains('9007199254740993') and str(script.new().number)=="9007199254740993","native integer tokens preserved without float conversion")
		if source.contains('create := func'):
			var instance = script.new()
			var description = instance.make()
			check(description is Element and description.properties.name=="lambda" and instance.get_child_count()==0,"ordinary lambda returns description without candidate Nodes")
			instance.free()
	for source in [
		'<Node />', 'extends Node\nfunc make(): return <Gradient />\n',
		'extends Node\nfunc make(): return <Rect />\n',
		'extends Node\nfunc make(): return <Node a={1} />\n',
		'extends Node\nfunc make(): return <Node name="a" name="b" />\n',
		'extends Node\nfunc make(): return <Node><Node /></Timer>\n',
		'extends Node\nfunc make(): return <Node>{Node.new()}</Node>\n',
		'extends Node\nfunc make(): return <Timer timeout={func(): pass} />\n',
		'extends Node\nfunc make(): return <Node script={null} />\n',
		'extends Node\nfunc make(): return <Node2D position="bad" />\n'
	]:
		var result := Compiler.compile(source,"negative.gogo")
		check(not result.ok and not result.diagnostics.is_empty(),"negative lexical/type/child/signal rejection")
		if not result.ok: check(result.diagnostics[0].span.start.line>=1 and result.diagnostics[0].span.start.column>=1,"authored diagnostic span")
	var helper_source := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\n@bindable var count: int = 0\nfunc build_view() -> Element: return helper()\nfunc helper() -> Element:\n\tvar create := func(): return <Node name={"Value%d" % count} />\n\treturn create.call()\n'
	var helper_result := Compiler.compile(helper_source,"helper.gogo")
	check(helper_result.ok,"ordinary helper/lambda shared description lowering compiles")
	var helper_script := GDScript.new()
	helper_script.resource_path = "res://_gogo_memory_%d.gd" % helper_script.get_instance_id()
	helper_script.source_code = helper_result.code
	check(helper_script.reload()==OK,"typed helper/lambda native semantics")
	var host = helper_script.new()
	root.add_child(host)
	for index in range(6): await process_frame
	var child = host.get_node("Value0")
	var record = Manager.records[host.get_instance_id()]
	host.count = 1
	for index in range(6): await process_frame
	check(host.get_node("Value1")==child and record.runs==2 and host.count_changed.get_connections().size()==1,"helper/lambda getter reads schedule same computation and retain actual Node")
	host.free()
	check(Manager.records.is_empty(),"helper-host lifetime clears sole manager")
	for old in ['build_view() -> Node','build_view()','build_view(value: int) -> Element','build_view() -> Variant']:
		var rejected := Compiler.compile(helper_source.replace('build_view() -> Element',old),"old.gogo")
		check(not rejected.ok and rejected.diagnostics[0].span.start.line==4,"invalid host convention rejects at authored declaration: "+old)
	# Frontend relative aliases and injected Resources share the actual output context.
	var destination := "res://custom/other/../deep/Relocated.gd"
	var moved_source := helper_source.replace("res://addons/estragon/", "../../addons/estragon/")
	var moved := Compiler.compile(moved_source, "authored/Relocated.gogo", destination)
	check(moved.ok and not moved.code.contains("res://"), "custom output derives every injected path without a fixed installation root")
	var moved_script := GDScript.new()
	moved_script.resource_path = destination
	moved_script.source_code = moved.code
	check(moved_script.reload()==OK, "relative imports and injected dependencies use actual output path, independently of diagnostic source name")
	var ordinary := Compiler.compile('extends Node\nfunc build_view() -> Node: return Node.new()\n',"ordinary.gogo")
	check(ordinary.ok,"no-GGX imperative Godot remains ordinary code")
	print("NATIVE_FRONTEND_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("NATIVE_FRONTEND_OK")
	quit(0 if failures==0 else 1)
