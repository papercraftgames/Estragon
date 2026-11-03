@tool
extends RefCounted
## ADR-0015-B1 opt-in proof, not the default Gogo frontend/editor mode.
const Model = preload("res://addons/estragon/compiler/model.gd")
const Source = preload("res://addons/estragon/compiler/source.gd")
const Parser = preload("res://addons/estragon/compiler/parser.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Validator = preload("res://addons/estragon/compiler/node_proof/validator.gd")
const Emitter = preload("res://addons/estragon/compiler/node_proof/emitter.gd")

static func compile(text: String, source_name: String, script_types: Dictionary = {}) -> Compiler.Compilation:
	var result := Compiler.Compilation.new()
	var file := Source.new(text, source_name)
	var parser := Parser.new(file)
	var module := parser.parse()
	if module != null:
		if module.mode != "hybrid": file.fail("B1 Node proof requires a GDScript-first module", 0)
		else: Validator.new(file, script_types).validate(module)
	result.diagnostics = file.diagnostics
	if not result.diagnostics.is_empty(): return result
	result.mode = "node-proof"
	result.source_map = Emitter.new(module, file).emit()
	result.code = result.source_map.code
	return result
