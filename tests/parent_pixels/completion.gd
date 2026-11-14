extends SceneTree
const Completion = preload("res://addons/estragon/editor/completion.gd")
const Context = preload("res://addons/estragon/editor/lexical_context.gd")
func _initialize() -> void:
	var failed := false
	for declaration in ["", "\tconst Pixels = 1\n", "\tvar Pixels: Node2D\n"]:
		var source: String = 'extends Node\nconst Pixels = preload("res://addons/estragon/runtime/composition/pixels.gd")\nfunc test():\n'+declaration+'\tPixels.parent_w'
		var lexical := Context.new()
		lexical.update(source)
		var rows := source.split("\n")
		var result := Completion.new().candidates(source,"res://probe.gd",lexical,rows.size()-1,rows[-1].length())
		var found: bool = result.any(func(item): return item.insert.begins_with("parent_width"))
		var ok: bool = found == declaration.is_empty()
		print("L02_COMPLETION ",str(declaration),": ",ok)
		if not ok: failed = true
	if not failed: print("L02_COMPLETION_OK")
	quit(1 if failed else 0)
