extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var errors := 0
var checks := 0
func check(value: bool,label: String):
	checks += 1
	print("CORE01 ",label,": ",value)
	if not value: errors += 1
func frames():
	for index in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var text := '''extends Node2D
const Element=preload("res://addons/estragon/runtime/composition/element.gd")
const Text=preload("res://addons/estragon/runtime/node/text.gd")
const Box=preload("res://addons/estragon/runtime/node/box.gd")
const Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")
@bindable var caption: String="Flynn"
@bindable var ordinary_hidden: String="Hidden"
@bindable var other: int=0
var calls: Dictionary={"badge":0,"ordinary":0,"explicit":0,"root":0}
func hidden()->String:
	calls.ordinary+=1
	return self.ordinary_hidden
func format_label(value: String)->String:
	calls.explicit+=1
	return value.to_upper()
func badge()->Element:
	calls.badge+=1
	var local=self.caption
	return <Box direction="column"><Text text={format_label(local)} />{<Text name="Structure" text="extra" /> if local=="other" else null}</Box>
func build_view()->Element:
	calls.root+=1
	var values: Array=[]
	for index in range(2):
		values.append(<Text text={str(index)} />)
	for index in range(2): values.append(<Text text={str(index)} />)
	return <Entry name="UI" width="640px" height="480px"><Box name="Body" direction="column">{badge()}{badge()}<Text name="Static" text={hidden()} /><Text name="Other" text={str(self.other)} /><Box name="VoidCalls">{values}</Box></Box></Entry>
'''
	var compiled = Compiler.compile(text,"res://Host.gogo","res://generated/Host.gd")
	for diagnostic in compiled.diagnostics: print(diagnostic.format())
	check(compiled.ok,"compiler")
	if not compiled.ok: quit(1); return
	var script := GDScript.new()
	script.resource_path="res://generated/Host.gd"
	script.source_code=compiled.code
	check(script.reload()==OK,"native semantics")
	if not script.can_instantiate(): quit(1); return
	var host=script.new()
	root.add_child(host)
	await frames()
	check(host.calls=={"badge":2,"ordinary":1,"explicit":2,"root":1},"two independent reactive occurrences and one ordinary call")
	var body=host.get_node("UI/Body")
	var first=body.get_child(0)
	var second=body.get_child(1)
	check(body.get_node("VoidCalls").get_child_count()==4,"native void Array.append statements execute without return adapters")
	check(first!=second and first.get_child(0).text=="FLYNN","distinct native mounts")
	host.other=1
	await frames()
	check(host.calls=={"badge":2,"ordinary":1,"explicit":2,"root":2},"unrelated parent reexecution uses helper caches")
	host.ordinary_hidden="Changed"
	await frames()
	check(host.calls.root==2 and body.get_node("Static").text=="Hidden","zero-arg ordinary body has no hidden observation")
	host.caption="other"
	await frames()
	check(host.calls.badge==4 and host.calls.explicit==4 and first.has_node("Structure") and second.has_node("Structure"),"GGX local/branch read invalidates both structures")
	check(first==body.get_child(0) and second==body.get_child(1),"retained native identities")
	var before=host.calls.duplicate()
	await frames()
	check(host.calls==before,"idle zero function work")
	host.queue_free()
	await frames()
	check(State.records.is_empty() and State.dirty.is_empty(),"unmount clears manager")
	print("CORE01_RUNTIME_ASSERTIONS ",checks," errors=",errors)
	if errors==0: print("CORE01_RUNTIME_OK")
	quit(0 if errors==0 else 1)
