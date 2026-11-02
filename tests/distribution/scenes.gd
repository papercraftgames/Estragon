extends SceneTree
## Runs from a cache-free distributed project and from an exported resource pack.
var _failed := false
var _checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	_checks += 1
	print("C01_H_CHECK ", message, ": ", value)
	if not value:
		_failed = true
		push_error("Distribution: " + message)

func _run() -> void:
	_check(ProjectSettings.get_setting("application/config/features")[0] == "4.0", "project declares baseline 4.0")
	var packed_mode := OS.get_cmdline_user_args().has("--pack")
	if not packed_mode:
		_check(not DirAccess.dir_exists_absolute("res://tools") and not FileAccess.file_exists("res://package.json"), "distributed addon has no contributor toolchain")
	for scene in ["hello/Hello", "layout/Layout", "compiled/Compiled", "mixed/Mixed", "interactive/Interactive", "counter/Counter"]:
		var location: String = "res://examples/" + scene + ".tscn"
		var packed := load(location) as PackedScene
		_check(packed != null and packed.can_instantiate(), "scene/dependencies load: " + scene)
		if packed == null or not packed.can_instantiate(): continue
		var host := packed.instantiate()
		root.add_child(host)
		await process_frame
		_check(host.get_child_count() == 0 and not host is Control, "single host, independent components: " + scene)
		if scene == "counter/Counter":
			_check(host.count == 0 and host.get_root().get_children()[1].text == "Count: 0", "shipped generated Counter executes")
			host.increment()
			await process_frame
			_check(host.count == 1, "shipped generated callback")
			host.reset_count()
			_check(host.count == 0, "shipped generated reset")
		host.free()
	_check(FileAccess.file_exists("res://examples/hello/generated/Main.gogo.json"), "legacy JSON included")
	if packed_mode:
		_check(FileAccess.file_exists("res://examples/counter/Counter.gogo"), "authored Gogo included by explicit export filter")
	print("C01_H_DISTRIBUTION_ASSERTIONS ", _checks)
	if not _failed: print("C01_H_DISTRIBUTION_OK")
	quit(1 if _failed else 0)
