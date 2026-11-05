extends SceneTree
## Nested-model property/layout parity through the sole computation manager.
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Demo = preload("res://examples/reactive/generated/Demo.gd")
const Model = preload("res://examples/reactive/generated/Model.gd")
const State = preload("res://examples/reactive/generated/State.gd")
const Manager = preload("res://addons/estragon/runtime/composition/state.tres")
var failures := 0
var assertions := 0
var reentrant_host
func check(value: bool, message: String) -> void:
    assertions += 1
    if not value:
        failures += 1
        push_error("F04 model parity: "+message)
func settle() -> void:
    for index in range(6): await process_frame
func reentrant(_old: int, value: int) -> void:
    if value==3: reentrant_host.count = 4
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var scene := Demo.new()
    root.add_child(scene)
    await settle()
    var record = Manager.records[scene.get_instance_id()]
    var title = scene.ui.get_node("Panel/Title")
    var bar = scene.ui.get_node("Panel/Row/Bar")
    var other = scene.ui.get_node("Panel/Row/Other")
    var panel = scene.ui.get_node("Panel")
    var label = scene.ui.get_node("Panel/Count")
    var ids := [title.get_instance_id(),bar.get_instance_id(),scene.ui.get_instance_id()]
    check(title.text=="Reactive model" and bar.width==120.0,"initial nested model text and geometry")
    check(scene.count_changed.get_connections().size()==1 and scene.model_changed.get_connections().size()==1,"one computation subscription per source property, deduplicating repeated reads")
    check(scene.model.player.tint_changed.get_connections().size()==1,"shared nested getter read is observed once across props")
    check(scene.ui.find_children("*","Node",true,false).size()==8,"no per-target reactive helper Nodes in mounted output")
    var before = [panel.get_layout_stats(),other.get_layout_stats(),bar.get_layout_stats()]
    scene.model.player.tint = Color.RED
    await settle()
    check(title.color==Color.RED and bar.fill==Color.RED,"style reacts on non-Node nested model")
    check(before==[panel.get_layout_stats(),other.get_layout_stats(),bar.get_layout_stats()],"paint-only commit preserves layout caches")
    before = other.get_layout_stats().measure
    var bar_before = bar.get_layout_stats()
    var runs: int = record.runs
    scene.model.player.width = 140.0
    scene.model.player.width = 180.0
    scene.model.player.width = 220.0
    check(bar.width==120.0,"source notifications defer native commit")
    await settle()
    check(bar.width==220.0 and bar.layout_size.x==220.0 and record.runs==runs+1,"coalesced owning function drives latest arranged geometry once")
    check(other.get_layout_stats().measure==before and bar.get_layout_stats().measure==bar_before.measure+1,"affected-branch measure preserves sibling cache")
    before = panel.get_layout_stats()
    runs = record.runs
    var writes: int = record.writes
    scene.model.player.width = 220.0
    await settle()
    check(before==panel.get_layout_stats() and record.runs==runs,"equal input neither rerenders nor relayouts")
    scene.count_changed.emit(scene.count,scene.count)
    await settle()
    check(before==panel.get_layout_stats() and record.writes==writes,"same-value explicit signal does not rewrite native declarations")
    reentrant_host = scene
    scene.count_changed.connect(reentrant)
    scene.count = 3
    await settle()
    check(scene.count==4 and label.text=="Value: 8" and panel.gap==16.0,"reentrant source settles to latest scalar and geometry")
    scene.count_changed.disconnect(reentrant)
    reentrant_host = null
    var old = scene.model
    var old_state = old.player
    var weak_old: WeakRef = weakref(old)
    var weak_state: WeakRef = weakref(old_state)
    scene.model = Model.new()
    await settle()
    check(old.player_changed.get_connections().is_empty() and old_state.tint_changed.get_connections().is_empty(),"successful recomposition disconnects previous model and nested reads")
    check(title.text=="Reactive model" and bar.width==120.0,"replacement props apply to retained native Nodes")
    old = null
    old_state = null
    check(weak_old.get_ref()==null and weak_state.get_ref()==null,"external subscriptions do not retain replaced model graph")
    var player = scene.model.player
    scene.model.player = null
    await settle()
    check(player.width_changed.get_connections().is_empty() and bar.width==120.0 and title.text=="","source-authored null fallback disconnects obsolete leaf observers")
    scene.model.player = State.new()
    scene.model.player.width = 260.0
    await settle()
    check(bar.width==260.0,"null path recovers through model replacement subscription")
    player = null
    var parent = title.get_parent()
    parent.remove_child(title)
    scene.ui.add_child(title)
    scene.model.player.title = "Transferred native leaf"
    await settle()
    check(title.get_parent()==parent and title.text=="Transferred native leaf" and scene.model.player.title_changed.get_connections().size()==1,"owning commit restores transferred leaf and retains one component observer")
    var freed_id: int = title.get_instance_id()
    title.free()
    scene.count += 1
    await settle()
    title = scene.ui.get_node("Panel/Title")
    check(title.get_instance_id()!=freed_id and scene.model.player.title_changed.get_connections().size()==1,"externally freed owned leaf remounts without duplicate subscriptions")
    var outside := Node.new()
    root.add_child(outside)
    bar.get_parent().remove_child(bar)
    outside.add_child(bar)
    root.remove_child(scene)
    check(scene.model.player.width_changed.get_connections().is_empty(),"host exit suspends all owned computation observers")
    scene.model.player.width = 280.0
    root.add_child(scene)
    await settle()
    check(bar.width==280.0 and bar.get_parent()==scene.ui.get_node("Panel/Row") and scene.model.player.width_changed.get_connections().size()==1,"host reentry refreshes and restores transferred native leaf")
    check(ids[1]==bar.get_instance_id() and ids[2]==scene.ui.get_instance_id(),"updates retain compatible ancestor/leaf identity")
    var source = scene.model
    source.player.width = 300.0
    scene.free()
    await settle()
    check(source.player_changed.get_connections().is_empty() and source.player.width_changed.get_connections().is_empty() and Manager.records.is_empty(),"host free cancels queued work and clears all model reads")
    outside.free()
    var nullable := Demo.new()
    nullable.model = null
    root.add_child(nullable)
    await settle()
    check(nullable.ui.get_node("Panel/Title").text=="" and nullable.model_changed.get_connections().size()==1,"initial null model observes replacement through same view")
    nullable.model = Model.new()
    await settle()
    check(nullable.ui.get_node("Panel/Title").text=="Reactive model","initial null root recovers")
    nullable.free()
    var counter: Node = load("res://examples/counter/Counter.tscn").instantiate()
    root.add_child(counter)
    await settle()
    var packed := PackedScene.new()
    check(packed.pack(counter)==OK and counter.ui.owner==null,"canonical Counter packs host without obsolete persisted binding graph")
    counter.free()
    counter = packed.instantiate()
    root.add_child(counter)
    await settle()
    counter.increment()
    await settle()
    check(counter.ui.get_node("Panel/Count").text=="Count: 1" and not counter.ui.get_node("Panel/Actions/Reset").disabled,"packed host recreates observable output and native event graph once")
    counter.free()
    var code := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\n@bindable var value: int = 1\nfunc build_view() -> Element: return helper()\nfunc helper() -> Element: return <Node name={String(self.value)} />\n'
    var first := Compiler.compile(code,"typed.gogo")
    var second := Compiler.compile(code,"typed.gogo")
    check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"ordinary helper descriptions have deterministic output/maps")
    check(not first.code.contains("_gogo_read_") and not first.code.contains("property_binding") and not first.code.contains(".add_child("),"sole generated description path has no old readers/attachment/helpers")
    var lines := first.code.split("\n")
    for index in range(lines.size()):
        if lines[index].contains("String(self.value)"):
            var mapped = first.source_map.original_position(index+1,lines[index].find("self.value")+1)
            check(mapped!=null and mapped.line==5 and mapped.column==code.split("\n")[4].find("self.value")+1,"helper getter read maps to exact authored line/column")
    var legacy := Compiler.compile(code.replace('build_view() -> Element','build_view() -> Node'),"old.gogo")
    check(not legacy.ok and legacy.diagnostics[0].span.start.line==4 and legacy.diagnostics[0].message.contains("eager"),"retired Node-returning entry rejects with authored diagnostic")
    print("REACTIVE_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
    if failures==0: print("REACTIVE_RUNTIME_OK")
    quit(1 if failures else 0)
