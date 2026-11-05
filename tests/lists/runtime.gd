extends SceneTree
const Inventory = preload("res://examples/inventory/generated/Inventory.gd")
const Item = preload("res://examples/inventory/generated/Item.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var assertions := 0
var failures := 0
func check(value: bool, message: String) -> void:
    assertions += 1
    if not value:
        failures += 1
        push_error("F03: "+message)
func _initialize() -> void:
    run.call_deferred()
func settle() -> void:
    for index in range(6): await process_frame
func counts(record) -> Array:
    return [record.allocations,record.frees,record.moves,record.writes]
func rows(panel: Node) -> Array:
    var result: Array = []
    for node in panel.get_children():
        if str(node.name).begins_with("Row"): result.append(node)
    return result
func run() -> void:
    var scene := Inventory.new()
    root.add_child(scene)
    await settle()
    var record = State.records[scene.get_instance_id()]
    var panel = scene.get_node("UI/Panel")
    var title = panel.get_node("Title")
    var footer = panel.get_node("Footer")
    var original := rows(panel)
    var first = original[0]
    var child_record = State.records[first.get_instance_id()]
    check(rows(panel).size()==3 and record.runs==1 and record.moves==0,"for-built nested list mounts once without moves")
    check(not first.has_meta("key") and first.get_meta_list().is_empty(),"key never becomes native property or metadata")
    first.clicks = 8
    first.rotation = 0.25
    await settle()
    var runs: int = record.runs
    var child_runs: int = child_record.runs
    var before := counts(record)
    scene.items = scene.items.duplicate()
    await settle()
    check(counts(record)==before and record.runs==runs+1 and child_record.runs==child_runs,"reference reassignment no-op does no native operations or nested reruns")
    scene.append_item()
    await settle()
    check(record.allocations==before[0]+1 and record.frees==before[1] and record.moves==before[2]+1,"append allocates one row and orders beside static footer once")
    check(rows(panel).slice(0,3)==original and panel.get_node("Footer")==footer,"append preserves existing rows and static sibling")
    before = counts(record)
    scene.items = [Item.new(99,"Prepend")] + scene.items
    await settle()
    check(record.allocations==before[0]+1 and record.frees==before[1] and record.moves==before[2]+1,"prepend creates/moves only one new row")
    before = counts(record)
    scene.insert_item()
    await settle()
    check(record.allocations==before[0]+1 and record.frees==before[1] and record.moves==before[2]+1,"middle insert creates/moves only one row")
    before = counts(record)
    scene.remove_item()
    await settle()
    check(record.allocations==before[0] and record.frees==before[1]+1 and record.moves==before[2],"delete frees only removed row and performs zero native moves")
    var previous := rows(panel)
    before = counts(record)
    scene.reverse_items()
    await settle()
    var reversed := previous.duplicate()
    reversed.reverse()
    check(rows(panel)==reversed and record.allocations==before[0] and record.frees==before[1] and record.moves==before[2]+previous.size()-1,"reverse retains all IDs with exactly n-1 moves")
    check(first.clicks==8 and first.rotation==0.25 and child_record.runs==child_runs,"reorder preserves row state/native transform and independent computation")
    before = counts(record)
    var next: Array = scene.items.duplicate()
    var swap = next[0]
    next[0] = next[1]
    next[1] = swap
    scene.items = next
    await settle()
    check(record.moves==before[2]+1 and record.allocations==before[0] and record.frees==before[1],"adjacent swap uses exactly one move")
    runs = record.runs
    child_runs = child_record.runs
    var unchanged_cache: int = footer.get_layout_stats().measure
    first.item.title = "Changed row only"
    await settle()
    check(record.runs==runs and child_record.runs==child_runs+1,"per-item observed field reruns only its row")
    check(footer.get_layout_stats().measure==unchanged_cache,"row update retains unaffected sibling layout measurement")
    before = counts(record)
    scene.use_map = true
    scene.show_note = false
    await settle()
    check(record.allocations==before[0] and record.frees==before[1]+1 and record.moves==before[2],"Array.map equivalent keeps keyed rows while conditional sibling disappears")
    check(panel.get_node("Title")==title and panel.get_node("Footer")==footer and first.clicks==8,"mixed conditional/list preserves unkeyed authored neighbors")
    var removed_model = scene.items[0]
    var removed = panel.get_node("Row%d" % removed_model.id)
    var removed_record = State.records[removed.get_instance_id()]
    var removed_runs: int = removed_record.runs
    removed.clicks += 1
    before = counts(record)
    scene.replace_item()
    await settle()
    check(not is_instance_valid(removed) and removed_record.disposed and removed_record.runs==removed_runs,"key change cancels queued old row job before removal")
    check(record.allocations==before[0]+1 and record.frees==before[1]+1 and removed_model.title_changed.get_connections().is_empty(),"key replacement disconnects removed model and allocates/frees once")
    # Same key, different native type: replace through the existing reconciler.
    var desired = record._normalize(scene.build_view())
    var leaf = null
    for child in desired.children[0].children:
        if child!=null and child.keyed:
            leaf = child
            break
    var old_row = rows(panel)[0]
    leaf.type = "Node2D"
    leaf.properties = {"name":"Alternate"}
    before = counts(record)
    check(record._valid(desired,record.mounted) and record._preflight(desired,record.mounted,scene),"same-key different-type output preflights")
    record.mounted = record._reconcile(desired,record.mounted,scene,scene)
    check(not is_instance_valid(old_row) and panel.has_node("Alternate") and record.allocations==before[0]+1 and record.frees==before[1]+1,"same key different type replaces exactly one native host")
    scene.show_note = true
    await settle()
    # Replace a row's model under the same key: host/state retained, reads rewired.
    var retained = rows(panel)[0]
    var old_model = retained.item
    var model_weak: WeakRef = weakref(old_model)
    var replacement := Item.new(old_model.id,"New model same key")
    next = scene.items.duplicate()
    next[0] = replacement
    var retained_id: int = retained.get_instance_id()
    scene.items = next
    await settle()
    check(rows(panel)[0].get_instance_id()==retained_id and retained.item==replacement and old_model.title_changed.get_connections().is_empty(),"same key new model retains host and rewires observers")
    # Release test-owned snapshots before checking model lifetime.
    desired = null
    leaf = null
    old_model = null
    check(model_weak.get_ref()==null,"old per-row model has no stale retained references")
    var parent = retained.get_parent()
    parent.remove_child(retained)
    check(replacement.title_changed.get_connections().is_empty(),"detached row disconnects")
    root.add_child(retained)
    await settle()
    check(replacement.title_changed.get_connections().size()==1,"reparented row reconnects once")
    retained.clicks += 1
    scene.reverse_items()
    await settle()
    check(retained.get_parent()==panel and replacement.title_changed.get_connections().size()==1,"keyed owning commit restores external reparent without duplicate observers")
    var freed_id: int = retained.get_instance_id()
    retained.free()
    scene.show_note = false
    await settle()
    check(panel.get_node("Row%d" % replacement.id).get_instance_id()!=freed_id,"externally freed keyed slot remounts once")
    # A valid simultaneous rename cannot be silently changed by native Node.
    var named := rows(panel).slice(0,2)
    var swapped_names := [str(named[1].name),str(named[0].name)]
    desired = record._normalize(scene.build_view())
    var descriptions: Array = []
    for child in desired.children[0].children:
        if child!=null and child.keyed: descriptions.append(child)
    descriptions[0].properties = descriptions[0].properties.duplicate()
    descriptions[1].properties = descriptions[1].properties.duplicate()
    descriptions[0].properties.name = swapped_names[0]
    descriptions[1].properties.name = swapped_names[1]
    check(record._valid(desired,record.mounted) and record._preflight(desired,record.mounted,scene),"simultaneous keyed sibling name swap validates complete final set")
    record.mounted = record._reconcile(desired,record.mounted,scene,scene)
    check(str(named[0].name)==swapped_names[0] and str(named[1].name)==swapped_names[1],"native final names survive swap without automatic renaming")
    desired = null
    descriptions.clear()
    scene.show_note = not scene.show_note
    await settle()
    # Foreign rescue must use keyed matching rather than old positions.
    var foreign := Node.new()
    foreign.name = "Foreign"
    var target = rows(panel)[0]
    target.get_node("Caption").add_child(foreign)
    foreign.owner = scene
    scene.remove_item()
    await settle()
    check(foreign.get_parent()==scene and foreign.owner==scene,"keyed removal rescues foreign descendant with valid owner")
    before = counts(record)
    runs = record.runs
    scene.items.append(Item.new(90,"Unobserved native append"))
    await settle()
    check(record.runs==runs and counts(record)==before,"raw in-place Array mutation does not inherently notify")
    scene.items = scene.items.duplicate()
    await settle()
    check(panel.has_node("Row90"),"reference reassignment observes latest in-place contents")
    var packed := PackedScene.new()
    check(packed.pack(scene)==OK,"keyed managed output remains transient for native scene packing")
    scene.items = []
    await settle()
    check(rows(panel).is_empty() and panel.get_node("Footer")==footer,"empty list retains static footer")
    scene.free()
    await settle()
    check(State.records.is_empty(),"free drops all nested/list computations and queued jobs")
    var restored: Node = packed.instantiate()
    root.add_child(restored)
    await settle()
    check(rows(restored.get_node("UI/Panel")).size()==3,"PackedScene recreates source-authoritative list once")
    restored.free()
    compiler_checks()
    print("LISTS_RUNTIME_ASSERTIONS ",assertions," failures=",failures)
    if failures==0: print("LISTS_RUNTIME_OK")
    quit(1 if failures else 0)
func compiler_checks() -> void:
    var source := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nfunc build_view() -> Element:\n\tvar rows: Array = []\n\tfor item in [1,2]:\n\t\trows.append(<Node key={item} />)\n\treturn <Node>{[[],rows,null,[<Node key="last" />]]}</Node>\n'
    var evaluation := 'extends Node\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nvar trace: Array = []\nfunc stamp(value: String) -> String:\n\ttrace.append(value)\n\treturn value\nfunc build_view() -> Element:\n\treturn <Node name={stamp("parent")}><Node name={stamp("first")} />{[<Node name={stamp("second")} /> if true else <Node name={stamp("skipped")} />]}<Node name={stamp("last")} /></Node>\n'
    var evaluation_result := Compiler.compile(evaluation,"evaluation.gogo")
    check(evaluation_result.ok,"native helper/conditional sequence source compiles")
    if evaluation_result.ok:
        var script := GDScript.new()
        script.source_code = evaluation_result.code
        check(script.reload()==OK,"evaluation order source passes native semantics")
        var probe = script.new()
        var output = probe.build_view()
        check(output is Element and probe.trace==["parent","first","second","last"] and probe.get_child_count()==0,"description expressions evaluate once left to right with lazy alternatives and no candidate Nodes")
        probe.free()
    var first := Compiler.compile(source,"lists.gogo")
    var second := Compiler.compile(source,"lists.gogo")
    check(first.ok and first.code==second.code and first.source_map.serialize()==second.source_map.serialize(),"loop arrays/keys compile deterministically with maps")
    for invalid in ['{7}','{Node.new()}','{[null,3]}','{true}']:
        var compiled := Compiler.compile(source.replace('{[[],rows,null,[<Node key="last" />]]}',invalid),"invalid.gogo")
        check(not compiled.ok and compiled.diagnostics[0].span.start.line==7,"invalid child leaf has authored diagnostic: "+invalid)
    for invalid in ['key={false}','key={null}','key={1.5}','key=""','key={<Node />}','key={[]}','key={&"name"}']:
        var compiled := Compiler.compile(source.replace('key="last"',invalid),"invalid-key.gogo")
        check(not compiled.ok and compiled.diagnostics[0].span.start.line==7,"invalid key has authored diagnostic: "+invalid)
    var scope := Element.new("Node",{},{},[Element.new("Node",{},{},[],"",1,true),[Element.new("Node",{},{},[],"","1",true)],Element.new("Node",{},{},[],"",null,false)])
    var owner := Node.new()
    var computation = preload("res://addons/estragon/runtime/composition/computation.gd").new(owner,State)
    var normalized = computation._normalize(scope)
    check(computation._valid(normalized,null),"int and String keys differ; missing keys use positional identity")
    scope.children[1][0].key = 1
    normalized = computation._normalize(scope)
    check(not computation._valid(normalized,null),"duplicate keys across separate nested arrays reject")
    owner.free()
    var duplicate := Compiler.compile(source.replace('{[[],rows,null,[<Node key="last" />]]}','<Node key="x" /><Node key="x" />'),"duplicate-key.gogo")
    check(not duplicate.ok and duplicate.diagnostics[0].message.contains("Duplicate"),"statically duplicate literal keys fail before Play")
    duplicate = Compiler.compile(source.replace('key="last"','key="x"').replace('[[],rows,null,[<Node key="x" />]]','[<Node key="x" />, [<Node key={"x"} />]]'),"nested-duplicate.gogo")
    check(not duplicate.ok and duplicate.diagnostics[0].message.contains("Duplicate"),"nested literal duplicate keys reject across array boundaries")
