extends Node
## External observer: the component runs its exact, untouched blank script.
func _ready() -> void:
	_probe.call_deferred()
func _probe() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var component := get_parent().get_node("Component")
	var kind: String = component.get_script().get_instance_base_type()
	if component.get_child_count() != 1 or not component.has_method("build_view"):
		push_error("New component did not mount its minimal view")
		get_tree().quit(1)
		return
	var view := component.get_child(0)
	if view.get_class() != kind or view.get_script() != null or view.get_child_count() != 0:
		push_error("Starter view must be one ordinary native leaf, without layout/content")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://e02-blank-"+kind+".png")
	var output := FileAccess.open("res://.godot/e02-game.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"text":"blank","children":component.get_child_count(),"base":kind}))
	output.close()
