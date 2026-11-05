extends SceneTree
func _initialize() -> void:
    run.call_deferred()
func capture(name: String) -> void:
    for index in range(8): await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png("res://"+name+".png")!=OK: quit(1)
func run() -> void:
    root.size = Vector2i(760,480)
    var scene = preload("res://examples/inventory/generated/Inventory.gd").new()
    root.add_child(scene)
    await capture("lists-initial")
    scene.first_state()
    scene.insert_item()
    scene.rename_item()
    await capture("lists-changed")
    scene.reverse_items()
    await capture("lists-reordered")
    if scene.get_node("UI/Panel/Row1").clicks!=1:
        push_error("Keyed native row lost state")
        quit(1)
        return
    root.size = Vector2i(960,600)
    await capture("lists-resized")
    scene.free()
    print("LISTS_VISUAL_OK")
    quit()
