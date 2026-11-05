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
	events.clear()
	model.amount_changed.connect(record)
	model.amount = 1.0
	model.amount = 1.0
	model.amount = 1.0000000001
	check(events.size()==2,"native exact value equality, not approximate float suppression")
	model.amount_changed.disconnect(record)
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
	events.clear()
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
	for line in range(output.code.split("\n").size()):
		if output.code.split("\n")[line].begins_with("var count:"):
			var original = output.source_map.original_position(line+1,1)
			check(original != null and original.line==3 and original.column==11,"typed declaration maps to authored inline var, not generated signal/setter")
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
	var imported := Compiler.compile('extends RefCounted\nconst Item = preload("res://examples/bindable/generated/Model.gd")\nvar _gogo_incoming_item: int = 1\nvar _gogo_previous_item: int = 2\n@bindable var item: Item = (\n\tItem.new()\n)\n',"imported.gogo")
	script = GDScript.new()
	script.source_code = imported.code
	check(imported.ok and script.reload()==OK,"explicit imported script type, multiline initializer and hygienic generated locals")
	var holder = script.new()
	check(holder.item is Base and holder.item.count==3,"imported model initialized without wrappers")
	holder.item_changed.connect(record)
	events.clear()
	var replacement := Base.new()
	holder.item = replacement
	check(holder.item==replacement and events.size()==1 and events[0][1]==replacement,"typed imported property emits actual model reference")
	holder.item_changed.disconnect(record)
	events.clear()
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
	var forbidden := Compiler.compile("extends RefCounted\n@bindable var count: int = 0\n","ordinary.gd")
	check(not forbidden.ok and forbidden.diagnostics[0].span.start.line==2,"annotation never added to ordinary .gd")
	var crlf := Compiler.compile("extends RefCounted\r\n# 😀 unicode comment\r\n@Bindable var count: int = 0\r\n","crlf.gogo")
	check(not crlf.ok and crlf.diagnostics[0].span.start.line==3 and crlf.diagnostics[0].span.start.column==1,"CRLF/Unicode authored annotation span")
	var ordinary := Compiler.compile('extends RefCounted\n# @bindable var fake\nvar text = "@bindable var fake"\n',"ordinary.gogo")
	check(ordinary.ok and not ordinary.code.contains("fake_changed"),"strings/comments are lexical, never annotations")
	class_wide_checks()
	print("BINDABLE_ASSERTIONS ",checks," failures=",failures)
	if failures==0: print("BINDABLE_RUNTIME_OK")
	quit(1 if failures else 0)

func class_wide_checks() -> void:
	var source := '@bindable\n# marker belongs to the script, not its first field\nextends RefCounted\nvar _private: int = 1\n@bindable var score: int = 2\nvar tags: Array[String] = []\nvar ignored = 3\nvar inferred := 4\nconst FIXED: int = 5\nclass Inner:\n\tvar value: int = 6\nfunc local() -> int:\n\tvar local_value: int = 7\n\treturn local_value\n'
	var first := Compiler.compile(source,"class.gogo")
	var again := Compiler.compile(source,"class.gogo")
	check(first.ok and first.code==again.code and first.source_map.serialize()==again.source_map.serialize(),"class-wide output/maps deterministic")
	if not first.ok: return
	check(first.code.count("signal score_changed(")==1 and first.code.count("set(_gogo_incoming_score)")==1,"class plus explicit property marker lowers exactly once")
	check(not first.code.contains("ignored_changed") and not first.code.contains("inferred_changed") and not first.code.contains("local_value_changed") and not first.code.contains("value_changed") and not first.code.contains("FIXED_changed"),"untyped/inferred/local/inner/const fields remain ordinary")
	var script := GDScript.new()
	script.source_code = first.code
	check(script.reload()==OK,"class-wide native RefCounted semantics")
	var model = script.new()
	check(model._private==1 and model.score==2 and model.tags.is_empty() and model.score_changed.get_connections().is_empty(),"class-wide initialization is quiet")
	events.clear()
	model.score_changed.connect(record)
	model.score += 1
	check(events==[[2,3]],"class plus property emits exactly one typed transition")
	model.score_changed.disconnect(record)
	events.clear()
	model._private_changed.connect(record)
	model._private = 8
	check(events==[[1,8]],"private-by-convention typed fields are eligible")
	model._private_changed.disconnect(record)
	events.clear()
	model.tags_changed.connect(record)
	var tags: Array[String] = []
	model.tags = tags
	model.tags = tags
	tags.append("native mutation")
	check(events.size()==1 and model.tags==["native mutation"],"class-wide typed array uses the same reference equality boundary")
	model.tags_changed.disconnect(record)
	events.clear()
	var exported := Compiler.compile('@tool\n@bindable\nextends Node\n@export var shown: int = 3\n@export_range(0,10,1)\nvar rating: int = 4\n',"export.gogo")
	script = GDScript.new()
	script.source_code = exported.code
	check(exported.ok and script.reload()==OK,"native export modifiers remain attached to generated properties, not signals")
	var node = script.new()
	var exposed := {}
	for property in node.get_property_list():
		if property.name in ["shown","rating"]: exposed[property.name] = int(property.usage)&PROPERTY_USAGE_EDITOR!=0
	check(exposed.get("shown",false) and exposed.get("rating",false) and not node.has_signal("position_changed"),"native export metadata preserved; inherited native properties not instrumented")
	node.shown_changed.connect(record)
	node.shown = 5
	check(events==[[3,5]],"class-wide Node host native signal")
	node.free()
	events.clear()
	for line in range(exported.code.split("\n").size()):
		if exported.code.split("\n")[line].begins_with("@export var shown"):
			var original = exported.source_map.original_position(line+1,1)
			check(original!=null and original.line==4 and original.column==1,"native annotation source span copied exactly")
		if exported.code.split("\n")[line].contains("var shown:"):
			var column: int = exported.code.split("\n")[line].find("var shown:")+1
			var original = exported.source_map.original_position(line+1,column)
			check(original!=null and original.line==4 and original.column==9,"inline export property var maps to authored column")
	var inherited := Compiler.compile('@bindable\nextends "res://examples/bindable/generated/Model.gd"\nvar extra: int = 8\n',"derived-class.gogo")
	script = GDScript.new()
	script.source_code = inherited.code
	check(inherited.ok and script.reload()==OK and not inherited.code.contains("signal count_changed"),"annotated derived owns only new fields; base signals inherited once")
	model = script.new()
	model.count_changed.connect(record)
	model.count += 1
	check(events==[[3,4]] and model.extra==8 and model.has_signal("extra_changed"),"mixed base/derived setter contract preserved")
	model.count_changed.disconnect(record)
	events.clear()
	var native_base := Compiler.compile('@bindable\nextends "res://examples/bindable/generated/Demo.gd"\nvar extra: int = 9\n',"ordinary-base.gogo")
	script = GDScript.new()
	script.source_code = native_base.code
	check(native_base.ok and script.reload()==OK,"class-wide Gogo can extend an unannotated ordinary script")
	node = script.new()
	check(node.has_signal("extra_changed") and not node.has_signal("model_changed") and not node.has_signal("events_changed"),"unannotated base fields stay unmodified")
	node.free()
	var static_source := Compiler.compile(source+"static var cached: int = 4\n","static.gogo")
	check(static_source.ok and not static_source.code.contains("cached_changed"),"static fields stay native and are never instance-observed")
	var class_init := Compiler.compile('@bindable\nextends RefCounted\nvar value: int = 3\nvar seen: Array = []\nfunc _init() -> void:\n\tvalue_changed.connect(changed)\n\tvalue = 4\nfunc changed(a: int,b: int) -> void: seen.append([a,b])\n',"class-init.gogo")
	script = GDScript.new()
	script.source_code = class_init.code
	check(class_init.ok and script.reload()==OK and script.new().seen==[[3,4]],"class-wide declaration quiet; _init writes use normal notification")
	for bad in [
		'@bindable\n@bindable\nextends RefCounted\nvar score: int = 0',
		'@bindable(1)\nextends RefCounted\nvar score: int = 0',
		'@Bindable\nextends RefCounted\nvar score: int = 0',
		'@bindable extends RefCounted\nvar score: int = 0',
		'var first: int = 0\n@bindable\nextends RefCounted',
		'extends RefCounted\nclass Inner:\n\t@bindable\n\textends RefCounted',
		'@bindable\nextends RefCounted\nvar score: int:\n\tget: return 1',
		'@bindable\nextends RefCounted\nvar score: int = 0; var other: int = 1',
		'@bindable\nextends RefCounted\nsignal score_changed\nvar score: int = 0',
		'@bindable\nextends RefCounted\nstatic var score_changed: int = 0\nvar score: int = 0',
		'@bindable\nextends Node\n@onready var score: int = 0',
		'@bindable\nextends Node\nvar child: Node = <Node />',
		'@bindable\nextends RefCounted\n@bindable var inferred = 0',
		'@bindable\nextends RefCounted\nfunc local():\n\t@bindable var score: int = 0'
	]:
		var rejected := Compiler.compile(bad+"\n","class-negative.gogo")
		check(not rejected.ok and rejected.diagnostics.size()==1 and rejected.diagnostics[0].span.start.line>=1,"class-wide invalid scope/accessor/annotation/collision rejects: "+bad)
	var forbidden := Compiler.compile("@bindable\nextends RefCounted\nvar score: int = 0\n","class.gd")
	check(not forbidden.ok and forbidden.diagnostics[0].span.start.line==1,"class marker is Gogo-only")
	var crlf := Compiler.compile(source.replace("\n","\r\n"),"class-crlf.gogo")
	check(crlf.ok and crlf.source_map.serialize().contains("\\r\\n"),"class-wide CRLF source retained")
