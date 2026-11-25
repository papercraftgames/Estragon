extends SceneTree
func _initialize(): run.call_deferred()
func run():
    var host=load("res://examples/constraint_layout/generated/Constraints.gd").new()
    root.add_child(host)
    var probe=preload("constraint_game.gd").new()
    var result=await probe.run(host)
    print("LAYOUT01_GAME_RESULT ",JSON.stringify(result))
    host.free()
    for index in range(6): await process_frame
    var state=preload("res://addons/estragon/runtime/composition/state.tres")
    if not state.records.is_empty(): result.ok=false
    if result.ok: print("LAYOUT01_GRAPHICS_OK")
    quit(0 if result.ok else 1)
