extends RefCounted
var checks:=0
var ok:=true
func check(value: bool,label: String):
    checks+=1
    print("CORE02_GAME ",label,": ",value)
    ok=ok and value
func frames(tree: SceneTree):
    for index in range(8): await tree.process_frame
func run(host: Node) -> Dictionary:
    var tree=host.get_tree()
    await frames(tree)
    var row=host.get_node("DataUI/List/Row1")
    var button=row.get_node("Action")
    var item=host.inventory.items.at(0)
    var edits:=0
    for size in [Vector2i(640,360),Vector2i(900,520)]:
        tree.root.size=size
        await frames(tree)
        button.grab_focus()
        var old=item.quantity
        var press=InputEventKey.new()
        press.keycode=KEY_SPACE
        press.pressed=true
        Input.parse_input_event(press)
        await frames(tree)
        press=InputEventKey.new()
        press.keycode=KEY_SPACE
        press.pressed=false
        Input.parse_input_event(press)
        await frames(tree)
        check(item.quantity==old+1,"native keyboard edits typed item once")
        edits+=1
        host.inventory.items.move(0,1)
        await frames(tree)
        check(host.get_node("DataUI/List/Row1")==row and row.get_node("Action")==button and button.has_focus(),"keyed reorder retains real focus and control identity")
        var point=button.get_global_transform_with_canvas()*(button.layout_size/2)
        old=item.quantity
        for down in [true,false]:
            var mouse=InputEventMouseButton.new()
            mouse.button_index=MOUSE_BUTTON_LEFT
            mouse.position=point
            mouse.pressed=down
            Input.parse_input_event(mouse)
            await frames(tree)
        check(item.quantity==old+1,"arranged native hit follows reordered row")
        edits+=1
        host.inventory.items.move(1,0)
        await frames(tree)
        await RenderingServer.frame_post_draw
        tree.root.get_texture().get_image().save_png("res://data-game-"+str(size.x)+".png")
    return {"ok":ok,"checks":checks,"edits":edits,"quantity":item.quantity,"identity":host.get_node("DataUI/List/Row1")==row,"focus":button.has_focus()}
