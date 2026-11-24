@tool
extends RefCounted
## Typed frontend -> ordinary GDScript. All output is range-mapped, never rewritten.
const Preset = preload("../runtime/composition/preset.gd")
const Element = preload("../runtime/composition/element.gd")
const State = preload("../runtime/composition/state.tres")
const Binding = preload("../runtime/composition/binding.gd")
const Data = preload("../runtime/data/state.tres")
const Collection = preload("../runtime/data/array_collection.gd")
const Model = preload("model.gd")
const Source = preload("source.gd")
const MappedWriter = preload("source_map.gd")

class Argument extends RefCounted:
	var spread := false
	var expression: Model.GdExpression
	var type_name: String
	var name: String
	var binding_path: Array = []
	var binding_type := "bool"

class Factory extends RefCounted:
	var name: String
	var root: Model.Component
	var arguments: Array[Argument] = []

var _output_directory: String
var _module: Model.Module
var _file: Source
var _writer: MappedWriter
var _factories: Array[Factory] = []
var _preset_methods: Array = []
var _arguments: Dictionary = {}
var _sequence: int = 0
var _variable: int = 0
var _factory_class: String
var _element_class: String

func _init(module: Model.Module, file: Source) -> void:
	# Paths are relative to the actual generated file, derived from installed Resources.
	# Pathless in-memory callers use the project root, as native GDScript does.
	_output_directory = file.generated_path().get_base_dir()
	if not _output_directory.is_absolute_path(): _output_directory = "res://" + _output_directory
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

func _resource(resource: Resource) -> String:
	return _string(Source.relative_path(_output_directory,resource.resource_path))

func emit() -> MappedWriter:
	_parts(_module.parts)
	if _module.data_type_edits.any(func(edit): return edit.value=="_GogoArrayCollection"): _writer.append("const _GogoArrayCollection = preload("+_resource(Collection)+")\n")
	if _module.data_shape and not _module.data_inherited: _writer.append("signal _gogo_data_changed\n")
	if _module.data_shape:
		_writer.append("\nconst _GOGO_DATA_SHAPE_"+_file.name.sha256_text().substr(0,16)+" = true\n")
		_writer.append("\nfunc to_data():\n"+_module.indentation+"return preload("+_resource(Data)+").to_data(self)\n")
	if not _module.data_types.is_empty():
		_writer.append("\nconst _GOGO_DATA_TYPES_"+_file.name.sha256_text().substr(0,16)+" = {")
		for name in _module.data_types: _writer.append(_string(name)+": "+_module.data_types[name]+",")
		_writer.append("}\n")
	var metadata := "_GOGO_RENDER_FUNCTIONS_"+_file.name.sha256_text().substr(0,16)
	while _module.identifiers.has(metadata): metadata += "_"
	_writer.append("\nconst "+metadata+" = "+var_to_str({"reactive":_module.render_functions,"ordinary":_module.ordinary_functions}))
	_writer.append("\n")
	var observable := {}
	for part in _module.parts:
		if part is Model.Bindable: observable[part.name] = part.type_name
	if not observable.is_empty():
		var contract := "_GOGO_BINDABLE_PROPERTIES_"+_file.name.sha256_text().substr(0,16)
		while _module.identifiers.has(contract): contract += "_"
		_writer.append("const "+contract+" = "+var_to_str(observable)+"\n")
	var exports := {}
	for binding in _module.presets:
		if binding.exported: exports[binding.name] = binding
	for name in exports:
		var binding = exports[name]
		_writer.append("\nvar "+name+":\n"+_module.indentation+"get: return "+binding.symbol+"\n",binding.span)
		if binding.mutable: _writer.append(_module.indentation+"set(value): "+binding.symbol+" = value\n",binding.span)
	for path in _module.project_imports:
		var imported: Dictionary = _module.project_imports[path]
		_writer.append("\nconst "+imported.alias+" = preload("+_string(Source.relative_path(_output_directory,path))+")\n",imported.span)
	for method in _preset_methods:
		_writer.append("\nfunc "+method.name+"(): return ",method.binding.span)
		_default_groups(method.binding)
		_writer.append("\n",method.binding.span)
	if _module.composition or _module.data_shape and not _module.data_notification:
		_writer.append("\nfunc _notification(_gogo_what: int) -> void:\n")
		if _module.composition: _writer.append(_module.indentation+"preload("+_resource(State)+").lifecycle(self, _gogo_what)\n")
		if _module.data_shape: _writer.append(_module.indentation+"if _gogo_what==NOTIFICATION_PREDELETE: preload("+_resource(Data)+").prune()\n")
	if not _factories.is_empty():
		_writer.append("\n\nclass " + _factory_class + ":", _factories[0].root.span)
		_writer.append("\n"+_module.indentation+"const "+_element_class+" = preload("+_resource(Element)+")\n")
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
	return ("true" if value.value else "false") if value.value is bool else _string(value.value)

func _argument(expression: Model.GdExpression, type_name: String, factory: Factory) -> void:
	var argument := Argument.new()
	argument.expression = expression
	argument.type_name = type_name
	argument.name = "_gogo_value_%d" % factory.arguments.size()
	factory.arguments.append(argument)
	_arguments[expression] = argument

func _collect(node: Model.Component, factory: Factory) -> void:
	if node.preset!=null:
		var expression := Model.GdExpression.new()
		expression.span = node.name_span
		var reference := Model.Literal.new()
		reference.kind = "preset-reference"
		reference.value = node.preset.symbol
		reference.span = node.name_span
		expression.parts.append(reference)
		node.preset_expression = expression
		_argument(expression,"Variant",factory)
	for attribute in node.attributes:
		if attribute.value is Model.GdExpression:
			_argument(attribute.value, attribute.type_name, factory)
			factory.arguments.back().spread = attribute.kind=="spread"
			if attribute.kind=="binding":
				factory.arguments.back().binding_path = attribute.binding_path
				factory.arguments.back().binding_type = attribute.binding_type
	for part in node.text_body:
		if part is Model.GdExpression: _argument(part,"Variant",factory)
	for child in node.children:
		if child is Model.GdExpression: _argument(child,"Variant",factory)
		else: _collect(child, factory)

func _parts(parts: Array[Model.SyntaxNode]) -> void:
	for part in parts:
		if part is Model.Code: _code(part.span)
		elif part is Model.Bindable: _bindable(part)
		elif part is Model.Layout: _layout(part)
		elif part is Model.RenderCall: _render_call(part)
		elif part is Model.DataWrite: _data_write(part)
		elif part is Model.Literal and part.kind=="preset-reference": _writer.append(str(part.value),part.span)
		else: _call(part)

func _code(span: Model.Span) -> void:
	var cursor: int = span.start.index
	var edits: Array = []
	edits.append_array(_module.data_type_edits)
	for imported in _module.resource_imports:
		edits.append({"span":imported.span,"value":_string(Source.relative_path(_output_directory,imported.path))})
	for imported in _module.identifier_imports: edits.append({"span":imported.span,"value":imported.alias})
	edits.sort_custom(func(a,b): return a.span.start.index<b.span.start.index)
	for edit in edits:
		var literal_span: Model.Span = edit.span
		if literal_span.start.index < cursor or literal_span.end.index > span.end.index: continue
		var before := _file.span(cursor,literal_span.start.index)
		_writer.append(_file.slice(before),before,true)
		_writer.append(edit.value,literal_span)
		cursor = literal_span.end.index
	var rest := _file.span(cursor,span.end.index)
	_writer.append(_file.slice(rest),rest,true)

func _data_write(write: Model.DataWrite) -> void:
	var location := _string("%s:%d:%d"%[_file.name,write.span.start.line,write.span.start.column])
	if not write.field.is_empty():
		_writer.append("preload("+_resource(Data)+").assign(",write.span)
		_parts(write.owner)
		_writer.append(", "+_string(write.field)+", ",write.span)
		_parts(write.expression)
		_writer.append(", "+location+")",write.span)
	else:
		_parts(write.prefix)
		_writer.append("preload("+_resource(Data)+").value(",write.span)
		_parts(write.expression)
		_writer.append(", "+write.descriptor+", "+write.previous+", "+location+")",write.span)

func _call(node: Model.Component) -> void:
	var factory := Factory.new()
	while true:
		factory.name = "_gogo_build_%d" % _sequence
		_sequence += 1
		if not _module.identifiers.has(factory.name): break
	factory.root = node
	_factories.append(factory)
	_collect(node, factory)
	var keyed: Model.Attribute
	for attribute in node.attributes:
		if attribute.kind=="key": keyed = attribute
	var key_symbol := "_gogo_mount_key"
	while _module.identifiers.has(key_symbol): key_symbol += "_"
	if keyed!=null:
		_writer.append("preload("+_resource(State)+").in_slot("+_string(_file.name+":"+str(node.span.start.offset))+", ",node.span)
		if keyed.value is Model.GdExpression: _parts(keyed.value.parts)
		else: _writer.append(literal(keyed.value),keyed.value.span)
		_writer.append(", func("+key_symbol+"): return ",node.span)
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
		if argument.spread: _writer.append("preload("+_resource(Element)+").snapshot(",argument.expression.span)
		if keyed!=null and argument.expression==keyed.value: _writer.append(key_symbol,argument.expression.span)
		elif argument.binding_path.is_empty(): _parts(argument.expression.parts)
		else: _binding_argument(argument)
		if argument.spread: _writer.append(")",argument.expression.span)
		_writer.append(")", argument.expression.span)
	_writer.append(("\n" + base if multiline else "") + ")", node.span)
	if keyed!=null: _writer.append(")",node.span)

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
	var expanded := node.attributes.any(func(item): return item.kind=="spread")
	var ordered := PackedStringArray()
	for attribute in node.attributes:
		var value: String = _arguments[attribute.value].name if attribute.value is Model.GdExpression else literal(attribute.value)
		if attribute.kind == "key":
			key = value
			keyed = "true"
			continue
		if expanded:
			ordered.append("[%s, %s, %s]" % ["null" if attribute.kind=="spread" else _string(attribute.name),value,_string("%s:%d:%d" % [_file.name,attribute.name_span.start.line,attribute.name_span.start.column])])
			continue
		var target := events if attribute.kind == "signal" else props
		target.append(_string(attribute.name)+": "+value)
	var children := PackedStringArray()
	for child in node.children:
		children.append(_arguments[child].name if child is Model.GdExpression else _description(child,indentation))
	var native_type := _string(node.runtime_class) if ClassDB.class_exists(node.runtime_class) else node.runtime_class
	if node.preset!=null: native_type = "preload("+_resource(Preset)+").type_of("+_arguments[node.preset_expression].name+")"
	_line("var %s := %s.new(%s, {%s}, {%s}, [%s], %s, %s, %s)" % [variable,_element_class,native_type,", ".join(props),", ".join(events),", ".join(children),_string("%s:%d:%d" % [_file.name,node.span.start.line,node.span.start.column]),key,keyed],node.span,indentation)
	for attribute in node.attributes:
		if attribute.kind=="placement" and not expanded: _line(variable+".origins["+_string(attribute.name)+"] = "+_string("%s:%d:%d" % [_file.name,attribute.name_span.start.line,attribute.name_span.start.column]),attribute.name_span,indentation)
		if attribute.kind=="binding": _line(variable+".origins[\"value\"] = "+_string("%s:%d:%d" % [_file.name,attribute.name_span.start.line,attribute.name_span.start.column]),attribute.name_span,indentation)

	if expanded: _line(variable+".expand(["+", ".join(ordered)+"])",node.span,indentation)
	_line(variable+".resolve_bindings()",node.span,indentation)
	if not node.text_body.is_empty():
		var parts := PackedStringArray()
		for part in node.text_body:
			var value: String = _arguments[part].name if part is Model.GdExpression else literal(part)
			parts.append("[%s, %s]" % [value,_string("%s:%d:%d" % [_file.name,part.span.start.line,part.span.start.column])])
		_line(variable+".set_text_body(["+", ".join(parts)+"])",node.span,indentation)
	if node.preset!=null: _line(variable+" = preload("+_resource(Preset)+").apply("+_arguments[node.preset_expression].name+", "+variable+")",node.span,indentation)
	return variable

func _layout(layout: Model.Layout) -> void:
	var indent := " ".repeat(layout.span.start.column-1)
	# Preserve the file's indentation convention for native statements/closures.
	if _module.indentation.begins_with("\t"): indent = "\t".repeat((layout.span.start.column-1)/_module.indentation.length())
	for index in range(layout.bindings.size()):
		var binding = layout.bindings[index]
		if index>0: _writer.append("\n"+indent,binding.span)
		_writer.append("var "+binding.symbol+" = preload("+_resource(Preset)+").new("+binding.base+", ",binding.span)
		if binding.scope==0:
			var method: String = binding.symbol+"_defaults"
			while _module.identifiers.has(method): method += "_"
			_module.identifiers.append(method)
			_preset_methods.append({"name":method,"binding":binding})
			_writer.append("Callable(self, "+_string(method)+")",binding.span)
		else:
			_writer.append("func(): return ",binding.span)
			_default_groups(binding)
		_writer.append(", "+var_to_str(binding.generated)+", "+_string("%s:%d:%d" % [_file.name,binding.span.start.line,binding.span.start.column])+")",binding.span)

func _default_groups(binding) -> void:
	_writer.append("[",binding.span)
	for group_index in range(binding.groups.size()):
		if group_index>0: _writer.append(", ",binding.span)
		_writer.append("[",binding.span)
		var group = binding.groups[group_index]
		for attr_index in range(group.attributes.size()):
			var attr = group.attributes[attr_index]
			if attr_index>0: _writer.append(", ",attr.span)
			_writer.append("["+("null" if attr.kind=="spread" else _string(attr.name))+", ",attr.span)
			if attr.kind=="spread": _writer.append("preload("+_resource(Element)+").snapshot(",attr.span)
			if attr.value is Model.GdExpression: _parts(attr.value.parts)
			else: _writer.append(literal(attr.value),attr.value.span)
			if attr.kind=="spread": _writer.append(")",attr.span)
			_writer.append(", "+_string("%s:%d:%d" % [_file.name,attr.name_span.start.line,attr.name_span.start.column])+"]",attr.span)
		_writer.append("]",binding.span)
	_writer.append("]",binding.span)


func _bindable(property: Model.Bindable) -> void:
	var incoming := "_gogo_incoming_"+property.name
	while _module.identifiers.has(incoming): incoming += "_"
	var previous := "_gogo_previous_"+property.name
	while _module.identifiers.has(previous): previous += "_"
	var indent := _module.indentation
	_writer.append("signal "+property.signal_name+"(previous: ",property.name_span)
	_code(property.type_span)
	_writer.append(", value: ",property.name_span)
	_code(property.type_span)
	_writer.append(")\n",property.name_span)
	if property.annotations_span != null:
		_writer.append(_file.slice(property.annotations_span),property.annotations_span,true)
	_code(property.declaration_span)
	if property.initializer!=null:
		_writer.append("preload("+_resource(Data)+").value(",property.initializer.span)
		_parts(property.initializer.parts)
		_writer.append(", "+property.data_type+", null, "+_string("%s:%d:%d"%[_file.name,property.name_span.start.line,property.name_span.start.column])+")",property.initializer.span)
	_writer.append(":",property.name_span)
	if property.comment_span != null:
		_writer.append(" ")
		_writer.append(_file.slice(property.comment_span),property.comment_span,true)
	_writer.append("\n"+indent+"set("+incoming+"):\n",property.name_span)
	# Use the native property backing slot: accesses inside its own setter are
	# direct, and declaration initialization does not call the setter.
	_writer.append(indent.repeat(2)+"if is_same("+property.name+", "+incoming+"): return\n",property.name_span)
	if _module.data_shape:
		_writer.append(indent.repeat(2)+"if not preload("+_resource(Data)+").can_attach(self, "+incoming+"): push_error(\"Cyclic Gogo data assignment\"); return\n",property.name_span)
	_writer.append(indent.repeat(2)+"var "+previous+": ",property.name_span)
	_code(property.type_span)
	_writer.append(" = "+property.name+"\n",property.name_span)
	_writer.append(indent.repeat(2)+property.name+" = "+incoming+"\n",property.name_span)
	var emission_indent := indent.repeat(2)
	if _module.data_shape:
		_writer.append(emission_indent+"if not preload("+_resource(Data)+").initializing(self):\n",property.name_span)
		emission_indent += indent
		_writer.append(emission_indent+"preload("+_resource(Data)+").refresh(self)\n",property.name_span)
	_writer.append(emission_indent+property.signal_name+".emit("+previous+", "+incoming+")\n",property.name_span)
	if _module.data_shape: _writer.append(emission_indent+"preload("+_resource(Data)+").notify(self)\n",property.name_span)
	_writer.append(indent+"get:\n"+indent.repeat(2)+"preload("+_resource(State)+").observe(self, &"+_string(property.signal_name)+")\n"+indent.repeat(2)+"return "+property.name+"\n",property.name_span)

func _binding_argument(argument: Argument) -> void:
	var path := argument.binding_path.duplicate()
	var root: String = path.pop_front()
	var field: String = path.pop_back()
	var owner := "_gogo_root"
	var source := "_gogo_source"
	var edit := "_gogo_edit"
	while _module.identifiers.has(owner): owner += "_"
	while _module.identifiers.has(source): source += "_"
	while _module.identifiers.has(edit): edit += "_"
	var endpoint := owner
	var checks: Array[String] = [owner+" != null"]
	for name in path:
		endpoint += "."+str(name)
		checks.append(endpoint+" != null")
	_writer.append("preload("+_resource(Binding)+").new("+root+", func("+owner+"): return "+endpoint+" if "+" and ".join(checks)+" else null, "+_string(field)+", func("+source+", "+edit+": "+argument.binding_type+"): "+source+"."+field+" = "+edit+", "+_string(".".join(argument.binding_path))+", (",argument.expression.span)
	# Keep the original property read in authored scope: native semantic
	# validation still rejects unknown members, and the getter runs once.
	_parts(argument.expression.parts)
	var original_checks: Array[String] = []
	var original := root
	original_checks.append(original+" != null")
	for name in path:
		original += "."+str(name)
		original_checks.append(original+" != null")
	_writer.append(") if "+" and ".join(original_checks)+" else null"+(", TYPE_STRING" if argument.binding_type=="String" else "")+")",argument.expression.span)

func _render_call(node: Model.RenderCall) -> void:
	var cast: String = node.result_type
	if node.statement or cast in ["void","Variant"]: cast = ""
	if not cast.is_empty(): _writer.append("(",node.span)
	var member := not node.receiver.is_empty()
	var base := member and node.receiver.size()==1 and node.receiver[0] is Model.Code and _file.text.substr(node.receiver[0].span.start.index,node.receiver[0].span.end.index-node.receiver[0].span.start.index).strip_edges()=="super"
	_writer.append("preload("+_resource(State)+")."+("base_at" if base else "method_at" if member else "call_at")+"("+_string(_file.name+":"+str(node.span.start.offset))+", ",node.span)
	if base:
		_writer.append("self, "+_string(_output_directory.path_join(_file.generated_path().get_file()))+", "+_string(node.method),node.span)
	elif member:
		_parts(node.receiver)
		_writer.append(", "+_string(node.method),node.span)
	else: _parts(node.callee)
	_writer.append(", [",node.span)
	for index in range(node.arguments.size()):
		if index>0: _writer.append(", ",node.span)
		_parts(node.arguments[index].parts)
	if member:
		var receiver := "_gogo_receiver"
		var args := "_gogo_arguments"
		while _module.identifiers.has(receiver): receiver += "_"
		while _module.identifiers.has(args): args += "_"
		_writer.append("], func("+receiver+", "+args+"): "+("" if node.result_type=="void" or node.statement else "return ")+("super" if base else receiver)+"."+node.method+"(",node.span)
		for index in range(node.arguments.size()):
			if index>0: _writer.append(", ",node.span)
			_writer.append(args+"["+str(index)+"]",node.span)
		_writer.append(")",node.span)
	else: _writer.append("]",node.span)
	# Never run/retain the proof closure: native static checking still sees the
	# authored call and its original argument types before source publication.
	_writer.append(", func(): ",node.span)
	if node.callable_value:
		_parts(node.callee)
		_writer.append(".call(",node.span)
		for index in range(node.arguments.size()):
			if index>0: _writer.append(", ",node.span)
			_parts(node.arguments[index].parts)
		_writer.append(")",node.span)
	else: _parts(node.original)
	if node.reactive_lambda: _writer.append(", true",node.span)
	_writer.append(")",node.span)
	if not cast.is_empty(): _writer.append(" as "+_memo_type(cast)+")",node.span)

func _memo_type(type: String) -> String:
	var source := Source.new(type)
	var lexer = preload("lexer.gd").new(source)
	var cursor := 0
	var result := ""
	while cursor<type.length():
		var token = lexer.next_token(cursor)
		if token==null: return type
		cursor = token.span.end.index
		result += _module.import_aliases.get(token.text,token.text) if token.kind=="identifier" else token.text
	return result
