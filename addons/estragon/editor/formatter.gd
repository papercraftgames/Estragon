@tool
extends RefCounted
## Leading indentation only. Native parser islands own markup/expression bounds;
## original GDScript suite relationships and every physical row are retained.
const Source = preload("../compiler/source.gd")
const Parser = preload("../compiler/parser.gd")
const Lexer = preload("../compiler/lexer.gd")
const Model = preload("../compiler/model.gd")
var file
var lines: PackedStringArray
var targets: Dictionary = {}
var protected: Dictionary = {}
var comments: Array = []
var size := 4
var unit := "\t"

func format_source(text: String, path: String = "<Gogo>", spaces: bool = false, indent_size: int = 4) -> Dictionary:
	file = Source.new(text,path)
	lines = text.split("\n")
	targets.clear()
	protected.clear()
	comments.clear()
	size = maxi(1,indent_size)
	unit = " ".repeat(size) if spaces else "\t"
	var parser := Parser.new(file)
	var module = parser.parse()
	if module!=null:
		for token in parser.lexer.tokens:
			if token.kind=="markup-comment": comments.append(token.span)
			if token.kind in ["string","markup-string","markup-comment"] or token.kind=="markup-text" and not token.text.strip_edges().is_empty():
				for line in range(token.span.start.line+1,token.span.end.line+1):
					if file.line_start(line)<token.span.end.index: protected[line-1] = true
		_gd(module.parts,0)
	if not file.diagnostics.is_empty():
		var records: Array = []
		for diagnostic in file.diagnostics:
			records.append({"source":path,"line":diagnostic.span.start.line,"column":diagnostic.span.start.column,"message":diagnostic.message})
		return {"ok":false,"text":text,"edits":[],"diagnostics":records}
	var edits: Array = []
	for row in range(lines.size()):
		if not targets.has(row) or protected.has(row) or lines[row].strip_edges().is_empty(): continue
		var old := _prefix(row)
		var next := unit.repeat(targets[row])
		if old!=next:
			edits.append({"line":row,"old":old,"new":next})
			lines[row] = next+lines[row].substr(old.length())
	return {"ok":true,"text":"\n".join(lines),"edits":edits,"diagnostics":[]}

func _prefix(row: int) -> String:
	var end := 0
	while end<lines[row].length() and lines[row][end] in [" ","\t"]: end += 1
	return lines[row].left(end)
func _width(row: int) -> int:
	var width := 0
	for character in _prefix(row): width = (width/size+1)*size if character=="\t" else width+1
	return width
func _at(offset: int, level: int) -> void:
	var row: int = file.position(offset).line-1
	var prefix: String = file.text.substr(file.line_start(row+1),offset-file.line_start(row+1))
	if prefix.strip_edges().is_empty(): targets[row] = maxi(0,level)
func _row(offset: int) -> int: return file.position(offset).line-1

func _tokens(parts: Array) -> Array:
	var result: Array = []
	var lexer := Lexer.new(file)
	for part in parts:
		if part is Model.Component or part is Model.Layout:
			result.append({"kind":"island","text":"<GGX>","span":part.span,"node":part})
		elif part is Model.Code:
			var cursor: int = part.span.start.index
			while cursor<part.span.end.index and file.diagnostics.is_empty():
				var token = lexer.next_token(cursor)
				if token==null: break
				result.append({"kind":token.kind,"text":token.text,"span":token.span})
				cursor = token.span.end.index
	return result

func _gd(parts: Array, floor_level: int) -> void:
	var tokens := _tokens(parts)
	var blocks: Array = []
	var brackets: Array = []
	var statement := false
	var pending := false
	var continued := false
	var last := ""
	var level := floor_level
	for token in tokens:
		if not file.diagnostics.is_empty(): return
		var row: int = token.span.start.line-1
		if token.kind=="whitespace": continue
		if token.kind=="comment":
			var comment_level := level+brackets.size()
			if brackets.is_empty() and not blocks.is_empty():
				var width := _width(row)
				for block in blocks:
					if block.input<=width: comment_level = block.output
				if pending and width>blocks[-1].input: comment_level = blocks[-1].output+1
			_at(token.span.start.index,comment_level)
			continue
		if token.kind=="continuation": continued = true; continue
		if token.kind=="newline":
			if brackets.is_empty() and not continued and statement:
				pending = last==":"
				statement = false
			continued = false
			continue
		if not statement:
			var width := _width(row)
			if blocks.is_empty():
				# Inline islands/attributes inherit the physical header's target.
				var base: int = targets.get(row,floor_level)
				blocks.append({"input":width,"output":base})
			elif pending:
				if width<=blocks[-1].input:
					file.fail("Cannot infer GDScript suite indentation; indent its body before formatting",token.span.start.index)
					return
				blocks.append({"input":width,"output":blocks[-1].output+1})
			else:
				while blocks.size()>1 and width<blocks[-1].input: blocks.pop_back()
				if width!=blocks[-1].input:
					file.fail("Ambiguous GDScript dedent/indent; source unchanged",token.span.start.index)
					return
			level = blocks[-1].output
			pending = false
			statement = true
		var closing: bool = token.text in [")","]","}"]
		var token_level: int = level+brackets.size()-(1 if closing and not brackets.is_empty() else 0)
		_at(token.span.start.index,token_level)
		if token.kind=="island":
			var base: int = targets.get(row,token_level)
			_node(token.node.root if token.node is Model.Layout else token.node,base)
		elif token.text in ["(","[","{"]: brackets.append(token.text)
		elif closing:
			if brackets.is_empty() or brackets[-1]!={")":"(","]":"[","}":"{"}[token.text]:
				file.fail("Unmatched GDScript delimiter; source unchanged",token.span.start.index)
				return
			brackets.pop_back()
		last = token.text
	if not brackets.is_empty():
		file.fail("Incomplete GDScript delimiter; source unchanged",file.text.length())
	if pending or statement and last==":" and brackets.is_empty():
		file.fail("Incomplete GDScript suite; source unchanged",file.text.length())

func _expression(expression, level: int) -> void:
	_at(expression.span.start.index,level)
	_gd(expression.parts,level+1)
	_at(expression.span.end.index-1,level)
func _node(node, level: int) -> void:
	_at(node.span.start.index,level)
	var end: int = node.name_span.end.index
	for attribute in node.attributes:
		_at(attribute.name_span.start.index,level+1)
		if attribute.value is Model.GdExpression: _expression(attribute.value,level+1)
		end = attribute.span.end.index
	while end<file.text.length() and file.text[end] in [" ","\t","\r","\n"]: end += 1
	_at(end,level)
	for comment in comments:
		if comment.start.index>end and comment.end.index<node.span.end.index: _at(comment.start.index,level+1)
	for child in node.children:
		if child is Model.Component: _node(child,level+1)
		elif child is Model.GdExpression: _expression(child,level+1)
	# The parser already authenticated this closing tag; never search literals.
	if file.text.substr(end,2)!="/>":
		var closing: int = node.span.end.index-1
		while closing>node.span.start.index and file.text[closing]!="<": closing -= 1
		_at(closing,level)
