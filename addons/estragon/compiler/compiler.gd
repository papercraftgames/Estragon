@tool
extends RefCounted
## Pure native compilation. Semantic validation/loading is an explicit next step.
const Model = preload("model.gd")
const Source = preload("source.gd")
const Frontend = preload("frontend.gd")
const Emitter = preload("emitter.gd")
const SourceMap = preload("source_map.gd")

class Compilation extends RefCounted:
	var code: String
	var source_map: SourceMap
	var diagnostics: Array[Model.Diagnostic] = []
	var ok: bool:
		get: return diagnostics.is_empty() and source_map != null

static func compile(source: String, source_name: String = "<source>", output_path: String = "") -> Compilation:
	var result := Compilation.new()
	var frontend := Frontend.analyze(source, source_name, output_path)
	result.diagnostics = frontend.diagnostics
	if not frontend.ok: return result
	result.source_map = Emitter.new(frontend.module, Source.new(source, source_name, output_path)).emit()
	result.code = result.source_map.code
	return result
