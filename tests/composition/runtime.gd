extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Counter = preload("res://examples/composition/generated/Counter.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var assertions := 0
var failures := 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("F01: "+message)
func _initialize() -> void:
	run.call_deferred()
func settle() -> void:
	for index in range(6): await process_frame
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
	var writes: int = record.writes
	await settle()
	check(record.runs==1 and record.writes==writes,"idle frames do zero composition or writes")
	scene.unused += 1
	scene.count = 0
	await settle()
	check(record.runs==1,"unread bindable and equal value do not schedule")
	# An unchanged desired value must not reset live native/game state.
	label.color = Color.RED
	button.text = "Native state"
	scene.count += 1
	scene.count += 1
	scene.count += 1
	check(scene.count==3 and label.text=="Count: 0","data synchronous, recomposition deferred")
	await settle()
	check(record.runs==2 and other_record.runs==1,"only affected component reruns once per coalesced flush")
	check(label.text=="Count: 3" and bar.layout_size.x==150.0,"function locals and automatic geometry recomposed")
	check(ids==[ui.get_instance_id(),label.get_instance_id(),button.get_instance_id()] and record.allocations==7,"retains actual Node IDs without throwaway allocations")
	check(label.color==Color.RED and button.text=="Native state","previous desired snapshots preserve unchanged native-owned values")
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
	root.remove_child(scene)
	check(scene.count_changed.get_connections().is_empty() and scene.model.width_changed.get_connections().is_empty(),"native host removal suspends subscriptions")
	scene.count = 9
	root.add_child(scene)
	await settle()
	check(scene.get_node("UI")==ui and label.text=="Count: 9" and scene.count_changed.get_connections().size()==1,"reattach refreshes without recreating Nodes or listeners")
	var foreign := Node.new()
	foreign.name = "Foreign"
	ui.add_child(foreign)
	var outside := Node.new()
	scene.add_child(outside)
	State.unmount(scene)
	check(is_instance_valid(foreign) and foreign.get_parent()==scene and is_instance_valid(outside),"unmount frees managed Nodes only and preserves foreign children")
	check(scene.count_changed.get_connections().is_empty() and not scene.has_node("UI"),"unmount disconnects and removes managed region")
	scene.free()
	var source = neighbor.model
	neighbor.count += 1
	neighbor.free()
	await settle()
	check(source.width_changed.get_connections().is_empty() and State.records.is_empty(),"queued invalidation cannot touch freed host; records and observers released")
	var code := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\n@bindable var count: int = 0\nfunc build_view() -> Element:\n\tvar value: String = String(count)\n\treturn <Node name={value} />\n'
	var first := Compiler.compile(code,"proof.gogo")
	var second := Compiler.compile(code,"proof.gogo")
	check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"native descriptor code/maps deterministic")
	check(first.code.contains("_Element.new") and not first.code.contains("Node.new()") and not first.code.contains("property_binding"),"view source emits desired values, not candidate live Nodes/helpers")
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
	print("COMPOSITION_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("COMPOSITION_RUNTIME_OK")
	quit(1 if failures else 0)
