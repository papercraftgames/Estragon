@tool
extends EditorPlugin
## Real editor Play entry points and child-game proof, autosave disabled.
var SOURCE := "res://examples/conditional/Counter.gogo"

var OUTPUT := "res://examples/counter/generated/Counter.gd"
const PROOF := "res://.godot/conditional-play.json"
var _interface: EditorInterface
var _failed := false
var _checks := 0
var _counter: CodeEdit
var _background: CodeEdit
var _source: String
var _background_source: String
var _plugin: EditorPlugin

func _enter_tree() -> void:
	_interface = get_editor_interface()
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	_checks += 1
	print("CONDITIONAL_EDITOR_CHECK ", message, ": ", value)
	if not value: _failed = true

func _wait(seconds: float = 0.1) -> void:
	await get_tree().create_timer(seconds).timeout

func _until(condition: Callable, message: String) -> bool:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if condition.call(): return true
		await get_tree().process_frame
	_check(false, message)
	return false

func _find_plugin() -> bool:
	for node in get_tree().root.find_children("*", "EditorPlugin", true, false):
		if node.get_script() != null and node.get_script().resource_path == "res://addons/estragon/editor/plugin.gd":
			_plugin = node
	return _plugin != null and _plugin.last_report.get("ok", false) and not _plugin._building and not _plugin._filesystem_busy()

func _selected_tree(path: String) -> Tree:
	for tree in _interface.get_file_system_dock().find_children("*", "Tree", true, false):
		var selected: TreeItem = tree.get_selected()
		if selected != null and selected.get_metadata(0) is String and selected.get_metadata(0) == path:
			return tree
	return null

func _code_ready(path: String) -> bool:
	var editor := _interface.get_script_editor().get_current_editor()
	if editor == null: return false
	var code := editor.get_base_editor() as CodeEdit
	return code != null and code.text == FileAccess.get_file_as_string(path) and code.syntax_highlighter != null and code.syntax_highlighter.get_script() != null and code.syntax_highlighter.get_script().resource_path == "res://addons/estragon/editor/highlighter.gd"

func _open(path: String) -> CodeEdit:
	_interface.get_file_system_dock().navigate_to_path(path)
	if not await _until(func(): return _selected_tree(path) != null, "dock selects source"): return null
	_selected_tree(path).item_activated.emit()
	if not await _until(func(): return _code_ready(path), "Gogo editor and highlighter ready"): return null
	return _interface.get_script_editor().get_current_editor().get_base_editor() as CodeEdit

func _uid() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(OUTPUT + ".uid") if FileAccess.file_exists(OUTPUT + ".uid") else PackedByteArray()

func _clear_proof() -> void:
	if FileAccess.file_exists(PROOF): DirAccess.remove_absolute(PROOF)

func _play(mode: String) -> void:
	if mode == "project": _interface.play_main_scene()
	else: _interface.play_current_scene()

func _stop() -> void:
	_interface.stop_playing_scene()
	await _until(func(): return not _interface.is_playing_scene() and not _plugin._building and not _plugin._filesystem_busy(), "child stopped and editor filesystem idle")

func _success(mode: String, value: int) -> void:
	var scenario_started := Time.get_ticks_msec()
	_clear_proof()
	_play(mode)
	if await _until(func(): return FileAccess.file_exists(PROOF), mode + " child executes current GGX"):
		var proof = JSON.parse_string(FileAccess.get_file_as_string(PROOF))
		_check(_interface.is_playing_scene() and proof.count==value and proof.text=="Count: %d" % value, mode+" executes newest Gogo native layout")
	await _stop()
	print("CI_EDITOR_TIMING success_", mode, " ", (Time.get_ticks_msec() - scenario_started) / 1000.0)

func _blocked(mode: String, diagnostic: String) -> void:
	var scenario_started := Time.get_ticks_msec()
	_clear_proof()
	var previous := FileAccess.get_file_as_bytes(OUTPUT)
	var map := FileAccess.get_file_as_bytes(OUTPUT + ".map.json")
	var timestamp := FileAccess.get_modified_time(OUTPUT)
	var uid := _uid()
	var cached = load(OUTPUT)
	var cached_source: String = cached.source_code
	_play(mode)
	await _wait(0.8)
	_check(not _interface.is_playing_scene() and not FileAccess.file_exists(PROOF), mode + " blocks stale child execution: " + diagnostic)
	_check(not _plugin.last_report.ok and diagnostic in str(_plugin.last_report.diagnostics), mode + " reports useful failure: " + diagnostic)
	_check(FileAccess.get_file_as_bytes(OUTPUT) == previous and FileAccess.get_file_as_bytes(OUTPUT + ".map.json") == map and FileAccess.get_modified_time(OUTPUT) == timestamp and _uid() == uid, "failed Play preserves generated code/map/UID/timestamp")
	_check(load(OUTPUT) == cached and cached.source_code == cached_source, "failed Play preserves Script identity/source")

	print("CI_EDITOR_TIMING rejected_", mode, " ", (Time.get_ticks_msec() - scenario_started) / 1000.0)

func _run() -> void:
	if not await _until(_find_plugin,"native addon startup"):
		_finish()
		return
	_interface.get_editor_settings().set_setting("run/auto_save/save_before_running",false)
	_interface.get_editor_settings().set_setting("text_editor/behavior/files/autosave_interval_secs",0)
	_counter = await _open(SOURCE)
	_check(_counter!=null,"real native Gogo CodeEdit")
	if _counter==null:
		_finish()
		return
	_check(_counter.syntax_highlighter != null and _counter.syntax_highlighter.get_script().resource_path == "res://addons/estragon/editor/highlighter.gd","real Gogo tab associated with native highlighter")
	_source = FileAccess.get_file_as_string(SOURCE)
	_interface.open_scene_from_path("res://examples/conditional/Counter.tscn")
	await _until(func(): return _interface.get_edited_scene_root() != null and _interface.get_edited_scene_root().scene_file_path == "res://examples/conditional/Counter.tscn" and not _plugin._filesystem_busy(), "requested scene ready")
	for mode in ["project","current"]:
		_counter.text = _source.replace("var count: int = 0","var count: int = 7")
		await _success(mode,7)
		_check(FileAccess.get_file_as_string(SOURCE)==_counter.text,"normal Play saves latest native Counter")
		_counter.text = _source.replace("pressed={increment}","pressed={missing_handler}")
		await _blocked(mode,"Counter.gogo:")
		_counter.text = _source.replace("<Entry name=","<RefCounted name=")
		await _blocked(mode,"Counter.gogo:")
		_counter.text = _source.replace("else null}","else 7}")
		await _blocked(mode,"Counter.gogo:22:")
		_counter.text = _source
		await _success(mode,0)
		var moved := SOURCE+".backup"
		DirAccess.rename_absolute(SOURCE,moved)
		DirAccess.make_dir_absolute(SOURCE)
		_counter.text = _source.replace("var count: int = 0","var count: int = 99")
		await _blocked(mode,"Counter.gogo:")
		DirAccess.remove_absolute(SOURCE)
		DirAccess.rename_absolute(moved,SOURCE)
		_counter.text = _source
		await _success(mode,0)
	_finish()
func _finish() -> void:
	print("CONDITIONAL_EDITOR_ASSERTIONS ",_checks)
	if not _failed: print("CONDITIONAL_EDITOR_OK")
	get_tree().quit(1 if _failed else 0)
