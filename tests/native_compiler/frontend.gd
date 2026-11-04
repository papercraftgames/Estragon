extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var failures: int = 0
var checks: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var examples := [
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
		check(not first.code.contains("!= OK:\n\t\t\tpush_error(\"test.gogo:1"),"no obsolete Error-returning child attachment")
		var script := GDScript.new()
		script.source_code = first.code
		check(script.reload()==OK,"native semantic acceptance of valid generated code")
		if source.contains('9007199254740993'):
			check(first.code.contains('9007199254740993') and str(script.new().number)=="9007199254740993","native integer tokens preserved without float conversion")
		if source.contains('create := func'):
			var instance = script.new()
			var node: Node = instance.make()
			check(node.name=="lambda","ordinary lambda containing GGX executes typed factory on both engines")
			node.free()
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
	print("NATIVE_FRONTEND_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("NATIVE_FRONTEND_OK")
	quit(0 if failures==0 else 1)
