@tool
extends RefCounted
## One lexical property lowering for explicit and class-wide Gogo annotations.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
var file: Source
var module: Model.Module
var members: Dictionary = {}
var properties: Dictionary = {}
var class_marker: Model.Span
func _init(source: Source) -> void:
	file = source
func apply(value: Model.Module) -> void:
	module = value
	_class_scope(module.parts)
	if not file.diagnostics.is_empty(): return
	_collect(module.parts)
	module.parts.assign(_parts(module.parts))
# A class marker is unambiguous only in the script preamble, directly
# before extends/class_name. Existing preceding-line property markers stay so.
func _class_scope(parts: Array) -> void:
	var preamble := true
	for part in parts:
		if not part is Model.Code: continue
		var lexer := Lexer.new(file)
		var cursor: int = part.span.start.index
		while cursor<part.span.end.index:
			var token = lexer.next_token(cursor)
			if token==null: return
			cursor = token.span.end.index
			if token.span.start.column!=1: continue
			if token.text in ["var","static","const","func","signal","class"]: preamble = false
			if token.text!="@": continue
			var name = lexer.next_token(cursor)
			if name==null or name.text.to_lower()!="bindable": continue
			var following = _next(lexer,name.span.end.index,true)
			if following==null or following.text not in ["extends","class_name"]: continue
			if not preamble or following.span.start.column!=1 or following.span.start.line==token.span.start.line:
				file.fail("Class @bindable must be a standalone preamble annotation before extends or class_name",token.span.start.index,name.span.end.index)
				return
			if class_marker!=null:
				file.fail("Duplicate class @bindable annotation",token.span.start.index,name.span.end.index)
				return
			class_marker = file.span(token.span.start.index,name.span.end.index)
func _collect(parts: Array) -> void:
	for part in parts:
		if not part is Model.Code: continue
		var lexer := Lexer.new(file)
		var cursor: int = part.span.start.index
		while cursor < part.span.end.index:
			var token = lexer.next_token(cursor)
			if token == null: return
			cursor = token.span.end.index
			if token.kind == "identifier" and token.text in ["var","signal","const","func","class"] and (token.span.start.column == 1 or file.text[file.line_start(token.span.start.line)] == "@" or file.text.substr(file.line_start(token.span.start.line),token.span.start.index-file.line_start(token.span.start.line)).strip_edges()=="static"):
				var name = lexer.next_token(cursor)
				while name != null and name.kind == "whitespace": name = lexer.next_token(name.span.end.index)
				if name != null and name.kind == "identifier": members[name.text] = name.span
func _parts(parts: Array) -> Array[Model.SyntaxNode]:
	var result: Array[Model.SyntaxNode] = []
	for part in parts:
		if not file.diagnostics.is_empty(): break
		if part is Model.GdExpression:
			part.parts.assign(_parts(part.parts))
		elif part is Model.Component:
			for attribute in part.attributes:
				if attribute.value is Model.GdExpression: attribute.value.parts.assign(_parts(attribute.value.parts))
			part.children.assign(_parts(part.children))
		if not part is Model.Code:
			result.append(part)
			continue
		var lexer := Lexer.new(file)
		var cursor: int = part.span.start.index
		var copied := cursor
		var pending_annotation: bool = false
		var annotations_start := -1
		var onready := false
		var static_field := false
		while cursor < part.span.end.index and file.diagnostics.is_empty():
			var token = lexer.next_token(cursor)
			if token == null: break
			cursor = token.span.end.index
			if token.text == "@":
				var name = lexer.next_token(cursor)
				if name == null: break
				if name.text.to_lower() == "bindable":
					if file.name.get_extension().to_lower() in ["gd","bgd"]:
						file.fail("@bindable is supported only in Gogo source",token.span.start.index,name.span.end.index)
						break
					if name.text != "bindable":
						file.fail("Only lowercase @bindable is supported",token.span.start.index,name.span.end.index)
						break
					if class_marker!=null and token.span.start.index==class_marker.start.index:
						if copied<token.span.start.index:
							var before := Model.Code.new()
							before.span = file.span(copied,token.span.start.index)
							result.append(before)
						cursor = name.span.end.index
						copied = cursor
						continue
					if class_marker!=null and _next(lexer,name.span.end.index,true).text=="@":
						file.fail("Duplicate/conflicting @bindable annotation",token.span.start.index,name.span.end.index)
						break
					if token.span.start.column != 1 or pending_annotation:
						file.fail("@bindable requires a top-level instance property without annotation composition",token.span.start.index)
						break
					var property = _property(lexer,name.span.end.index,part.span.end.index,token.span.start.index)
					if property == null: break
					if copied < token.span.start.index:
						var before := Model.Code.new()
						before.span = file.span(copied,token.span.start.index)
						result.append(before)
					result.append(property)
					cursor = property.span.end.index
					copied = cursor
					pending_annotation = false
					continue
				if token.span.start.column==1 and name.text not in ["tool","icon","static_unload"]:
					pending_annotation = true
					if annotations_start<0: annotations_start = token.span.start.index
					onready = onready or name.text=="onready"
			if token.text=="static": static_field = true
			if class_marker!=null and not static_field and token.text=="var" and (token.span.start.column==1 or annotations_start>=0 and file.text[file.line_start(token.span.start.line)]=="@"):
				var field = _next(lexer,token.span.end.index)
				var colon = _next(lexer,field.span.end.index) if field!=null else null
				# Untyped/inferred/static/local/inner fields are ordinary GDScript.
				if colon!=null and colon.text==":":
					if onready:
						file.fail("Class @bindable does not support @onready fields; use selective property annotations",annotations_start,token.span.end.index)
						break
					var start: int = annotations_start if annotations_start>=0 else token.span.start.index
					var property = _property(lexer,token.span.start.index,part.span.end.index,start)
					if property==null: break
					if start<token.span.start.index: property.annotations_span = file.span(start,token.span.start.index)
					if copied<start:
						var before := Model.Code.new()
						before.span = file.span(copied,start)
						result.append(before)
					result.append(property)
					cursor = property.span.end.index
					copied = cursor
			if token.text=="var" or token.span.start.column==1 and token.text in ["func","static","const","class","signal","extends","class_name"]:
				pending_annotation = false
				annotations_start = -1
				onready = false
				static_field = false
		if copied < part.span.end.index:
			var after := Model.Code.new()
			after.span = file.span(copied,part.span.end.index)
			result.append(after)
	return result
func _next(lexer, cursor: int, lines: bool = false):
	var token = lexer.next_token(cursor)
	while token != null and (token.kind in ["whitespace","comment"] or lines and token.kind == "newline"):
		token = lexer.next_token(token.span.end.index)
	return token
func _property(lexer, cursor: int, limit: int, start: int):
	var declaration = _next(lexer,cursor,true)
	if declaration == null: return null
	if declaration.text != "var" or declaration.span.start.column != 1 and declaration.span.start.line != file.position(start).line:
		file.fail("@bindable requires var name: ExplicitType, with no arguments or other annotations",start,declaration.span.end.index)
		return null
	var name = _next(lexer,declaration.span.end.index)
	var colon = _next(lexer,name.span.end.index) if name != null else null
	if name == null or name.kind != "identifier" or colon == null or colon.text != ":":
		file.fail("@bindable requires an explicit property type (var name: Type)",start)
		return null
	var token = _next(lexer,colon.span.end.index)
	if token == null or token.kind != "identifier":
		file.fail("@bindable requires an explicit property type",colon.span.end.index)
		return null
	var property := Model.Bindable.new()
	property.name = name.text
	property.name_span = name.span
	property.type_span = token.span
	property.signal_name = property.name+"_changed"
	if properties.has(property.name) or members.has(property.signal_name):
		file.fail("@bindable property/signal collision: "+property.signal_name,name.span.start.index,name.span.end.index)
		return null
	properties[property.name] = true
	var depth: int = 0
	var initialized: bool = false
	var declaration_end: int = token.span.end.index
	var comment_start: int = -1
	cursor = token.span.start.index
	while cursor < limit:
		token = lexer.next_token(cursor)
		if token == null: return null
		if depth == 0 and token.kind in ["newline","eof"]: break
		if token.text == ";" or depth == 0 and token.text == ":":
			file.fail("@bindable does not support multiple declarations or custom accessors",token.span.start.index,token.span.end.index)
			return null
		if not initialized and depth == 0 and token.text == "=":
			property.type_span = file.span(property.type_span.start.index,declaration_end)
			initialized = true
		if token.text in ["(","[","{"]: depth += 1
		elif token.text in [")","]","}"]: depth -= 1
		if token.kind == "comment" and depth == 0: comment_start = token.span.start.index
		elif token.kind not in ["whitespace","comment","newline"]: declaration_end = token.span.end.index
		cursor = token.span.end.index
	if not initialized: property.type_span = file.span(property.type_span.start.index,declaration_end)
	if depth != 0 or cursor == limit and limit < file.text.length() and file.text[limit] not in ["\r","\n"]:
		file.fail("@bindable initializer must be native GDScript, not a GGX element",start,cursor)
		return null
	var following = _next(lexer,cursor,true)
	if following != null and following.span.start.column > 1 and following.text in ["get","set"]:
		file.fail("@bindable custom accessors are not supported",following.span.start.index,following.span.end.index)
		return null
	property.declaration_span = file.span(declaration.span.start.index,declaration_end)
	if comment_start >= 0: property.comment_span = file.span(comment_start,cursor)
	property.span = file.span(start,cursor)
	property.type_name = file.slice(property.type_span)
	return property
