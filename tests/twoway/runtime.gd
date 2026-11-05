extends SceneTree
const Demo = preload("res://examples/twoway/generated/Demo.gd")
const Model = preload("res://examples/twoway/generated/Model.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var assertions := 0
var failures := 0
var edits: Array = []
var changes: Array = []
func check(value: bool, message: String) -> void:
    assertions += 1
    print("TWOWAY_CHECK ",message,": ",value)
    if not value:
        failures += 1
        push_error("TwoWay: "+message)
func _initialize() -> void:
    run.call_deferred()
func settle() -> void:
    for index in range(8): await process_frame
func edit(value: bool) -> void: edits.append(value)
func changed(previous: bool, value: bool) -> void: changes.append([previous,value])
func click(node: Node2D) -> void:
    var point = node.get_global_transform_with_canvas() * (node.layout_size*0.5)
    var press := InputEventMouseButton.new()
    press.button_index = MOUSE_BUTTON_LEFT
    press.position = point
    press.pressed = true
    Input.parse_input_event(press)
    var release := InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.position = point
    release.pressed = false
    Input.parse_input_event(release)
func run() -> void:
    var scene := Demo.new()
    root.add_child(scene)
    await settle()
    var scope = State.records[scene.get_instance_id()]
    var toggle = scene.get_node("UI/Panel/Edit")
    var label = scene.get_node("UI/Panel/Status")
    var row = scene.get_node("UI/Panel/First")
    var peer = scene.get_node("UI/Panel/Second")
    var child_scope = State.records[row.get_instance_id()]
    var peer_scope = State.records[peer.get_instance_id()]
    var id: int = toggle.get_instance_id()
    check(toggle is Node2D and not toggle is Control and not toggle.value and label.text=="Disabled","native initial controlled bool projection")
    toggle.value_changed.connect(edit)
    scene.model.enabled_changed.connect(changed)
    var runs: int = scope.runs
    click(toggle)
    await settle()
    check(scene.model.enabled and toggle.value and label.text=="Enabled" and edits==[true] and changes==[[false,true]],"actual primary-pointer route edits native model exactly once")
    check(scope.runs==runs+1 and toggle.get_instance_id()==id and label==scene.get_node("UI/Panel/Status"),"one composed commit retains toggle and label")
    click(toggle)
    await settle()
    check(not scene.model.enabled and edits==[true,false] and changes==[[false,true],[true,false]],"repeat pointer click produces one transition each")
    edits.clear()
    changes.clear()
    runs = scope.runs
    scene.model.enabled = false
    await settle()
    check(changes.is_empty() and edits.is_empty() and scope.runs==runs,"same-value model assignment has no event or composition")
    scene.model.enabled = true
    await settle()
    check(toggle.value and edits.is_empty() and changes==[[false,true]],"model projection never emits reciprocal user edit")
    toggle.value = false
    check(scene.model.enabled and edits.is_empty(),"programmatic control assignment is not user input")
    var nested_before: int = child_scope.runs
    scene.revision += 1
    await settle()
    check(toggle.value and child_scope.runs==nested_before and peer_scope.runs==nested_before,"controlled actual value restored without rerendering unaffected nested peers")
    var child_runs: int = child_scope.runs
    var peer_runs: int = peer_scope.runs
    var writes: int = child_scope.writes
    scene.reverse = true
    await settle()
    check(row==scene.get_node("UI/Panel/First") and peer==scene.get_node("UI/Panel/Second") and child_scope.runs==child_runs and peer_scope.runs==peer_runs and child_scope.writes==writes,"key reorder preserves input identity and does no peer work")
    var old = scene.model
    var weak := weakref(old)
    var callback = toggle.value_changed.get_connections()[0].callable
    scene.replace_model()
    callback.call(false)
    check(old.enabled and not scene.model.enabled,"stale callback cannot write old or new model before replacement commit")
    old.enabled_changed.disconnect(changed)
    await settle()
    check(toggle==scene.get_node("UI/Panel/Edit") and not toggle.value and old.enabled_changed.get_connections().is_empty(),"retained input rewires to authoritative replacement and disconnects old dependencies")
    old = null
    check(weak.get_ref()==null,"binding records and generated closures do not retain old model")
    callback.call(true)
    check(not scene.model.enabled,"disconnected captured callback remains inert after replacement")
    # Reentrant native model write wins, with no reciprocal user event or loop.
    var reentrant: Callable = func(_before: bool, next: bool):
        if next: scene.model.enabled = false
    scene.model.enabled_changed.connect(reentrant)
    edits.clear()
    click(toggle)
    await settle()
    check(not scene.model.enabled and not toggle.value and edits==[true],"reentrant model restore wins at deferred commit even when old desired snapshot is unchanged")
    scene.model.enabled_changed.disconnect(reentrant)
    var reedit: Callable = func(_before: bool, next: bool):
        if next: toggle.value_changed.emit(false)
    scene.model.enabled_changed.connect(reedit)
    click(toggle)
    await settle()
    check(scene.model.enabled and toggle.value,"reentrant edit callback is bounded and cannot ping-pong the boundary")
    scene.model.enabled_changed.disconnect(reedit)
    scene.model.enabled = false
    await settle()
    toggle.disabled = true
    edits.clear()
    click(toggle)
    await settle()
    check(edits.is_empty() and not scene.model.enabled,"disabled pointer activation produces no edit")
    toggle.disabled = false
    # Host-local binding and selective subscriptions.
    var host_child_runs: int = child_scope.runs
    var host_toggle = scene.get_node("UI/Panel/HostEdit")
    click(host_toggle)
    await settle()
    check(scene.enabled and host_toggle.value and child_scope.runs==host_child_runs,"host self binding uses same manager without nested rerender")
    var nested_toggle = row.get_node("RowView/Edit")
    var stale = nested_toggle.value_changed.get_connections()[0].callable
    scene.show_row = false
    await settle()
    stale.call(true)
    check(not is_instance_valid(row) and not scene.model.enabled,"unmounted keyed input callback cannot write")
    scene.model = null
    await settle()
    check(not scene.has_node("UI/Panel/Edit"),"null source intentionally omitted by ordinary conditional")
    var invalid = preload("res://addons/estragon/runtime/composition/binding.gd").new(scene,func(owner): return owner.model,"enabled",func(owner, value: bool): owner.enabled = value,"model.enabled")
    check(not invalid.valid,"present null binding rejects instead of silently becoming writable")
    scene.replace_model()
    scene.show_row = true
    await settle()
    toggle = scene.get_node("UI/Panel/Edit")
    var foreign := Node.new()
    foreign.name = "Foreign"
    toggle.add_child(foreign)
    foreign.owner = scene
    scene.model = null
    await settle()
    check(is_instance_valid(foreign) and foreign.get_parent()==scene and foreign.owner==scene,"binding unmount preserves foreign child and native owner")
    scene.replace_model()
    await settle()
    toggle = scene.get_node("UI/Panel/Edit")
    callback = toggle.value_changed.get_connections()[0].callable
    root.remove_child(scene)
    callback.call(true)
    check(not scene.model.enabled and toggle.value_changed.get_connections().is_empty(),"host detach disconnects input and suppresses captured callback")
    root.add_child(scene)
    await settle()
    check(toggle==scene.get_node("UI/Panel/Edit") and toggle.value_changed.get_connections().size()==1,"reparent/resume reconnects exactly once retaining native input")
    click(toggle)
    await settle()
    check(scene.model.enabled,"resumed pointer route writes current model")
    var packed := PackedScene.new()
    check(packed.pack(scene)==OK,"native scene packs without transient managed controls")
    var restored = packed.instantiate()
    root.add_child(restored)
    await settle()
    check(restored.get_node("UI/Panel/Edit").value_changed.get_connections().size()==1 and restored.get_meta_list().is_empty(),"pack/reload reconstitutes binding once with no reactive metadata")
    restored.free()
    var retained = scene.model
    scene.free()
    callback.call(false)
    check(retained.enabled and retained.enabled_changed.get_connections().is_empty() and State.records.is_empty(),"host free releases listeners/records and stale input cannot write")
    compiler_checks()
    print("TWOWAY_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
    if failures==0: print("TWOWAY_RUNTIME_OK")
    quit(1 if failures else 0)
func compiler_checks() -> void:
    var source := FileAccess.get_file_as_string("res://examples/twoway/Demo.gogo")
    for fixture in ["BadArity","BadSignal","BadValue"]:
        var bad_control := Compiler.compile(source.replace("res://addons/estragon/runtime/node/toggle.gd","res://tests/twoway/"+fixture+".gd"),"examples/twoway/Demo.gogo")
        check(not bad_control.ok and "writable bool value" in bad_control.diagnostics[0].message,"reject native input contract: "+fixture)
    var first := Compiler.compile(source,"examples/twoway/Demo.gogo")
    var second := Compiler.compile(source,"examples/twoway/Demo.gogo")
    check(first.ok and second.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"typed binding generation/maps deterministic")
    var mapped := false
    for index in range(first.code.split("\n").size()):
        var line: String = first.code.split("\n")[index]
        if line.contains("binding.gd"):
            var point = first.source_map.original_position(index+1,line.find("preload")+1)
            mapped = mapped or point!=null and point.line==21
    check(mapped,"generated binding linkage maps to exact authored binding expression line")
    for path in ["true","model.enabled","self.model.enabled or true","self.replace_model().enabled","self.model.note","self.position.x","self.missing","self.model.enabled[0]","self.model.enabled + 1"]:
        var bad := Compiler.compile(source.replace("bind:value={self.model.enabled}","bind:value={"+path+"}"),"examples/twoway/Demo.gogo")
        check(not bad.ok and bad.diagnostics[0].span.start.line==21,"reject invalid writable/observable/type path: "+path)
    for replacement in ["bind:value=\"bad\"","bind:other={self.model.enabled}","bind:value={self.model.enabled} value={true}","bind:value={self.model.enabled} value_changed={replace_model}","bind:value={self.model.enabled} bind:value={self.model.enabled}"]:
        check(not Compiler.compile(source.replace("bind:value={self.model.enabled}",replacement),"examples/twoway/Demo.gogo").ok,"reject unsupported/conflicting binding: "+replacement)
    check(not Compiler.compile(source.replace("<Toggle name=\"Edit\"","<Text name=\"Edit\""),"examples/twoway/Demo.gogo").ok,"reject input without typed value/signal contract")
