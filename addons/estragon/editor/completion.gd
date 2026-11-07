@tool
extends RefCounted
## Lexical declarations + public ClassDB metadata. No authored Script loads/new().
const Context = preload("lexical_context.gd")
const Build = preload("build_service.gd")
var sources: Dictionary = {}
var _script_cache: Dictionary = {}
var _classes: PackedStringArray = []
var _text := ""
var _path := ""
var _symbols: Dictionary = {}
var _aliases: Dictionary = {}
var _base := "Node"
var _native_cache: Dictionary = {}

func _init() -> void:
	_classes = ClassDB.get_class_list()
func invalidate() -> void:
	_text = ""
	_native_cache.clear()
	_script_cache.clear()
func _tokens(text: String) -> Array:
	var context := Context.new()
	context.update(text)
	var result: Array = []
	for index in range(context.lines.size()):
		for token in context.line(index).tokens:
			if token.kind in ["comment","tag","property"]: continue
			if token.kind == "string" and not result.is_empty() and result[-1].kind == "string" and result[-1].end == token.start:
				result[-1].text += token.text
				result[-1].end = token.end
			else: result.append(token.duplicate())
	return result
func _resolve_path(raw: String, source: String) -> String:
	if raw.length() < 2: return ""
	var value := raw.substr(1,raw.length()-2).c_unescape()
	if value.is_absolute_path(): return value.simplify_path()
	var output := Build.output_for(source) if source.ends_with(".gogo") else source
	return output.get_base_dir().path_join(value).simplify_path()
func _declarations(text: String, source: String) -> Dictionary:
	var tokens := _tokens(text)
	var symbols: Dictionary = {}
	var aliases: Dictionary = {}
	var base := ""
	for index in range(tokens.size()):
		var word: String = tokens[index].text
		if word == "extends" and index+1 < tokens.size():
			base = _resolve_path(tokens[index+1].text,source) if tokens[index+1].kind == "string" else tokens[index+1].text
		if word not in ["var","const","func","signal","class_name","class"] or index+1 >= tokens.size(): continue
		var name: String = tokens[index+1].text
		if not name.is_valid_identifier(): continue
		var type := ""
		if index+3 < tokens.size() and tokens[index+2].text == ":": type = tokens[index+3].text
		symbols[name] = {"type":type,"kind":CodeEdit.KIND_FUNCTION if word == "func" else (CodeEdit.KIND_SIGNAL if word == "signal" else (CodeEdit.KIND_CONSTANT if word == "const" else (CodeEdit.KIND_CLASS if word in ["class","class_name"] else CodeEdit.KIND_MEMBER)))}
		if word == "const":
			for cursor in range(index+2,mini(index+7,tokens.size()-2)):
				if tokens[cursor].text == "preload" and tokens[cursor+1].text == "(" and tokens[cursor+2].kind == "string": aliases[name] = _resolve_path(tokens[cursor+2].text,source)
	# Typed arguments/local declarations also contribute names, never inferred values.
	for index in range(1,tokens.size()-2):
		if tokens[index].text == ":" and tokens[index-1].text.is_valid_identifier() and tokens[index+1].text.is_valid_identifier():
			var name: String = tokens[index-1].text
			if not symbols.has(name): symbols[name] = {"type":tokens[index+1].text,"kind":CodeEdit.KIND_VARIABLE}
	return {"symbols":symbols,"aliases":aliases,"base":base}
func _index(text: String, source: String) -> void:
	if text == _text and source == _path: return
	_text = text
	_path = source
	var declarations := _declarations(text,source)
	_symbols = declarations.symbols
	_aliases = declarations.aliases
	_base = declarations.base
func _script(path: String) -> Dictionary:
	var text: String = sources.get(path,FileAccess.get_file_as_string(path))
	if not _script_cache.has(path) or _script_cache[path].text != text:
		_script_cache[path] = {"text":text,"declarations":_declarations(text,path)}
	return _script_cache[path].declarations
func _members(type: String, aliases: Dictionary, visited: Array = []) -> Dictionary:
	var name: String = aliases.get(type,type)
	if name.is_empty() or name in visited or visited.size() >= 12: return {}
	if ClassDB.class_exists(name):
		if _native_cache.has(name): return _native_cache[name]
		var result: Dictionary = {}
		for prop in ClassDB.class_get_property_list(name):
			if not str(prop.name).contains("/") and not (int(prop.usage)&PROPERTY_USAGE_READ_ONLY):
				result[prop.name] = {"type":str(prop.get("class_name","")),"kind":CodeEdit.KIND_MEMBER}
		for method in ClassDB.class_get_method_list(name): result[method.name] = {"type":"","kind":CodeEdit.KIND_FUNCTION}
		for sig in ClassDB.class_get_signal_list(name): result[sig.name] = {"type":"","kind":CodeEdit.KIND_SIGNAL}
		_native_cache[name] = result
		return result
	if not name.begins_with("res://"):
		for entry in ProjectSettings.get_global_class_list():
			if entry["class"] == name: return _members(str(entry.path),{},visited+[name])
		return {}
	var authored := name.get_base_dir().get_base_dir().path_join(name.get_file().get_basename()+".gogo")
	if name.get_base_dir().get_file() == "generated" and FileAccess.file_exists(authored): name = authored
	if not FileAccess.file_exists(name): return {}
	var declarations := _script(name)
	var result := _members(declarations.base,declarations.aliases,visited+[name])
	result.merge(declarations.symbols,true)
	return result
func _node_type(type: String, aliases: Dictionary, visited: Array = []) -> bool:
	var name: String = aliases.get(type,type)
	if name in visited or visited.size() >= 12: return false
	if ClassDB.class_exists(name): return ClassDB.is_parent_class(name,"Node") and ClassDB.can_instantiate(name)
	if not name.begins_with("res://"):
		for entry in ProjectSettings.get_global_class_list():
			if entry["class"] == name: return _node_type(str(entry.path),{},visited+[name])
		return false
	if not FileAccess.file_exists(name): return false
	var declarations := _declarations(FileAccess.get_file_as_string(name),name)
	return _node_type(declarations.base,declarations.aliases,visited+[name])
func candidates(text: String, source: String, lexical: RefCounted, row: int, column: int) -> Array:
	_index(text,source)
	lexical.update(text)
	var context: Dictionary = lexical.context(row,column)
	if context.suppressed: return []
	var left: String = lexical.lines[row].left(column)
	var prefix := ""
	var cursor := left.length()-1
	while cursor >= 0 and (left[cursor].is_valid_identifier() or left[cursor].is_valid_int() or left[cursor] == ":"):
		prefix = left[cursor]+prefix
		cursor -= 1
	var offered: Dictionary = {}
	if context.mode == "tag":
		if context.closing:
			if not context.tags.is_empty(): offered[context.tags[-1]] = {"kind":CodeEdit.KIND_CLASS}
		elif context.name_pending or not left.substr(maxi(0,left.rfind("<"))+1).contains(" ") and not left.substr(maxi(0,left.rfind("<"))+1).contains("\t"):
			for name in _classes:
				if ClassDB.is_parent_class(name,"Node") and ClassDB.can_instantiate(name): offered[name] = {"kind":CodeEdit.KIND_CLASS}
			for name in _aliases:
				if _node_type(name,_aliases): offered[name] = {"kind":CodeEdit.KIND_CLASS}
			for entry in ProjectSettings.get_global_class_list():
				if str(entry["class"]).begins_with(prefix) and _node_type(str(entry["class"]),{}): offered[entry["class"]] = {"kind":CodeEdit.KIND_CLASS}
		else:
			var members := _members(context.tag,_aliases)
			for name in members:
				if members[name].kind in [CodeEdit.KIND_MEMBER,CodeEdit.KIND_SIGNAL] and name not in ["owner","script"]: offered[name] = members[name]
			if _node_type(context.tag,_aliases): offered.key = {"kind":CodeEdit.KIND_MEMBER}
			if members.has("value") and members.has("value_changed"): offered["bind:value"] = {"kind":CodeEdit.KIND_MEMBER}
	elif context.mode == "body": return []
	elif cursor >= 0 and left[cursor] == ".":
		var begin := cursor-1
		while begin >= 0 and (left[begin].is_valid_identifier() or left[begin].is_valid_int() or left[begin] == "."): begin -= 1
		var receiver := left.substr(begin+1,cursor-begin-1)
		var chain := receiver.split(".")
		var members: Dictionary = _symbols.duplicate(true) if chain[0] == "self" else {}
		if chain[0] == "self": members.merge(_members(_base,_aliases),false)
		elif _symbols.has(chain[0]): members = _members(_symbols[chain[0]].type,_aliases)
		else: members = _members(chain[0],_aliases)
		for index in range(1,chain.size()): members = _members(str(members.get(chain[index],{}).get("type","")),_aliases)
		offered = members
	else:
		for word in Context.KEYWORDS: offered[word] = {"kind":CodeEdit.KIND_PLAIN_TEXT}
		for name in _classes: offered[name] = {"kind":CodeEdit.KIND_CLASS}
		for entry in ProjectSettings.get_global_class_list(): offered[entry["class"]] = {"kind":CodeEdit.KIND_CLASS}
		offered.merge(_symbols,true)
		offered.merge(_members(_base,_aliases),false)
		if cursor >= 0 and left[cursor] == "@":
			offered.clear()
			for name in ["bindable","tool","export","export_range","onready","warning_ignore"]: offered[name] = {"kind":CodeEdit.KIND_PLAIN_TEXT}
	var result: Array = []
	for name in offered:
		if str(name).begins_with(prefix) and not str(name).begins_with("_"):
			result.append({"text":str(name).trim_prefix("bind:") if prefix.begins_with("bind:") else str(name),"kind":offered[name].kind})
	result.sort_custom(func(a,b): return a.text < b.text)
	return result
