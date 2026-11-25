extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Binding = preload("res://addons/estragon/runtime/composition/binding.gd")
var checks := 0
var failed := false
func check(test: bool,label: String):
	checks += 1
	print("UI04_FRONTEND ",label,": ",test)
	failed = failed or not test
func _initialize():
	var header := 'extends Node2D\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Choices = preload("res://addons/estragon/runtime/node/radio_group.gd")\nconst Option = preload("res://addons/estragon/runtime/node/radio.gd")\n@bindable var choice: String = "a"\n'
	var source := header+'func direct(): return <Choices value={self.choice}><Option value={self.choice}>A</Option></Choices>\nfunc snapshot():\n    var current := self.choice\n    return <Choices value={current}><Option value="a" /></Choices>\nfunc computed(): return <Choices value={self.choice.to_upper()} />\n'
	var result = Compiler.compile(source,"examples/radio/Probe.gogo","res://examples/radio/generated/Probe.gd")
	check(result.ok,"exact installed Script aliases compile")
	if not result.ok:
		for diagnostic in result.diagnostics: print(diagnostic.format())
		quit(1); return
	var script := GDScript.new()
	script.resource_path = "res://examples/radio/generated/Probe.gd"
	script.source_code = result.code
	check(script.reload()==OK,"native semantic validation")
	var host = script.new()
	var direct = host.direct()
	check(direct.bindings.size()==1 and direct.bindings.value.kind==TYPE_STRING and direct.bindings.value.observable,"group direct path has existing String linkage")
	check(direct.children[0].bindings.is_empty() and direct.children[0].properties.value=="a","Radio identity direct source never manufactures a two-way writer")
	check(not Binding.declared(preload("res://addons/estragon/runtime/node/radio.gd"),"value",TYPE_STRING),"option Script has no writable observable String binding metadata")
	for method in ["snapshot","computed"]: check(host.call(method).bindings.is_empty(),"one-way "+method)
	var again = Compiler.compile(source,"examples/radio/Probe.gogo","res://examples/radio/generated/Probe.gd")
	check(result.code==again.code and result.source_map.serialize()==again.source_map.serialize(),"deterministic code/maps")
	check(result.code.contains("_gogo_edit: String") and result.source_map.source.text==source,"typed writer retains exact authored content")
	host.free()
	for body in ['<Option />','<Option value="" />','<Choices><Option value="a"/><Option value="a" disabled /></Choices>','<Choices bind:value={self.choice} />','<Choices value />','<Option value="a" selected />','<Choices disabled="bad" />']:
		var bad = Compiler.compile(header+'func view(): return '+body+'\n',"examples/radio/Bad.gogo","res://examples/radio/generated/Bad.gd")
		check(not bad.ok and not bad.diagnostics.is_empty() and bad.diagnostics[0].span.start.line==6,"authored static rejection "+body)
	print("UI04_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI04_FRONTEND_OK")
	quit(1 if failed else 0)
