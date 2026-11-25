extends RefCounted
const State=preload("res://addons/estragon/runtime/composition/state.tres")
const Profile=preload("res://addons/estragon/runtime/composition/profile.tres")
var checks:=0
var ok:=true
func check(value: bool,label: String):
    checks+=1
    ok=ok and value
    print("LAYOUT01_GAME ",label,": ",value)
func near(a: float,b: float) -> bool: return absf(a-b)<0.02
func frames(tree: SceneTree):
    for index in range(9): await tree.process_frame
func core(node): return node._get_layout_coordinator().model
func run(host: Node) -> Dictionary:
    var tree=host.get_tree()
    tree.root.size=Vector2i(460,420)
    await frames(tree)
    var grid=host.get_node("UI/Grid")
    var body=grid.get_node("Body")
    var header=grid.get_node("Title")
    var header_root=header.get_node("Header")
    var flow_host=header_root.get_node("Nested")
    var flow=flow_host.get_node("Flow")
    var fixed=grid.get_node("Fixed")
    var input=body.get_layout_child("Editor")
    var editor: LineEdit=input.get_focus_control()
    var first=body.get_layout_child("Row1")
    var first_button=first.get_node("Action")
    var calls=[host.calls,header.calls,flow_host.calls]
    var fixed_measures=core(fixed).measure_count
    input.grab_focus()
    await frames(tree)
    editor.caret_column=4
    editor.select(1,4)
    for width in [460,600,460]:
        tree.root.size=Vector2i(width,420)
        await frames(tree)
        var expected: float=48 if width==460 else 20
        check(near(flow.layout_size.x,(width-20.0)/2.0) and near(flow.layout_size.y,expected),"transparent nested Wrap uses actual Grid cell "+str(width))
        check(near(header_root.layout_size.y,expected+16) and near(core(grid).policy_result.rows[0],expected+16),"dependent height propagates through auto VBox and spanning Body row "+str(width))
        check(near(body.layout_size.y,420-12-expected-16),"definite fr Body gets real remainder "+str(width))
        check(calls==[host.calls,header.calls,flow_host.calls],"layout resize never reruns Gogo view functions "+str(width))
        check(editor==input.get_focus_control() and editor.has_focus() and editor.has_selection() and editor.caret_column==4,"native caret/selection/focus retained across constraint changes "+str(width))
        check(body.scroll_range.y>0 and near(body.content_extent.y-core(body).scroll_geometry.viewport.size.y,body.scroll_range.y),"scroll extent agrees with post-gutter viewport "+str(width))
        await RenderingServer.frame_post_draw
        tree.root.get_texture().get_image().save_png("res://constraint-layout-"+str(width)+".png")
    check(core(fixed).measure_count==fixed_measures,"unrelated fixed sibling keeps measurement cache")
    var previous: int=first.presses
    var point=first_button.get_global_transform_with_canvas()*(first_button.layout_size/2)
    for down in [true,false]:
        var event=InputEventMouseButton.new()
        event.button_index=MOUSE_BUTTON_LEFT
        event.position=point
        event.pressed=down
        Input.parse_input_event(event)
        await frames(tree)
    check(first.presses==previous+1 and first_button.has_focus(),"actual post-layout clipped native pointer target activates once")
    for down in [true,false]:
        var event=InputEventKey.new()
        event.keycode=KEY_SPACE
        event.pressed=down
        Input.parse_input_event(event)
        await frames(tree)
    check(first.presses==previous+2,"retained native focus owns exactly one keyboard activation")
    body.scroll_offset=Vector2(0,20)
    await frames(tree)
    tree.root.size=Vector2i(600,420)
    await frames(tree)
    check(near(body.scroll_offset.y,20),"resize preserves valid native scroll offset")
    host.items.move(0,1)
    host.items.append({"id":11,"label":"Eleven"})
    await frames(tree)
    check(body.get_layout_child("Row1")==first and first.get_node("Action")==first_button and first_button.has_focus(),"observable keyed insert/reorder retains native focus and identities")
    var second=body.get_layout_child("Row2")
    var second_calls: int=second.calls
    host.items.at(1).label="Changed"
    await frames(tree)
    check(first_button.text=="Changed" and second.calls==second_calls,"deep collection item edit updates only affected row view")
    host.items.remove_at(10)
    await frames(tree)
    check(body.get_layout_child("Row11")==null,"observable removal reflows current content")
    host.show_header=false
    await frames(tree)
    check(not is_instance_valid(header) and near(core(grid).policy_result.rows[0],10) and body.get_layout_child("Editor")==input,"conditional removes auto track contributor and retains Body/Input")
    host.show_header=true
    await frames(tree)
    check(near(core(grid).policy_result.rows[0],36),"conditional remount remeasures from existing 290px cell")
    Profile.set_enabled(true)
    Profile.reset()
    await frames(tree)
    var idle: Dictionary=Profile.snapshot()
    Profile.set_enabled(false)
    check(idle.counts.get("views",0)==0 and idle.counts.get("layout_measures",0)==0 and idle.counts.get("layout_arranges",0)==0,"settled idle has zero render/measure/arrange work")
    var packed=PackedScene.new()
    var packed_ok=packed.pack(host)==OK and ResourceSaver.save(packed,"res://constraint-packed.tscn")==OK
    var reopened=load("res://constraint-packed.tscn").instantiate() if packed_ok else null
    if reopened!=null: tree.root.add_child(reopened)
    await frames(tree)
    check(reopened!=null and reopened.has_node("UI/Grid/Title") and near(reopened.get_node("UI/Grid/Title/Header").layout_size.y,36),"native pack/reopen restores constrained source composition")
    if reopened!=null: reopened.free()
    await frames(tree)
    var count: int=State.records.size()
    check(count>0,"original retained composition remains active after independent reopened cleanup")
    return {"ok":ok,"checks":checks,"root_calls":host.calls,"identity":body.get_layout_child("Row1")==first,"idle":idle.counts}
