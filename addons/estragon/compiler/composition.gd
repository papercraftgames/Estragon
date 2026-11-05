@tool
extends RefCounted
## F01 exact lexical function convention; no whole-source replacement.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const Resolver = preload("res://addons/estragon/compiler/native/resolver.gd")
var file
func _init(source) -> void:
	file = source
func apply(module) -> void:
	var resolver := Resolver.new(file)
	resolver.scan(module)
	var lexer := Lexer.new(file)
	var tokens: Array = []
	var cursor := 0
	while cursor < file.text.length():
		var token = lexer.next_token(cursor)
		if token == null: return
		cursor = token.span.end.index
		if token.kind not in ["whitespace","newline","comment","continuation"]: tokens.append(token)
	var start := -1
	var end: int = file.text.length()
	for index in range(tokens.size()-6):
		var token = tokens[index]
		if token.text!="func" or token.span.start.column!=1 or tokens[index+1].text!="build_view": continue
		if tokens[index+2].text!="(" or tokens[index+3].text!=")" or tokens[index+4].text!="->": continue
		var type: String = tokens[index+5].text
		if resolver.aliases.get(type,"")!="res://addons/estragon/runtime/composition/element.gd": continue
		if start>=0:
			file.fail("Duplicate F01 build_view composition function",token.span.start.index)
			return
		start = token.span.start.index
		for following in tokens.slice(index+7):
			if following.span.start.column==1:
				end = following.span.start.index
				break
	if start<0: return
	module.composition = true
	for index in range(tokens.size()-1):
		if tokens[index].text=="func" and tokens[index].span.start.column==1 and tokens[index+1].text=="_notification":
			file.fail("F01 composition owns _notification; use ordinary _ready/event methods",tokens[index+1].span.start.index)
			return
	for part in module.parts:
		if part is Model.Component and part.span.start.index>start and part.span.end.index<=end: _mark(part)
func _mark(node) -> void:
	node.described = true
	for child in node.children:
		if child is Model.Component: _mark(child)
		elif child is Model.GdExpression:
			for part in child.parts:
				if part is Model.Component: _mark(part)
