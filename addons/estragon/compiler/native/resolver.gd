@tool
extends RefCounted
## Static Node type metadata. Never instantiate authored classes or use editor/tree.
const Model = preload("../model.gd")
const Lexer = preload("../lexer.gd")
const Source = preload("../source.gd")
const Parser = preload("../parser.gd")
const Bindable = preload("../bindable.gd")
const ProjectSources = preload("../project_sources.gd")
var visiting: Dictionary = {}
var file
var aliases: Dictionary = {}
var native_aliases: Dictionary = {}
var globals: Dictionary = {}
var symbols: Dictionary = {}
var project
var _module
var source_only := false

func _init(source) -> void:
	file = source
	project = source.project
	# Native filesystem refresh can retain a deleted class cache entry. Never
	# let a missing Script reserve a name or fall back to its cached executable.
	for item in ProjectSettings.get_global_class_list():
		if FileAccess.file_exists(str(item.path)): globals[str(item["class"])] = str(item.path)

func scan(module: Model.Module) -> void:
	_module = module
	# Only top-level lexical declarations in authored Code ranges are imports.
	# No evaluation or regex parsing of mixed source.
	for part in module.parts:
		if not part is Model.Code: continue
		var lexer := Lexer.new(file)
		var tokens: Array = []
		var cursor: int = part.span.start.index
		while cursor < part.span.end.index:
			var token = lexer.next_token(cursor)
			if token == null: return
			cursor = token.span.end.index
			if token.kind not in ["whitespace", "comment", "newline", "continuation"]: tokens.append(token)
		for index in range(tokens.size()-1):
			if tokens[index].text in ["var","const","func","signal","class","class_name","for"] and tokens[index+1].kind == "identifier": symbols[tokens[index+1].text] = true
			if index>0 and tokens[index].text == ":" and tokens[index-1].kind == "identifier": symbols[tokens[index-1].text] = true
		for index in range(tokens.size() - 5):
			var token = tokens[index]
			if token.text != "const" or file.text.substr(file.line_start(token.span.start.line), token.span.start.index - file.line_start(token.span.start.line)) != "": continue
			var name: String = tokens[index + 1].text
			var next: int = index + 2
			# Optional explicit Script/GDScript annotation.
			if tokens[next].text == ":": next += 2
			if next + 4 >= tokens.size() or tokens[next].text != "=" or tokens[next + 1].text != "preload" or tokens[next + 2].text != "(" or tokens[next + 3].kind != "string" or tokens[next + 4].text != ")": continue
			if aliases.has(name):
				file.fail("Ambiguous duplicate preload alias " + name, tokens[index + 1].span.start.index)
				return
			var raw: String = tokens[next + 3].text
			# Godot decodes only a lexer-proven string literal, never application code.
			var literal := GDScript.new()
			literal.source_code = "@tool\nextends RefCounted\nstatic func value() -> String:\n\treturn " + raw + "\n"
			if literal.reload() != OK:
				file.fail("Invalid preload path literal", tokens[next + 3].span.start.index)
				return
			var path: String = literal.call("value")
			if path.begins_with("uid://"):
				var uid := ResourceUID.text_to_id(path)
				if not ResourceUID.has_id(uid):
					file.fail("Unknown preload UID: "+path,tokens[next+3].span.start.index)
					return
				path = ResourceUID.get_id_path(uid)
			elif not path.is_absolute_path():
				var output: String = file.generated_path()
				path = output.get_base_dir().path_join(path).simplify_path()
			if not path.is_absolute_path(): path = "res://" + path
			aliases[name] = path.simplify_path()
		for index in range(tokens.size()-3):
			if tokens[index].text!="const" or tokens[index].span.start.column!=1 or tokens[index+2].text!="=": continue
			var target: String = tokens[index+3].text
			if index+4<tokens.size() and tokens[index+4].span.start.line==tokens[index+3].span.start.line: continue
			if ClassDB.class_exists(target): native_aliases[tokens[index+1].text] = target

func scope():
	if project == null: project = ProjectSources.new()
	return project

func resolve(name: String, span: Model.Span, project_tags: bool = true) -> Dictionary:
	if native_aliases.has(name):
		var native: String = native_aliases[name]
		if not ClassDB.is_parent_class(native,"Node") or not ClassDB.can_instantiate(native): return _fail("Non-constructible native alias "+name,span)
		return {"native":native,"script":null,"native_alias":native}
	if aliases.has(name):
		if ClassDB.class_exists(name):
			return _fail("Ambiguous GGX preload alias " + name, span)
		var explicit := _script(name,aliases[name],span,project_tags)
		return _import(name,explicit,explicit.get("gogo_path",""),span) if project_tags else explicit
	if project_tags:
		var candidates: Array = scope().named(name)
		if not project.errors.is_empty(): return _fail("Cannot index project Gogo sources: "+str(project.errors),span)
		if not candidates.is_empty():
			var same_global: bool = candidates.size()==1 and globals.get(name,"")==project.resource(ProjectSources.output_for(candidates[0]))
			if candidates.size()!=1 or symbols.has(name) or ClassDB.class_exists(name) or globals.has(name) and not same_global:
				return _fail("Ambiguous project Gogo component "+name+": "+", ".join(candidates)+"; select a source with an explicit uniquely named preload alias",span)
			var source: String = candidates[0]
			var path: String = project.resource(ProjectSources.output_for(source))
			if project.authored(file.name) == source: return _fail("Self-reference in Gogo component "+source,span)
			var result := _gogo(name,path,project.resource(source),span)
			return _import(name,result,path,span)
	if globals.has(name):
		var global := _script(name,globals[name],span,project_tags)
		return _import(name,global,global.get("gogo_path",""),span) if project_tags else global
	if not ClassDB.class_exists(name): return _fail("Unknown Node GGX component %s; use a native class or explicit preload alias" % JSON.stringify(name), span)
	if not ClassDB.is_parent_class(name, "Node") or not ClassDB.can_instantiate(name):
		return _fail("Unknown or non-constructible Node GGX type " + name, span)
	return {"native": name, "script": null}

func _import(name: String, result: Dictionary, path: String, span: Model.Span) -> Dictionary:
	if result.is_empty() or path.is_empty(): return result
	var alias: String
	if _module.project_imports.has(path): alias = _module.project_imports[path].alias
	else:
		alias = "_GogoProject_"+str(_module.project_imports.size())
		while _module.identifiers.has(alias): alias += "_"
		_module.identifiers.append(alias)
		_module.project_imports[path] = {"alias":alias,"span":span}
	result.project_alias = alias
	for property in result.get("properties",{}).values():
		if str(property.get("class_name",""))==name or str(property.get("class_name","")).begins_with(name+"."): property["class_name"] = alias+str(property["class_name"]).trim_prefix(name)
	return result

func _script(name: String, path: String, span: Model.Span, check_constructor: bool = true) -> Dictionary:
	var authored := path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo")
	if path.get_base_dir().get_file()=="generated":
		if FileAccess.file_exists(authored): return _gogo(name,path,authored,span,check_constructor)
		if FileAccess.file_exists(path+".map.json"): return _fail("Missing authored Gogo source for "+path,span)
	# Completion uses the same lexical metadata walk for ordinary Script bases;
	# it must not load authored scripts (including their static initializers).
	if source_only and FileAccess.file_exists(path): return _gogo(name,path,path,span,check_constructor)
	if not ResourceLoader.exists(path, "GDScript"): return _fail("GGX script import not found: " + path, span)
	var script: Script = load(path)
	# CACHE_MODE_IGNORE still changes GDScript's internal cache on tested Godot.
	# Never mutate an application's live Script during metadata analysis.
	if script is GDScript and script.source_code.replace("\r\n","\n") != FileAccess.get_file_as_string(path).replace("\r\n","\n"):
		return _fail("Imported Script has unsynchronized disk/cache source; reload it in Godot before compiling GGX: " + path, span)
	if not script is GDScript or not ClassDB.is_parent_class(script.get_instance_base_type(), "Node") or not ClassDB.can_instantiate(script.get_instance_base_type()):
		return _fail("GGX hierarchy script must be a constructible Node: " + name, span)
	if not Engine.is_editor_hint() and not script.can_instantiate(): return _fail("GGX hierarchy script must be a constructible Node: "+name,span)
	if script.has_method("is_abstract") and script.call("is_abstract"): return _fail("Abstract GGX component: "+name,span)
	var required := false
	for method in script.get_script_method_list():
		if method.name == "_init":
			required = method.args.size() > method.default_args.size()
			break
	if check_constructor and required: return _fail("GGX construction requires a zero-argument initializer: " + name, span)
	return {"native": script.get_instance_base_type(), "script": script,"required_initializer":required}

func _gogo(name: String, path: String, authored: String, span: Model.Span, check_constructor: bool = true) -> Dictionary:
	if visiting.has(path): return _fail("Cyclic Gogo component inheritance: "+path,span)
	visiting[path] = true
	var text: String = scope().read(project.authored(authored)) if project.sources.has(project.authored(authored)) else FileAccess.get_file_as_string(authored)
	var source := Source.new(text,authored,path,project)
	var module = Parser.new(source).parse()
	if module != null: Bindable.new(source).apply(module)
	if module == null or not source.diagnostics.is_empty():
		visiting.erase(path)
		return _fail("Invalid authored Gogo component metadata: "+authored,span)
	var imported = get_script().new(source)
	imported.visiting = visiting
	imported.source_only = source_only
	imported.scan(module)
	var lexer := Lexer.new(source)
	var tokens: Array = []
	var cursor := 0
	while cursor < source.text.length():
		var token = lexer.next_token(cursor)
		if token == null: break
		cursor = token.span.end.index
		if token.kind not in ["whitespace","comment","newline","continuation"]: tokens.append(token)
	var base := {}
	var declared_name := ""
	for index in range(tokens.size()-1):
		if tokens[index].text=="class_name" and tokens[index].span.start.column==1: declared_name = tokens[index+1].text
	for index in range(tokens.size()-1):
		if tokens[index].text!="extends" or tokens[index].span.start.column!=1: continue
		var target = tokens[index+1]
		if target.kind=="string":
			var literal: String = target.text.substr(1,target.text.length()-2)
			if not literal.is_absolute_path(): literal = path.get_base_dir().path_join(literal).simplify_path()
			base = imported._script(name,literal,span,false)
		else: base = imported.resolve(target.text,span,false)
		break
	visiting.erase(path)
	if base.is_empty(): return _fail("Gogo component requires an explicit constructible Node base: "+authored,span)
	if not ClassDB.is_parent_class(base.native,"Node"): return _fail("GGX hierarchy script must be a constructible Node: "+name,span)
	var required: bool = base.get("required_initializer",false)
	var properties: Dictionary = base.get("properties",{}).duplicate()
	var signals: Dictionary = base.get("signals",{}).duplicate()
	var declarations: Array = []
	for index in range(tokens.size()-3):
		var token = tokens[index]
		if token.text == "@" and token.span.start.column == 1 and tokens[index+1].text == "abstract": return _fail("Abstract Gogo component: "+authored,span)
		if token.text=="func" and token.span.start.column==1 and tokens[index+1].text=="_init":
			required = false
			var depth := 1
			var parameter := false
			var optional := false
			for item in tokens.slice(index+3):
				if item.text in ["(","[","{"]: depth += 1
				elif item.text in [")","]","}"]:
					depth -= 1
					if depth==0:
						if parameter and not optional: required = true
						break
				elif depth==1:
					if item.text=="=": optional = true
					elif item.text==",":
						if parameter and not optional: required = true
						parameter = false
						optional = false
					else: parameter = true
		if token.text=="signal" and token.span.start.column==1: signals[tokens[index+1].text] = {"name":tokens[index+1].text}
		var start: int = source.line_start(token.span.start.line)
		if token.text!="var" or source.text.substr(start,1) in [" ","\t"] or tokens[index+2].text!=":": continue
		if index>0 and tokens[index-1].text=="static" and tokens[index-1].span.start.line==token.span.start.line: continue
		var end: int = index+3
		while end+1<tokens.size() and tokens[end+1].span.start.line==token.span.start.line and tokens[end+1].text not in ["=",":"]: end += 1
		declarations.append({"name":tokens[index+1].text,"type_name":source.text.substr(tokens[index+3].span.start.index,tokens[end].span.end.index-tokens[index+3].span.start.index),"signal_name":""})
	for part in module.parts:
		if part is Model.Bindable: declarations.append(part)
	for part in declarations:
		var type: String = part.type_name
		var kind: int = {"bool":TYPE_BOOL,"int":TYPE_INT,"float":TYPE_FLOAT,"String":TYPE_STRING,"StringName":TYPE_STRING_NAME,"Vector2":TYPE_VECTOR2,"Vector2i":TYPE_VECTOR2I,"Rect2":TYPE_RECT2,"Rect2i":TYPE_RECT2I,"Vector3":TYPE_VECTOR3,"Vector3i":TYPE_VECTOR3I,"Transform2D":TYPE_TRANSFORM2D,"Vector4":TYPE_VECTOR4,"Vector4i":TYPE_VECTOR4I,"Plane":TYPE_PLANE,"Quaternion":TYPE_QUATERNION,"AABB":TYPE_AABB,"Basis":TYPE_BASIS,"Transform3D":TYPE_TRANSFORM3D,"Projection":TYPE_PROJECTION,"Color":TYPE_COLOR,"NodePath":TYPE_NODE_PATH,"RID":TYPE_RID,"Callable":TYPE_CALLABLE,"Signal":TYPE_SIGNAL,"Dictionary":TYPE_DICTIONARY,"Array":TYPE_ARRAY,"PackedByteArray":TYPE_PACKED_BYTE_ARRAY,"PackedInt32Array":TYPE_PACKED_INT32_ARRAY,"PackedInt64Array":TYPE_PACKED_INT64_ARRAY,"PackedFloat32Array":TYPE_PACKED_FLOAT32_ARRAY,"PackedFloat64Array":TYPE_PACKED_FLOAT64_ARRAY,"PackedStringArray":TYPE_PACKED_STRING_ARRAY,"PackedVector2Array":TYPE_PACKED_VECTOR2_ARRAY,"PackedVector3Array":TYPE_PACKED_VECTOR3_ARRAY,"PackedColorArray":TYPE_PACKED_COLOR_ARRAY}.get(type,TYPE_OBJECT)
		if type.begins_with("Array["): kind = TYPE_ARRAY
		var qualified := ""
		if kind==TYPE_OBJECT:
			if type==declared_name: qualified = name
			elif ClassDB.class_exists(type.get_slice(".",0)) or imported.globals.has(type.get_slice(".",0)): qualified = type
			else: qualified = name+"."+type
		properties[part.name] = {"name":part.name,"type":kind,"class_name":qualified,"usage":PROPERTY_USAGE_DEFAULT}
		if not part.signal_name.is_empty(): signals[part.signal_name] = {"name":part.signal_name}
	if check_constructor and required: return _fail("GGX construction requires a zero-argument initializer: "+name,span)
	return {"native":base.native,"script":base.script,"properties":properties,"signals":signals,"required_initializer":required,"gogo_path":path}

func _fail(message: String, span: Model.Span) -> Dictionary:
	file.fail(message, span.start.index, span.end.index)
	return {}

# Source-only proof for a writable Gogo path. Native fields never gain an
# observation contract merely because an unrelated signal shares their name.
func bindable_path(module, names: Array) -> bool:
	if names.is_empty(): return false
	for part in module.parts:
		if not part is Model.Bindable or part.name!=names[0]: continue
		if names.size()==1: return part.type_name=="bool"
		var path: String = aliases.get(part.type_name,globals.get(part.type_name,""))
		if path.is_empty(): return false
		var authored := path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo")
		if path.get_base_dir().get_file()!="generated" or not FileAccess.file_exists(authored): return false
		var source := Source.new(FileAccess.get_file_as_string(authored),authored)
		var parsed = Parser.new(source).parse()
		if parsed==null: return false
		Bindable.new(source).apply(parsed)
		if not source.diagnostics.is_empty(): return false
		var imported = get_script().new(source)
		imported.scan(parsed)
		return imported.bindable_path(parsed,names.slice(1))
	return false

# Godot 4.0 reports TYPE_NIL even for typed GDScript signal arguments.
# Recover only this lexical declaration contract; native reload remains the
# semantic authority. Never instantiate a control to inspect its signals.
func signal_contract(script: Script, event: Dictionary) -> Dictionary:
	var args: Array = event.get("args",[])
	if args.size()!=1 or args[0].type!=TYPE_NIL or not script is GDScript: return event
	var source := Source.new(script.source_code,script.resource_path)
	var lexer := Lexer.new(source)
	var tokens: Array = []
	var cursor := 0
	while cursor<source.text.length():
		var token = lexer.next_token(cursor)
		if token==null: return event
		cursor = token.span.end.index
		if token.kind not in ["whitespace","newline","comment","continuation"]: tokens.append(token)
	for index in range(tokens.size()-6):
		if tokens[index].text!="signal" or tokens[index].span.start.column!=1 or tokens[index+1].text!=event.name: continue
		if tokens[index+2].text!="(" or tokens[index+3].kind!="identifier" or tokens[index+4].text!=":" or tokens[index+6].text!=")": return event
		var kind: int = {"bool":TYPE_BOOL,"int":TYPE_INT,"float":TYPE_FLOAT,"String":TYPE_STRING}.get(tokens[index+5].text,TYPE_NIL)
		var result := event.duplicate(true)
		result.args[0].type = kind
		return result
	return event
