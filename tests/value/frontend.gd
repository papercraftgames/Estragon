extends SceneTree
const Compiler=preload("res://addons/estragon/compiler/compiler.gd")
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_FRONTEND ",label,": ",test)
func _initialize():
	var header='extends Node2D\nconst Element=preload("res://addons/estragon/runtime/composition/element.gd")\nconst Slider=preload("res://addons/estragon/runtime/node/slider.gd")\nconst NumberInput=preload("res://addons/estragon/runtime/node/number_input.gd")\nconst IntegerInput=preload("res://addons/estragon/runtime/node/integer_input.gd")\nconst Select=preload("res://addons/estragon/runtime/node/select.gd")\nconst Option=preload("res://addons/estragon/runtime/node/option.gd")\n@bindable var decimal: float=0.5\n@bindable var integer: int=3\n@bindable var choice: String="a"\n'
	var source=header+'func decimal_view(): return <Slider value={self.decimal} />\nfunc number_view(): return <NumberInput value={self.decimal} />\nfunc integer_view(): return <IntegerInput value={self.integer} />\nfunc choice_view(): return <Select value={self.choice}><Option value={self.choice}/></Select>\nfunc snapshot():\n    var current: float=self.decimal\n    return <Slider value={current} />\nfunc computed(): return <Slider value={self.decimal*2.0} />\n'
	var result=Compiler.compile(source,"examples/values/Probe.gogo","res://examples/values/generated/Probe.gd")
	check(result.ok,"all native value aliases compile with typed metadata")
	if not result.ok:
		for diagnostic in result.diagnostics: print(diagnostic.format())
		quit(1);return
	var script:=GDScript.new();script.resource_path="res://examples/values/generated/Probe.gd";script.source_code=result.code
	check(script.reload()==OK,"actual-path numeric writer semantics")
	var host=script.new()
	for method in ["decimal_view","number_view","integer_view","choice_view"]:
		var element=host.call(method)
		var kind:int=TYPE_INT if method=="integer_view" else TYPE_STRING if method=="choice_view" else TYPE_FLOAT
		check(element.bindings.size()==1 and element.bindings.value.kind==kind and element.bindings.value.observable,"exact typed binding "+method)
	check(host.choice_view().children[0].bindings.is_empty(),"Option identity never becomes two-way")
	check(host.snapshot().bindings.is_empty() and host.computed().bindings.is_empty(),"numeric snapshots/computed expressions stay one-way")
	var again=Compiler.compile(source,"examples/values/Probe.gogo","res://examples/values/generated/Probe.gd")
	check(result.code==again.code and result.source_map.serialize()==again.source_map.serialize() and result.source_map.source.text==source,"deterministic maps and exact authored content")
	check(result.code.contains("_gogo_edit: float") and result.code.contains("_gogo_edit: int") and result.code.contains("TYPE_FLOAT") and result.code.contains("TYPE_INT"),"typed float and int source writers in the single emitter")
	host.free()
	for body in ['<Option />','<Option value=""/>','<Select><Option value="a"/><Option value="a" disabled/></Select>','<Slider orientation="diagonal"/>','<Slider min_value={2.0} max_value={1.0}/>','<Slider step={-0.5}/>','<Slider value={NAN}/>','<NumberInput value={INF}/>','<IntegerInput step={0}/>','<IntegerInput value={0.5}/>','<Slider value={0.53} min_value={0.0} max_value={1.0} step={0.05}/>','<Slider bind:value={self.decimal}/>','<IntegerInput bad_numeric_property="bad"/>']:
		var bad=Compiler.compile(header+'func view(): return '+body+'\n',"examples/values/Bad.gogo","res://examples/values/generated/Bad.gd")
		check(not bad.ok and not bad.diagnostics.is_empty() and bad.diagnostics[0].span.start.line==11,"mapped static rejection "+body)
	print("UI05_FRONTEND_ASSERTIONS ",checks," ok=",ok)
	if ok: print("UI05_FRONTEND_OK")
	quit(0 if ok else 1)
