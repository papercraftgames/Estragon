@tool
extends RefCounted
## Token/span call lowering. GDScript stays native; authored GGX marks functions.
const Model = preload("model.gd")
const Parser = preload("parser.gd")
const Layouts = preload("layouts.gd")
const Resolver = preload("native/resolver.gd")
const Source = preload("source.gd")
const Lexer = preload("lexer.gd")
var file
var module
var functions: Array = []
var returns: Dictionary = {}
var resolver
var declarations: Array = []
var methods: Dictionary = {}
var native_methods: Dictionary = {}
var builtin_types: Dictionary = {}
var lambda_bindings: Array = []
var lexical
const VARIANT_TYPES := ["Nil","bool","int","float","String","StringName","Vector2","Vector2i","Rect2","Rect2i","Vector3","Vector3i","Transform2D","Vector4","Vector4i","Plane","Quaternion","AABB","Basis","Transform3D","Projection","Color","NodePath","RID","Object","Callable","Signal","Dictionary","Array","PackedByteArray","PackedInt32Array","PackedInt64Array","PackedFloat32Array","PackedFloat64Array","PackedStringArray","PackedVector2Array","PackedVector3Array","PackedColorArray"]
const INTRINSICS := ["preload","load","str","int","float","bool","String","StringName","Vector2","Vector2i","Vector3","Vector3i","Vector4","Vector4i","Color","Rect2","Rect2i","Transform2D","Dictionary","Array","Callable","Signal","NodePath","RID","assert","print","prints","print_debug","push_error","push_warning","is_instance_valid","is_same","typeof","weakref","range","min","max","minf","maxf","mini","maxi","abs","absf","absi","clamp","clampf","clampi","snapped","lerp","floor","ceil","round","sin","cos","sqrt"]
# Native traversal callbacks are syntax-transparent, not opaque application
# helper bodies. Their GGX/lambda children run in the current render context.
const TRAVERSAL := ["map","filter","reduce","any","all","sort_custom"]
func _init(source) -> void: file = source
func apply(value) -> void:
	module = value
	for name in VARIANT_TYPES: builtin_types[name] = true
	resolver = Resolver.new(file)
	resolver.scan(module)
	var tokens := _tokens(module.parts)
	returns = _returns(tokens)
	lexical = Layouts.new(file)
	lexical.module = module
	lexical._index()
	_lambdas(tokens)
	_declarations(tokens)
	for index in range(tokens.size()-1):
		if tokens[index].text=="func": methods[tokens[index+1].text] = true
	for native in ["Node2D","Node3D"]:
		for method in ClassDB.class_get_method_list(native): native_methods[str(method.name)] = true
	for part in module.parts:
		if part is Model.Bindable and resolver.aliases.has(part.type_name): declarations.append({"name":part.name,"type":part.type_name,"span":part.declaration_span})
	for index in range(tokens.size()-2):
		if tokens[index].text!="func" or tokens[index+1].kind!="identifier": continue
		var prefix: String = file.text.substr(file.line_start(tokens[index].span.start.line),tokens[index].span.start.index-file.line_start(tokens[index].span.start.line))
		if prefix.strip_edges() not in ["","static"]: continue
		var opening := index+2
		if tokens[opening].text!="(": continue
		var closing := _close(tokens,opening)
		if closing<0: continue
		var colon := closing+1
		while colon<tokens.size() and tokens[colon].text!=":": colon += 1
		if colon>=tokens.size(): continue
		var end: int = file.text.length()
		for following in range(colon+1,tokens.size()):
			if tokens[following].span.start.column==1:
				end = tokens[following].span.start.index
				break
		var begin: int = tokens[colon].span.end.index
		var reactive := false
		for token in tokens:
			if token.kind=="ggx" and token.span.start.index>=begin and token.span.end.index<=end: reactive = true
		if reactive or tokens[index+1].text=="build_view":
			functions.append({"start":begin,"end":end})
			module.render_functions.append(tokens[index+1].text)
	if functions.is_empty() and module.presets.is_empty(): return
	if module.identifiers.has("_GOGO_RENDER_FUNCTIONS"):
		file.fail("Reserved compiler render metadata name _GOGO_RENDER_FUNCTIONS",0)
		return
	module.parts.assign(_rewrite(module.parts))
func _tokens(parts: Array, source = null) -> Array:
	var result: Array = []
	var lexer := Lexer.new(file if source==null else source)
	for part in parts:
		if part is Model.Component:
			result.append({"kind":"ggx","text":"<ggx>","span":part.span})
		elif part is Model.Code:
			var cursor: int = part.span.start.index
			while cursor<part.span.end.index:
				var token = lexer.next_token(cursor)
				if token==null: break
				cursor = token.span.end.index
				if token.kind not in ["whitespace","newline","comment","continuation"]: result.append(token)
	return result
func _close(tokens: Array, start: int) -> int:
	var stack: Array = []
	for index in range(start,tokens.size()):
		var text: String = tokens[index].text
		if text in ["(","[","{"]: stack.append(text)
		elif text in [")","]","}"]:
			if stack.is_empty(): return -1
			stack.pop_back()
			if stack.is_empty(): return index
	return -1
func _reactive(offset: int) -> bool:
	for function in functions:
		if offset>=function.start and offset<function.end: return true
	return false
func _rewrite(parts: Array, force: bool = false) -> Array:
	# Descend into islands first; enclosing calls treat each entire island as an
	# operand and never lex attribute text as GDScript.
	for part in parts:
		if part is Model.Layout:
			for binding in part.bindings:
				for group in binding.groups:
					for attr in group.attributes:
						if attr.value is Model.GdExpression: attr.value.parts.assign(_rewrite(attr.value.parts,true))
		elif part is Model.Component:
			for attr in part.attributes:
				if attr.value is Model.GdExpression: attr.value.parts.assign(_rewrite(attr.value.parts,force))
			for child in part.children:
				if child is Model.GdExpression: child.parts.assign(_rewrite(child.parts,force))
				elif child is Model.Component: _rewrite([child],force)
			for child in part.text_body:
				if child is Model.GdExpression: child.parts.assign(_rewrite(child.parts))
		elif part is Model.GdExpression: part.parts.assign(_rewrite(part.parts,force))
	var tokens := _tokens(parts)
	var calls: Array = []
	for index in range(1,tokens.size()):
		if tokens[index].text!="(" or tokens[index-1].kind!="identifier" or not force and not _reactive(tokens[index].span.start.index): continue
		var name: String = tokens[index-1].text
		if name in Lexer.KEYWORDS or name in INTRINSICS or ClassDB.class_exists(name) or builtin_types.has(name): continue
		if index>1 and tokens[index-2].text=="func": continue
		if name=="new": continue
		var scripted := false
		if index>2 and tokens[index-2].text==".":
			var receiver: String = tokens[index-3].text
			scripted = resolver.aliases.has(receiver) or not _receiver_type(receiver,tokens[index].span.start.index).is_empty()
		if name in TRAVERSAL and not scripted and not methods.has(name): continue
		if native_methods.has(name) and not scripted and not methods.has(name): continue
		var end := _close(tokens,index)
		if end<0: continue
		var begin := index-1
		# Ordinary qualified method chains, including parenthesized/subscripted
		# receivers, stay actual native method references in emitted code.
		while begin>1 and tokens[begin-1].text==".":
			begin -= 2
			if tokens[begin].text in [")","]"]:
				var depth := 1
				var close: String = tokens[begin].text
				while begin>0 and depth>0:
					begin -= 1
					if tokens[begin].text==close: depth += 1
					elif tokens[begin].text==("(" if close==")" else "["): depth -= 1
				if begin>0 and tokens[begin-1].kind=="identifier": begin -= 1
		var args: Array = []
		var cursor := index+1
		var nested := 0
		for offset in range(index+1,end):
			var text: String = tokens[offset].text
			if text in ["(","[","{"]: nested += 1
			elif text in [")","]","}"]: nested -= 1
			elif text=="," and nested==0:
				args.append(file.span(tokens[cursor].span.start.index,tokens[offset].span.start.index))
				cursor = offset+1
		if cursor<end: args.append(file.span(tokens[cursor].span.start.index,tokens[end].span.start.index))
		calls.append({"span":file.span(tokens[begin].span.start.index,tokens[end].span.end.index),"callee":file.span(tokens[begin].span.start.index,tokens[index-1].span.end.index),"arguments":args,"result_type":_type(tokens,begin,index-1),"receiver":file.span(tokens[begin].span.start.index,tokens[index-2].span.start.index) if index>1 and tokens[index-2].text=="." else null,"method":name,"callable_value":begin==index-1 and not methods.has(name) and lexical.symbols.any(func(symbol): return symbol.name==name),"reactive_lambda":_lambda_at(name,tokens[index].span.start.index) if begin==index-1 or begin==index-3 and tokens[begin].text=="self" else false})
	calls.sort_custom(func(a,b): return a.span.start.index<b.span.start.index or a.span.start.index==b.span.start.index and a.span.end.index>b.span.end.index)
	if parts.is_empty(): return parts
	return _range(parts,parts[0].span.start.index,parts[-1].span.end.index,calls)
func _range(parts: Array, start: int, end: int, calls: Array) -> Array:
	var result: Array = []
	var cursor := start
	for item in calls:
		if item.span.start.index<cursor or item.span.end.index>end: continue
		result.append_array(_slice(parts,cursor,item.span.start.index))
		var call := Model.RenderCall.new()
		call.span = item.span
		call.result_type = item.result_type
		call.reactive_lambda = item.reactive_lambda
		call.callable_value = item.callable_value
		if item.receiver!=null:
			call.receiver.assign(_range(parts,item.receiver.start.index,item.receiver.end.index,calls))
			call.method = item.method
		call.callee.assign(_slice(parts,item.callee.start.index,item.callee.end.index))
		call.original.assign(_slice(parts,item.span.start.index,item.span.end.index))
		for argument in item.arguments:
			var expression := Model.GdExpression.new()
			expression.span = argument
			expression.parts.assign(_range(parts,argument.start.index,argument.end.index,calls))
			call.arguments.append(expression)
		result.append(call)
		cursor = item.span.end.index
	result.append_array(_slice(parts,cursor,end))
	return result
func _slice(parts: Array, start: int, end: int) -> Array:
	var result: Array = []
	for part in parts:
		if part.span.end.index<=start or part.span.start.index>=end: continue
		if part is Model.Code:
			var code := Model.Code.new()
			code.span = file.span(maxi(start,part.span.start.index),mini(end,part.span.end.index))
			result.append(code)
		else: result.append(part)
	return result

func _returns(tokens: Array) -> Dictionary:
	var result := {}
	for index in range(tokens.size()-2):
		if tokens[index].text!="func" or tokens[index+1].kind!="identifier" or tokens[index+2].text!="(": continue
		var end := _close(tokens,index+2)
		if end<0 or end+2>=tokens.size() or tokens[end+1].text!="->": continue
		var type := ""
		var cursor := end+2
		while cursor<tokens.size() and tokens[cursor].text!=":":
			type += tokens[cursor].text
			cursor += 1
		result[tokens[index+1].text] = type
	return result
func _type(tokens: Array, begin: int, end: int) -> String:
	if begin==end or end-begin==2 and tokens[begin].text=="self": return returns.get(tokens[end].text,"")
	var receiver := begin+2 if tokens[begin].text=="self" else begin
	if end-receiver!=2: return ""
	var alias: String = tokens[receiver].text
	if not resolver.aliases.has(alias): alias = _receiver_type(alias,tokens[end].span.start.index)
	if not resolver.aliases.has(alias): return ""
	var path: String = resolver.aliases[alias]
	var authored: String = path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo")
	if path.get_base_dir().get_file()=="generated" and FileAccess.file_exists(authored): path = authored
	if not FileAccess.file_exists(path): return ""
	var project = resolver.scope()
	var key: String = project.authored(path)
	var text: String = project.read(key) if project.sources.has(key) else FileAccess.get_file_as_string(path)
	var source := Source.new(text,path)
	var imported_module = Parser.new(source).parse()
	if imported_module==null: return ""
	var type: String = _returns(_tokens(imported_module.parts,source)).get(tokens[end].text,"")
	if type.is_empty(): return ""
	# Imported types live on the source Script alias, never an instance variable.
	var lexer := Lexer.new(Source.new(type))
	var cursor := 0
	var result := ""
	var qualified := false
	var variants: Array = ["void","Variant"]
	variants.append_array(VARIANT_TYPES)
	var globals: Array = []
	for item in ProjectSettings.get_global_class_list(): globals.append(str(item["class"]))
	while cursor<type.length():
		var token = lexer.next_token(cursor)
		if token==null: return ""
		cursor = token.span.end.index
		var name: String = token.text
		if token.kind=="identifier" and not qualified and name not in variants and name not in globals and not ClassDB.class_exists(name): result += alias+"."
		result += name
		qualified = name=="."
	return result
func _declarations(tokens: Array) -> void:
	for index in range(tokens.size()-3):
		var token = tokens[index]
		if token.text in ["var","const"] and tokens[index+1].kind=="identifier":
			var name: String = tokens[index+1].text
			var type := ""
			if tokens[index+2].text==":": type = tokens[index+3].text
			elif tokens[index+2].text in ["=",":="]: type = tokens[index+3].text
			if resolver.aliases.has(type): declarations.append({"name":name,"type":type,"span":token.span})
		elif token.text==":" and index>0 and tokens[index-1].kind=="identifier" and resolver.aliases.has(tokens[index+1].text):
			declarations.append({"name":tokens[index-1].text,"type":tokens[index+1].text,"span":tokens[index-1].span})
func _receiver_type(name: String, offset: int) -> String:
	var result := ""
	for declaration in declarations:
		if declaration.name!=name or declaration.span.start.index>=offset: continue
		# A declaration leaves scope at the next same/lower-indented statement.
		var indentation: int = declaration.span.start.column-1
		var visible := true
		if indentation>0:
			for line in range(declaration.span.start.line+1,file.position(offset).line+1):
				var start: int = file.line_start(line)
				var end: int = file.line_start(line+1)
				var text: String = file.text.substr(start,end-start)
				if text.strip_edges().is_empty() or text.strip_edges().begins_with("#"): continue
				var width: int = text.length()-text.strip_edges(true,false).length()
				if width<indentation: visible = false; break
		if visible: result = declaration.type
	return result

func _lambdas(tokens: Array) -> void:
	for index in range(2,tokens.size()):
		if tokens[index].text!="func" or tokens[index-1].text not in ["=",":="] or tokens[index-2].kind!="identifier": continue
		var binding_index := index-4 if index>3 and tokens[index-3].text==":" else index-2
		var end: int = file.text.length()
		var line: int = tokens[index].span.start.line
		var indentation := 0
		while file.text[file.line_start(line)+indentation] in [" ","\t"]: indentation += 1
		for next in range(index+1,tokens.size()):
			if tokens[next].span.start.line>line and tokens[next].span.start.column-1<=indentation:
				end = tokens[next].span.start.index
				break
		var reactive := false
		for next in range(index+1,tokens.size()):
			if tokens[next].span.start.index>=end: break
			if tokens[next].kind=="ggx": reactive = true
		lambda_bindings.append({"name":tokens[binding_index].text,"start":tokens[index].span.start.index,"end":end,"reactive":reactive,"scope":lexical._scope(tokens[index].span.start.index)})
func _lambda_at(name: String, offset: int) -> bool:
	var scope: int = lexical._scope(offset)
	while scope>=0:
		var found = null
		for binding in lambda_bindings:
			if binding.name==name and binding.scope==scope and binding.start<offset: found = binding
		for symbol in lexical.symbols:
			if symbol.name==name and symbol.scope==scope and symbol.span.start.index<offset and (found==null or symbol.span.start.index>found.start): return false
		if found!=null: return found.reactive
		scope = lexical.scopes[scope].parent
	return false
