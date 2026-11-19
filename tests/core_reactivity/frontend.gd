extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var failures := 0
var checks := 0
var sequence := 0
const HEADER := 'extends Node2D\nconst Element=preload("res://addons/estragon/runtime/composition/element.gd")\nconst Text=preload("res://addons/estragon/runtime/node/text.gd")\nconst Box=preload("res://addons/estragon/runtime/node/box.gd")\n'
func check(value: bool,label: String):
	checks += 1
	print("CORE01_FRONTEND ",label,": ",value)
	if not value: failures += 1
func compile(body: String):
	sequence += 1
	return Compiler.compile(HEADER+body,"res://Probe.gogo","res://generated/Probe%d.gd" % sequence)
func native(result) -> bool:
	if not result.ok: return false
	var script := GDScript.new()
	script.resource_path="res://generated/Probe%d.gd" % sequence
	script.source_code=result.code
	return script.reload()==OK
func _initialize():
	var body := '@bindable var caption: String="Flynn"\nfunc label(value: String)->String:return value.to_upper()\nfunc badge()->Element:\n\tvar local := label(self.caption)\n\treturn <Text text={local} />\nfunc build_view()->Element:return <Box>{badge()}{badge()}</Box>\n'
	var result = compile(body)
	check(result.ok and native(result),"native typed calls, inferred locals and GGX helper lowering")
	if result.ok:
		check(result.code.contains('"reactive": ["badge", "build_view"]') and result.code.contains('"ordinary": ["label"]'),"actual authored GGX classifies reactive functions; ordinary function stays opaque")
		check(result.code.count('.call_at(')>=3 and result.code.contains(' as String)'),"distinct sourced invocation sites and preserved return inference")
		var again = Compiler.compile(HEADER+body,"res://Probe.gogo","res://generated/Probe%d.gd" % sequence)
		check(again.code==result.code and again.source_map.serialize()==result.source_map.serialize(),"deterministic sourced call lowering")
		var generated_index: int = result.code.find('.call_at(')
		var position = preload("res://addons/estragon/compiler/source.gd").new(result.code).position(generated_index)
		var mapped = result.source_map.original_position(position.line,position.column)
		check(mapped!=null and mapped.line==8,"generated call maps to authored call expression")
	result = compile('const Ordinary=preload("res://app/ordinary.gd")\nvar ordinary=Ordinary.new()\nfunc build_view()->Element:\n\tvar label := ordinary.label("typed")\n\treturn <Text text={label} />\n')
	check(result.ok and native(result) and result.code.contains(' as String)'),"imported ordinary .gd call retains native inferred return type")
	result = compile('const Ordinary=preload("res://app/ordinary.gd")\nvar ordinary=Ordinary.new()\nfunc build_view()->Element:return <Text text={ordinary.map("custom map")} />\n')
	check(result.ok and native(result) and result.code.contains(".method_at("),"ordinary imported map method is memoized; native traversal spelling is not a global exemption")
	result = compile('var bag: Dictionary={}\nfunc row(value: int)->Element:return <Text key={value} text={str(value)} />\nfunc build_view()->Element:\n\tvar list: Array=[]\n\tfor i in range(2): list.append(row(i))\n\treturn <Box>{list}</Box>\n')
	check(result.ok and native(result),"ordinary loops, void native calls and keyed descriptions compile")
	result = compile('func decorate(value: Element)->Element:return value\nfunc build_view()->Element:return decorate(<Text text="nested call" />)\n')
	check(result.ok and native(result),"native calls can contain GGX expression arguments")
	result = compile('static func badge(value: String)->Element:return <Text text={value} />\nfunc build_view()->Element:return badge("static")\n')
	check(result.ok and native(result) and result.code.contains('"badge"'),"static GGX helper classification uses authored body")
	result = compile('func no_markup()->Element:return Element.new(Text)\nfunc build_view()->Element:return <Box>{no_markup()}</Box>\n')
	check(result.ok and native(result) and result.code.contains('"reactive": ["build_view"]'),"manual Element construction is an ordinary function")
	result = compile('func event()->void:pass\nfunc build_view()->Element:return <Node2D ready={event} />\n')
	check(result.ok and native(result) and not result.code.contains('.call_at('),"handler references are not invocations")
	result = compile('func helper()->String:return "literal helper()"\nfunc build_view()->Element:\n\t# helper() is a comment\n\treturn <Text text="helper()" />\n')
	check(result.ok and native(result) and not result.code.contains('.call_at('),"strings and comments do not acquire calls")
	print("CORE01_EXPECTED_SEMANTIC_BEGIN")
	result = compile('func helper(value: String)->String:return value\nfunc build_view()->Element:return <Text text={helper(42)} />\n')
	check(result.ok and not native(result),"native proof preserves invalid argument rejection")
	print("CORE01_EXPECTED_SEMANTIC_END")
	result = compile('const _GOGO_RENDER_FUNCTIONS=[]\nfunc build_view()->Element:return <Text />\n')
	check(not result.ok and result.diagnostics[0].message.contains("Reserved"),"hygienic render metadata collision rejects")
	print("CORE01_FRONTEND_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("CORE01_FRONTEND_OK")
	quit(0 if failures==0 else 1)
