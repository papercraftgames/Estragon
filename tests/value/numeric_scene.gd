extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var host=load("res://examples/values/generated/Values.gd").new();root.add_child(host)
	var probe=preload("numeric_game.gd").new();var result=await probe.run(host)
	print("UI05_NUMERIC_RESULT ",JSON.stringify(result));host.free()
	if result.ok: print("UI05_NUMERIC_OK")
	quit(0 if result.ok else 1)
