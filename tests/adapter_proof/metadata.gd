extends SceneTree
func _initialize() -> void:
	var failures: int = 0
	for path in ["res://addons/estragon/runtime/node/estragon_2d.gd", "res://addons/estragon/runtime/node/estragon_3d.gd", "res://addons/estragon/runtime/node/component_2d.gd", "res://addons/estragon/runtime/node/component_3d.gd", "res://addons/estragon/runtime/node/native_2d.gd", "res://addons/estragon/runtime/node/native_3d.gd", "res://addons/estragon/adapter_proof/native_2d.gd", "res://addons/estragon/adapter_proof/native_3d.gd", "res://addons/estragon/compiler/compiler.gd", "res://examples/counter/generated/Counter.gd"]:
		var first = load(path)
		if first == null or first != load(path): failures += 1
		if Engine.get_version_info().minor >= 4:
			var uid: String = FileAccess.get_file_as_string(path + ".uid").strip_edges()
			if ResourceUID.id_to_text(ResourceLoader.get_resource_uid(path)) != uid or load(uid) != first:
				failures += 1
	var texture = load("res://Assets/Estragon Centered Logo.png")
	var font = load("res://Assets/Fonts/LondonTwo.ttf")
	if not texture is Texture2D or texture.get_width() <= 0 or not font is Font: failures += 1
	if failures == 0: print("GODOT_METADATA_IDENTITY_OK")
	else: printerr("Metadata identity/import assertions failed: ",failures)
	quit(1 if failures else 0)
