extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var host=load("res://examples/data/generated/Gallery.gd").new()
    root.add_child(host)
    var probe=preload("game.gd").new()
    var result=await probe.run(host)
    print("CORE02_GAME_RESULT ",JSON.stringify(result))
    host.free()
    for index in range(5): await process_frame
    if result.ok: print("CORE02_INTEGRATION_OK")
    quit(0 if result.ok else 1)
