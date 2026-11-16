extends SceneTree
func _initialize(): run.call_deferred()
func run():
	var host = load("res://app/generated/UXGallery.gd").new()
	root.add_child(host)
	var probe = preload("res://tests/ux01/game.gd").new()
	var result: Dictionary = await probe.run(host)
	var packed := PackedScene.new()
	var saved: bool = packed.pack(host)==OK and ResourceSaver.save(packed,"res://ux01-packed.tscn")==OK
	var ok: bool = result.ok and saved
	host.free()
	for i in range(8): await process_frame
	host = load("res://ux01-packed.tscn").instantiate()
	root.add_child(host)
	for i in range(8): await process_frame
	ok = ok and host.has_node("UI/Content/Scroll") and host.get_node("UI/Content/Scroll").get_content_root()!=null
	host.free()
	for i in range(8): await process_frame
	ok = ok and preload("res://addons/estragon/runtime/composition/state.tres").records.is_empty()
	print("UX01_PACK_RELOAD ",ok)
	if ok: print("UX01_GALLERY_OK")
	quit(0 if ok else 1)
