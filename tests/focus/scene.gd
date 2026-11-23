extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var host = load("res://app/generated/Focus.gd").new()
	root.add_child(host)
	var result = await preload("game.gd").new().run(host)
	host.queue_free()
	for i in range(8): await process_frame
	if result.ok: print("UI01_SCENE_OK")
	quit(0 if result.ok else 1)
