@tool
extends RefCounted
## Detect the automatic host entry. Every GGX expression is a description.
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
	var has_ggx := false
	for part in module.parts:
		if part is Model.Component: has_ggx = true
	var start := -1
	for index in range(tokens.size()-6):
		var token = tokens[index]
		if token.text!="func" or token.span.start.column!=1 or tokens[index+1].text!="build_view": continue
		if tokens[index+2].text!="(" or tokens[index+3].text!=")" or tokens[index+4].text!="->": continue
		var type: String = tokens[index+5].text
		if resolver.aliases.get(type,"")!="res://addons/estragon/runtime/composition/element.gd":
			if has_ggx and type in ["Node","Node2D","Node3D"]:
				file.fail("build_view must return Element descriptions; eager Node-returning GGX is unsupported",tokens[index+5].span.start.index,tokens[index+5].span.end.index)
				return
			continue
		if start>=0:
			file.fail("Duplicate build_view composition function",token.span.start.index)
			return
		start = token.span.start.index
	if start<0: return
	module.composition = true
	for index in range(tokens.size()-1):
		if tokens[index].text=="func" and tokens[index].span.start.column==1 and tokens[index+1].text=="_notification":
			file.fail("Composition owns _notification; use ordinary _ready/event methods",tokens[index+1].span.start.index)
			return
