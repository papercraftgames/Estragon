@tool
extends RefCounted
## Static Node type metadata. Never instantiate authored classes or use editor/tree.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
var file
var aliases: Dictionary = {}
var globals: Dictionary = {}
const LEGACY := ["VBox", "HBox", "Rect", "Text", "Button"]

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
		if name in LEGACY or ClassDB.class_exists(name) or globals.has(name) and globals[name] != aliases[name]:
			return _fail("Ambiguous GGX preload alias " + name, span)
		return _script(name, aliases[name], span)
	if globals.has(name): return _script(name, globals[name], span)
	if not ClassDB.class_exists(name): return _fail("Unknown component %s; expected VBox, HBox, Rect, Text or Button" % JSON.stringify(name), span)
	if not ClassDB.is_parent_class(name, "Node") or not ClassDB.can_instantiate(name):
		return _fail("Unknown or non-constructible Node GGX type " + name, span)
	return {"native": name, "script": null}

func _script(name: String, path: String, span: Model.Span) -> Dictionary:
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

func _fail(message: String, span: Model.Span) -> Dictionary:
	file.fail(message, span.start.index, span.end.index)
	return {}
