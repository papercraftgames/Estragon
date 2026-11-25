extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var host=load("res://examples/values/generated/Values.gd").new();root.add_child(host)
	var probe=preload("game.gd").new();var result=await probe.run(host)
	print("UI05_GAME_RESULT ",JSON.stringify(result));host.free()
	for i in range(8): await process_frame
	var state=preload("res://addons/estragon/runtime/composition/state.tres")
	var focus=preload("res://addons/estragon/runtime/node/internal/focus.tres")
	if not state.records.is_empty() or not focus.viewports.is_empty() or not focus.geometry_changed.get_connections().is_empty(): result.ok=false
	if result.ok: print("UI05_GRAPHICS_OK")
	quit(0 if result.ok else 1)
