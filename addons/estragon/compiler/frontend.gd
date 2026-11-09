@tool
extends RefCounted
## Native source -> typed frontend result. No emitter, subprocess or editor state.
const Model = preload("model.gd")
const Source = preload("source.gd")
const Parser = preload("parser.gd")
const Bindable = preload("bindable.gd")
const Validator = preload("validator.gd")
const Composition = preload("composition.gd")

static func analyze(text: String, source_name: String = "<source>", output_path: String = "", project_sources = null) -> Model.Result:
	var file := Source.new(text, source_name, output_path, project_sources)
	var parser := Parser.new(file)
	var result := Model.Result.new()
	var module := parser.parse()
	if module != null: Bindable.new(file).apply(module)
	if module != null and file.diagnostics.is_empty(): Composition.new(file).apply(module)
	if module != null and file.diagnostics.is_empty(): Validator.new(file).validate(module)
	result.tokens = parser.lexer.tokens
	result.diagnostics = file.diagnostics
	result.module = module if result.diagnostics.is_empty() else null
	return result
