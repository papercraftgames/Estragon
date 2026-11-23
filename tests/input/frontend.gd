extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var checks := 0
var failed := false
func check(value: bool,label: String):
	checks += 1
	failed = failed or not value
	print("UI03_FRONTEND ",label,": ",value)
func _initialize():
	var source='extends RefCounted\nconst Input = preload("res://addons/estragon/runtime/node/input.gd")\nclass Plain extends RefCounted:\n    signal text_changed(previous: String, value: String)\n    var text: String = "plain"\nclass ReadOnly extends RefCounted:\n    var reads: int = 0\n    var text: String:\n        get:\n            reads += 1\n            return "read only"\n@bindable var text: String = "Hello"\nvar plain = Plain.new()\nvar read_only = ReadOnly.new()\nvar data: Dictionary = {"text":"dictionary"}\nfunc direct(): return <Input value={self.text} />\nfunc parameter(item): return <Input value={item.text} />\nfunc snapshot():\n    var current := self.text\n    return <Input value={current} />\nfunc computed(): return <Input value={self.text.to_upper()} />\nfunc unobserved(): return <Input value={self.plain.text} />\nfunc readonly(): return <Input value={self.read_only.text} />\nfunc dictionary(): return <Input value={self.data.text} />\nfunc literal(): return <Input value="literal" />\nfunc spread(): return <Input value={self.text} {...{"value":"spread"}} />\n'
	var result = Compiler.compile(source,"app/Probe.gogo","res://app/generated/Probe.gd")
	check(result.ok,"String fixture compiles with exact installed Input alias")
	if not result.ok:
		for d in result.diagnostics: print(d.format())
		quit(1); return
	var script := GDScript.new()
	script.resource_path = "res://app/generated/Probe.gd"
	script.source_code = result.code
	check(script.reload()==OK,"actual native String semantic validation")
	var host = script.new()
	var binding = host.direct().bindings.value
	check(binding.valid and binding.observable and binding.kind==TYPE_STRING and binding.value=="Hello","String candidate has typed source metadata and snapshot")
	check(host.parameter(host).bindings.size()==1,"direct parameter path shares implicit String linkage")
	for method in ["snapshot","computed","unobserved","readonly","dictionary","literal","spread"]:
		var element = host.call(method)
		check(element.bindings.is_empty() and element.properties.value is String,"one-way "+method)
	check(host.parameter({"text":"plain"}).bindings.is_empty(),"Dictionary parameter is a one-way native value")
	check(host.read_only.reads==1,"original value getter executes once")
	var again=Compiler.compile(source,"app/Probe.gogo","res://app/generated/Probe.gd")
	check(result.code==again.code and result.source_map.serialize()==again.source_map.serialize(),"String code/maps/contract deterministic")
	check(result.code.contains("TYPE_STRING") and result.code.contains("_gogo_edit: String") and result.source_map.source.text==source,"typed String writer retains source map content")
	for attributes in ['bind:value={self.text}','value','placeholder','disabled="bad"','invalid="bad"','value="one" value="two"','font_size="bad"']:
		var bad=Compiler.compile('extends Node2D\nconst Input = preload("res://addons/estragon/runtime/node/input.gd")\nfunc view(): return <Input '+attributes+' />\n',"app/Bad.gogo","res://app/generated/Bad.gd")
		check(not bad.ok and not bad.diagnostics.is_empty() and bad.diagnostics[0].span.start.line==3,"mapped static rejection "+attributes)
	print("UI03_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI03_FRONTEND_OK")
	quit(1 if failed else 0)
