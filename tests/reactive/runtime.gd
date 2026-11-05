extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Demo = preload("res://examples/reactive/generated/Demo.gd")
const Model = preload("res://examples/reactive/generated/Model.gd")
const State = preload("res://examples/reactive/generated/State.gd")
var failures := 0
var assertions := 0
var reentrant_host
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error("T09-B: "+message)
func settle() -> void:
	for index in range(6): await process_frame
func reentrant(_old: int, value: int) -> void:
	if value == 3: reentrant_host.count = 4
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var scene := Demo.new()
	root.add_child(scene)
	await settle()
	var title = scene.ui.get_node("Panel/Title")
	var bar = scene.ui.get_node("Panel/Row/Bar")
	var other = scene.ui.get_node("Panel/Row/Other")
	var panel = scene.ui.get_node("Panel")
	var label = scene.ui.get_node("Panel/Count")
	var ids := [title.get_instance_id(),bar.get_instance_id(),scene.ui.get_instance_id()]
	check(title.text=="Reactive model" and bar.width==120.0,"initial nested model text and geometry")
	check(scene.evaluations==1,"unrelated side effect evaluated once")
	check(scene.count_changed.get_connections().size()==2,"repeated self path deduplicated per binding")
	check(scene.model_changed.get_connections().size()==4,"one root subscription per dependent property")
	var before = [panel.get_layout_stats(),other.get_layout_stats(),bar.get_layout_stats()]
	scene.model.player.tint = Color.RED
	await settle()
	check(title.color==Color.RED and bar.fill==Color.RED,"style reacts on non-Node nested model")
	check(before==[panel.get_layout_stats(),other.get_layout_stats(),bar.get_layout_stats()],"paint-only binding updates preserve measure/arrange caches")
	before = other.get_layout_stats().measure
	var bar_before = bar.get_layout_stats()
	scene.model.player.width = 140.0
	scene.model.player.width = 180.0
	scene.model.player.width = 220.0
	check(bar.width==120.0,"source notifications batch until deferred application")
	await settle()
	check(bar.width==220.0 and bar.layout_size.x==220.0,"coalesced binding drives real arranged geometry")
	check(other.get_layout_stats().measure==before,"unrelated sibling measure cache retained")
	check(bar.get_layout_stats().measure==bar_before.measure+1,"batched width changes cause one measurement")
	before = panel.get_layout_stats()
	scene.model.player.width = 220.0
	await settle()
	check(before==panel.get_layout_stats(),"equal input has no redundant layout")
	scene.count_changed.emit(scene.count,scene.count)
	await settle()
	check(before==panel.get_layout_stats(),"repeated same-value notifications do not rewrite or relayout")
	reentrant_host = scene
	scene.count_changed.connect(reentrant)
	scene.count = 3
	await settle()
	check(scene.count==4 and label.text=="Value: 8" and panel.gap==16.0,"reentrant source writes settle to latest scalar and geometry")
	scene.count_changed.disconnect(reentrant)
	reentrant_host = null
	var old = scene.model
	var old_state = old.player
	var weak_state: WeakRef = weakref(old_state)
	var weak_old: WeakRef = weakref(old)
	scene.model = Model.new()
	check(old.player_changed.get_connections().is_empty() and old_state.tint_changed.get_connections().is_empty(),"replacement synchronously releases old nested listeners")
	await settle()
	check(title.text=="Reactive model" and bar.width==120.0,"new model paths apply")
	old = null
	check(weak_old.get_ref()==null,"subscriptions never retain replaced model")
	old_state = null
	check(weak_state.get_ref()==null,"replaced nested leaf is not retained by subscription records")
	var player = scene.model.player
	scene.model.player = null
	await settle()
	check(player.width_changed.get_connections().is_empty() and bar.width==120.0,"null intermediate disconnects leaf and holds last value")
	scene.model.player = State.new()
	scene.model.player.width = 260.0
	await settle()
	check(bar.width==260.0,"null path recovers with new leaf subscription")
	player = null
	var parent = title.get_parent()
	parent.remove_child(title)
	check(scene.model.player.title_changed.get_connections().is_empty(),"detached target disconnects")
	scene.model.player.title = "Detached change"
	parent.add_child(title)
	await settle()
	check(title.text=="Detached change" and scene.model.player.title_changed.get_connections().size()==1,"reattach refreshes and reconnects exactly once")
	parent.remove_child(title)
	scene.ui.add_child(title)
	await settle()
	check(scene.model.player.title_changed.get_connections().size()==1,"reparent keeps one subscription")
	title.free()
	check(scene.model.player.title_changed.get_connections().is_empty(),"target free disconnects leaf")
	check(scene.evaluations==1 and ids[1]==bar.get_instance_id() and ids[2]==scene.ui.get_instance_id(),"updates retain Nodes and once-only expressions")
	var outside := preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	root.add_child(outside)
	bar.get_parent().remove_child(bar)
	outside.add_child(bar)
	await settle()
	check(scene.model.player.width_changed.get_connections().size()==1,"target transfer outside host retains one connection")
	root.remove_child(scene)
	check(scene.model.player.width_changed.get_connections().is_empty(),"host exit suspends independently parented target")
	scene.model.player.width = 280.0
	root.add_child(scene)
	await settle()
	check(bar.width==280.0 and scene.model.player.width_changed.get_connections().size()==1,"host reentry refreshes transferred target without duplicate listeners")
	var source = scene.model
	source.player.width = 300.0 # Pending work must not outlive a freed host.
	scene.free()
	check(source.player_changed.get_connections().is_empty() and source.player.width_changed.get_connections().is_empty(),"host/target free disconnects every model listener")
	await settle()
	outside.free()
	var nullable := Demo.new()
	nullable.model = null
	root.add_child(nullable)
	await settle()
	check(nullable.ui.get_node("Panel/Title").text=="" and nullable.model_changed.get_connections().size()==4,"initial null path retains native defaults and observes replacement")
	nullable.model = Model.new()
	await settle()
	check(nullable.ui.get_node("Panel/Title").text=="Reactive model","initially null root recovers without rebuilding")
	nullable.free()
	# Pack/reload native ownership and persistent methods, without regenerating UI.
	var counter: Node = load("res://examples/counter/Counter.tscn").instantiate()
	root.add_child(counter)
	await settle()
	var packed := PackedScene.new()
	check(packed.pack(counter)==OK,"reactive Counter packs with owner persistence")
	counter.free()
	counter = packed.instantiate()
	root.add_child(counter)
	await settle()
	counter.increment()
	await settle()
	check(counter.ui.get_node("Panel/Count").text=="Count: 1" and not counter.ui.get_node("Panel/Actions/Reset").disabled,"packed bindings and native event graph restore")
	counter.free()
	var code := 'extends Node\n@bindable var value: int = 1\nfunc view(): return <Node name={String(self.value)} />\n'
	var first := Compiler.compile(code,"typed.gogo")
	var second := Compiler.compile(code,"typed.gogo")
	check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"reactive output/maps deterministic")
	var lines := first.code.split("\n")
	for index in range(lines.size()):
		if lines[index].contains("String(self.value)"):
			var mapped = first.source_map.original_position(index+1,lines[index].find("self.value")+1)
			check(mapped != null and mapped.line==3 and mapped.column==code.split("\n")[2].find("self.value")+1,"copied reactive read maps to exact authored expression column")
	for bad in ['self.value.method()', 'self.value[0]', 'self.missing', 'self.value + unknown()', 'self.value + (await next)']:
		var result := Compiler.compile(code.replace('String(self.value)',bad),"negative.gogo")
		check(not result.ok and result.diagnostics[0].span.start.line==3,"unsupported dependency diagnosed at authored line: "+bad)
	var position := Compiler.compile(code.replace('name={String(self.value)}','position={Vector2(self.value,0)}').replace('<Node','<Node2D'),"position.gogo")
	check(not position.ok and position.diagnostics[0].message.contains("deferred"),"reactive layout-controlled position explicitly deferred")
	for member in ["rotation_degrees", "skew"]:
		var transform := Compiler.compile(code.replace('name={String(self.value)}',member+'={self.value}').replace('<Node','<Node2D'),"transform.gogo")
		check(not transform.ok and transform.diagnostics[0].message.contains("deferred"),"native transform alias cannot bypass deferral: "+member)
	print("REACTIVE_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("REACTIVE_RUNTIME_OK")
	quit(1 if failures else 0)
