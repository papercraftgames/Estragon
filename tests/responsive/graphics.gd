extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var host = load("res://app/ResponsiveGallery.tscn").instantiate()
	root.add_child(host)
	var result: Dictionary = await preload("res://tests/responsive/game.gd").new().run(host)
	var packed := PackedScene.new()
	var saved: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://packed-responsive.tscn")==OK
	var ok: bool = result.ok and saved
	host.free()
	for frame in range(8): await process_frame
	host = load("res://packed-responsive.tscn").instantiate()
	root.add_child(host)
	for frame in range(12): await process_frame
	ok = ok and host.has_node("UI/Content/Named/Main") and host.get_node("UI/Content/Named").columns==["140px","1fr"]
	host.free()
	for frame in range(8): await process_frame
	ok = ok and preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres").placements.is_empty()
	print("L0910_GRAPHICS_PACK_RELOAD ",ok)
	if ok: print("L0910_GRAPHICS_OK")
	quit(0 if ok else 1)
