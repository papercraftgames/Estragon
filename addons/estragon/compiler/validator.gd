@tool
extends RefCounted
## Static native Node property/signal contracts; no SceneTree or editor dependency.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Resolver = preload("res://addons/estragon/compiler/native/resolver.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const Reactive = preload("res://addons/estragon/compiler/reactive.gd")
var file: Source
var _mode: String
var resolver
var reactive
func _init(source: Source) -> void:
	file = source
	resolver = Resolver.new(source)
func validate(module: Model.Module) -> void:
	reactive = Reactive.new(file,module)
	_mode = module.mode
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
	if _mode != "hybrid":
		_error("Node GGX requires a GDScript-first module", node.name_span)
		return
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
		if node.described and name=="key":
			_error("GGX sibling keys and arrays are deferred to F03; conditional slots preserve identity",attribute.name_span)
			return
		if seen.has(name):
			_error("Duplicate Node property or signal " + name, attribute.name_span)
			return
		seen[name] = true
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
			if attribute.kind == "property" and not node.described: reactive.analyze(attribute.value,attribute.name)
	var sibling_names := {}
	for child in node.children:
		if node.described and child is Model.GdExpression:
			_node(child)
			_child_expression(child)
			continue
		if not child is Model.Component:
			_error("Node GGX children must be newly declared Node elements; expression adoption is unsupported", child.span)
			return
		_node(child)
		if node.described and child is Model.Component:
			for attribute in child.attributes:
				if attribute.name=="name" and attribute.value is Model.Literal:
					var name: String = str(attribute.value.value)
					if sibling_names.has(name):
						_error("Duplicate declared sibling name "+name,attribute.value.span)
						return
					sibling_names[name] = true

func _child_expression(expression) -> void:
	var tokens: Array = []
	var lexer := Lexer.new(file)
	for part in expression.parts:
		if part is Model.Component:
			tokens.append({"text":"<element>","span":part.span})
			continue
		var cursor: int = part.span.start.index
		while cursor < part.span.end.index:
			var token = lexer.next_token(cursor)
			if token == null: return
			cursor = token.span.end.index
			if token.kind not in ["whitespace","comment","newline","continuation"]: tokens.append({"text":token.text,"span":token.span})
	_child_result(tokens,expression.span)
func _child_result(tokens: Array, span) -> void:
	# Result alternatives are descriptions/null, while the condition remains
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
	_error("Conditional child results must be GGX Elements or null; arrays, scalars and live Nodes are unsupported",tokens[0].span if not tokens.is_empty() else span)

func _native_type(property: Dictionary) -> String:
	if property.type == TYPE_OBJECT:
		var native: String = str(property.get("class_name", ""))
		return native if not native.is_empty() else "Object"
	if property.type == TYPE_NIL: return "Variant"
	# Names are stable Variant types, not an engine-version-specific type_string API.
	return {TYPE_BOOL:"bool", TYPE_INT:"int", TYPE_FLOAT:"float", TYPE_STRING:"String", TYPE_STRING_NAME:"StringName", TYPE_VECTOR2:"Vector2", TYPE_VECTOR2I:"Vector2i", TYPE_RECT2:"Rect2", TYPE_RECT2I:"Rect2i", TYPE_VECTOR3:"Vector3", TYPE_VECTOR3I:"Vector3i", TYPE_TRANSFORM2D:"Transform2D", TYPE_VECTOR4:"Vector4", TYPE_VECTOR4I:"Vector4i", TYPE_PLANE:"Plane", TYPE_QUATERNION:"Quaternion", TYPE_AABB:"AABB", TYPE_BASIS:"Basis", TYPE_TRANSFORM3D:"Transform3D", TYPE_PROJECTION:"Projection", TYPE_COLOR:"Color", TYPE_NODE_PATH:"NodePath", TYPE_RID:"RID", TYPE_CALLABLE:"Callable", TYPE_SIGNAL:"Signal", TYPE_DICTIONARY:"Dictionary", TYPE_ARRAY:"Array", TYPE_PACKED_BYTE_ARRAY:"PackedByteArray", TYPE_PACKED_INT32_ARRAY:"PackedInt32Array", TYPE_PACKED_INT64_ARRAY:"PackedInt64Array", TYPE_PACKED_FLOAT32_ARRAY:"PackedFloat32Array", TYPE_PACKED_FLOAT64_ARRAY:"PackedFloat64Array", TYPE_PACKED_STRING_ARRAY:"PackedStringArray", TYPE_PACKED_VECTOR2_ARRAY:"PackedVector2Array", TYPE_PACKED_VECTOR3_ARRAY:"PackedVector3Array", TYPE_PACKED_COLOR_ARRAY:"PackedColorArray"}.get(property.type, "")
