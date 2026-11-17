extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var host = load("res://app/generated/SurfaceGallery.gd").new()
	root.add_child(host)
	var result: Dictionary = await preload("res://tests/surfaces/game.gd").new().run(host)
	host.free()
	for i in range(8): await process_frame
	if result.ok: print("S04_PLAY_OK")
	quit(0 if result.ok else 1)
