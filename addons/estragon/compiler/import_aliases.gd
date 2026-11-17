@tool
extends RefCounted
## Explicit native-name imports are lexical Gogo names, not native registrations.
## Only lexer-proven identifier spans enter the existing mapped emitter.
const Model = preload("model.gd")
const Lexer = preload("lexer.gd")
var file
var module
var declarations: Dictionary = {}
func _init(source) -> void: file = source
func apply(value) -> void:
	module = value
	if module.import_aliases.is_empty(): return
	_parts(module.parts)
func _parts(parts: Array) -> void:
	for part in parts:
		if part is Model.Code: _code(part.span)
		elif part is Model.Bindable:
			_code(part.declaration_span)
		elif part is Model.GdExpression: _parts(part.parts)
		elif part is Model.Component:
			for attribute in part.attributes:
				if attribute.value is Model.GdExpression: _parts(attribute.value.parts)
			_parts(part.children)
			_parts(part.text_body)
func _code(span) -> void:
	var lexer := Lexer.new(file)
	var cursor: int = span.start.index
	var tokens: Array = []
	while cursor<span.end.index:
		var token = lexer.next_token(cursor)
		if token==null: return
		cursor = token.span.end.index
		if token.kind not in ["whitespace","newline","comment","continuation"]: tokens.append(token)
	var parameter_depth := 0
	var in_function := false
	for index in range(tokens.size()):
		var token = tokens[index]
		if token.text=="func": in_function = true
		elif in_function and token.text=="(": parameter_depth += 1
		elif in_function and token.text==")":
			parameter_depth -= 1
			if parameter_depth==0: in_function = false
		if token.kind!="identifier" or not module.import_aliases.has(token.text): continue
		if in_function and parameter_depth==1 and index>0 and tokens[index-1].text in ["(",","] and index+1<tokens.size() and tokens[index+1].text in [":","=",",",")"]:
			file.fail("Imported native-name alias cannot be a parameter: "+token.text,token.span.start.index,token.span.end.index)
			return
		# GDScript dictionary shorthand is a string key, not an expression.
		if index+1<tokens.size() and tokens[index+1].text=="=" and index>0 and tokens[index-1].text in ["{",","]: continue
		# Member access is a different name, except explicit self.constant.
		if index>0 and tokens[index-1].text=="." and (index<2 or tokens[index-2].text!="self"): continue
		if index>0 and tokens[index-1].text in ["var","const","func","signal","class","for"]:
			var prefix: String = file.text.substr(file.line_start(token.span.start.line),tokens[index-1].span.start.index-file.line_start(token.span.start.line))
			if tokens[index-1].text!="const" or not prefix.is_empty() or declarations.has(token.text):
				file.fail("Imported native-name alias cannot be redeclared: "+token.text,token.span.start.index,token.span.end.index)
				return
			declarations[token.text] = true
		module.identifier_imports.append({"span":token.span,"alias":module.import_aliases[token.text]})
