extends SceneTree
var packer := PCKPacker.new()
var failed: bool = false
func add_file(path: String) -> void:
	if packer.add_file(path,path)!=OK:
		failed = true
		push_error("Cannot pack addon resource: "+path)
func add_dir(path: String) -> void:
	for file in DirAccess.get_files_at(path): add_file(path.path_join(file))
	for dir in DirAccess.get_directories_at(path): add_dir(path.path_join(dir))
func _initialize() -> void:
	if packer.pck_start(OS.get_cmdline_user_args()[0])!=OK:
		quit(1)
		return
	add_dir("res://addons")
	add_dir("res://examples")
	add_file("res://project.godot")
	add_file("res://tests/distribution/scenes.gd")
	if FileAccess.file_exists("res://.godot/global_script_class_cache.cfg"): add_file("res://.godot/global_script_class_cache.cfg")
	if packer.flush()!=OK: failed = true
	if not failed: print("ADDON_PACK_OK")
	quit(1 if failed else 0)
