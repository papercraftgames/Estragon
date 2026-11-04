extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Base = preload("res://examples/bindable/generated/Model.gd")
const Derived = preload("res://examples/bindable/generated/Derived.gd")
var failures: int = 0
var checks: int = 0
var events: Array = []
var reentrant_model: RefCounted
class Receiver extends Node:
	var events: Array = []
	func changed(previous: int, value: int) -> void:
		events.append([previous,value])
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("T09-A: "+message)
func record(previous, value) -> void:
	events.append([previous,value])
func reentrant(_previous: int, value: int) -> void:
	if value==10: reentrant_model.count = 11
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	check(OS.get_name()=="Linux" and OS.get_environment("PATH").ends_with("no-tools"),"Linux Godot-only acceptance")
	var model := Derived.new()
	check(model is RefCounted and not (model as Object) is Node,"code-only typed data model is non-Node")
	check(model.count==3 and model.title=="Model" and model.enabled and model.items.is_empty() and model.peer==null,"quiet typed base/derived initialization")
	check(model.count_changed.get_connections().is_empty(),"declaration creates no subscriptions/events")
	model.count_changed.connect(record)
	var id: int = model.get_instance_id()
	model.count = 3
	check(events.is_empty(),"same primitive assignment suppressed")
	model.count += 1
	model.increment()
	check(model.count==5 and events==[[3,4],[4,5]],"external and internal compound assignments notify old/new once")
	check(model.get_instance_id()==id,"assignments retain model identity")
	model.count_changed.disconnect(record)
	model.count = 6
	check(events.size()==2,"explicit native disconnect stops callbacks")
	events.clear()
	model.title_changed.connect(record)
	model.rename()
	check(events==[["Model","Derived"]],"inherited typed property/signal setter used by derived method")
	model.title_changed.disconnect(record)
	events.clear()
	model.enabled_changed.connect(record)
	model.enabled = false
	check(events==[[true,false]],"derived property has independent typed notification")
	model.enabled_changed.disconnect(record)
	model.items_changed.connect(record)
	events.clear()
	var items: Array[int] = []
	model.items = items
	check(events.size()==1,"equal-content reference replacement not suppressed")
	model.items = items
	items.append(2)
	check(events.size()==1 and model.items==[2],"same reference suppressed; in-place mutation is outside T09-A")
	model.items_changed.disconnect(record)
	events.clear()
	model.peer_changed.connect(record)
	var peer := RefCounted.new()
	model.peer = peer
	model.peer = peer
	model.peer = null
	check(events.size()==2 and events[0][1]==peer and events[1][0]==peer,"Object reference/null equality")
	model.peer_changed.disconnect(record)
	events.clear()
	model.count_changed.connect(record)
	reentrant_model = model
	model.count_changed.connect(reentrant)
	model.count = 10
	check(model.count==11 and events==[[6,10],[10,11]],"reentrant writes store before synchronous depth-first events, preserve later state")
	model.count_changed.disconnect(reentrant)
	model.count_changed.disconnect(record)
	reentrant_model = null
	var receiver := Receiver.new()
	model.count_changed.connect(receiver.changed)
	model.count += 1
	check(receiver.events==[[11,12]],"ordinary native receiver callback")
	receiver.free()
	check(model.count_changed.get_connections().is_empty(),"receiver free cleans native connection")
	model.count += 1
	var weak: WeakRef = weakref(model)
	events.clear()
	model = null
	check(weak.get_ref()==null,"non-Node model releases without generated ownership cycles")
	# Code-only module imports, native property initialization and typed Node scope.
	var source := 'extends RefCounted\nvar seen: Array = []\n@bindable var count: int = 3 # keep comment\nfunc _init():\n\tcount_changed.connect(changed)\n\tcount = 4\nfunc changed(a: int,b: int): seen.append([a,b])\n'
	var output := Compiler.compile(source,"init.gogo")
	check(output.ok,"annotation/property source analyzes")
	var script := GDScript.new()
	script.source_code = output.code
	check(script.reload()==OK,"generated setter native semantics")
	var initialized = script.new()
	check(initialized.count==4 and initialized.seen==[[3,4]],"declaration quiet, _init assignment observes initialized value")
	var again := Compiler.compile(source,"init.gogo")
	check(output.code==again.code and output.source_map.serialize()==again.source_map.serialize(),"deterministic bindable emission/maps")
	check(not output.code.contains("@bindable") and output.code.contains("signal count_changed"),"ordinary GDScript only")
	var node_compiled := Compiler.compile('extends Node\n@bindable var score: int = 1\n',"node.gogo")
	script = GDScript.new()
	script.source_code = node_compiled.code
	check(node_compiled.ok and script.reload()==OK,"same annotation on a Node class without a model superclass")
	var node = script.new()
	node.score_changed.connect(record)
	events.clear()
	node.score += 1
	check(events==[[1,2]],"Node property native signal")
	node.free()
	var negatives := [
		'@Bindable var count: int = 0','@bindable(1) var count: int = 0','@bindable @bindable var count: int = 0',
		'@bindable var count = 0','@bindable var count := 0','@bindable const count: int = 0',
		'@bindable static var count: int = 0','@bindable var count: int = 0; var other = 1',
		'@bindable var count: int:\n\tset(value): count = value','@export\n@bindable var count: int = 0',
		'signal count_changed\n@bindable var count: int = 0','var count_changed: int = 1\n@bindable var count: int = 0',
		'func test():\n\t@bindable var count: int = 0','class Inner:\n\t@bindable var count: int = 0'
	]
	for bad in negatives:
		var result := Compiler.compile('extends RefCounted\n'+bad+'\n',"negative.gogo")
		check(not result.ok and result.diagnostics.size()==1,"source annotation/declaration collision rejection: "+bad)
		if not result.ok: check(result.diagnostics[0].span.start.line>=2,"authored annotation diagnostic line")
	var ordinary := Compiler.compile('extends RefCounted\n# @bindable var fake\nvar text = "@bindable var fake"\n',"ordinary.gogo")
	check(ordinary.ok and not ordinary.code.contains("fake_changed"),"strings/comments are lexical, never annotations")
	print("BINDABLE_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("BINDABLE_RUNTIME_OK")
	quit(1 if failures else 0)
