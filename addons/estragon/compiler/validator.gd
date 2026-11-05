@tool
extends RefCounted
## Static native Node property/signal contracts; no SceneTree or editor dependency.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Resolver = preload("res://addons/estragon/compiler/native/resolver.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
var file: Source
var resolver
func _init(source: Source) -> void:
	file = source
	resolver = Resolver.new(source)
func validate(module: Model.Module) -> void:
	resolver.scan(module)
	for part in module.parts: _node(part)
func _node(node: Model.SyntaxNode) -> void:
	if not file.diagnostics.is_empty(): return
	if node is Model.GdExpression:
		for part in node.parts: _node(part)
	elif node is Model.Component: _component(node)
func _error(message: String, span: Model.Span) -> void:
	file.fail(message,span.start.index,span.end.index)

func _component(node: Model.Component) -> void:
	var resolved: Dictionary = resolver.resolve(node.name, node.name_span)
	if resolved.is_empty(): return
	node.runtime_class = node.name
	var properties: Dictionary = {}
	var signals: Dictionary = {}
	for property in ClassDB.class_get_property_list(resolved.native): properties[property.name] = property
	for event in ClassDB.class_get_signal_list(resolved.native): signals[event.name] = event
	var script: Script = resolved.script
	while script != null:
		for property in script.get_script_property_list():
			if not properties.has(property.name): properties[property.name] = property
		for event in script.get_script_signal_list():
			if not signals.has(event.name): signals[event.name] = event
		script = script.get_base_script()
	properties.merge(resolved.get("properties",{}),true)
	signals.merge(resolved.get("signals",{}),true)
	var seen: Dictionary = {}
	for attribute in node.attributes:
		var name := attribute.name
		if seen.has(name):
			_error("Duplicate Node property or signal " + name, attribute.name_span)
			return
		seen[name] = true
		if name=="key":
			attribute.kind = "key"
			attribute.type_name = "Variant"
			if attribute.value is Model.Literal:
				if str(attribute.value.value).is_empty(): _error("GGX key must be an integer or nonempty String",attribute.value.span)
			else: _key_expression(attribute.value)
			continue
		if signals.has(name):
			attribute.kind = "signal"
			attribute.type_name = "Callable"
			if not attribute.value is Model.GdExpression:
				_error("Node signals require a named handler/Callable expression", attribute.value.span)
				return
			var lexer := Lexer.new(file)
			var index: int = attribute.value.span.start.index + 1
			while index < attribute.value.span.end.index - 1:
				var token := lexer.next_token(index)
				if token == null: return
				if token.kind == "identifier" and token.text == "func":
					_error("Inline anonymous GGX handlers are not supported; use a named handler/Callable", token.span)
					return
				index = token.span.end.index
		elif properties.has(name) and name not in ["owner", "script"] and not name.contains("/") and not (int(properties[name].usage) & PROPERTY_USAGE_READ_ONLY):
			attribute.type_name = _native_type(properties[name])
			if attribute.type_name.is_empty():
				_error("Unsupported Node property metadata: " + name, attribute.name_span)
				return
		else:
			_error("Unknown, read-only or reserved Node property/signal " + name, attribute.name_span)
			return
		if attribute.value is Model.Literal:
			if attribute.type_name not in ["String", "StringName"]:
				_error("Typed Node values require {GDScript expressions}; only strings may be quoted", attribute.value.span)
				return
			attribute.value.kind = "string-literal"
			attribute.value.type_name = attribute.type_name
		else:
			_node(attribute.value)
	var sibling_names := {}
	for child in node.children:
		if child is Model.GdExpression:
			_node(child)
			_child_expression(child)
			continue
		if not child is Model.Component:
			_error("Node GGX children must be newly declared Node elements; expression adoption is unsupported", child.span)
			return
		_node(child)
		if child is Model.Component:
			for attribute in child.attributes:
				if attribute.name=="name" and attribute.value is Model.Literal:
					var name: String = str(attribute.value.value)
					if sibling_names.has(name):
						_error("Duplicate declared sibling name "+name,attribute.value.span)
						return
					sibling_names[name] = true
	_static_keys(node.children,{})

# Inspect only statically simultaneous children. A conditional expression's
# alternatives are validated at runtime; it must not create false duplicates.
func _static_keys(children: Array, keys: Dictionary) -> void:
	for child in children:
		if child is Model.Component:
			for attribute in child.attributes:
				if attribute.kind!="key": continue
				var literal = null
				if attribute.value is Model.Literal: literal = "s:"+str(attribute.value.value)
				else:
					var text: String = file.slice(attribute.value.span).substr(1).trim_suffix("}").strip_edges()
					if text.is_valid_int(): literal = "i:"+str(int(text))
					else:
						var tokens := _expression_tokens(attribute.value)
						if tokens.size()==1 and tokens[0].kind=="string" and not tokens[0].text.contains("\\"):
							var value: String = tokens[0].text
							var delimiter := 3 if value.begins_with(value[0].repeat(3)) else 1
							literal = "s:"+value.substr(delimiter,value.length()-delimiter*2)
				if literal==null: continue
				if keys.has(literal):
					_error("Duplicate declared sibling key "+str(literal),attribute.value.span)
					return
				keys[literal] = true
		elif child is Model.GdExpression:
			var conditional := false
			var lexer := Lexer.new(file)
			for part in child.parts:
				if not part is Model.Code: continue
				var cursor: int = part.span.start.index
				while cursor<part.span.end.index:
					var token = lexer.next_token(cursor)
					if token==null: return
					cursor = token.span.end.index
					if token.kind=="identifier" and token.text=="if": conditional = true
			if not conditional: _static_keys(child.parts,keys)

func _key_expression(expression) -> void:
	var tokens := _expression_tokens(expression)
	if tokens.is_empty(): return
	# Token kinds keep strings/comments containing constructor-looking text
	# ordinary values; never classify source by substring replacement.
	var first: String = tokens[0].text
	var invalid := false
	if tokens.size()==1:
		invalid = first in ["<element>","null","true","false",'""',"''",'""""""',"''''''"] or tokens[0].kind=="number" and first.is_valid_float() and not first.is_valid_int()
	elif tokens.size()==2 and first in ["+","-"] and tokens[1].kind=="number":
		invalid = tokens[1].text.is_valid_float() and not tokens[1].text.is_valid_int()
	elif first in ["[","{","&","<element>"]: invalid = true
	elif tokens.size()>1 and tokens[1].text=="(" and _direct_call(tokens,1):
		invalid = first in ["bool","float","StringName","Vector2","Vector3","Color","Dictionary","NodePath"]
	elif tokens.size()>3 and tokens[1].text=="." and tokens[2].text=="new" and tokens[3].text=="(" and _direct_call(tokens,3): invalid = true
	if invalid: _error("GGX key must be an integer or nonempty String",expression.span)
func _direct_call(tokens: Array, start: int) -> bool:
	var depth := 0
	for index in range(start,tokens.size()):
		if tokens[index].text=="(": depth += 1
		elif tokens[index].text==")":
			depth -= 1
			if depth==0: return index==tokens.size()-1
	return false
func _expression_tokens(expression) -> Array:
	var tokens: Array = []
	var lexer := Lexer.new(file)
	for part in expression.parts:
		if part is Model.Component:
			tokens.append({"text":"<element>","kind":"element","span":part.span})
			continue
		var cursor: int = part.span.start.index
		while cursor < part.span.end.index:
			var token = lexer.next_token(cursor)
			if token==null: return []
			cursor = token.span.end.index
			if token.kind not in ["whitespace","comment","newline","continuation"]: tokens.append({"text":token.text,"kind":token.kind,"span":token.span})
	return tokens
func _child_expression(expression) -> void:
	_child_result(_expression_tokens(expression),expression.span)
func _child_result(tokens: Array, span) -> void:
	# Result alternatives are descriptions/null/sequences; the condition remains
	# normal native GDScript. This closes the Variant ternary loophole where
	# Godot defers an int/Object conversion until gameplay.
	if tokens.size()==1 and tokens[0].text in ["<element>","null"]: return
	var depth := 0
	var conditional := -1
	var alternative := -1
	var outer_close := -1
	for index in range(tokens.size()):
		var value: String = tokens[index].text
		if value in ["(","[","{"]: depth += 1
		elif value in [")","]","}"]:
			depth -= 1
			if depth==0 and outer_close<0: outer_close = index
		elif depth==0:
			if value=="if" and conditional<0: conditional = index
			elif value=="else" and conditional>=0:
				alternative = index
				break
	if not tokens.is_empty() and tokens[0].text=="(" and outer_close==tokens.size()-1:
		_child_result(tokens.slice(1,tokens.size()-1),span)
		return
	if conditional>0 and alternative>conditional+1 and alternative<tokens.size()-1:
		_child_result(tokens.slice(0,conditional),span)
		_child_result(tokens.slice(alternative+1),span)
		return
	if tokens.size()>=2 and tokens[0].text=="[" and outer_close==tokens.size()-1:
		var begin := 1
		depth = 0
		for index in range(1,tokens.size()-1):
			var value: String = tokens[index].text
			if value in ["(","[","{"]: depth += 1
			elif value in [")","]","}"]: depth -= 1
			elif value=="," and depth==0:
				_child_result(tokens.slice(begin,index),span)
				begin = index+1
		if begin<tokens.size()-1: _child_result(tokens.slice(begin,tokens.size()-1),span)
		return
	# Unknown native expressions (locals, typed helper returns, Array.map) are
	# runtime-validated as a complete desired tree. Obvious scalar/live Node
	# leaves fail at their authored span, including conditional alternatives.
	if not tokens.is_empty():
		var first: String = tokens[0].text
		var constructor: bool = tokens.size()>3 and tokens[1].text=="." and tokens[2].text=="new" and tokens[3].text=="(" and _direct_call(tokens,3)
		var scalar_call: bool = tokens.size()>1 and tokens[1].text=="(" and _direct_call(tokens,1) and first in ["int","float","bool","String","StringName","Vector2","Vector3","Color","Dictionary","NodePath"]
		if tokens[0].kind=="identifier" and first not in ["true","false"] and not scalar_call and (not constructor or resolver.aliases.get(first,"")=="res://addons/estragon/runtime/composition/element.gd"):
			return
	_error("GGX children require Element, null or nested Arrays of descriptions; scalars/live Nodes reject",tokens[0].span if not tokens.is_empty() else span)

func _native_type(property: Dictionary) -> String:
	if property.type == TYPE_OBJECT:
		var native: String = str(property.get("class_name", ""))
		return native if not native.is_empty() else "Object"
	if property.type == TYPE_NIL: return "Variant"
	# Names are stable Variant types, not an engine-version-specific type_string API.
	return {TYPE_BOOL:"bool", TYPE_INT:"int", TYPE_FLOAT:"float", TYPE_STRING:"String", TYPE_STRING_NAME:"StringName", TYPE_VECTOR2:"Vector2", TYPE_VECTOR2I:"Vector2i", TYPE_RECT2:"Rect2", TYPE_RECT2I:"Rect2i", TYPE_VECTOR3:"Vector3", TYPE_VECTOR3I:"Vector3i", TYPE_TRANSFORM2D:"Transform2D", TYPE_VECTOR4:"Vector4", TYPE_VECTOR4I:"Vector4i", TYPE_PLANE:"Plane", TYPE_QUATERNION:"Quaternion", TYPE_AABB:"AABB", TYPE_BASIS:"Basis", TYPE_TRANSFORM3D:"Transform3D", TYPE_PROJECTION:"Projection", TYPE_COLOR:"Color", TYPE_NODE_PATH:"NodePath", TYPE_RID:"RID", TYPE_CALLABLE:"Callable", TYPE_SIGNAL:"Signal", TYPE_DICTIONARY:"Dictionary", TYPE_ARRAY:"Array", TYPE_PACKED_BYTE_ARRAY:"PackedByteArray", TYPE_PACKED_INT32_ARRAY:"PackedInt32Array", TYPE_PACKED_INT64_ARRAY:"PackedInt64Array", TYPE_PACKED_FLOAT32_ARRAY:"PackedFloat32Array", TYPE_PACKED_FLOAT64_ARRAY:"PackedFloat64Array", TYPE_PACKED_STRING_ARRAY:"PackedStringArray", TYPE_PACKED_VECTOR2_ARRAY:"PackedVector2Array", TYPE_PACKED_VECTOR3_ARRAY:"PackedVector3Array", TYPE_PACKED_COLOR_ARRAY:"PackedColorArray"}.get(property.type, "")
