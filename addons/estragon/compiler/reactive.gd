@tool
extends RefCounted
## Lexical, source-spanned opt-in reads. Never evaluates authored application code.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const CONSTRUCTORS = ["Color", "Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i", "String", "StringName", "int", "float", "bool"]
var file
var roots: Dictionary = {}
func _init(source, module) -> void:
	file = source
	for part in module.parts:
		if part is Model.Bindable: roots[part.name] = true
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
	if property in ["position", "global_position", "transform", "global_transform", "rotation", "scale", "x", "y"]:
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
