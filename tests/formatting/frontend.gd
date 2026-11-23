extends SceneTree
const Formatter = preload("res://addons/estragon/editor/formatter.gd")
const Parser = preload("res://addons/estragon/compiler/parser.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var checks := 0
var errors := 0
var sequence := 0
func check(value: bool, label: String):
	checks += 1
	print("EDIT01_FRONTEND ",label,": ",value)
	if not value: errors += 1
func signature(text: String) -> Array:
	var parser=Parser.new(Source.new(text))
	if parser.parse()==null: return []
	var result: Array=[]
	for token in parser.lexer.tokens:
		if token.kind=="whitespace" or token.kind=="markup-text" and token.text.strip_edges().is_empty(): continue
		result.append([token.kind,token.text])
	return result
func formatted(text: String, label: String, spaces: bool=true) -> Dictionary:
	var result=Formatter.new().format_source(text,label,spaces,4)
	check(result.ok,label+" syntax/structure accepted")
	if result.ok:
		check(signature(text)==signature(result.text),label+" tokens, literals and physical rows preserved")
		var again=Formatter.new().format_source(result.text,label,spaces,4)
		check(again.ok and again.edits.is_empty() and again.text==result.text,label+" idempotent")
	return result
func description(element) -> Array:
	var descendants: Array = []
	for child in element.children: descendants.append(description(child))
	return [element.type.resource_path if element.type is Script else element.type,element.properties,element.placement,descendants]
func semantic(text: String, spaces: bool, width: int) -> void:
	var report=Formatter.new().format_source(text,"semantic",spaces,width)
	check(report.ok,"semantic fixture formats with selected indentation")
	if not report.ok:
		print(report.diagnostics)
		return
	var instances: Array = []
	for source in [text,report.text]:
		sequence += 1
		var path := "res://app/generated/Semantic%d.gd" % sequence
		var result=Compiler.compile(source,"res://app/Semantic.gogo",path)
		check(result.ok,"original/formatted native compilation")
		if not result.ok: return
		var script:=GDScript.new()
		script.resource_path=path
		script.source_code=result.code
		var valid:=script.reload()==OK
		check(valid,"original/formatted actual native GDScript semantics")
		if not valid: return
		instances.append(script.new())
	for value in [2,8]:
		check(description(instances[0].view(value))==description(instances[1].view(value)),"conditional/literal/spread/layout description semantic parity")
func _initialize():
	var owner='func build_view() -> Element:\n    return <Entry2D\n width={get_viewport_rect().size.x}\n  height={get_viewport_rect().size.y}\n >\n<VBox fill_width={true} fill_height={true}>\n<Text text="Hello World!" />\n     <Text text="This is fun!" />\n </VBox>\n </Entry2D>\n'
	var result=formatted(owner,"owner Cmd+I reproduction")
	check(result.text=='func build_view() -> Element:\n    return <Entry2D\n        width={get_viewport_rect().size.x}\n        height={get_viewport_rect().size.y}\n    >\n        <VBox fill_width={true} fill_height={true}>\n            <Text text="Hello World!" />\n            <Text text="This is fun!" />\n        </VBox>\n    </Entry2D>\n',"owner paired/self-closing and multiline attributes have exact indentation")
	var script='func view(value):\n  if value < 4:\n      var text = "less < than and quote \\\" >"\n      return <Box>\n<Text text={text} {...{ "width": "10px" }} />\n</Box>\n  else:\n      return <Text text={str(value > 8)} />\n'
	result=formatted(script,"nested suites and comparisons")
	check(result.text.contains('    if value < 4:\n        var text') and result.text.contains('    else:\n        return'),"native suite relationships normalize without guessing dedents")
	var literals='func view():\n    var text = """first\n  literal <Tag> { brackets }\n   final"""\n    return <Box>\n<Text text="first\n  property content" />\n<!-- comment\n  literal comment indentation -->\n<Text>first\n  meaningful text\n end</Text>\n</Box>\n'
	result=formatted(literals,"multiline literal contents and comments")
	check(result.text.contains("\n        <!-- comment\n  literal comment indentation -->"),"comment start indents while multiline comment contents stay exact")
	var expressions='func view():\n    return <Box\n {...{\n "color": "red",\n "value": [1, 2],\n }}\n >\n {\n [<Text\n text={str(value)}\n /> for value in [1, 2]]\n }\n</Box>\n'
	formatted(expressions,"nested arrays, spreads and GGX islands")
	var matrix='layout const <Layout\n columns={2}\n>\n <Header /> <Header />\n<Side /> <Body />\n</Layout>\nfunc view():\n    return <Layout />\n'
	result=formatted(matrix,"layout matrix")
	check(result.text.contains('    <Header /> <Header />\n    <Side /> <Body />'),"matrix cells stay on their original rows")
	formatted('func view():\n    # native comment\n    return <Box>\n{<Text text={str({"a": [1, 2]})} /> if 1 < 2 else null}\n</Box>\n',"interpolation, braces and comparison")
	formatted(owner.replace("\n","\r\n"),"CRLF",false)
	for sample in ["nested_layout/Home","layouts/Layouts","core_reactivity/Core"]:
		var path="res://examples/"+sample+".gogo"
		if FileAccess.file_exists(path): formatted(FileAccess.get_file_as_string(path),sample,false)
	var native='extends RefCounted\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Text = preload("res://addons/estragon/runtime/node/text.gd")\n@bindable var title: String = "literal <tag>"\nlayout const <Layout>\n <Cell /> <Cell />\n</Layout>\nfunc view(value: int) -> Element:\n  if value < 4:\n      return <Layout>\n <Cell><Text text={self.title} {...{ "width": "20px" }} /></Cell>\n </Layout>\n  else:\n      return <Text text={"other\\nline"} />\n'
	semantic(native,true,2)
	semantic(native,false,4)
	for invalid in ['func view():\n    return <Box>\n <Text />\n','func view():\n    return <Box><Text /></Wrong>\n','func view():\n    return <Text text={"unfinished} />\n','func view():\nreturn <Box />\n','func view():\n    if true:\n        pass\n      return <Box />\n','func view():\n','func view():\n    var items = [1, 2\n','func view():\n    var items = (1]\n']:
		result=Formatter.new().format_source(invalid,"invalid")
		check(not result.ok and result.text==invalid and result.edits.is_empty() and not result.diagnostics.is_empty(),"malformed/ambiguous input refuses without mutation")
	print("EDIT01_FRONTEND_ASSERTIONS ",checks," errors=",errors)
	if errors==0: print("EDIT01_FRONTEND_OK")
	quit(0 if errors==0 else 1)
