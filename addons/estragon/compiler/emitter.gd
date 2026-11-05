@tool
extends RefCounted
## Typed frontend -> ordinary GDScript. All output is range-mapped, never rewritten.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const MappedWriter = preload("res://addons/estragon/compiler/source_map.gd")

class Argument extends RefCounted:
	var expression: Model.GdExpression
	var type_name: String
	var name: String
	var reader: String
	var sources: String

class Factory extends RefCounted:
	var name: String
	var root: Model.Component
	var arguments: Array[Argument] = []
	var reactive: bool = false

var _module: Model.Module
var _file: Source
var _writer: MappedWriter
var _factories: Array[Factory] = []
var _arguments: Dictionary = {}
var _sequence: int = 0
var _variable: int = 0
var _factory_class: String
var _depth: int = 0
var _owned: PackedStringArray = []
var _connections: Array[Dictionary] = []

func _init(module: Model.Module, file: Source) -> void:
	_module = module
	_file = file
	_writer = MappedWriter.new(file)
	# Explicit class lookup avoids old native lambda resolution of bare static
	# methods. Arguments still use ordinary typed calls in authored scope.
	var index := 0
	while true:
		_factory_class = "_GogoFactories_%d" % index
		if not _module.identifiers.has(_factory_class): break
		index += 1

func emit() -> MappedWriter:
	_parts(_module.parts)
	_writer.append("\n")
	if _module.composition:
		_writer.append("\nfunc _notification(_gogo_what: int) -> void:\n"+_module.indentation+"preload(\"res://addons/estragon/runtime/composition/state.tres\").lifecycle(self, _gogo_what)\n")
	for factory in _factories:
		for argument in factory.arguments:
			if not argument.reader.is_empty(): _reader(argument)
	if not _factories.is_empty():
		_writer.append("\n\nclass " + _factory_class + ":", _factories[0].root.span)
		_writer.append("\n"+_module.indentation+"const _Element = preload(\"res://addons/estragon/runtime/composition/element.gd\")\n")
	# Calls in argument expressions may append additional factories.
	var index: int = 0
	while index < _factories.size():
		_factory(_factories[index])
		index += 1
	_writer.finish()
	return _writer

## Escape a GDScript literal character-by-character; never touch authored code.
static func _string(value: String) -> String:
	var output := '"'
	for character in value:
		match character:
			'"': output += '\\"'
			"\\": output += "\\\\"
			"\n": output += "\\n"
			"\r": output += "\\r"
			"\t": output += "\\t"
			_:
				var point := character.unicode_at(0)
				output += "\\u%04x" % point if point < 32 else character
	return output + '"'

static func literal(value: Model.Literal) -> String:
	return _string(value.value)

func _argument(expression: Model.GdExpression, type_name: String, factory: Factory) -> void:
	var argument := Argument.new()
	argument.expression = expression
	argument.type_name = type_name
	argument.name = "_gogo_value_%d" % factory.arguments.size()
	if not expression.dependencies.is_empty():
		factory.reactive = true
		var suffix := _arguments.size()
		argument.reader = "_gogo_read_%d" % suffix
		while _module.identifiers.has(argument.reader): argument.reader += "_"
		argument.sources = argument.reader+"_sources"
		while _module.identifiers.has(argument.sources): argument.sources += "_"
	factory.arguments.append(argument)
	_arguments[expression] = argument

func _collect(node: Model.Component, factory: Factory) -> void:
	for attribute in node.attributes:
		if attribute.value is Model.GdExpression: _argument(attribute.value, attribute.type_name, factory)
	for child in node.children:
		_collect(child, factory)

func _parts(parts: Array[Model.SyntaxNode]) -> void:
	for part in parts:
		if part is Model.Code: _writer.append(_file.slice(part.span), part.span, true)
		elif part is Model.Bindable: _bindable(part)
		else: _call(part)

func _call(node: Model.Component) -> void:
	var factory := Factory.new()
	while true:
		factory.name = "_gogo_build_%d" % _sequence
		_sequence += 1
		if not _module.identifiers.has(factory.name): break
	factory.root = node
	_factories.append(factory)
	_collect(node, factory)
	var multiline := factory.arguments.size() > 3
	var start := _file.line_start(node.span.start.line)
	var end := start
	while end < _file.text.length() and _file.text[end] in [" ", "\t"]: end += 1
	var base := _file.text.substr(start, end - start)
	_writer.append(_factory_class + "." + factory.name + "(", node.span)
	for index in range(factory.arguments.size()):
		var argument := factory.arguments[index]
		if index > 0: _writer.append("," if multiline else ", ", node.span)
		if multiline: _writer.append("\n" + base + _module.indentation, argument.expression.span)
		if not argument.reader.is_empty(): _writer.append(argument.reader+"()",argument.expression.span)
		else:
			_writer.append("(", argument.expression.span)
			_parts(argument.expression.parts)
			_writer.append(")", argument.expression.span)
	if factory.reactive: _writer.append(", self",node.span)
	_writer.append(("\n" + base if multiline else "") + ")", node.span)

func _factory(factory: Factory) -> void:
	_writer.append("\n\n" + _module.indentation + "static func " + factory.name + "(", factory.root.span)
	var multiline := factory.arguments.size() > 3
	for index in range(factory.arguments.size()):
		var argument := factory.arguments[index]
		if index > 0: _writer.append("," if multiline else ", ", argument.expression.span)
		_writer.append(("\n" + _module.indentation.repeat(2) if multiline else "") + argument.name + ": " + ("Array" if not argument.reader.is_empty() else argument.type_name), argument.expression.span)
	if factory.reactive: _writer.append(", _gogo_host: Node",factory.root.span)
	_writer.append(("\n" + _module.indentation if multiline else "") + ") -> " + ("_Element" if factory.root.described else factory.root.runtime_class) + ":\n", factory.root.span)
	_variable = 0
	var variable := _description(factory.root,_module.indentation.repeat(2)) if factory.root.described else _component(factory.root, _module.indentation.repeat(2))
	_writer.append(_module.indentation.repeat(2) + "return " + variable + "\n", factory.root.span)

func _line(text: String, span: Model.Span, indentation: String) -> void:
	_writer.append(indentation + text + "\n", span)

func _description(node: Model.Component, indentation: String) -> String:
	var variable := "element_%d" % _variable
	_variable += 1
	var props := PackedStringArray()
	var events := PackedStringArray()
	for attribute in node.attributes:
		var value: String = _arguments[attribute.value].name if attribute.value is Model.GdExpression else literal(attribute.value)
		var target := events if attribute.kind == "signal" else props
		target.append(_string(attribute.name)+": "+value)
	var children := PackedStringArray()
	for child in node.children: children.append(_description(child,indentation))
	var native_type := _string(node.runtime_class) if ClassDB.class_exists(node.runtime_class) else node.runtime_class
	_line("var %s := _Element.new(%s, {%s}, {%s}, [%s], %s)" % [variable,native_type,", ".join(props),", ".join(events),", ".join(children),_string("%s:%d:%d" % [_file.name,node.span.start.line,node.span.start.column])],node.span,indentation)
	return variable

func _component(node: Model.Component, indentation: String) -> String:
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
		if attribute.kind == "property":
			if value is Model.GdExpression and not value.dependencies.is_empty():
				var binding: Argument = _arguments[value]
				_line("if not %s.is_empty(): %s.%s = %s[0]" % [argument,variable,attribute.name,argument],value.span,indentation)
				var helper := "binding_%d" % _variable
				_variable += 1
				_line("var %s: Node = preload(\"res://addons/estragon/runtime/node/internal/property_binding.gd\").attach(%s, _gogo_host, &%s, &%s, &%s, %s)" % [helper,variable,_string(binding.reader),_string(binding.sources),_string(attribute.name),argument],value.span,indentation)
				_owned.append(helper)
			else: _line(variable + "." + attribute.name + " = " + argument, value.span, indentation)
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

func _reader(argument: Argument) -> void:
	var expression := argument.expression
	var indent := _module.indentation
	var guards: PackedStringArray = []
	for path in expression.dependencies:
		var prefix := "self"
		for index in range(path.size()-1):
			prefix += "."+path[index]
			if not guards.has(prefix+" != null"): guards.append(prefix+" != null")
	_line("func "+argument.reader+"() -> Array:",expression.span,"")
	if not guards.is_empty(): _line("if not ("+" and ".join(guards)+"): return []",expression.span,indent)
	_writer.append(indent+"var _gogo_result: "+argument.type_name+" = (",expression.span)
	_parts(expression.parts)
	_writer.append(")\n"+indent+"return [_gogo_result]\n\n",expression.span)
	_line("func "+argument.sources+"() -> Array:",expression.span,"")
	_line("var _gogo_sources: Array = []",expression.span,indent)
	for path in expression.dependencies:
		var prefix := "self"
		var level := 1
		for index in range(path.size()):
			_line("_gogo_sources.append("+prefix+"."+path[index]+"_changed)",expression.span,indent.repeat(level))
			prefix += "."+path[index]
			if index < path.size()-1:
				_line("if "+prefix+" != null:",expression.span,indent.repeat(level))
				level += 1
	_line("return _gogo_sources\n",expression.span,indent)

func _bindable(property: Model.Bindable) -> void:
	var incoming := "_gogo_incoming_"+property.name
	while _module.identifiers.has(incoming): incoming += "_"
	var previous := "_gogo_previous_"+property.name
	while _module.identifiers.has(previous): previous += "_"
	var indent := _module.indentation
	_writer.append("signal "+property.signal_name+"(previous: ",property.name_span)
	_writer.append(_file.slice(property.type_span),property.type_span,true)
	_writer.append(", value: ",property.name_span)
	_writer.append(_file.slice(property.type_span),property.type_span,true)
	_writer.append(")\n",property.name_span)
	_writer.append(_file.slice(property.declaration_span),property.declaration_span,true)
	_writer.append(":",property.name_span)
	if property.comment_span != null:
		_writer.append(" ")
		_writer.append(_file.slice(property.comment_span),property.comment_span,true)
	_writer.append("\n"+indent+"set("+incoming+"):\n",property.name_span)
	# Use the native property backing slot: accesses inside its own setter are
	# direct, and declaration initialization does not call the setter.
	_writer.append(indent.repeat(2)+"if is_same("+property.name+", "+incoming+"): return\n",property.name_span)
	_writer.append(indent.repeat(2)+"var "+previous+": "+property.type_name+" = "+property.name+"\n",property.name_span)
	_writer.append(indent.repeat(2)+property.name+" = "+incoming+"\n",property.name_span)
	_writer.append(indent.repeat(2)+property.signal_name+".emit("+previous+", "+incoming+")\n",property.name_span)
	_writer.append(indent+"get:\n"+indent.repeat(2)+"preload(\"res://addons/estragon/runtime/composition/state.tres\").observe(self, &"+_string(property.signal_name)+")\n"+indent.repeat(2)+"return "+property.name+"\n",property.name_span)
