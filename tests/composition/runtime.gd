extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Counter = preload("res://examples/composition/generated/Counter.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var assertions := 0
var failures := 0
var reentrant_host
func cascade(_previous: int, value: int) -> void:
	if value==5: reentrant_host.count = 6
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("F01: "+message)
func _initialize() -> void:
	run.call_deferred()
func settle() -> void:
	for index in range(6): await process_frame
func resource_lifetime(script: GDScript, observe: bool) -> WeakRef:
	# End the creator frame before asserting release: 4.0 keeps dynamic-call
	# temporaries in an active coroutine frame longer than newer VMs do.
	var resource = script.new()
	if observe:
		State.begin()
		var amount: int = resource.amount
		var observed: Dictionary = State.finish()
		check(amount==3 and observed.size()==1,"Resource reads use the same scoped tracker without injected fields")
	return weakref(resource)
func run() -> void:
	var scene := Counter.new()
	var neighbor := Counter.new()
	root.add_child(scene)
	root.add_child(neighbor)
	await settle()
	var record = State.records[scene.get_instance_id()]
	var other_record = State.records[neighbor.get_instance_id()]
	var ui = scene.get_node("UI")
	var label = ui.get_node("Panel/Count")
	var button = ui.get_node("Panel/Increment")
	var bar = ui.get_node("Panel/Bar")
	var ids := [ui.get_instance_id(),label.get_instance_id(),button.get_instance_id()]
	check(record.runs==1 and other_record.runs==1,"initial composition exactly once per component")
	check(record.allocations==7 and ui.find_children("*","Node",true,false).size()==6,"descriptions allocate actual subtree once and no binder Nodes")
	check(scene.get_meta_list().is_empty() and ui.get_meta_list().is_empty() and scene.model.get_meta_list().is_empty(),"no injected tracking metadata on user Nodes/models")
	check(label.text=="Count: 0" and bar.layout_size.x==120.0,"Gogo description mounts typed native text/geometry")
	check(scene.count_changed.get_connections().size()==1 and scene.model.width_changed.get_connections().size()==1,"getter reads dedup to one computation connection")
	check(button.pressed.get_connections().size()==1,"native handler initially connected once")
	var incompatible = scene.build_view()
	incompatible.children.clear()
	check(record._valid(incompatible,record.mounted) and record._preflight(incompatible,record.mounted,scene) and record.allocations==7,"F02 dynamic preflight validates changed shape without allocation or native commit")
	check(not record._boundary_clear(scene.build_view(),scene),"existing foreign root-name conflict cannot silently rename/adopt a native child")
	var writes: int = record.writes
	await settle()
	check(record.runs==1 and record.writes==writes,"idle frames do zero composition or writes")
	scene.unused += 1
	scene.count = 0
	await settle()
	check(record.runs==1,"unread bindable and equal value do not schedule")
	# An unchanged desired value must not reset live native/game state.
	label.color = Color.RED
	ui.get_node("Panel/Title").color = Color.RED
	button.text = "Native state"
	scene.count += 1
	scene.count += 1
	scene.count += 1
	check(scene.count==3 and label.text=="Count: 0","data synchronous, recomposition deferred")
	await settle()
	check(record.runs==2 and other_record.runs==1,"only affected component reruns once per coalesced flush")
	check(label.text=="Count: 3" and bar.layout_size.x==150.0,"function locals and automatic geometry recomposed")
	check(ids==[ui.get_instance_id(),label.get_instance_id(),button.get_instance_id()] and record.allocations==7,"retains actual Node IDs without throwaway allocations")
	check(label.color==Color.RED and ui.get_node("Panel/Title").color==Color.RED and button.text=="Native state","previous desired snapshots preserve unchanged declared/native-owned values")
	check(button.pressed.get_connections().size()==1,"rerun never duplicates native handlers")
	button.pressed.emit()
	await settle()
	check(scene.count==4 and label.text=="Count: 4","ordinary native handler and += automatically recompose")
	var old = scene.model
	var weak: WeakRef = weakref(old)
	scene.model = Model.new()
	scene.model.title = "New model"
	scene.model.width = 200.0
	await settle()
	check(ui.get_node("Panel/Title").text=="New model" and bar.layout_size.x==240.0,"helper method/model getter reads track replacement")
	check(old.title_changed.get_connections().is_empty() and old.width_changed.get_connections().is_empty(),"replacement detaches prior model sources")
	old = null
	check(weak.get_ref()==null,"external record does not retain replaced model")
	# Nested scopes isolate reads, including inherited typed properties.
	State.begin()
	var captured_count: int = scene.count
	State.begin()
	var captured_width: float = scene.model.width
	var inner: Dictionary = State.finish()
	var outer: Dictionary = State.finish()
	check(captured_count==4 and captured_width==200.0 and inner.size()==2 and outer.size()==1,"native getters retain typed values and nested scopes isolate reads")
	check(State.scopes.is_empty(),"scope stack balanced after nested/native helper reads")
	reentrant_host = scene
	scene.count_changed.connect(cascade)
	var before_runs: int = record.runs
	scene.count = 5
	await settle()
	check(scene.count==6 and label.text=="Count: 6" and record.runs==before_runs+1,"synchronous reentrant source writes coalesce to one latest-value composition")
	scene.count_changed.disconnect(cascade)
	reentrant_host = null
	root.remove_child(scene)
	check(scene.count_changed.get_connections().is_empty() and scene.model.width_changed.get_connections().is_empty(),"native host removal suspends subscriptions")
	scene.count = 9
	root.add_child(scene)
	await settle()
	check(scene.get_node("UI")==ui and label.text=="Count: 9" and scene.count_changed.get_connections().size()==1,"reattach refreshes without recreating Nodes or listeners")
	var foreign := Node.new()
	foreign.name = "Foreign"
	ui.add_child(foreign)
	foreign.owner = scene
	var outside := Node.new()
	scene.add_child(outside)
	State.unmount(scene)
	check(is_instance_valid(foreign) and foreign.get_parent()==scene and foreign.owner==scene and is_instance_valid(outside),"unmount frees managed Nodes only and preserves foreign children/owner")
	check(scene.count_changed.get_connections().is_empty() and not scene.has_node("UI"),"unmount disconnects and removes managed region")
	scene.free()
	var source = neighbor.model
	neighbor.count += 1
	neighbor.free()
	await settle()
	check(source.width_changed.get_connections().is_empty() and State.records.is_empty(),"queued invalidation cannot touch freed host; records and observers released")
	var persistent := Counter.new()
	root.add_child(persistent)
	await settle()
	var packed := PackedScene.new()
	check(packed.pack(persistent)==OK and persistent.get_node("UI").owner==null,"runtime managed view remains separate from authored scene owner persistence")
	persistent.free()
	persistent = packed.instantiate()
	root.add_child(persistent)
	await settle()
	persistent.increment()
	await settle()
	check(persistent.get_child_count()==1 and persistent.get_node("UI/Panel/Count").text=="Count: 1","PackedScene reload remounts once without duplicate managed regions/handlers")
	persistent.free()
	var code := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\n@bindable var count: int = 0\nfunc build_view() -> Element:\n\tvar value: String = String(count)\n\treturn <Node name={value} />\n'
	var first := Compiler.compile(code,"proof.gogo")
	var second := Compiler.compile(code,"proof.gogo")
	check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"native descriptor code/maps deterministic")
	check(first.code.contains("_GogoElement_0.new") and not first.code.contains("Node.new()") and not first.code.contains("property_binding"),"view source emits desired values, not candidate live Nodes/helpers")
	var hygienic := Compiler.compile(code.replace("@bindable var count", "const _GogoElement_0: int = 2\nconst _gogo_element_0: int = 3\n@bindable var count"),"hygienic.gogo")
	check(hygienic.ok and hygienic.code.contains("_GogoElement_0_.new") and hygienic.code.contains("var _gogo_element_0_"),"descriptor type/local names avoid authored identifiers")
	var lines := first.code.split("\n")
	for index in range(lines.size()):
		if lines[index].contains("(value)"):
			var mapped = first.source_map.original_position(index+1,lines[index].find("value")+1)
			check(mapped!=null and mapped.line==6,"descriptor arguments retain authored source map")
	var invalid := Compiler.compile(code.replace('<Node name=','<RefCounted name='),"invalid.gogo")
	check(not invalid.ok and invalid.diagnostics[0].span.start.line==6,"invalid non-Node target fails at authored source")
	invalid = Compiler.compile(code+'func _notification(what): pass\n',"lifecycle.gogo")
	check(not invalid.ok and invalid.diagnostics[0].span.start.line==7,"F01 lifecycle hook collision rejects explicitly")
	var bad := Element.new("RefCounted")
	var computation = preload("res://addons/estragon/runtime/composition/computation.gd").new(root,State)
	check(not computation._valid(bad,null),"runtime refuses invalid desired target without instantiating it")
	# A generated inherited getter is still observed through ordinary methods.
	var derived_source := 'extends "res://examples/composition/generated/Model.gd"\nfunc read_title() -> String: return title\n'
	var script := GDScript.new()
	script.source_code = derived_source
	check(script.reload()==OK,"native model inheritance compiles")
	var inherited = script.new()
	State.begin()
	var title: String = inherited.read_title()
	var observed: Dictionary = State.finish()
	check(title=="Native composition" and observed.size()==1,"inherited Gogo getter registers native read")
	var resource_code := Compiler.compile('extends Resource\n@bindable var amount: int = 3\n',"resource.gogo")
	var resource_script := GDScript.new()
	resource_script.source_code = resource_code.code
	check(resource_code.ok and resource_script.reload()==OK,"typed Resource model getter compiles")
	var control_script := GDScript.new()
	control_script.source_code = "extends Resource\n"
	check(control_script.reload()==OK,"native Resource lifetime control compiles")
	var control_weak: WeakRef = resource_lifetime(control_script,false)
	var resource_weak: WeakRef = resource_lifetime(resource_script,true)
	check(control_weak.get_ref()==null and resource_weak.get_ref()==null,"native and observed Resource sources release after the creator frame returns")
	var conditional_script := GDScript.new()
	conditional_script.source_code = 'extends "res://examples/composition/generated/Counter.gd"\nfunc heading() -> String:\n\treturn model.title if count % 2 == 0 else "Odd"\nfunc build_view() -> Element:\n\tvar view: Element = super.build_view()\n\tif count > 0: view.children[0].children[3].handlers["pressed"] = reset_count\n\treturn view\n'
	check(conditional_script.reload()==OK,"ordinary helper branching compiles without a dependency-expression parser")
	var conditional = conditional_script.new()
	root.add_child(conditional)
	await settle()
	check(conditional.model.title_changed.get_connections().size()==1,"executed helper branch subscribes to its real read")
	conditional.count = 1
	await settle()
	var conditional_record = State.records[conditional.get_instance_id()]
	check(conditional.model.title_changed.get_connections().is_empty(),"new dynamic read set drops unexecuted helper branch dependency")
	before_runs = conditional_record.runs
	conditional.model.title = "Unused branch"
	await settle()
	check(conditional_record.runs==before_runs,"unread model change does not recompose")
	var changed_button = conditional.get_node("UI/Panel/Increment")
	check(changed_button.pressed.get_connections().size()==1,"changed desired handler replaces rather than duplicates connection")
	changed_button.pressed.emit()
	await settle()
	check(conditional.count==0 and changed_button.pressed.get_connections().size()==1,"updated native Callable executes and can restore original handler")
	conditional.free()
	print("COMPOSITION_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("COMPOSITION_RUNTIME_OK")
	quit(1 if failures else 0)
