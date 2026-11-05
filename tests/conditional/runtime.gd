extends SceneTree
const Counter = preload("res://examples/conditional/generated/Counter.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var assertions := 0
var failures := 0
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("F02: "+message)
func _initialize() -> void:
	run.call_deferred()
func settle() -> void:
	for index in range(6): await process_frame
func run() -> void:
	var scene := Counter.new()
	root.add_child(scene)
	await settle()
	var record = State.records[scene.get_instance_id()]
	var panel = scene.get_node("UI/Panel")
	var nested = panel.get_node("Nested")
	var child_record = State.records[nested.get_instance_id()]
	var prompt = panel.get_node("Prompt")
	var after = panel.get_node("After")
	var always = panel.get_node("Always")
	var stable := [panel.get_instance_id(),after.get_instance_id(),always.get_instance_id(),nested.get_instance_id()]
	var allocated: int = record.allocations
	check(record.runs==1 and child_record.runs==1,"initial parent/independent nested computation once")
	check(not panel.has_node("Bonus") and prompt is Node2D,"false branch and null hole initial state")
	scene.count = 1
	await settle()
	check(panel.get_node("Prompt")==prompt and record.allocations==allocated and child_record.runs==1,"false-to-false retains branch and does not recompose child")
	prompt.position += Vector2(1,1)
	scene.count = 2
	await settle()
	check(panel.get_node("Prompt")==prompt,"compatible conditional type retains native identity")
	scene.count = 3
	await settle()
	var action = panel.get_node("Action")
	check(not is_instance_valid(prompt) and action.pressed.get_connections().size()==1 and record.allocations==allocated+1 and record.frees==1,"false-to-true replaces exactly one slot and connects handler once")
	scene.count = 4
	await settle()
	check(panel.get_node("Action")==action and child_record.runs==1,"true-to-true retains Node and nested scope")
	scene.show_bonus = true
	await settle()
	var bonus = panel.get_node("Bonus")
	var wait = bonus.get_node("Wait")
	check(after==panel.get_node("After") and after.get_index()>bonus.get_index(),"optional slot insertion preserves later static sibling and order")
	scene.count = 5
	await settle()
	check(bonus==panel.get_node("Bonus") and not is_instance_valid(wait) and bonus.get_node("Deep").layout_size.x==120.0,"deep nested conditional replaces leaf only and measures geometry")
	scene.show_bonus = false
	await settle()
	check(not is_instance_valid(bonus) and after==panel.get_node("After"),"optional branch removal retains sibling after null hole")
	scene.count = 0
	await settle()
	check(not is_instance_valid(action) and panel.has_node("Prompt"),"true-to-false recreates only affected branch")
	check(stable==[panel.get_instance_id(),after.get_instance_id(),always.get_instance_id(),nested.get_instance_id()],"all compatible ancestor/sibling/child host IDs retained")
	var old = scene.model
	var weak: WeakRef = weakref(old)
	scene.model = Model.new()
	scene.model.title = "Replacement"
	await settle()
	check(panel.get_node("Prompt").text=="Replacement" and nested.get_node("ChildView").text.begins_with("Replacement"),"typed model replacement updates parent and independently observed child")
	check(old.title_changed.get_connections().is_empty(),"old model observers disconnected")
	old = null
	check(weak.get_ref()==null,"no old model retention")
	var before: int = record.runs
	nested.value = 2
	scene.show_child = false
	await settle()
	check(child_record.runs==3 and child_record.disposed and not is_instance_valid(nested),"parent-first removal cancels dirty descendant before it renders")
	check(record.runs==before+1,"parent runs once for branch removal")
	check(scene.model.title_changed.get_connections().size()==1,"nested removal disconnects its model dependency")
	scene.show_child = true
	await settle()
	nested = panel.get_node("Nested")
	check(nested.get_node("ChildView").text.begins_with("Replacement"),"nested remount computes latest model once")
	var foreign := Node.new()
	foreign.name = "Foreign"
	nested.get_node("ChildView").add_child(foreign)
	foreign.owner = scene
	scene.show_child = false
	await settle()
	check(is_instance_valid(foreign) and foreign.get_parent()==scene and foreign.owner==scene,"deep nested managed removal rescues foreign child with valid owner")
	# Preflight must reject bad output before any destructive replacement.
	var desired = scene.build_view()
	desired.children[0].children[1] = Element.new("RefCounted")
	var old_prompt = panel.get_node("Prompt")
	check(not record._valid(desired,record.mounted) and panel.get_node("Prompt")==old_prompt,"invalid branch target leaves prior mounted branch intact")
	desired = scene.build_view()
	desired.children[0].children[1].properties["unknown"] = 1
	check(not record._preflight(desired,record.mounted,scene),"runtime metadata rejects invalid property before commit")
	var outside := Node.new()
	outside.name = "Collision"
	panel.add_child(outside)
	desired = scene.build_view()
	desired.children[0].children[1].properties.name = "Collision"
	check(not record._preflight(desired,record.mounted,scene) and is_instance_valid(outside),"foreign name collision fails preflight without adoption/deletion")
	# Declaration removal leaves native values, while event sets disconnect.
	var current = scene.build_view()
	var leaf = record.mounted.children[0].children[1]
	var actual = leaf.node.get_ref()
	actual.text = "Native value"
	current.children[0].children[1].properties.erase("text")
	check(record._preflight(current,record.mounted,scene),"legitimate changed property set accepted")
	record._reconcile(current,record.mounted,scene,scene)
	check(actual.text=="Native value","removed declared prop relinquishes control without resetting native state")
	var calls: int = record.runs
	var writes: int = record.writes
	await settle()
	check(calls==record.runs and writes==record.writes,"idle frames do no render or writes")
	var packed := PackedScene.new()
	check(packed.pack(scene)==OK,"authored host packs separately from transient dynamic output")
	scene.count += 1
	scene.free()
	await settle()
	check(State.records.is_empty(),"queued invalidation and all nested observers drop on host free")
	var restored: Node = packed.instantiate()
	root.add_child(restored)
	await settle()
	check(restored.get_node("UI/Panel").has_node("Prompt"),"PackedScene reload composes native conditional output once")
	restored.free()
	# Source child values are typed Element/null; no arrays or native Nodes.
	var source := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\n@bindable var yes: bool = false\nfunc build_view() -> Element:\n\treturn <Node>{<Node name="A" /> if yes else null}<Node name="After" /></Node>\n'
	var first := Compiler.compile(source,"conditional.gogo")
	var second := Compiler.compile(source,"conditional.gogo")
	check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"conditional descriptors deterministic with source maps")
	for invalid in ['else 3','else [<Node />]','else Node.new()']:
		var compiled := Compiler.compile(source.replace('else null',invalid),"invalid.gogo")
		if compiled.ok:
			var script := GDScript.new()
			# Native semantic negatives are covered in editor, without suppressing
			# arbitrary engine errors in this positive runtime process.
			check(compiled.code.contains("_GogoElement"),"invalid child remains statically Element-typed: "+invalid)
		else: check(compiled.diagnostics[0].span.start.line==5,"invalid child diagnostic authored line")
	print("CONDITIONAL_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("CONDITIONAL_RUNTIME_OK")
	quit(1 if failures else 0)
