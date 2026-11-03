extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Node2D = load("res://examples/node_proof/Main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://b1-before.png") != OK:
		quit(1)
		return
	scene.get_node("Composition/Pulse").start()
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	if scene.ticks != 1 or root.get_texture().get_image().save_png("res://b1-after.png") != OK:
		quit(1)
		return
	scene.free()
	print("GGX_B1_VISUAL_OK")
	quit()
