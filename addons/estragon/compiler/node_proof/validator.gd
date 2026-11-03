@tool
extends RefCounted
## Bounded native types, with explicit caller-supplied spatial script aliases.
## Metadata only: never instantiate authored scripts or depend on a SceneTree.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
const BUILTINS := ["Node", "Node2D", "Node3D", "Timer", "Polygon2D", "MeshInstance3D"]
var file: Source
var scripts: Dictionary

func _init(source: Source, script_types: Dictionary) -> void:
	file = source
	scripts = script_types

func validate(module: Model.Module) -> void:
	for alias in scripts:
		var script = scripts[alias]
		if not alias is String or not alias.is_valid_identifier() or alias in BUILTINS or not script is GDScript:
			file.fail("B1 custom types require identifier aliases for preloaded GDScript spatial Nodes", 0)
			return
		if not script.can_instantiate() or script.get_instance_base_type() not in ["Node2D", "Node3D"]:
			file.fail("B1 custom type must derive from Node2D or Node3D", 0)
			return
	for part in module.parts: _node(part)

func _error(message: String, span: Model.Span) -> void:
	if file.diagnostics.is_empty(): file.fail(message, span.start.index, span.end.index)

func _node(node: Model.SyntaxNode) -> void:
	if not file.diagnostics.is_empty(): return
	if node is Model.GdExpression:
		for part in node.parts: _node(part)
	elif node is Model.Component: _component(node)

func _component(node: Model.Component) -> void:
	if not node.name in BUILTINS and not scripts.has(node.name):
		_error("Unknown B1 Node type %s; non-Node hierarchy elements are not supported" % node.name, node.name_span)
		return
	var native: String = node.name
	if scripts.has(node.name): native = scripts[node.name].get_instance_base_type()
	var properties: Dictionary = {}
	var signals: Dictionary = {}
	for property in ClassDB.class_get_property_list(native): properties[property.name] = property
	for event in ClassDB.class_get_signal_list(native): signals[event.name] = event
	if scripts.has(node.name):
		var script: Script = scripts[node.name]
		while script != null:
			for property in script.get_script_property_list():
				if not properties.has(property.name): properties[property.name] = property
			for event in script.get_script_signal_list():
				if not signals.has(event.name): signals[event.name] = event
			script = script.get_base_script()
	node.runtime_class = node.name
	var seen: Dictionary = {}
	for attribute in node.attributes:
		var name := attribute.name
		if seen.has(name):
			_error("Duplicate B1 property or signal " + name, attribute.name_span)
			return
		seen[name] = true
		if signals.has(name):
			attribute.kind = "signal"
			attribute.type_name = "Callable"
			if not attribute.value is Model.GdExpression:
				_error("B1 signals require a named handler or Callable reference", attribute.value.span)
				return
			var lexer := Lexer.new(file)
			var index: int = attribute.value.span.start.index + 1
			while index < attribute.value.span.end.index - 1:
				var token := lexer.next_token(index)
				if token == null: return
				if token.kind == "identifier" and token.text == "func":
					_error("Inline anonymous GGX handler declarations are outside B1; use a named handler/Callable reference", token.span)
					return
				index = token.span.end.index
		elif properties.has(name) and name not in ["owner", "script"] and not name.contains("/"):
			var property: Dictionary = properties[name]
			attribute.type_name = _type(property)
			if attribute.type_name.is_empty():
				_error("Property metadata type is outside the B1 subset: " + name, attribute.name_span)
				return
		else:
			_error("Unknown or reserved B1 property/signal " + name, attribute.name_span)
			return
		if attribute.value is Model.Literal:
			if attribute.type_name not in ["String", "StringName"]:
				_error("B1 typed values require {GDScript expressions}; only strings may be quoted", attribute.value.span)
				return
			attribute.value.kind = "string-literal"
			attribute.value.type_name = attribute.type_name
		else: _node(attribute.value)
	for child in node.children:
		if child is Model.GdExpression:
			_error("B1 children must be newly declared Node elements; borrowed/expression children are not adopted", child.span)
			return
		_node(child)

func _type(property: Dictionary) -> String:
	if property.type == TYPE_OBJECT:
		var class_name_value := str(property.get("class_name", ""))
		return class_name_value if not class_name_value.is_empty() else "Object"
	if property.type == TYPE_NIL: return "Variant"
	return {TYPE_BOOL: "bool", TYPE_INT: "int", TYPE_FLOAT: "float", TYPE_STRING: "String", TYPE_STRING_NAME: "StringName", TYPE_VECTOR2: "Vector2", TYPE_VECTOR3: "Vector3", TYPE_COLOR: "Color", TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array", TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array"}.get(property.type, "")
