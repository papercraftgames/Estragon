extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Completion = preload("res://addons/estragon/editor/completion.gd")
const Context = preload("res://addons/estragon/editor/lexical_context.gd")
const Catalog = preload("res://addons/estragon/editor/components.gd")
var failed := false
var checks := 0
var completion = Completion.new()
const PATH := "res://app/Editor.gogo"
func check(ok: bool,label: String):
	checks += 1
	print("D07_FRONTEND ",label,": ",ok)
	failed = failed or not ok
func options(source: String) -> Array:
	var index := source.find("§")
	var text := source.replace("§","")
	var before := text.left(index).split("\n")
	return completion.candidates(text,PATH,Context.new(),before.size()-1,before[-1].length())
func _initialize():
	var imported := 'extends Node2D\nconst Button=preload("res://addons/estragon/runtime/node/button.gd")\n'
	var source := imported+'const Other=Button\nvar caption="é 🌱 Button"\n# Button is an import, never a comment rewrite.\nfunc typed(value: Array[Button]) -> Button: return value[0]\nfunc make():\n\tvar object={"Button":"member"}\n\treturn <Button text={object.Button+str(Button)} />\nfunc body(): return <Label>{str(Button)}</Label>\n'
	var result = Compiler.compile(source,PATH,"res://app/generated/Editor.gd")
	check(result.ok,"native-name preload with constructors/types/body expressions compiles")
	if result.ok:
		check(result.code.contains('const _GogoImport_0=preload(') and result.code.contains('Array[_GogoImport_0]') and result.code.contains('-> _GogoImport_0') and result.code.contains('const Other=_GogoImport_0'),"lexical declarations/types/ordinary Script alias share one private identity")
		check(result.code.contains('"é 🌱 Button"') and result.code.contains('# Button is an import') and result.code.contains('object.Button') and result.code.contains('str(_GogoImport_0)'),"strings/comments/unrelated members remain intact; body references lower")
		var index: int = result.code.find('_GogoImport_0')
		var point = preload("res://addons/estragon/compiler/source.gd").new(result.code).position(index)
		var original = result.source_map.original_position(point.line,point.column)
		check(original.line==2 and original.column==7,"generated private alias maps to exact authored identifier span")
		var again = Compiler.compile(source,PATH,"res://app/generated/Editor.gd")
		check(again.code==result.code and again.source_map.serialize()==result.source_map.serialize(),"private symbol/range maps deterministic")
	var collision = Compiler.compile(imported+'var _GogoImport_0=1\nfunc make(): return <Button />\n',PATH)
	check(collision.ok and collision.code.contains('const _GogoImport_0_='),"generated identifier avoids authored symbol collisions")
	for body in ['const Button=preload("res://addons/estragon/runtime/node/button.gd")\nfunc view():return <Button />','func view():return <Button imaginary />','func view():return <Button background_color="bad" />','func view():return <Button pressed={func():pass} />','var Button=1\nfunc view():return <Button />','func method(Button: int): pass']:
		var rejected = Compiler.compile(imported+body,PATH)
		check(not rejected.ok and not rejected.diagnostics.is_empty() and rejected.diagnostics[0].source_name==PATH,"source-located duplicate/invalid imported contract "+body.left(30))
	for path in ['res://missing_button.gd','res://tests/button_imports/non_node.gd','res://tests/button_imports/required.gd','res://app/panel_gradient.tres']:
		var rejected = Compiler.compile('extends Node2D\nconst Button=preload("'+path+'")\nfunc view():return <Button />\n',PATH)
		check(not rejected.ok and not rejected.diagnostics.is_empty() and rejected.diagnostics[0].span.start.line>=2,"nonconstructible/missing/resource import rejects "+path)
	var generic = Compiler.compile('extends Node2D\nconst Node2D=preload("res://addons/estragon/runtime/node/button.gd")\nfunc make():return <Node2D />\n',PATH)
	check(generic.ok and generic.code.contains('const _GogoImport_0=preload('),"native-name lowering is explicit import precedence, not Button magic")
	var plain = Compiler.compile('extends Node2D\nfunc make():return <Button text="Native" />\n',PATH)
	check(plain.ok and plain.code.contains('.new("Button",') and not plain.code.contains('_GogoImport_'),"unimported Button remains ClassDB with no implicit framework fallback")
	check(not Compiler.compile('extends Node2D\nfunc make():return <Button background_color="#383838" />\n',PATH).ok,"native Button never gains fake Estragon properties")
	var bare := 'extends Node2D\nfunc make(): return <Bu§ />\n'
	var offered := options(bare)
	var native := offered.filter(func(item): return item.text.begins_with("Button — Godot"))
	var framework := offered.filter(func(item): return item.text.contains("Estragon native"))
	check(native.size()==1 and native[0].imports.is_empty() and framework.size()==1 and framework[0].insert=="Button" and framework[0].imports[0].alias=="Button","popup separates native Godot from deliberate Estragon import")
	check(not Catalog.ITEMS.any(func(item):return item.alias in ["UiButton","EButton"]),"catalog never recommends prefixed Button aliases")
	var complete := bare.replace("Bu§","Button")
	check(completion.import_plan(complete,PATH).text.is_empty(),"Add Missing Imports leaves an unimported native Button alone")
	if not framework.is_empty():
		var edit = completion.import_plan(complete,PATH,framework[0].imports)
		check(edit.text.begins_with('const Button = preload(') and not edit.text.contains('UiButton') and not edit.text.contains('EButton'),"explicit completion selection inserts the legal authored Button import")
	var authored := imported+'func make():return <Button bac§ />\n'
	check(options(authored).any(func(item):return item.insert=="background_color"),"source-aware imported Button fields available")
	check(not options('extends Node2D\nfunc make():return <Button bac§ />\n').any(func(item):return item.insert=="background_color"),"removing import immediately restores native field completion without stale cache")
	check(completion.definition(imported,PATH,"Button").ends_with('/runtime/node/button.gd'),"definition lookup returns actual lexical import resource")
	print("D07_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("D07_FRONTEND_OK")
	quit(1 if failed else 0)
