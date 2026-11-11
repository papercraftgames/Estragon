extends SceneTree
const Completion = preload("res://addons/estragon/editor/completion.gd")
const Context = preload("res://addons/estragon/editor/lexical_context.gd")
var checks := 0
var failed := false
var model := Completion.new()
const SOURCE := "res://app/Screens/Home.gogo"
func check(ok: bool, label: String) -> void:
	checks += 1
	print("E10_CHECK ",label,": ",ok)
	if not ok: failed = true
func options(text: String) -> Array:
	var at := text.find("§")
	var before := text.left(at)
	var rows := before.split("\n")
	return model.candidates(text.replace("§",""),SOURCE,Context.new(),rows.size()-1,rows[-1].length())
func has(text: String, name: String) -> bool:
	return options(text).any(func(item): return item.text==name or item.text.begins_with(name+" —"))
func hint(text: String) -> String:
	var at := text.find("§")
	var rows := text.left(at).split("\n")
	return model.call_hint(text.replace("§",""),SOURCE,Context.new(),rows.size()-1,rows[-1].length())
func _initialize() -> void:
	for base in ["Node2D","Node3D"]:
		var header: String = "extends "+base+"\nfunc demo():\n\t"
		for call in ["get_tree().","self.get_tree().","(get_tree()).","get_viewport().get_tree().","get_node(\"Path\").get_tree().","get_node(str(foo(bar()))).get_tree()."]:
			check(has(header+call+"qu§","quit"),base+" static return chain "+call)
		check(has(header+"get_viewport().§","get_visible_rect"),base+" viewport native return members")
		check(has(header+"get_node(\"Path\").§","queue_free"),base+" get_node conservative Node members")
	var tree := "extends Node2D\nvar tree: SceneTree\nfunc demo(local: Node):\n\t"
	check(has(tree+"tree.qu§","quit") and has(tree+"local.get_tree().qu§","quit"),"typed property/argument chains")
	check(has("extends Node2D\nfunc demo():\n\tvar local: Node\n\tlocal.get_tree().qu§","quit"),"typed local method chain")
	check(has("extends Node2D\nfunc scene() -> SceneTree:\n\treturn get_tree()\nfunc demo():\n\tscene().qu§","quit"),"explicit typed source method return")
	check(has("extends Node2D\nfunc scene() -> SceneTree:\n\treturn get_tree()\nfunc demo():\n\tself.scene().qu§","quit"),"explicit self source method return")
	check(hint(tree+"get_tree().quit(§").begins_with("quit(") and hint(tree+"get_tree().quit(§").contains("void"),"chained native call signature")
	check(hint(tree+"get_node(str(foo())).get_tree().quit(§").begins_with("quit("),"nested arguments do not confuse chained hint")
	check(has(tree+"get_tree() . qu§","quit"),"whitespace between postfix tokens")
	check(has(tree+"get_node(\n\t\tstr(foo())\n\t).get_tree().qu§","quit"),"multiline balanced call arguments")
	check(has(tree+"return <Node name={get_tree().qu§","quit"),"GGX attribute expression uses native chain completion")
	for bad in ["missing().","get_tree(.","tree[0].","get_tree().missing().","get_tree().quit().","get_tree().quit."]:
		check(options(tree+bad+"§").is_empty(),"unproven receiver suppressed "+bad)
	check(options("extends Node2D\nfunc scene(): return get_tree()\nfunc demo():\n\tscene().§").is_empty(),"dynamic source return never fabricated")
	check(options("extends Node2D\nfunc a(tree: SceneTree): pass\nfunc b():\n\ttree.§").is_empty(),"typed argument from different function is out of scope")
	check(options("extends Node2D\nfunc demo(tree: Variant):\n\ttree.§").is_empty(),"explicit Variant receiver remains dynamic")
	check(options(tree+'# get_tree().§').is_empty() and options(tree+'"get_tree().§').is_empty(),"comment/string suppression")
	check(has(tree+"get_node(\"paren ) and .\").get_tree().qu§","quit"),"strings in arguments stay opaque")
	check(has(tree+"((get_tree())).qu§","quit"),"nested grouped receiver")
	check(has(tree+"get_tree().root.get_tree().qu§","quit"),"native returned property chain")
	check(options("extends Node2D\nfunc demo():\n\ttree.§\n\tvar tree: SceneTree\n").is_empty(),"later local declaration does not leak into earlier scope")
	check(options("extends Node2D\nfunc demo():\n\tvar tree: SceneTree.Unresolved\n\ttree.§").is_empty(),"unresolved qualified type does not fabricate outer-class members")
	check(options(tree+"get_tree()"+".get_tree()".repeat(40)+".§").is_empty(),"chain recursion bounded")
	check(options(tree+"get_node("+" ".repeat(4200)+").§").is_empty(),"receiver scan budget bounded")
	check(has("extends Node2D\nfunc demo():\n\treturn <Nod§","Node2D"),"GGX tag completion remains available")
	var calls := options(tree+"get_tree().qu§")
	check(calls.any(func(item): return item.text=="quit" and item.insert=="quit()" and item.kind==CodeEdit.KIND_FUNCTION and item.hint.begins_with("quit(")) and calls.all(func(item): return item.text.begins_with("qu")),"filtered callable invocation and native signature")
	check(options(tree+"get_tree().qu§()").any(func(item): return item.text=="quit" and item.insert=="quit"),"existing invocation parenthesis not duplicated")
	check(options(tree+'return <Node tree_exited={self.get_tree().qu§').any(func(item): return item.text=="quit" and item.insert=="quit"),"signal attribute completion preserves Callable reference rather than invoking it")
	check(has('extends Node2D\nconst SceneTree = Node2D\nfunc demo():\n\tget_tree().qu§',"quit"),"native return identity is not redirected by a same-named source alias")
	var helper := "res://app/ChainHelper.gd"
	DirAccess.make_dir_recursive_absolute(helper.get_base_dir())
	var file := FileAccess.open(helper,FileAccess.WRITE)
	file.store_string("extends RefCounted\nfunc scene() -> SceneTree:\n\treturn null\n")
	file.close()
	var imported := 'extends Node2D\nconst Helper = preload("../../ChainHelper.gd")\nvar helper: Helper\nfunc demo():\n\thelper.scene().qu§'
	check(has(imported,"quit") and not ResourceLoader.has_cached(helper),"source typed method metadata never loads authored Script")
	model.sources[helper] = "extends RefCounted\nfunc scene() -> Viewport:\n\treturn null\n"
	check(has(imported.replace(".qu§",".§"),"get_visible_rect") and not has(imported,"quit"),"unsaved dependency return type overrides saved metadata")
	print("E10_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("E10_CHAIN_OK")
	quit(1 if failed else 0)
