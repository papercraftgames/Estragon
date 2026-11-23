extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var checks := 0
var failed := false
var sequence := 0
func check(value: bool,label: String):
	checks += 1
	print("UI02_FRONTEND ",label,": ",value)
	failed = failed or not value
func compile(text: String):
	sequence += 1
	return Compiler.compile(text,"res://Probe.gogo","res://Probe%d.gd" % sequence)
func instance(text: String):
	var result = compile(text)
	for diagnostic in result.diagnostics: print(diagnostic.format())
	check(result.ok,"native frontend accepts fixture")
	if not result.ok: return null
	var script := GDScript.new()
	script.resource_path = "res://Probe%d.gd" % sequence
	script.source_code = result.code
	var valid := script.reload()==OK
	check(valid,"actual native GDScript semantic validation")
	return script.new() if valid else null
func _initialize():
	var header='extends RefCounted\nconst Checkbox = preload("res://addons/estragon/runtime/node/checkbox.gd")\n'
	var data='class Plain extends RefCounted:\n    var flag: bool = false\nclass ReadOnly extends RefCounted:\n    var flag: bool:\n        get: return true\nvar plain = Plain.new()\nvar read_only = ReadOnly.new()\n@bindable var flag: bool = false\n'
	var functions='func direct(): return <Checkbox value={self.flag} />\nfunc parameter(item): return <Checkbox value={item.flag} />\nfunc snapshot():\n    var current := self.flag\n    return <Checkbox value={current} />\nfunc computed(): return <Checkbox value={not self.flag} />\nfunc unobserved(): return <Checkbox value={self.plain.flag} />\nfunc getter_only(): return <Checkbox value={self.read_only.flag} />\nfunc literal(): return <Checkbox value={true} />\nfunc spread(): return <Checkbox value={self.flag} {...{ "value": true }} />\n'
	var host = instance(header+data+functions)
	if host!=null:
		check(host.direct().bindings.size()==1 and host.parameter(host).bindings.size()==1,"self and direct object paths bind when both contracts are observable/writable Bool")
		for method in ["snapshot","computed","unobserved","getter_only","literal","spread"]:
			var element = host.call(method)
			check(element.bindings.is_empty() and typeof(element.properties.value)==TYPE_BOOL,"one-way snapshot/computed/plain/read-only/literal/spread: "+method)
	var result=compile(header+data+functions)
	var again=Compiler.compile(header+data+functions,"res://Probe.gogo","res://Probe%d.gd" % sequence)
	check(result.code==again.code and result.source_map.serialize()==again.source_map.serialize(),"implicit linkage and metadata/maps deterministic")
	var mapped:=false
	var lines: PackedStringArray = result.code.split("\n")
	for index in range(lines.size()):
		if lines[index].contains('binding.gd'):
			var point=result.source_map.original_position(index+1,lines[index].find("preload")+1)
			mapped = mapped or point!=null and point.line>=12
	check(mapped,"generated binding linkage retains original authored expression mapping")
	for attribute in ['bind:value={self.flag}','value={self.flag} value={true}','disabled="false"','checked_background_color="bad"','width="bad"']:
		var bad=compile(header+data+'func view(): return <Checkbox '+attribute+' />\n')
		check(not bad.ok and not bad.diagnostics.is_empty() and bad.diagnostics[0].span.start.line>1,"mapped static negative property/syntax: "+attribute)
	var native=compile('extends Node2D\nfunc view(): return <CheckBox button_pressed={true} />\n')
	check(native.ok and native.code.contains('new('),"unimported native Godot CheckBox remains native, no reserved alias")
	print("UI02_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI02_FRONTEND_OK")
	quit(1 if failed else 0)
