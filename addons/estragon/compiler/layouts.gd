@tool
extends RefCounted
## Lexical component presets. Scope boundaries come from native tokens/indentation,
## never markup substitutions or evaluation of authored expressions.
const Source = preload("source.gd")
const Parser = preload("parser.gd")
const Model = preload("model.gd")
const Lexer = preload("lexer.gd")
const Resolver = preload("native/resolver.gd")
const Definition = preload("../runtime/node/internal/grid_definition.gd")
const Grid = preload("../runtime/node/grid.gd")
const Box = preload("../runtime/node/box.gd")
var visiting: Dictionary = {}
var file
var module
var resolver
var tokens: Array = []
var scopes: Array = [{"start":0,"end":0,"indent":0,"parent":-1}]
var symbols: Array = []
func _init(source) -> void: file = source
func apply(value) -> void:
	module = value
	# Qualified instance exports can be used by modules without declarations too.
	if not module.parts.any(func(part): return part is Model.Layout) and not _has_qualified(module.parts): return
	resolver = Resolver.new(file)
	resolver.scan(module)
	if not file.diagnostics.is_empty(): return
	_index()
	for part in module.parts:
		if part is Model.Layout: _declaration(part)
		if not file.diagnostics.is_empty(): return
	_references(module.parts)

func _error(message: String, span) -> void:
	file.fail(message,span.start.index,span.end.index)
func _unique() -> String:
	var name := "_GogoLayout_"+str(module.presets.size())
	while module.identifiers.has(name): name += "_"
	module.identifiers.append(name)
	return name
func _index() -> void:
	var anchors: Array = []
	var lexer := Lexer.new(file)
	for part in module.parts:
		if part is Model.Layout:
			anchors.append(part.span.start)
			continue
		if not part is Model.Code: continue
		var cursor: int = part.span.start.index
		var depth := 0
		while cursor<part.span.end.index:
			var token = lexer.next_token(cursor)
			if token==null: return
			cursor = token.span.end.index
			if token.kind in ["whitespace","newline","comment","continuation"]: continue
			tokens.append(token)
			var prefix: String = file.text.substr(file.line_start(token.span.start.line),token.span.start.index-file.line_start(token.span.start.line))
			if depth==0 and prefix.strip_edges().is_empty(): anchors.append(token.span.start)
			if token.text in ["(","[","{"]: depth += 1
			elif token.text in [")","]","}"]: depth -= 1
	anchors.sort_custom(func(a,b): return a.index<b.index)
	scopes[0].end = file.text.length()+1
	var stack: Array = [0]
	for point in anchors:
		var indent: int = point.column-1
		while scopes[stack[-1]].indent>indent:
			scopes[stack.pop_back()].end = point.index
		if indent>scopes[stack[-1]].indent:
			var index := scopes.size()
			scopes.append({"start":point.index,"end":file.text.length()+1,"indent":indent,"parent":stack[-1]})
			stack.append(index)
	_parameters()
	for index in range(tokens.size()-1):
		if tokens[index].text in ["var","const","func","class","signal","for"] and tokens[index+1].kind=="identifier":
			symbols.append({"name":tokens[index+1].text,"span":tokens[index+1].span,"scope":_scope(tokens[index].span.start.index),"kind":tokens[index].text})
func _scope(offset: int) -> int:
	var selected := 0
	for index in range(1,scopes.size()):
		if offset>=scopes[index].start and offset<scopes[index].end and scopes[index].indent>scopes[selected].indent: selected = index
	return selected
func _visible(name: String, offset: int, own: bool = false):
	var scope := 0 if own else _scope(offset)
	while scope>=0:
		var found = null
		for binding in module.presets:
			if binding.name==name and binding.scope==scope and binding.visible<=offset and (found==null or binding.visible>found.visible): found = binding
		for symbol in symbols:
			if symbol.name==name and symbol.scope==scope and symbol.span.start.index<offset and (found==null or symbol.span.start.index>found.visible): return null
		if found!=null: return found
		scope = scopes[scope].parent
	return null
func _declaration(layout) -> void:
	var scope := _scope(layout.span.start.index)
	if layout.exported and scope!=0:
		_error("export layout is only valid at module scope",layout.span)
		return
	var root = layout.root
	if not root.name.is_valid_identifier() or root.name in Lexer.KEYWORDS:
		_error("layout bindings require unqualified Gogo identifiers; import a qualified component under an explicit alias",root.name_span)
		return
	var rows: Array = []
	var groups := {}
	var line := -1
	for child in root.children:
		if child is Model.Literal and str(child.value).strip_edges().is_empty(): continue
		if not child is Model.Component or not child.children.is_empty():
			_error("layout body requires an area matrix of empty named tags",child.span)
			return
		if not child.name.is_valid_identifier() or child.name in Lexer.KEYWORDS or child.name==root.name:
			_error("layout area requires a distinct unqualified identifier",child.name_span)
			return
		if line!=child.span.start.line:
			rows.append([])
			line = child.span.start.line
		rows[-1].append(child.name)
		if not groups.has(child.name): groups[child.name] = []
		groups[child.name].append(child)
	if rows.is_empty():
		_error("layout requires at least one area row",root.span)
		return
	var areas: Array = []
	for row in rows: areas.append(" ".join(row))
	var canonical := Definition.normalize(rows[0].size(),rows.size(),areas)
	if canonical.has("error"):
		_error("layout matrix: "+canonical.error,root.span)
		return
	# All bases are resolved before this declaration's new bindings are visible.
	var pending: Array = []
	var root_binding = _binding(root,[root],layout,scope,true)
	if root_binding==null: return
	root_binding.generated = {"direction":"grid","columns":rows[0].size(),"rows":null,"template":"","areas":areas}
	pending.append(root_binding)
	for name in groups:
		var binding = _binding(groups[name][0],groups[name],layout,scope,false)
		if binding==null: return
		binding.generated = {"area":name}
		pending.append(binding)
	layout.bindings = pending
	module.presets.append_array(pending)

func _binding(node, groups: Array, layout, scope: int, root: bool):
	var binding := Model.Preset.new()
	binding.name = node.name
	binding.span = node.name_span
	binding.scope = scope
	binding.visible = layout.span.end.index
	binding.mutable = layout.mutable
	binding.exported = layout.exported
	binding.groups = groups
	# Reserve immediately; the pending bindings are not yet lookup-visible.
	binding.symbol = "_GogoLayout_"+str(module.identifiers.size())
	while module.identifiers.has(binding.symbol): binding.symbol += "_"
	module.identifiers.append(binding.symbol)
	if layout.exported and (ClassDB.class_exists(node.name) or resolver.globals.has(node.name)):
		_error("Cannot export a preset under a native/global class name; choose an explicit local alias: "+node.name,node.name_span)
		return null
	if layout.exported and resolver.aliases.has(node.name) and not module.import_aliases.has(node.name):
		var private_import := "_GogoImport_"+str(module.import_aliases.size())
		while module.identifiers.has(private_import): private_import += "_"
		module.identifiers.append(private_import)
		module.import_aliases[node.name] = private_import
	var previous = _visible(node.name,layout.span.start.index)
	if previous==null: previous = _alias_before(node.name,layout.span.start.index)
	if previous!=null:
		if layout.exported and previous.symbol==node.name and previous.groups.is_empty():
			previous.symbol = binding.symbol+"_base"
			module.identifiers.append(previous.symbol)
			for symbol in symbols:
				if symbol.name==node.name and symbol.span.start.index<previous.visible: module.identifier_imports.append({"span":symbol.span,"alias":previous.symbol})
		binding.base = previous.symbol
		binding.resolved = previous.resolved
	else:
		var authored = _native_before(node.name,layout.span.start.index)
		var imported: bool = authored!=null and authored.kind=="const" and authored.scope==0 and (resolver.aliases.has(node.name) or resolver.native_aliases.has(node.name))
		var project = resolver.scope()
		var candidates: Array = project.named(node.name).filter(func(path): return path!=project.authored(file.name))
		var known: bool = imported or resolver.globals.has(node.name) or ClassDB.class_exists(node.name) or not candidates.is_empty()
		if authored!=null and not imported:
			_error("layout base collides with a non-component binding: "+node.name,node.name_span)
			return null
		if known:
			binding.resolved = resolver.resolve(node.name,node.name_span)
			if binding.resolved.is_empty(): return null
			binding.base = binding.resolved.get("project_alias",binding.resolved.get("runtime_alias",binding.resolved.get("native_alias",node.name)))
		else:
			var script = Grid if root else Box
			binding.resolved = {"native":"Node2D","script":script}
			var path: String = script.resource_path
			if not module.project_imports.has(path): module.project_imports[path] = {"alias":_unique(),"span":node.name_span}
			binding.base = module.project_imports[path].alias
			binding.resolved.runtime_alias = binding.base
	if root and not Definition.marked(binding.resolved.script):
		_error("layout root base must support native Grid properties; use a Grid-derived component",node.name_span)
		return null
	var literals := {}
	for group in groups:
		var seen := {}
		for attribute in group.attributes:
			if attribute.name in ["key","bind:value"]:
				_error("layout defaults cannot preset key or bind:value; author instance controls at the use site",attribute.name_span)
				return null
			if attribute.kind=="spread": continue
			if seen.has(attribute.name):
				_error("Duplicate layout default "+attribute.name,attribute.name_span)
				return null
			seen[attribute.name] = true
			var constant := _constant(attribute.value)
			if constant.known:
				if literals.has(attribute.name) and (typeof(literals[attribute.name])!=typeof(constant.value) or literals[attribute.name]!=constant.value):
					_error("Conflicting repeated layout default "+attribute.name,attribute.name_span)
					return null
				literals[attribute.name] = constant.value
	return binding

func _references(parts: Array) -> void:
	for part in parts:
		if part is Model.Code: _code(part.span)
		elif part is Model.Bindable: _code(part.declaration_span)
		elif part is Model.GdExpression: _references(part.parts)
		elif part is Model.Layout:
			for binding in part.bindings:
				for group in binding.groups:
					for attr in group.attributes:
						if attr.value is Model.GdExpression: _references(attr.value.parts)
		elif part is Model.Component:
			part.preset = _visible(part.name,part.name_span.start.index)
			if part.preset==null and not part.name.contains("."): part.preset = _alias_before(part.name,part.name_span.start.index)
			if part.preset==null and part.name.contains("."): part.preset = _qualified(part.name,part.name_span)
			if part.preset==null and _parameter_hidden(part.name,part.name_span.start.index):
				_error("Component preset is hidden by a native parameter: "+part.name,part.name_span)
				return
			for attr in part.attributes:
				if attr.value is Model.GdExpression: _references(attr.value.parts)
			_references(part.children)
func _code(span) -> void:
	var lexer := Lexer.new(file)
	var items: Array = []
	var cursor: int = span.start.index
	while cursor<span.end.index:
		var token = lexer.next_token(cursor)
		if token==null: return
		cursor = token.span.end.index
		if token.kind not in ["whitespace","newline","comment","continuation"]: items.append(token)
	for index in range(items.size()):
		var token = items[index]
		if token.kind!="identifier": continue
		if index>0 and items[index-1].text=="." and (index<2 or items[index-2].text!="self"): continue
		if index+1<items.size() and items[index+1].text=="=" and index>0 and items[index-1].text in ["{",","]: continue
		var binding = _visible(token.text,token.span.start.index,index>1 and items[index-1].text=="." and items[index-2].text=="self")
		if binding==null: continue
		if index>0 and items[index-1].text=="." and binding.scope!=0: continue
		if index>0 and items[index-1].text in ["var","const","func","class","signal","for"]: continue
		if symbols.any(func(item): return item.kind=="parameter" and item.span.start.index==token.span.start.index): continue
		if not binding.mutable and index+1<items.size() and items[index+1].text in ["=","+=","-=","*=","/=","%=","&=","|=","^=","**=","<<=",">>="]:
			_error("Cannot assign to layout const "+token.text,token.span)
			return
		module.identifier_imports.append({"span":token.span,"alias":binding.symbol})

func _has_qualified(parts: Array) -> bool:
	for part in parts:
		if part is Model.Component:
			if part.name.contains(".") or _has_qualified(part.children): return true
			for attr in part.attributes:
				if attr.value is Model.GdExpression and _has_qualified(attr.value.parts): return true
		elif part is Model.GdExpression and _has_qualified(part.parts): return true
	return false
func _qualified(name: String, span):
	var path := name.split(".")
	if path.size()!=2:
		_error("Qualified preset tags require a typed host instance and exported binding",span)
		return null
	if path[0]=="self":
		var own = _visible(path[1],span.start.index,true)
		if own!=null and own.scope==0: return own
		_error("Unknown lexical component preset "+name,span)
		return null
	var type := ""
	var receiver := path[0]
	for index in range(tokens.size()-2):
		if tokens[index].text==receiver and tokens[index+1].text==":" and tokens[index+2].kind=="identifier" and tokens[index].span.start.index<span.start.index:
			var declared = _native_before(receiver,span.start.index)
			if declared!=null and declared.span.start.index==tokens[index].span.start.index: type = tokens[index+2].text
	if not resolver.aliases.has(type):
		_error("Qualified preset tags require a typed Gogo host instance; use an explicit preload alias for native component types",span)
		return null
	var output: String = resolver.aliases[type]
	var authored: String = output.get_base_dir().get_base_dir().path_join(output.get_file().get_basename()+".gogo")
	if not FileAccess.file_exists(authored):
		_error("Qualified preset host has no authored Gogo source: "+type,span)
		return null
	if visiting.has(authored):
		_error("Cyclic exported layout composition: "+authored,span)
		return null
	visiting[authored] = true
	var project = resolver.scope()
	var source_key: String = project.authored(authored)
	var text: String = project.read(source_key) if project.sources.has(source_key) else FileAccess.get_file_as_string(authored)
	var source := Source.new(text,authored,output,file.project)
	var parsed = Parser.new(source).parse()
	if parsed!=null:
		var layouts = get_script().new(source)
		layouts.visiting = visiting
		layouts.apply(parsed)
	visiting.erase(authored)
	if parsed==null or not source.diagnostics.is_empty():
		_error("Invalid exported layout source: "+authored+("; "+source.diagnostics[0].message if not source.diagnostics.is_empty() else ""),span)
		return null
	var exported = null
	for binding in parsed.presets:
		if binding.name==path[1] and binding.exported and binding.scope==0: exported = binding
	if exported==null:
		_error("Unknown or unexported layout binding "+name,span)
		return null
	# Metadata is lexical; runtime reads the existing host's public value. No
	# exporting host is ever instantiated by the compiler or by an import.
	var result := Model.Preset.new()
	result.name = name
	result.symbol = name
	result.span = span
	result.resolved = exported.resolved.duplicate(true)
	var script: Script = result.resolved.script
	var resource: String = result.resolved.get("gogo_path",script.resource_path if script!=null else "")
	if not resource.is_empty():
		if not module.project_imports.has(resource): module.project_imports[resource] = {"alias":_unique(),"span":span}
		var alias: String = module.project_imports[resource].alias
		var previous: String = result.resolved.get("project_alias",result.resolved.get("runtime_alias",""))
		for property in result.resolved.get("properties",{}).values():
			var qualified: String = str(property.get("class_name",""))
			if not previous.is_empty() and (qualified==previous or qualified.begins_with(previous+".")): property["class_name"] = alias+qualified.trim_prefix(previous)
		result.resolved.project_alias = alias
	return result

func _alias_before(name: String, offset: int):
	var declaration := -1
	for index in range(tokens.size()-5):
		if tokens[index].text in ["var","const"] and tokens[index+1].text==name and tokens[index+2].text=="=" and tokens[index+3].kind=="identifier" and tokens[index+4].text=="." and tokens[index+5].kind=="identifier" and tokens[index].span.start.index<offset:
			var candidate_scope := _scope(tokens[index].span.start.index)
			var scope := _scope(offset)
			while scope>=0 and scope!=candidate_scope: scope = scopes[scope].parent
			if scope>=0: declaration = index
	if declaration<0: return null
	var first = tokens[declaration+3]
	var last = tokens[declaration+5]
	var value = _qualified(first.text+"."+last.text,file.span(first.span.start.index,last.span.end.index))
	if value==null: return null
	value.name = name
	value.symbol = name
	value.visible = last.span.end.index
	value.scope = _scope(first.span.start.index)
	value.mutable = tokens[declaration].text=="var"
	module.presets.append(value)
	return value

func _parameters() -> void:
	for index in range(tokens.size()-2):
		if tokens[index].text!="func": continue
		var opening := index+1
		if tokens[opening].kind=="identifier": opening += 1
		if opening>=tokens.size() or tokens[opening].text!="(": continue
		var depth := 0
		var closing := -1
		var parameters: Array = []
		for cursor in range(opening,tokens.size()):
			var token = tokens[cursor]
			if token.text in ["(","[","{"]: depth += 1
			elif token.text in [")","]","}"]:
				depth -= 1
				if depth==0:
					closing = cursor
					break
			elif depth==1 and token.kind=="identifier" and tokens[cursor-1].text in ["(",","]: parameters.append(token)
		if closing<0: continue
		var colon := closing+1
		while colon<tokens.size() and tokens[colon].text!=":": colon += 1
		if colon>=tokens.size(): continue
		var parent := _scope(tokens[index].span.start.index)
		var scope := -1
		if colon+1<tokens.size() and tokens[colon+1].span.start.line==tokens[colon].span.start.line:
			scope = scopes.size()
			scopes.append({"start":tokens[colon].span.end.index,"end":file.line_start(tokens[colon].span.end.line+1),"indent":scopes[parent].indent+1,"parent":parent})
		else:
			for candidate in range(scopes.size()):
				if scopes[candidate].parent==parent and scopes[candidate].start>tokens[colon].span.end.index and (scope<0 or scopes[candidate].start<scopes[scope].start): scope = candidate
		if scope<0: continue
		for parameter in parameters: symbols.append({"name":parameter.text,"span":parameter.span,"scope":scope,"kind":"parameter"})

func _parameter_hidden(name: String, offset: int) -> bool:
	var scope := _scope(offset)
	while scope>=0:
		for symbol in symbols:
			if symbol.name==name and symbol.scope==scope and symbol.kind=="parameter": return true
		scope = scopes[scope].parent
	return false

func _constant(value) -> Dictionary:
	if value is Model.Literal: return {"known":true,"value":value.value}
	if not value is Model.GdExpression or value.parts.size()!=1 or not value.parts[0] is Model.Code: return {"known":false}
	var text: String = file.slice(value.parts[0].span).strip_edges()
	if text.is_valid_int(): return {"known":true,"value":int(text)}
	if text.is_valid_float(): return {"known":true,"value":float(text)}
	if text in ["true","false","null"]: return {"known":true,"value":str_to_var(text)}
	return {"known":false}

func _native_before(name: String, offset: int):
	var scope := _scope(offset)
	while scope>=0:
		var latest = null
		for symbol in symbols:
			if symbol.name==name and symbol.scope==scope and symbol.span.start.index<offset and (latest==null or symbol.span.start.index>latest.span.start.index): latest = symbol
		if latest!=null: return latest
		scope = scopes[scope].parent
	return null
