extends SceneTree
const Data=preload("res://addons/estragon/runtime/data/state.tres")
const Collection=preload("res://addons/estragon/runtime/data/array_collection.gd")
const State=preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var errors := 0
var signals := 0
func check(value: bool,label: String) -> void:
    checks+=1
    print("CORE02 ",label,": ",value)
    if not value: errors+=1
func changed(): signals+=1
func frames():
    for index in range(6): await process_frame
func _initialize(): run.call_deferred()
func run():
    var Inventory=load("res://examples/data/generated/Inventory.gd")
    var Item=load("res://examples/data/generated/Item.gd")
    var result=Data.hydrate({"items":[{"id":1},{"id":2,"details":{"tags":["deep"]}}]},Inventory)
    check(result.ok,"recursive typed hydration")
    if not result.ok: quit(1); return
    var inventory=result.value
    check(inventory.items.at(0).quantity==1 and inventory.items.at(0).name=="Unnamed" and inventory.selected==null,"declared and native defaults; nullable model")
    check(Data.hydrate(JSON.parse_string('{"items":[{"id":3,"quantity":4}]}'),Inventory).ok,"real parsed JSON numeric fields hydrate")
    var plain=inventory.to_data()
    check(plain.items[1].details.tags==["deep"] and plain.selected==null,"recursive serialization")
    Data.refresh(inventory)
    inventory._gogo_data_changed.connect(changed)
    var item=inventory.items.at(0)
    item.details.note="Deep edit"
    check(signals==1,"grandchild same-identity upward notification")
    inventory.selected=item
    signals=0
    item.details.note="Diamond"
    check(signals==1,"shared child diamond emits once at root")
    inventory.selected=null
    var reentrant=func():
        if item.quantity<3: item.quantity=3
    inventory._gogo_data_changed.connect(reentrant)
    item.quantity=2
    check(item.quantity==3,"reentrant listener settles without notification storm")
    inventory._gogo_data_changed.disconnect(reentrant)
    inventory.items.append(item)
    signals=0
    item.quantity+=1
    check(signals==1,"duplicate instance membership subscribes once")
    inventory.items.remove_at(0)
    signals=0
    item.quantity+=1
    check(signals==1,"duplicate remaining membership stays observed")
    inventory.items.remove_at(1)
    signals=0
    item.quantity+=1
    check(signals==0,"last membership removal detaches")
    inventory.items.begin_update()
    inventory.items.append({"id":3})
    inventory.items.insert(0,{"id":4})
    inventory.items.move(0,2)
    inventory.items.end_update()
    check(signals==1,"one structural notification for mutation batch")
    var old=inventory.items.at(0)
    inventory.items.replace(0,{"id":5})
    signals=0
    old.details.note="Detached"
    check(signals==0,"replacement detaches nested graph")
    var before=inventory.to_data()
    print("CORE02_EXPECTED_REJECTION_BEGIN")
    check(not inventory.items.reset([{"id":6},{"id":"wrong"}]),"invalid reset rejected")
    check(not inventory.items.insert(-1,{"id":6}),"invalid index rejected")
    Data.assign(inventory,"items",[{"id":7},{"unknown":true}],"fixture.gogo:1:1")
    await process_frame
    print("CORE02_EXPECTED_REJECTION_END")
    check(inventory.to_data()==before,"failed collection and hydration keep prior state atomically")
    var cycle: Array=[]
    cycle.append(cycle)
    check(not Data.hydrate(cycle,[TYPE_ARRAY]).ok,"plain-data cycles rejected")
    cycle.clear()
    check(not Data.hydrate({"items":[{"details":{"note":Vector2.ONE}}]},Inventory).ok,"unsupported native values rejected")
    check(not Data.hydrate({"items":{}},Inventory).ok,"malformed collection rejected")
    var nested=Data.hydrate([[{"id":8}]],[[Item]])
    check(nested.ok and nested.value.at(0).at(0).id==8,"deeply nested typed collections hydrate")
    var deep_events: Array=[]
    nested.value.changed.connect(func(): deep_events.append(true))
    nested.value.at(0).at(0).details.note="Nested collections"
    check(deep_events.size()==1,"nested collections bubble grandchild changes")
    check(Data.hydrate(inventory.to_data(),Inventory).value.to_data()==inventory.to_data(),"model JSON-like round trip")
    check(not Data.hydrate({"title":null},Inventory).ok,"null scalar rejected")
    check(Data.hydrate({"selected":null,"items":null},Inventory).ok,"nullable model and collection references")
    var retained=inventory.items
    inventory=null
    result.clear()
    check(retained.get_signal_connection_list("changed").is_empty(),"parent GC disconnects child subscriptions")
    var host=load("res://examples/data/generated/Gallery.gd").new()
    root.add_child(host)
    await frames()
    check(host.has_node("DataUI/List/Row1"),"real keyed GGX mounts")
    if not host.has_node("DataUI/List/Row1"): host.free(); quit(1); return
    var row1=host.get_node("DataUI/List/Row1")
    var row2=host.get_node("DataUI/List/Row2")
    var button=row1.get_node("Action")
    var computation=State.records[host.get_instance_id()]
    var runs=computation.runs
    host.raw.append(1)
    host.raw_data.value=2
    await frames()
    check(computation.runs==runs,"raw Array and Dictionary in-place mutations remain unobserved")
    var replacement: Array=[2]
    host.raw=replacement
    await frames()
    check(computation.runs==runs+1 and is_same(host.raw,replacement),"raw reference replacement stays native and observable")
    var count=host.row_calls.duplicate()
    var summary_count=host.summary_calls
    host.inventory.items.at(0).details.note="Edited in place"
    await frames()
    check(host.summary_calls==summary_count+1,"same root argument invalidates opaque summary")
    check(host.row_calls[1]==count[1]+1 and host.row_calls[2]==count[2],"only affected row recomputes")
    check(host.get_node("DataUI/List/Row1")==row1 and row1.get_node("Action")==button,"leaf edits retain native nodes and handlers")
    runs=computation.runs
    for index in range(20): host.inventory.items.at(0).quantity+=1
    await frames()
    check(computation.runs==runs+1,"burst leaf edits coalesce in the existing scheduler")
    host.inventory.items.move(0,1)
    await frames()
    check(host.get_node("DataUI/List/Row1")==row1 and host.get_node("DataUI/List/Row2")==row2,"reordering retains keyed identities")
    print("CORE02_EXPECTED_REJECTION_BEGIN")
    host.inventory.items.append({"id":1})
    await frames()
    await process_frame
    print("CORE02_EXPECTED_REJECTION_END")
    check(host.get_node("DataUI/List/Row1")==row1 and host.get_node("DataUI/List/Row2")==row2,"duplicate keys reject before native changes")
    host.inventory.items.remove_at(2)
    await frames()
    host.pulse+=1
    await frames()
    count=host.row_calls.duplicate()
    await frames()
    check(host.row_calls==count,"idle has no row computations")
    host.replace_items()
    await frames()
    check(host.inventory.items.size()==1 and host.inventory.items.at(0).name=="Cable","compiled property Array assignment hydrates")
    host.replace_inventory()
    await frames()
    check(host.inventory.title=="Refilled" and host.inventory.items.size()==2 and host.has_node("DataUI/List/Row2") and host.get_node("DataUI/List/Title").text.begins_with("Refilled"),"compiled model reassignment hydrates and updates native UI")
    host.show_rows=false
    await frames()
    check(not host.has_node("DataUI/List/Row1"),"conditional removes rows")
    host.inventory.items.reset([])
    host.show_rows=true
    await frames()
    check(not host.has_node("DataUI/List/Row1"),"empty collection renders")
    var model=host.inventory
    host.free()
    await frames()
    check(State.records.is_empty(),"unmount removes render computations")
    check(model.get_signal_connection_list("_gogo_data_changed").is_empty(),"unmount disconnects render subscriptions")
    model=null
    retained=null
    item=null
    old=null
    inventory=null
    await frames()
    Data.prune()
    print("CORE02_CHECKS ",checks," ERRORS ",errors)
    if errors==0: print("CORE02_RUNTIME_OK")
    quit(0 if errors==0 else 1)
