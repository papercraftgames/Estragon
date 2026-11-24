@tool
extends RefCounted
## Lexer/span typed-data boundaries. Ordinary .gd is never rewritten.
const Model = preload("model.gd")
const Lexer = preload("lexer.gd")
const Resolver = preload("native/resolver.gd")
var file
var module
var aliases := {}
var declarations: Array = []
var lexical
func _init(source): file = source
func apply(value) -> void:
	module = value
	lexical = preload("layouts.gd").new(file)
	lexical.module = preload("parser.gd").new(file).parse()
	lexical._index()
	if module.data_shape:
		var tokens: Array = lexical.tokens
		for index in range(tokens.size()-5):
			if tokens[index].text!="func" or tokens[index+1].text!="_notification" or tokens[index].span.start.column!=1: continue
			var colon := index+4
			while colon<tokens.size() and tokens[colon].text!=")": colon += 1
			while colon<tokens.size() and tokens[colon].text!=":": colon += 1
			if colon+1>=tokens.size(): continue
			var parameter: String = tokens[index+3].text
			module.data_notification = true
			module.data_type_edits.append({"span":file.span(tokens[colon].span.end.index,tokens[colon+1].span.start.index),"value":"\n"+module.indentation+"if "+parameter+"==NOTIFICATION_PREDELETE: preload(%s).prune()\n"%var_to_str(preload("source.gd").relative_path(file.generated_path().get_base_dir(),preload("../runtime/data/state.tres").resource_path))+module.indentation})
	var resolver := Resolver.new(file)
	resolver.scan(module)
	for name in resolver.aliases:
		if _shape_import(resolver.aliases[name]): aliases[name] = true
	for index in range(lexical.tokens.size()-1):
		if lexical.tokens[index].text!="extends": continue
		var base = lexical.tokens[index+1]
		if aliases.has(base.text): module.data_inherited = true
		elif base.kind=="string":
			var path = str_to_var(base.text)
			if path is String:
				if not path.is_absolute_path(): path = file.generated_path().get_base_dir().path_join(path).simplify_path()
				module.data_inherited = _shape_import(path)
	if module.identifiers.has("_GogoArrayCollection"):
		file.fail("Reserved Gogo data type name _GogoArrayCollection",0)
		return
	for part in module.parts:
		if part is Model.Bindable:
			part.data_type = descriptor(part.type_name)
			if not part.data_type.is_empty():
				module.data_types[part.name] = part.data_type
				if aliases.has(part.type_name) or part.type_name.begins_with("ArrayCollection["):
					declarations.append({"name":part.name,"type":part.data_type,"offset":part.name_span.start.index})
			if part.type_name.begins_with("ArrayCollection") and part.data_type.is_empty():
				file.fail("ArrayCollection requires one supported typed data element",part.type_span.start.index,part.type_span.end.index)
				return
			if part.type_name.begins_with("ArrayCollection["): _collection_type(part.type_span)
	var tokens: Array = lexical.tokens
	for symbol in lexical.symbols:
		var index := -1
		for cursor in range(tokens.size()):
			if tokens[cursor].span.start.index==symbol.span.start.index: index = cursor; break
		if index<0 or index+2>=tokens.size() or tokens[index+1].text!=":": continue
		var end := index+2
		var depth := 0
		while end+1<tokens.size():
			if tokens[end].text=="[": depth += 1
			elif tokens[end].text=="]": depth -= 1
			if depth==0 and tokens[end+1].text!="[": break
			end += 1
		var type_span = file.span(tokens[index+2].span.start.index,tokens[end].span.end.index)
		var type := descriptor(file.slice(type_span))
		if type.is_empty() or not (aliases.has(file.slice(type_span)) or file.slice(type_span).begins_with("ArrayCollection[")): continue
		declarations.append({"name":symbol.name,"type":type,"offset":symbol.span.start.index})
		if symbol.scope==0: module.data_types[symbol.name] = type
		if file.slice(type_span).begins_with("ArrayCollection["): _collection_type(type_span)
	# Godot 4.0's statically typed custom-iterator fast path passes/clobbers
	# iterator state differently from Variant iteration. Keep Gogo iteration on
	# the public Variant protocol, including independent nested iterators.
	for index in range(tokens.size()-3):
		if tokens[index].text!="for" or tokens[index+2].text!="in": continue
		var end := index+3
		var depth := 0
		while end<tokens.size():
			if tokens[end].text in ["(","[","{"]: depth += 1
			elif tokens[end].text in [")","]","}"]: depth -= 1
			if depth==0 and tokens[end].text==":": break
			end += 1
		if end>=tokens.size(): continue
		var span = file.span(tokens[index+3].span.start.index,tokens[end].span.start.index)
		var root: String = tokens[index+3].text
		var type := _type(root,span.start.index)
		if root=="self" and index+5<end and tokens[index+4].text==".": type = _type(tokens[index+5].text,span.start.index,true)
		if type.is_empty(): continue
		module.data_type_edits.append({"span":span,"value":"preload(%s).iterate(%s)"%[var_to_str(preload("source.gd").relative_path(file.generated_path().get_base_dir(),preload("../runtime/data/state.tres").resource_path)),file.slice(span)]})
	module.parts.assign(_rewrite(module.parts))
	for part in module.parts:
		if not part is Model.Bindable or part.data_type.is_empty(): continue
		var declaration := _tokens([_code(part.declaration_span)])
		for index in range(declaration.size()):
			if declaration[index].text!="=" or not (part.type_name.begins_with("ArrayCollection[") or aliases.has(part.type_name)): continue
			part.initializer = Model.GdExpression.new()
			part.initializer.span = file.span(declaration[index+1].span.start.index,part.declaration_span.end.index)
			part.initializer.parts.assign([_code(part.initializer.span)])
			part.declaration_span = file.span(part.declaration_span.start.index,declaration[index+1].span.start.index)
			break
func _shape_import(path: String) -> bool:
	var authored := path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo")
	if not FileAccess.file_exists(authored): return false
	var text = file.project.read(file.project.authored(authored)) if file.project!=null else FileAccess.get_file_as_string(authored)
	var source = preload("source.gd").new(text,authored)
	var imported = preload("parser.gd").new(source).parse()
	if imported==null: return false
	preload("bindable.gd").new(source).apply(imported)
	return imported.data_shape
func descriptor(type: String) -> String:
	type = type.strip_edges()
	if type.begins_with("Array[") and type.ends_with("]"):
		var element := descriptor(type.substr(6,type.length()-7))
		return '{"array": '+element+'}' if not element.is_empty() else ""
	if type.begins_with("ArrayCollection[") and type.ends_with("]"):
		var element := descriptor(type.substr(16,type.length()-17))
		return "["+element+"]" if not element.is_empty() else ""
	if aliases.has(type): return module.import_aliases.get(type,type)
	var primitive := {"bool":"TYPE_BOOL","int":"TYPE_INT","float":"TYPE_FLOAT","String":"TYPE_STRING","Array":"TYPE_ARRAY","Dictionary":"TYPE_DICTIONARY"}
	return primitive.get(type,"")
func _collection_type(span) -> void:
	module.data_type_edits.append({"span":span,"value":"_GogoArrayCollection"})
func _tokens(parts: Array) -> Array:
	var result: Array = []
	for part in parts:
		if part is Model.RenderCall: result.append_array(_tokens(part.original))
		elif part is Model.Code:
			var lexer := Lexer.new(file)
			var cursor: int = part.span.start.index
			while cursor<part.span.end.index:
				var token = lexer.next_token(cursor)
				if token==null: break
				cursor = token.span.end.index
				if token.kind not in ["whitespace","newline","comment","continuation"]: result.append(token)
	return result
func _code(span):
	var code := Model.Code.new()
	code.span = span
	return code
func _slice(parts: Array, start: int, end: int) -> Array:
	var output: Array = []
	for part in parts:
		if part.span.end.index<=start or part.span.start.index>=end: continue
		output.append(_code(file.span(maxi(start,part.span.start.index),mini(end,part.span.end.index))) if part is Model.Code else part)
	return output
func _type(name: String, offset: int, own: bool = false) -> String:
	var scope: int = 0 if own else lexical._scope(offset)
	while scope>=0:
		var selected = null
		for symbol in lexical.symbols:
			if symbol.name==name and symbol.scope==scope and (symbol.span.start.index<=offset or scope==0) and (selected==null or symbol.span.start.index>selected.span.start.index): selected = symbol
		if selected!=null:
			for declaration in declarations:
				if declaration.offset==selected.span.start.index: return declaration.type
			return ""
		scope = lexical.scopes[scope].parent
	return ""
func _rewrite(parts: Array) -> Array:
	for part in parts:
		if part is Model.GdExpression: part.parts.assign(_rewrite(part.parts))
		elif part is Model.Component:
			for attribute in part.attributes:
				if attribute.value is Model.GdExpression: attribute.value.parts.assign(_rewrite(attribute.value.parts))
			part.children.assign(_rewrite(part.children))
	var tokens := _tokens(parts)
	var writes: Array = []
	for index in range(1,tokens.size()-1):
		if tokens[index].text!="=": continue
		var start := index-1
		while start>0 and tokens[start-1].span.start.line==tokens[index].span.start.line and tokens[start-1].text!=";": start -= 1
		if tokens[start].text!="var":
			for cursor in range(start,index):
				if tokens[cursor].text==":": start = cursor+1
		var declaration: bool = tokens[start].text=="var"
		var name: String = tokens[start+1].text if declaration else tokens[start].text
		var type := _type(name,tokens[index].span.start.index)
		if name=="self" and start+2<index: type = _type(tokens[start+2].text,tokens[index].span.start.index,true)
		if type.is_empty(): continue
		var end := index+1
		var depth := 0
		while end<tokens.size():
			if depth==0 and (tokens[end].text==";" or end>index+1 and tokens[end].span.start.line>tokens[end-1].span.end.line): break
			if tokens[end].text in ["(","[","{"]: depth += 1
			elif tokens[end].text in [")","]","}"]: depth -= 1
			end += 1
		var write := Model.DataWrite.new()
		write.span = file.span(tokens[start].span.start.index,tokens[end-1].span.end.index)
		write.expression.assign(_slice(parts,tokens[index+1].span.start.index,write.span.end.index))
		if not declaration and tokens[index-2].text==".":
			write.field = tokens[index-1].text
			write.owner.assign(_slice(parts,tokens[start].span.start.index,tokens[index-2].span.start.index))
		else:
			write.prefix.assign(_slice(parts,write.span.start.index,tokens[index+1].span.start.index))
			write.descriptor = type
			write.previous = "null" if declaration else name
		writes.append(write)
	if parts.is_empty(): return parts
	var output: Array = []
	var cursor: int = parts[0].span.start.index
	for write in writes:
		if write.span.start.index<cursor: continue
		output.append_array(_slice(parts,cursor,write.span.start.index))
		output.append(write)
		cursor = write.span.end.index
	output.append_array(_slice(parts,cursor,parts[-1].span.end.index))
	return output
