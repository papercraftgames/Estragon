@tool
extends RefCounted
## Shared authored source scope. No compiler/editor/tree or authored Script loads.
const CONFIG := "gogo.config.json"
const EXCLUDED := ["generated", "node_modules", "tests", "vendor"]
var root: String
var sources: Dictionary = {}
var errors: Array = []
var overrides: Dictionary = {}
var discovered := false
var texts: Dictionary = {}
func _init(project: String = "res://") -> void:
	root = ProjectSettings.globalize_path(project).simplify_path().trim_suffix("/")
func _fail(message: String) -> void: errors.append(message)
func safe(path: String) -> bool:
	if not path.begins_with(root + "/"):
		_fail("Generated/source path escapes the project: " + path)
		return false
	var current := path
	while current != root:
		var directory := DirAccess.open(current.get_base_dir())
		if directory != null and directory.has_method("is_link") and directory.call("is_link", current.get_file()):
			_fail("Symlinks are not supported in Gogo source/output paths: " + path.trim_prefix(root + "/"))
			return false
		current = current.get_base_dir()
	return true

func discover() -> void:
	if discovered: return
	discovered = true
	var config_path := root.path_join(CONFIG)
	if not FileAccess.file_exists(config_path):
		visit(root, true)
		return
	if not safe(config_path): return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(config_path)) != OK:
		_fail(CONFIG + ": " + json.get_error_message())
		return
	var config: Variant = json.data
	if not config is Dictionary or config.size() != 2 or config.get("version") != 1 or not config.get("source_roots") is Array or config.source_roots.is_empty():
		_fail(CONFIG + ": expected version 1 and nonempty project-relative source_roots only")
		return
	for source_root in config.source_roots:
		if not source_root is String or source_root.is_empty() or source_root.is_absolute_path() or ":" in source_root or "\\" in source_root:
			_fail(CONFIG + ": invalid source root " + str(source_root))
			continue
		var invalid := false
		for part in source_root.split("/"):
			if part.begins_with(".") or part in EXCLUDED: invalid = true
		if invalid:
			_fail(CONFIG + ": invalid source root " + source_root)
			continue
		var path := root.path_join(source_root).simplify_path()
		if safe(path): visit(path)

func visit(path: String, default_root: bool = false) -> void:
	if path != root and not safe(path): return
	if FileAccess.file_exists(path):
		if path.ends_with(".gogo"): sources[path.trim_prefix(root + "/")] = true
		return
	var directory := DirAccess.open(path)
	if directory == null:
		_fail("Cannot read Gogo source root: " + path.trim_prefix(root + "/"))
		return
	var entries := Array(directory.get_directories()) + Array(directory.get_files())
	entries.sort()
	for name in entries:
		if name.begins_with(".") or name in EXCLUDED or default_root and name == "addons": continue
		visit(path.path_join(name))

static func output_for(source: String) -> String:
	return source.get_base_dir().path_join("generated").path_join(source.get_file().trim_suffix(".gogo") + ".gd")


func resource(source: String) -> String:
	return "res://"+source if root == ProjectSettings.globalize_path("res://").trim_suffix("/") else root.path_join(source)
func authored(path: String) -> String:
	return ProjectSettings.globalize_path(path).simplify_path().trim_prefix(root+"/")
func read(source: String) -> String:
	var path := resource(source)
	if overrides.has(path): return overrides[path]
	if not texts.has(source): texts[source] = FileAccess.get_file_as_string(root.path_join(source))
	return texts[source]
func named(name: String) -> Array:
	discover()
	var found: Array = []
	for source in sources:
		if str(source).get_file().get_basename() == name: found.append(source)
	found.sort()
	return found
