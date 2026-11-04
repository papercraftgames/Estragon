@tool
extends "res://addons/estragon/compiler/emitter.gd"
## Reuse lexical composition, typed calls and maps; only Node construction differs.
var _depth: int = 0
var _owned: PackedStringArray = []
var _connections: Array[Dictionary] = []

func _collect(node: Model.Component, factory: Factory) -> void:
	if not node.native_node:
		super._collect(node, factory)
		return
	for attribute in node.attributes:
		if attribute.value is Model.GdExpression: _argument(attribute.value, attribute.type_name, factory)
	for child in node.children: _collect(child, factory)

func _component(node: Model.Component, indentation: String) -> String:
	if not node.native_node: return super._component(node, indentation)
	var root := _depth == 0
	if root:
		_owned.clear()
		_connections.clear()
	_depth += 1
	var variable := "component_%d" % _variable
	_variable += 1
	_line("var %s: %s = %s.new()" % [variable, node.runtime_class, node.runtime_class], node.span, indentation)
	for attribute in node.attributes:
		var value := attribute.value
		var argument: String = _arguments[value].name if value is Model.GdExpression else literal(value)
		if attribute.kind == "property": _line(variable + "." + attribute.name + " = " + argument, value.span, indentation)
		else: _connections.append({"node": variable, "name": attribute.name, "argument": argument, "span": value.span})
	for child in node.children:
		var child_value := _component(child, indentation)
		_line("%s.add_child(%s)" % [variable, child_value], child.span, indentation)
		_owned.append(child_value)
	_depth -= 1
	if root:
		# Set owner only after the complete new subtree is attached. No external
		# Nodes are traversed/adopted; expression children are rejected by native validation.
		for owned in _owned: _line("%s.owner = %s" % [owned, variable], node.span, indentation)
		for event in _connections:
			var message := _string("%s:%d:%d: Node GGX signal %s requires a valid Callable/connection" % [_file.name, event.span.start.line, event.span.start.column, event.name])
			_line("if not %s.is_valid() or %s.%s.connect(%s, Object.CONNECT_PERSIST) != OK:" % [event.argument, event.node, event.name, event.argument], event.span, indentation)
			_line(_module.indentation + "push_error(%s)" % message, event.span, indentation)
			_line(_module.indentation + variable + ".free()", event.span, indentation)
			_line(_module.indentation + "return null", event.span, indentation)
	return variable
