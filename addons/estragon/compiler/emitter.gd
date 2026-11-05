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

class Factory extends RefCounted:
	var name: String
	var root: Model.Component
	var arguments: Array[Argument] = []

var _module: Model.Module
var _file: Source
var _writer: MappedWriter
var _factories: Array[Factory] = []
var _arguments: Dictionary = {}
var _sequence: int = 0
var _variable: int = 0
var _factory_class: String
var _element_class: String

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
	_element_class = "_GogoElement_0"
	while _module.identifiers.has(_element_class): _element_class += "_"

func emit() -> MappedWriter:
	_parts(_module.parts)
	_writer.append("\n")
	if _module.composition:
		_writer.append("\nfunc _notification(_gogo_what: int) -> void:\n"+_module.indentation+"preload(\"res://addons/estragon/runtime/composition/state.tres\").lifecycle(self, _gogo_what)\n")
	if not _factories.is_empty():
		_writer.append("\n\nclass " + _factory_class + ":", _factories[0].root.span)
		_writer.append("\n"+_module.indentation+"const "+_element_class+" = preload(\"res://addons/estragon/runtime/composition/element.gd\")\n")
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
	factory.arguments.append(argument)
	_arguments[expression] = argument

func _collect(node: Model.Component, factory: Factory) -> void:
	for attribute in node.attributes:
		if attribute.value is Model.GdExpression: _argument(attribute.value, attribute.type_name, factory)
	for child in node.children:
		if child is Model.GdExpression: _argument(child,"Variant",factory)
		else: _collect(child, factory)

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
		_writer.append("(", argument.expression.span)
		_parts(argument.expression.parts)
		_writer.append(")", argument.expression.span)
	_writer.append(("\n" + base if multiline else "") + ")", node.span)

func _factory(factory: Factory) -> void:
	_writer.append("\n\n" + _module.indentation + "static func " + factory.name + "(", factory.root.span)
	var multiline := factory.arguments.size() > 3
	for index in range(factory.arguments.size()):
		var argument := factory.arguments[index]
		if index > 0: _writer.append("," if multiline else ", ", argument.expression.span)
		_writer.append(("\n" + _module.indentation.repeat(2) if multiline else "") + argument.name + ": " + argument.type_name, argument.expression.span)
	_writer.append(("\n" + _module.indentation if multiline else "") + ") -> " + _element_class + ":\n", factory.root.span)
	_variable = 0
	var variable := _description(factory.root,_module.indentation.repeat(2))
	_writer.append(_module.indentation.repeat(2) + "return " + variable + "\n", factory.root.span)

func _line(text: String, span: Model.Span, indentation: String) -> void:
	_writer.append(indentation + text + "\n", span)

func _description(node: Model.Component, indentation: String) -> String:
	var variable := "_gogo_element_%d" % _variable
	while _module.identifiers.has(variable): variable += "_"
	_variable += 1
	var props := PackedStringArray()
	var events := PackedStringArray()
	var key := "null"
	var keyed := "false"
	for attribute in node.attributes:
		var value: String = _arguments[attribute.value].name if attribute.value is Model.GdExpression else literal(attribute.value)
		if attribute.kind == "key":
			key = value
			keyed = "true"
			continue
		var target := events if attribute.kind == "signal" else props
		target.append(_string(attribute.name)+": "+value)
	var children := PackedStringArray()
	for child in node.children:
		children.append(_arguments[child].name if child is Model.GdExpression else _description(child,indentation))
	var native_type := _string(node.runtime_class) if ClassDB.class_exists(node.runtime_class) else node.runtime_class
	_line("var %s := %s.new(%s, {%s}, {%s}, [%s], %s, %s, %s)" % [variable,_element_class,native_type,", ".join(props),", ".join(events),", ".join(children),_string("%s:%d:%d" % [_file.name,node.span.start.line,node.span.start.column]),key,keyed],node.span,indentation)
	return variable

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
	if property.annotations_span != null:
		_writer.append(_file.slice(property.annotations_span),property.annotations_span,true)
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
