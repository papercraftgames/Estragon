@tool
extends EditorSyntaxHighlighter
## Native theme palette + edit-invalidated tolerant line contexts.
const Context = preload("lexical_context.gd")
const CODE := Color("dedede")
const KEYWORD := Color("ff7085")
const TAG := Color("8bd5ff")
const PROPERTY := Color("c6a0f6")
const STRING := Color("a6da95")
const COMMENT := Color("808790")
const EXPRESSION := Color("eed49f")
var settings: EditorSettings
var lexical = Context.new()
var _version := -1
const PALETTE := {"code":["text_color",CODE], "keyword":["keyword_color",KEYWORD], "tag":["user_type_color",TAG], "property":["member_variable_color",PROPERTY], "string":["string_color",STRING], "comment":["comment_color",COMMENT], "expression":["symbol_color",EXPRESSION], "symbol":["symbol_color",EXPRESSION], "number":["number_color",Color("a1ffe0")], "type":["base_type_color",TAG], "function":["function_color",Color("57b3ff")], "annotation":["annotation_color",KEYWORD]}

func _init(editor_settings: EditorSettings = null) -> void:
	settings = editor_settings
func _create() -> EditorSyntaxHighlighter:
	return get_script().new(settings)
func _get_name() -> String: return "Gogo"
func _get_supported_languages() -> PackedStringArray: return PackedStringArray(["gogo"])
func _clear_highlighting_cache() -> void: _version = -1
func color(kind: String) -> Color:
	var entry: Array = PALETTE.get(kind,PALETTE.code)
	var key: String = "text_editor/theme/highlighting/"+entry[0]
	return settings.get_setting(key) if settings != null and settings.has_setting(key) else entry[1]
func _get_line_syntax_highlighting(index: int) -> Dictionary:
	var edit := get_text_edit()
	if edit == null: return {}
	if _version != edit.get_version():
		lexical.update(edit.text)
		_version = edit.get_version()
	var result := {0:{"color":color("code")}}
	for token in lexical.line(index).tokens:
		result[token.start] = {"color":color(token.kind)}
		result[token.end] = {"color":color("code")}
	return result
