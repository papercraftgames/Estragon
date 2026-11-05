extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failures := 0
func _initialize() -> void:
    run.call_deferred()
func settle() -> void:
    for index in range(6): await process_frame
func check(value: bool, message: String) -> void:
    print("LISTS_REJECTION_CHECK ",message,": ",value)
    if not value: failures += 1
func run() -> void:
    var script := GDScript.new()
    script.source_code = 'extends "res://examples/inventory/generated/Inventory.gd"\n@export var invalid: int = 0\nfunc build_view() -> Element:\n\tvar view: Element = super.build_view()\n\tvar list: Array = view.children[0].children[2][1]\n\tif invalid==1: list[1].key = list[0].key\n\tif invalid==2: list.append(42)\n\tif invalid==3: list[0].key = false\n\tif invalid==4: list[0].properties.name = "Footer"\n\tif invalid==5: list[0].properties.unknown = 1\n\tif invalid==6: list[0].type = "RefCounted"\n\tif invalid==7: list.append(self)\n\tif invalid==8: list[0].key = &"key"\n\tif invalid==9: list[0].key = ""\n\tif invalid==10: list[0].key = 1.5\n\tif invalid==11: list[0].key = null\n\treturn view\n'
    if script.reload()!=OK: quit(1); return
    var scene = script.new()
    root.add_child(scene)
    await settle()
    var record = State.records[scene.get_instance_id()]
    var panel = scene.get_node("UI/Panel")
    var row = panel.get_node("Row1")
    var child_record = State.records[row.get_instance_id()]
    for mode in range(1,12):
        var before := [record.allocations,record.frees,record.moves,record.writes,record.runs]
        scene.invalid = mode
        scene.show_note = not scene.show_note
        await settle()
        check(panel.get_node("Row1")==row and before==[record.allocations,record.frees,record.moves,record.writes,record.runs],"bad sequence/key/name/type/property atomically retains tree: %d" % mode)
        check(not child_record.disposed and row.item.title_changed.get_connections().size()==1,"rejection preserves row subscription: %d" % mode)
        scene.invalid = 0
        scene.show_note = not scene.show_note
        await settle()
        check(record.runs==before[4]+1 and panel.get_node("Row1")==row,"repair recovers prior subscription: %d" % mode)
    var foreign := Node.new()
    foreign.name = "Collision"
    row.get_node("Caption").add_child(foreign)
    var collision := Node.new()
    collision.name = "Collision"
    scene.add_child(collision)
    var before: int = record.runs
    scene.remove_item()
    await settle()
    check(is_instance_valid(row) and foreign.get_parent()==row.get_node("Caption") and record.runs==before,"keyed foreign rescue collision rejects before removal")
    collision.free()
    scene.show_note = not scene.show_note
    await settle()
    check(not is_instance_valid(row) and foreign.get_parent()==scene,"foreign rescue conflict repairs safely")
    var cyclic: Array = []
    cyclic.append(cyclic)
    var desired = scene.build_view()
    desired.children = cyclic
    check(record._normalize(desired)==null,"cyclic arrays reject with bounded traversal")
    cyclic.clear()
    desired = null
    scene.free()
    if failures==0: print("LISTS_REJECTION_OK")
    quit(1 if failures else 0)
