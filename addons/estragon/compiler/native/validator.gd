@tool
extends "res://addons/estragon/compiler/validator.gd"
## Legacy tags keep shipped semantics; Node trees use typed native metadata.
const Resolver = preload("res://addons/estragon/compiler/native/resolver.gd")
const Lexer = preload("res://addons/estragon/compiler/lexer.gd")
var resolver

func _init(source) -> void:
	super(source)
	resolver = Resolver.new(source)

func validate(module: Model.Module) -> void:
	resolver.scan(module)
	super.validate(module)

func _is_native(node: Model.Component) -> bool:
	return not CLASSES.has(node.name) and not node.name.contains(":") and (_mode == "hybrid" or ClassDB.class_exists(node.name))

func _legacy_check(node: Model.Component) -> bool:
	if resolver.aliases.has(node.name):
		_error("Preload alias conflicts with reserved legacy GGX tag " + node.name, node.name_span)
		return false
	for child in node.children:
		if child is Model.Component and not CLASSES.has(child.name) and (ClassDB.class_exists(child.name) or resolver.aliases.has(child.name) or resolver.globals.has(child.name)):
			_error("Cannot mix legacy and Node GGX children in one tree", child.name_span)
			return false
	return true

func _native_component(node: Model.Component) -> void:
	if _mode != "hybrid":
		_error("Node GGX requires a GDScript-first module", node.name_span)
		return
	var resolved: Dictionary = resolver.resolve(node.name, node.name_span)
	if resolved.is_empty(): return
	node.native_node = true
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
	var seen: Dictionary = {}
	for attribute in node.attributes:
		var name := attribute.name
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
		else: _node(attribute.value)
	for child in node.children:
		if not child is Model.Component:
			_error("Node GGX children must be newly declared Node elements; expression adoption is unsupported", child.span)
			return
		if CLASSES.has(child.name):
			_error("Cannot mix Node and legacy children in one tree", child.name_span)
			return
		_node(child)

func _native_type(property: Dictionary) -> String:
	if property.type == TYPE_OBJECT:
		var native: String = str(property.get("class_name", ""))
		return native if not native.is_empty() else "Object"
	if property.type == TYPE_NIL: return "Variant"
	# Names are stable Variant types, not an engine-version-specific type_string API.
	return {TYPE_BOOL:"bool", TYPE_INT:"int", TYPE_FLOAT:"float", TYPE_STRING:"String", TYPE_STRING_NAME:"StringName", TYPE_VECTOR2:"Vector2", TYPE_VECTOR2I:"Vector2i", TYPE_RECT2:"Rect2", TYPE_RECT2I:"Rect2i", TYPE_VECTOR3:"Vector3", TYPE_VECTOR3I:"Vector3i", TYPE_TRANSFORM2D:"Transform2D", TYPE_VECTOR4:"Vector4", TYPE_VECTOR4I:"Vector4i", TYPE_PLANE:"Plane", TYPE_QUATERNION:"Quaternion", TYPE_AABB:"AABB", TYPE_BASIS:"Basis", TYPE_TRANSFORM3D:"Transform3D", TYPE_PROJECTION:"Projection", TYPE_COLOR:"Color", TYPE_NODE_PATH:"NodePath", TYPE_RID:"RID", TYPE_CALLABLE:"Callable", TYPE_SIGNAL:"Signal", TYPE_DICTIONARY:"Dictionary", TYPE_ARRAY:"Array", TYPE_PACKED_BYTE_ARRAY:"PackedByteArray", TYPE_PACKED_INT32_ARRAY:"PackedInt32Array", TYPE_PACKED_INT64_ARRAY:"PackedInt64Array", TYPE_PACKED_FLOAT32_ARRAY:"PackedFloat32Array", TYPE_PACKED_FLOAT64_ARRAY:"PackedFloat64Array", TYPE_PACKED_STRING_ARRAY:"PackedStringArray", TYPE_PACKED_VECTOR2_ARRAY:"PackedVector2Array", TYPE_PACKED_VECTOR3_ARRAY:"PackedVector3Array", TYPE_PACKED_COLOR_ARRAY:"PackedColorArray"}.get(property.type, "")
