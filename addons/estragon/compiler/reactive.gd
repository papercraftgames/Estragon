@tool
extends RefCounted
## Lexical, source-spanned opt-in reads. Never evaluates authored application code.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Parser = preload("res://addons/estragon/compiler/parser.gd")
const Bindable = preload("res://addons/estragon/compiler/bindable.gd")
const Resolver = preload("res://addons/estragon/compiler/native/resolver.gd")
const CONSTRUCTORS = ["Color", "Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i", "String", "StringName", "int", "float", "bool"]
var file
var roots: Dictionary = {}
var context: Dictionary
var metadata: Dictionary = {}
func _init(source, module) -> void:
	file = source
	context = _context(source,module)
	for part in module.parts:
		if part is Model.Bindable: roots[part.name] = part
func _context(source, module) -> Dictionary:
	var imports := Resolver.new(source)
	imports.scan(module)
	var fields := {}
	for part in module.parts:
		if part is Model.Bindable: fields[part.name] = part
	return {"fields":fields,"imports":imports.aliases,"globals":imports.globals}
func _model(type: String, scope: Dictionary) -> Dictionary:
	var path: String = scope.imports.get(type,scope.globals.get(type,""))
	if path.is_empty(): return {}
	if metadata.has(path): return metadata[path]
	# Read authored model declarations even on a cold first build: generated
	# modules may not yet exist or may be the previous editor transaction.
	var directory := path.get_base_dir()
	if directory.get_file() != "generated": return {}
	var authored := directory.get_base_dir().path_join(path.get_file().get_basename()+".gogo")
	if not FileAccess.file_exists(authored): return {}
	var source := Source.new(FileAccess.get_file_as_string(authored),authored)
	var parsed = Parser.new(source).parse()
	if parsed == null: return {}
	Bindable.new(source).apply(parsed)
	if not source.diagnostics.is_empty(): return {}
	var result := _context(source,parsed)
	metadata[path] = result
	return result
func _validate_path(path: PackedStringArray, token) -> bool:
	var scope := context
	for index in range(path.size()):
		if not scope.fields.has(path[index]):
			file.fail("Reactive dependency requires a typed Gogo @bindable property: "+".".join(path),token.span.start.index,token.span.end.index)
			return false
		if index < path.size()-1:
			scope = _model(scope.fields[path[index]].type_name,scope)
			if scope.is_empty():
				file.fail("Reactive intermediate paths require explicitly imported typed Gogo models",token.span.start.index,token.span.end.index)
				return false
	return true
func analyze(expression, property: String) -> void:
	var tokens: Array = []
	var lexer := Lexer.new(file)
	for part in expression.parts:
		if not part is Model.Code:
			# Only diagnose nested composition if this is a reactive expression.
			continue
		var cursor: int = part.span.start.index
		while cursor < part.span.end.index:
			var token = lexer.next_token(cursor)
			cursor = token.span.end.index
			if token.kind not in ["whitespace", "newline", "comment", "continuation"]: tokens.append(token)
	var opted := false
	for token in tokens:
		if token.kind == "identifier" and token.text == "self": opted = true
	if not opted: return
	if property in ["position", "global_position", "transform", "global_transform", "rotation", "rotation_degrees", "global_rotation", "global_rotation_degrees", "rotation_order", "quaternion", "basis", "global_basis", "scale", "global_scale", "skew", "top_level", "x", "y"]:
		file.fail("Reactive transforms/position are deferred until layout authority is specified",expression.span.start.index,expression.span.end.index)
		return
	for part in expression.parts:
		if not part is Model.Code:
			file.fail("Reactive property expressions cannot contain GGX",part.span.start.index,part.span.end.index)
			return
	var index := 0
	while index < tokens.size():
		var token = tokens[index]
		if token.kind == "identifier" and token.text == "self":
			var path := PackedStringArray()
			index += 1
			while index + 1 < tokens.size() and tokens[index].text == "." and tokens[index+1].kind == "identifier":
				path.append(tokens[index+1].text)
				index += 2
			if path.is_empty() or not roots.has(path[0]):
				file.fail("Reactive self paths must start at a typed @bindable property in this module",token.span.start.index,token.span.end.index)
				return
			if not _validate_path(path,token): return
			if not expression.dependencies.has(path): expression.dependencies.append(path)
			continue
		if token.kind == "identifier":
			if token.text not in ["true", "false", "null", "if", "else", "and", "or", "not"] and not (token.text in CONSTRUCTORS and index+1 < tokens.size() and tokens[index+1].text == "("):
				file.fail("Reactive expressions support self property paths, operators, literals and native value constructors only",token.span.start.index,token.span.end.index)
				return
		elif token.text not in ["(", ")", ",", "+", "-", "*", "/", "%", "==", "!=", "<", ">", "<=", ">=", "**", "&", "|", "^", "~", "<<", ">>"] and token.kind not in ["number", "string"]:
			file.fail("Unsupported reactive expression operation",token.span.start.index,token.span.end.index)
			return
		# A call immediately after a property path is never a pure read.
		if token.text == "(" and index > 0 and tokens[index-1].kind == "identifier" and tokens[index-1].text not in CONSTRUCTORS:
			file.fail("Reactive expressions cannot call methods or authored functions",token.span.start.index,token.span.end.index)
			return
		index += 1
