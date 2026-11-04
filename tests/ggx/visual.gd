extends SceneTree
var failure: bool = false
func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for index in range(4): await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://" + name + ".png") != OK: failure = true

func run() -> void:
	root.size = Vector2i(640,360)
	for dimension in [2,3]:
		var scene: Node = load("res://examples/ggx/TwoD.tscn" if dimension == 2 else "res://examples/ggx/ThreeD.tscn").instantiate()
		root.add_child(scene)
		await capture("c2-%dd-initial" % dimension)
		scene.entry.get_node("Pulse").timeout.emit()
		await capture("c2-%dd-changed" % dimension)
		root.size = Vector2i(800,420)
		await capture("c2-%dd-resized" % dimension)
		scene.free()
		root.size = Vector2i(640,360)
	print("GGX_C2_VISUAL_OK" if not failure else "GGX_C2_VISUAL_FAILED")
	quit(1 if failure else 0)
