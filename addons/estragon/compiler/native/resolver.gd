@tool
extends RefCounted
## Static Node type metadata. Never instantiate authored classes or use editor/tree.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Parser = preload("res://addons/estragon/compiler/parser.gd")
const Bindable = preload("res://addons/estragon/compiler/bindable.gd")
var visiting: Dictionary = {}
var file
var aliases: Dictionary = {}
var globals: Dictionary = {}

func _init(source) -> void:
	file = source
	for item in ProjectSettings.get_global_class_list(): globals[str(item["class"])] = str(item.path)

func scan(module: Model.Module) -> void:
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
			if not path.is_absolute_path():
				var output: String = file.name.get_base_dir().path_join("generated").path_join(file.name.get_file().get_basename() + ".gd")
				path = output.get_base_dir().path_join(path).simplify_path()
			if not path.begins_with("res://"): path = "res://" + path
			aliases[name] = path

func resolve(name: String, span: Model.Span) -> Dictionary:
	if aliases.has(name):
		if ClassDB.class_exists(name) or globals.has(name) and globals[name] != aliases[name]:
			return _fail("Ambiguous GGX preload alias " + name, span)
		return _script(name, aliases[name], span)
	if globals.has(name): return _script(name, globals[name], span)
	if not ClassDB.class_exists(name): return _fail("Unknown Node GGX component %s; use a native class or explicit preload alias" % JSON.stringify(name), span)
	if not ClassDB.is_parent_class(name, "Node") or not ClassDB.can_instantiate(name):
		return _fail("Unknown or non-constructible Node GGX type " + name, span)
	return {"native": name, "script": null}

func _script(name: String, path: String, span: Model.Span) -> Dictionary:
	var authored := path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo")
	if path.get_base_dir().get_file()=="generated" and FileAccess.file_exists(authored): return _gogo(name,path,authored,span)
	if not ResourceLoader.exists(path, "GDScript"): return _fail("GGX script import not found: " + path, span)
	var script: Script = load(path)
	# CACHE_MODE_IGNORE still changes GDScript's internal cache on tested Godot.
	# Never mutate an application's live Script during metadata analysis.
	if script is GDScript and script.source_code.replace("\r\n","\n") != FileAccess.get_file_as_string(path).replace("\r\n","\n"):
		return _fail("Imported Script has unsynchronized disk/cache source; reload it in Godot before compiling GGX: " + path, span)
	if not script is GDScript or not script.can_instantiate() or not ClassDB.is_parent_class(script.get_instance_base_type(), "Node"):
		return _fail("GGX hierarchy script must be a constructible Node: " + name, span)
	for method in script.get_script_method_list():
		if method.name == "_init" and method.args.size() > method.default_args.size():
			return _fail("GGX construction requires a zero-argument initializer: " + name, span)
	return {"native": script.get_instance_base_type(), "script": script}

func _gogo(name: String, path: String, authored: String, span: Model.Span) -> Dictionary:
	if visiting.has(path): return _fail("Cyclic Gogo component inheritance: "+path,span)
	visiting[path] = true
	var source := Source.new(FileAccess.get_file_as_string(authored),authored)
	var module = Parser.new(source).parse()
	if module != null: Bindable.new(source).apply(module)
	if module == null or not source.diagnostics.is_empty():
		visiting.erase(path)
		return _fail("Invalid authored Gogo component metadata: "+authored,span)
	var imported = get_script().new(source)
	imported.visiting = visiting
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
	for index in range(tokens.size()-1):
		if tokens[index].text!="extends" or tokens[index].span.start.column!=1: continue
		var target = tokens[index+1]
		if target.kind=="string":
			var literal: String = target.text.substr(1,target.text.length()-2)
			if not literal.is_absolute_path(): literal = path.get_base_dir().path_join(literal).simplify_path()
			base = imported._script(name,literal,span)
		else: base = imported.resolve(target.text,span)
		break
	visiting.erase(path)
	if base.is_empty(): return _fail("Gogo component requires an explicit constructible Node base: "+authored,span)
	var properties: Dictionary = base.get("properties",{}).duplicate()
	var signals: Dictionary = base.get("signals",{}).duplicate()
	var declarations: Array = []
	for index in range(tokens.size()-3):
		var token = tokens[index]
		if token.text=="func" and token.span.start.column==1 and tokens[index+1].text=="_init":
			var depth := 1
			var parameter := false
			var optional := false
			for item in tokens.slice(index+3):
				if item.text in ["(","[","{"]: depth += 1
				elif item.text in [")","]","}"]:
					depth -= 1
					if depth==0:
						if parameter and not optional: return _fail("GGX construction requires a zero-argument initializer: "+name,span)
						break
				elif depth==1:
					if item.text=="=": optional = true
					elif item.text==",":
						if parameter and not optional: return _fail("GGX construction requires a zero-argument initializer: "+name,span)
						parameter = false
						optional = false
					else: parameter = true
		if token.text=="signal" and token.span.start.column==1: signals[tokens[index+1].text] = {"name":tokens[index+1].text}
		if token.text!="var" or token.span.start.column!=1 or tokens[index+2].text!=":": continue
		var end: int = index+3
		while end+1<tokens.size() and tokens[end+1].span.start.line==token.span.start.line and tokens[end+1].text not in ["=",":"]: end += 1
		declarations.append({"name":tokens[index+1].text,"type_name":source.text.substr(tokens[index+3].span.start.index,tokens[end].span.end.index-tokens[index+3].span.start.index),"signal_name":""})
	for part in module.parts:
		if part is Model.Bindable: declarations.append(part)
	for part in declarations:
		var type: String = part.type_name
		var kind: int = {"bool":TYPE_BOOL,"int":TYPE_INT,"float":TYPE_FLOAT,"String":TYPE_STRING,"StringName":TYPE_STRING_NAME,"Vector2":TYPE_VECTOR2,"Vector2i":TYPE_VECTOR2I,"Rect2":TYPE_RECT2,"Rect2i":TYPE_RECT2I,"Vector3":TYPE_VECTOR3,"Vector3i":TYPE_VECTOR3I,"Transform2D":TYPE_TRANSFORM2D,"Vector4":TYPE_VECTOR4,"Vector4i":TYPE_VECTOR4I,"Plane":TYPE_PLANE,"Quaternion":TYPE_QUATERNION,"AABB":TYPE_AABB,"Basis":TYPE_BASIS,"Transform3D":TYPE_TRANSFORM3D,"Projection":TYPE_PROJECTION,"Color":TYPE_COLOR,"NodePath":TYPE_NODE_PATH,"RID":TYPE_RID,"Callable":TYPE_CALLABLE,"Signal":TYPE_SIGNAL,"Dictionary":TYPE_DICTIONARY,"Array":TYPE_ARRAY,"PackedByteArray":TYPE_PACKED_BYTE_ARRAY,"PackedInt32Array":TYPE_PACKED_INT32_ARRAY,"PackedInt64Array":TYPE_PACKED_INT64_ARRAY,"PackedFloat32Array":TYPE_PACKED_FLOAT32_ARRAY,"PackedFloat64Array":TYPE_PACKED_FLOAT64_ARRAY,"PackedStringArray":TYPE_PACKED_STRING_ARRAY,"PackedVector2Array":TYPE_PACKED_VECTOR2_ARRAY,"PackedVector3Array":TYPE_PACKED_VECTOR3_ARRAY,"PackedColorArray":TYPE_PACKED_COLOR_ARRAY}.get(type,TYPE_OBJECT)
		if type.begins_with("Array["): kind = TYPE_ARRAY
		properties[part.name] = {"name":part.name,"type":kind,"class_name":(type if ClassDB.class_exists(type) else name+"."+type) if kind==TYPE_OBJECT else "","usage":PROPERTY_USAGE_DEFAULT}
		if not part.signal_name.is_empty(): signals[part.signal_name] = {"name":part.signal_name}
	return {"native":base.native,"script":base.script,"properties":properties,"signals":signals}

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
