@tool
extends RefCounted
## Native frontend data only. No Nodes, runtime components or editor services.

class Position extends RefCounted:
	var index: int # Godot Unicode scalar index for slicing.
	var offset: int # UTF-16 offset for cross-frontend diagnostics/maps.
	var line: int
	var column: int

class Span extends RefCounted:
	var start: Position
	var end: Position

class Diagnostic extends RefCounted:
	var source_name: String
	var span: Span
	var message: String

	func format() -> String:
		return "%s:%d:%d: %s" % [source_name, span.start.line, span.start.column, message]

class Token extends RefCounted:
	var kind: String
	var text: String
	var span: Span

class SyntaxNode extends RefCounted:
	var kind: String
	var span: Span

class Code extends SyntaxNode:
	func _init() -> void:
		kind = "gdscript-source"

class Bindable extends SyntaxNode:
	var name: String
	var name_span: Span
	var type_span: Span
	var type_name: String
	var signal_name: String
	var annotations_span: Span # Native property annotations, never attached to generated signal.
	var declaration_span: Span
	var comment_span: Span
	func _init() -> void:
		kind = "bindable-property"

class GdExpression extends SyntaxNode:
	var parts: Array[SyntaxNode] = []
	func _init() -> void:
		kind = "gdscript-expression"

class Literal extends SyntaxNode:
	var value: Variant
	var type_name: String
	func _init() -> void:
		kind = "raw-literal"

class Attribute extends RefCounted:
	var span: Span
	var binding_path: Array = []
	var binding_type := "bool"
	var kind: String = "property"
	var name: String
	var name_span: Span
	var value: SyntaxNode
	var type_name: String

class Component extends SyntaxNode:
	var name: String
	var name_span: Span
	var runtime_class: String
	var preset: Preset
	var preset_expression: GdExpression
	var attributes: Array[Attribute] = []
	var children: Array[SyntaxNode] = []
	var text_body: Array[SyntaxNode] = []
	func _init() -> void:
		kind = "component-expression"

class Layout extends SyntaxNode:
	var root: Component
	var mutable := false
	var exported := false
	var bindings: Array = []
	func _init() -> void: kind = "layout-declaration"

class Preset extends RefCounted:
	var name: String
	var symbol: String
	var base: String
	var resolved: Dictionary = {}
	var groups: Array = []
	var generated: Dictionary = {}
	var span: Span
	var visible: int
	var scope: int
	var mutable := false
	var exported := false

class RenderCall extends SyntaxNode:
	var result_type: String = ""
	var statement := false
	var reactive_lambda := false
	var callable_value := false
	var callee: Array[SyntaxNode] = []
	var receiver: Array[SyntaxNode] = []
	var method: String = ""
	var arguments: Array = []
	var original: Array[SyntaxNode] = []
	func _init() -> void: kind = "render-call"

class Module extends RefCounted:
	var render_functions: Array = []
	var ordinary_functions: Array = []
	var presets: Array = []
	var import_aliases: Dictionary = {}
	var identifier_imports: Array = []
	var project_imports: Dictionary = {}
	var resource_imports: Array = []
	var composition: bool = false
	var parts: Array[SyntaxNode] = []
	var identifiers: PackedStringArray = []
	var indentation: String = "\t"

class Result extends RefCounted:
	var module: Module
	var tokens: Array[Token] = []
	var diagnostics: Array[Diagnostic] = []
	var ok: bool:
		get: return module != null and diagnostics.is_empty()
