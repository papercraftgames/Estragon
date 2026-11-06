extends SceneTree
var Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
var State = preload("res://addons/estragon/runtime/composition/state.tres")
const Inventory = preload("res://examples/inventory/generated/Inventory.gd")
const Item = preload("res://examples/inventory/generated/Item.gd")
const Conditional = preload("res://examples/conditional/generated/Counter.gd")
const Model = preload("res://examples/composition/generated/Model.gd")
const ToggleDemo = preload("res://examples/twoway/generated/Demo.gd")
const Counter = preload("res://examples/counter/generated/Counter.gd")
const WARMUP := 2
const SAMPLES := 7
var failures := 0
var assertions := 0
var cases: Array = []
func check(value: bool, message: String) -> void:
    assertions += 1
    if not value:
        failures += 1
        push_error("F06: "+message)
func _initialize() -> void: run.call_deferred()
func settle(frames: int = 6) -> void:
    for index in range(frames): await process_frame
func count(key: String) -> int: return int(Profile.counts.get(key,0))
func measure(name: String, action: Callable, verify: Callable) -> void:
    var samples: Array = []
    for index in range(WARMUP+SAMPLES):
        Profile.reset()
        var before_memory := OS.get_static_memory_usage()
        var started := Time.get_ticks_usec()
        action.call()
        State.drain()
        var elapsed := Time.get_ticks_usec()-started
        await settle(2)
        verify.call()
        if index>=WARMUP:
            var sample := Profile.snapshot()
            sample["mutation_drain_us"] = elapsed
            sample["static_memory_delta_bytes"] = OS.get_static_memory_usage()-before_memory
            sample["objects"] = Performance.get_monitor(Performance.OBJECT_COUNT)
            samples.append(sample)
    cases.append({"name":name,"samples":samples})
    write_profile()
    print("PROFILING_CASE ",name)
func idle(scene: Node, name: String) -> void:
    root.add_child(scene)
    await settle()
    Profile.reset()
    await settle(12)
    check(Profile.counts.is_empty(),name+" idle has zero instrumented work")
    cases.append({"name":name+"/idle-12-frames","samples":[Profile.snapshot()]})
func run() -> void:
    root.size = Vector2i(960,640)
    check(not Profile.enabled,"profiling disabled by default")
    var cold := Counter.new()
    root.add_child(cold)
    await settle()
    check(Profile.counts.is_empty() and Profile.timings.is_empty(),"disabled hook collects no counts/timing samples")
    cold.free()
    await settle()
    Profile.set_enabled(true)
    var hud := ToggleDemo.new()
    await idle(hud,"class-wide-nested-hud")
    var host = State.records[hud.get_instance_id()]
    var row = hud.get_node("UI/Panel/First")
    var nested = State.records[row.get_instance_id()]
    var peer = State.records[hud.get_node("UI/Panel/Second").get_instance_id()]
    var peer_runs: int = peer.runs
    var row_id: int = row.get_instance_id()
    await measure("hud/32-host-writes",func():
        for index in range(32): hud.revision += 1,
        func(): check(count("views")==1 and count("coalesced")==31 and peer.runs==peer_runs and row.get_instance_id()==row_id,"32 writes coalesce, unrelated nested peer idle"))
    await measure("hud/same-value",func(): hud.revision = hud.revision,
        func(): check(count("views")==0 and count("elements")==0,"same-value write has no composition"))
    await measure("hud/row-only",func(): row.model.note += "!",
        func(): check(count("views")==0,"unread class-wide field has no observers"))
    await measure("hud/shared-model",func(): hud.model.enabled = not hud.model.enabled,
        func(): check(count("views")==3 and count("nodes_created")==0 and count("nodes_freed")==0,"only three interested model computations, retained Nodes"))
    var toggle = hud.get_node("UI/Panel/Edit")
    var toggle_id: int = toggle.get_instance_id()
    Profile.reset()
    await click(toggle)
    await settle()
    check(hud.model.enabled==toggle.value and count("views")==3 and count("property_writes")==5,"pointer edit has one authoritative projection without echo")
    cases.append({"name":"toggle/actual-pointer","samples":[Profile.snapshot()]})
    await measure("toggle/model-replace",func(): hud.replace_model(),
        func(): check(hud.get_node("UI/Panel/Edit").get_instance_id()==toggle_id and count("binding_disconnects")==3 and count("binding_connects")==3,"model replacement rewires three controls once"))
    hud.free()
    await settle()
    var conditional := Conditional.new()
    await idle(conditional,"deep-conditional")
    var child = conditional.get_node("UI/Panel/Nested")
    var label = conditional.get_node("UI/Panel/After")
    var sibling_measure: int = label.get_layout_stats().measure
    await measure("conditional/deep-branch",func():
        conditional.count = 5 if conditional.count==0 else 0
        conditional.show_bonus = not conditional.show_bonus,
        func(): check(conditional.get_node("UI/Panel/After")==label and label.get_layout_stats().measure==sibling_measure,"conditional preserves sibling identity/measure cache"))
    await measure("conditional/model-replace",func(): conditional.model = Model.new(),
        func(): check(count("views")==2,"model replacement schedules parent and independent nested component"))
    Profile.reset()
    conditional.show_child = false
    child.value += 1
    State.drain()
    await settle()
    check(count("cancelled_jobs")==1 and not is_instance_valid(child),"parent-first removal cancels dirty nested computation")
    cases.append({"name":"conditional/parent-child-cancellation","samples":[Profile.snapshot()]})
    conditional.free()
    await settle()
    for size in [8,64,128]: await inventory(size)
    for dimension in ["TwoD","ThreeD"]:
        var scene: Node = load("res://examples/ggx/generated/"+dimension+".gd").new()
        await idle(scene,dimension)
        var entry = scene.get_node("Entry")
        var first = entry.get_node("First")
        var original = first.position
        var id: int = first.get_instance_id()
        await measure(dimension+"/bounded-layout",func(): first.width += 0.25,
            func(): check(first.get_instance_id()==id and first.position==original and count("views")==0 and count("layout_flushes")==1,"native dimensional layout retains transform authority without recompose"))
        scene.free()
        await settle()
    var objects_before := Performance.get_monitor(Performance.OBJECT_COUNT)
    var memory_before := OS.get_static_memory_usage()
    var weak_models: Array = []
    for index in range(12):
        var scene := ToggleDemo.new()
        root.add_child(scene)
        await settle()
        weak_models.append(weakref(scene.model))
        scene.replace_model()
        await settle()
        scene.show_row = false
        scene.free()
        await settle()
        check(State.records.is_empty() and State.dirty.is_empty(),"repeated mount/free clears manager scopes and pending jobs")
    for weak in weak_models: check(weak.get_ref()==null,"replaced weak model released")
    check(int(Performance.get_monitor(Performance.OBJECT_COUNT)-objects_before)==weak_models.size(),"only the twelve retained WeakRef probes remain after repeated lifetimes")
    cases.append({"name":"lifetime/12-cycles","objects_before":objects_before,"objects_after":Performance.get_monitor(Performance.OBJECT_COUNT),"static_memory_delta_bytes":OS.get_static_memory_usage()-memory_before})
    Profile.set_enabled(false)
    Profile.reset()
    write_profile()
    print("PROFILING_ASSERTIONS ",assertions," failures=",failures)
    if failures==0: print("PROFILING_RUNTIME_OK")
    quit(1 if failures else 0)
func inventory(size: int) -> void:
    var scene := Inventory.new()
    var items: Array = []
    for index in range(size): items.append(Item.new(index+1,"Item %d" % index))
    scene.items = items
    scene.next_id = size+1
    root.add_child(scene)
    await settle()
    var row = scene.get_node("UI/Panel/Row1")
    row.clicks = 7
    await settle()
    var row_id: int = row.get_instance_id()
    await measure("list/%d/no-op" % size,func(): scene.items = scene.items.duplicate(),
        func(): check(count("nodes_created")==0 and count("nodes_freed")==0 and count("moves")==0 and count("property_writes")==0 and count("views")==1,"near-no-op has no native edits or row reruns"))
    await measure("list/%d/reverse" % size,func(): scene.reverse_items(),
        func(): check(count("nodes_created")==0 and count("nodes_freed")==0 and count("moves")==size-1 and scene.get_node("UI/Panel/Row1").get_instance_id()==row_id and row.clicks==7,"reverse retains IDs/state with exactly n-1 native moves"))
    await measure("list/%d/append-remove" % size,func():
        scene.append_item()
        State.drain()
        scene.items = scene.items.slice(0,size),
        func(): check(count("nodes_created")==2 and count("nodes_freed")==2,"append/remove allocates and frees only one row plus caption"))
    await measure("list/%d/prepend-remove" % size,func():
        scene.items = [Item.new(scene.next_id,"Prepend")] + scene.items
        scene.next_id += 1
        State.drain()
        scene.items = scene.items.slice(1),
        func(): check(count("nodes_created")==2 and count("nodes_freed")==2,"prepend/remove touches only inserted row"))
    var parent_runs: int = State.records[scene.get_instance_id()].runs
    await measure("list/%d/row-state" % size,func(): row.clicks += 1,
        func(): check(count("views")==1 and State.records[scene.get_instance_id()].runs==parent_runs,"row state reruns one independent observer"))
    scene.free()
    await settle()
func click(node: Node2D) -> void:
    var point: Vector2 = node.get_global_transform_with_canvas()*(node.layout_size*0.5)
    for down in [true,false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.position = point
        event.pressed = down
        Input.parse_input_event(event)
        await process_frame

func write_profile() -> void:
    var output := FileAccess.open("res://profile.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"platform":OS.get_name(),"warmup":WARMUP,"samples":SAMPLES,"cases":cases,"assertions":assertions,"failures":failures}))
    output.close()
