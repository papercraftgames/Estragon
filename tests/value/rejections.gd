extends SceneTree
const Compiler=preload("res://addons/estragon/compiler/compiler.gd")
const State=preload("res://addons/estragon/runtime/composition/state.tres")
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_REJECTION ",label,": ",test)
func frames():
	for i in range(10): await process_frame
func _initialize(): run.call_deferred()
func run():
	var host=load("res://examples/values/generated/Values.gd").new();root.add_child(host);await frames()
	var select=host.get_node("UI/Select");var native=select.get_native_control();select.grab_focus()
	var id:int=native.get_instance_id();var events:Array=[];select.value_changed.connect(func(a,b):events.append([a,b]))
	for props in [{"repair":{"value":"explore"}},{"repair":{"value":""}},{"repair":{"value":4}}]:
		print("UI05_EXPECTED_BEGIN");host.option_props=props;await frames();print("UI05_EXPECTED_END")
		check(native.get_instance_id()==id and native.text=="Explore" and select.has_focus() and events.is_empty(),"invalid Option desired set atomically retains popup trigger/focus/value")
		host.option_props={};await frames()
	var h=host.get_node("UI/Ranges").get_child(0).get_node("Horizontal")
	h.grab_focus();var hid:int=h.get_native_control().get_instance_id()
	for props in [{"min_value":2.0,"max_value":1.0},{"step":-0.05},{"value":NAN},{"value":INF},{"value":0.53},{"value":3},{"orientation":"diagonal"},{"bad_numeric_property":true}]:
		print("UI05_EXPECTED_BEGIN");host.numeric_props=props;await frames();print("UI05_EXPECTED_END")
		check(h.get_native_control().get_instance_id()==hid and h.value==0.5 and h.has_focus() and host.model.volume==0.5,"invalid desired numeric config preserves whole mounted view/model "+str(props))
		host.numeric_props={};await frames()
	var range_events:Array=[];h.value_changed.connect(func(a,b):range_events.append([a,b]))
	print("UI05_EXPECTED_BEGIN");h.step=-1.0;print("UI05_EXPECTED_END")
	check(h.step==0.05 and h.value==0.5 and range_events.is_empty(),"native negative step rejects without transition")
	print("UI05_EXPECTED_BEGIN");h.value=NAN;print("UI05_EXPECTED_END")
	check(h.value==0.5 and range_events.is_empty(),"native NaN rejects without transition")
	var source='extends Node2D\nconst Element=preload("res://addons/estragon/runtime/composition/element.gd")\nconst Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")\nconst Slider=preload("res://addons/estragon/runtime/node/slider.gd")\nconst IntegerInput=preload("res://addons/estragon/runtime/node/integer_input.gd")\nconst Model=preload("res://examples/values/generated/Model.gd")\n@bindable var model: Model=Model.new()\n@bindable var wrong: bool=false\nfunc build_view() -> Element:\n    return <Entry name="Root"><Slider name="Decimal" value={self.model.volume} min_value={0.0} max_value={1.0} step={0.05}/>{<Slider name="Wrong" value={self.model.lives}/> if self.wrong else null}<IntegerInput name="Integer" value={self.model.lives}/></Entry>\n'
	var result=Compiler.compile(source,"examples/values/Negative.gogo","res://examples/values/generated/Negative.gd")
	var script:=GDScript.new();script.resource_path="res://examples/values/generated/Negative.gd";script.source_code=result.code
	check(result.ok and script.reload()==OK,"negative binding fixture has native semantic/type metadata proof")
	var probe=script.new();root.add_child(probe);await frames();var decimal=probe.get_node("Root/Decimal")
	print("UI05_EXPECTED_BEGIN");probe.wrong=true;await frames();print("UI05_EXPECTED_END")
	check(not probe.has_node("Root/Wrong") and probe.get_node("Root/Decimal")==decimal,"int model cannot silently bind float endpoint; prior tree retained")
	probe.wrong=false;await frames()
	var old_model=probe.model
	print("UI05_EXPECTED_BEGIN");probe.model=null;await frames();print("UI05_EXPECTED_END")
	check(probe.get_node("Root/Decimal")==decimal and decimal.value==0.5,"null numeric source rejects whole transaction")
	probe.model=old_model;await frames()
	print("UI05_EXPECTED_BEGIN");probe.model.volume=0.53;await frames();print("UI05_EXPECTED_END")
	check(decimal.value==0.5 and probe.model.volume==0.53,"noncanonical source retained as authored; no silent control-to-source normalization")
	var runs:int=State.records[probe.get_instance_id()].runs;await frames()
	check(State.records[probe.get_instance_id()].runs==runs,"invalid source does not schedule an infinite projection repair loop")
	probe.model.volume=0.75;await frames()
	check(decimal.value==0.75 and probe.get_node("Root/Decimal")==decimal,"canonical source repair reuses mounted native endpoint")
	probe.free();host.free();await frames()
	check(State.records.is_empty(),"unmount releases all mounted bindings and computations")
	print("UI05_REJECTION_ASSERTIONS ",checks," ok=",ok)
	if ok: print("UI05_REJECTIONS_OK")
	quit(0 if ok else 1)
