@tool
extends RefCounted
## Native project build. No editor UI, processes or external tool configuration.
const Compiler = preload("../compiler/compiler.gd")
const Validation = preload("../compiler/script_validation.gd")
const Dependencies = preload("script_dependencies.gd")
const ProjectSources = preload("../compiler/project_sources.gd")
const CONFIG := "gogo.config.json"
var _project_sources
const EXCLUDED := ["generated", "node_modules", "tests", "vendor"]
var _project: String
var _report := {"ok": false, "outputs": [], "changed": [], "diagnostics": [], "source_diagnostics": [], "isolated_preflight": {"status": "UNTESTED"}}
var _sources: Dictionary = {}
var _staging: String
var _previous_code: Dictionary = {}

static func run_build(project: String = "res://") -> Dictionary:
	var build := new()
	build._project = ProjectSettings.globalize_path(project).simplify_path().trim_suffix("/")
	return build._run()

func _fail(message: String) -> void:
	_report.diagnostics.append(message)

func _fail_source(diagnostic) -> void:
	_fail(diagnostic.format())
	_report.source_diagnostics.append({"source":diagnostic.source_name,"line":diagnostic.span.start.line,"column":diagnostic.span.start.column,"end_line":diagnostic.span.end.line,"end_column":diagnostic.span.end.column,"message":diagnostic.message})

func _scope():
	if _project_sources == null: _project_sources = ProjectSources.new(_project)
	return _project_sources
func _safe(path: String) -> bool:
	var scope = _scope()
	var before: int = scope.errors.size()
	var valid: bool = scope.safe(path)
	_report.diagnostics.append_array(scope.errors.slice(before))
	return valid
func _discover() -> void:
	var scope = _scope()
	scope.discover()
	_sources = scope.sources
	_report.diagnostics.append_array(scope.errors)
static func output_for(source: String) -> String: return ProjectSources.output_for(source)

func _run() -> Dictionary:
	var directory := DirAccess.open(_project)
	_report["symlink_checks"] = {"status": "PASS" if directory != null and directory.has_method("is_link") else "BLOCKED", "reason": "Symlink-free source/output paths are required; older engines cannot introspect links. Lexical path containment remains enforced."}
	_discover()
	if not _report.diagnostics.is_empty(): return _report
	var sources := _sources.keys()
	sources.sort()
	var compiled: Array[Dictionary] = []
	# Metadata resolution and code generation must read the same source snapshot.
	for source in sources:
		var input := FileAccess.open(_project.path_join(source), FileAccess.READ)
		if input == null:
			_fail(source + ": cannot read source (" + error_string(FileAccess.get_open_error()) + ")")
			continue
		_scope().texts[source] = input.get_as_text()
	if not _report.diagnostics.is_empty(): return _report
	for source in sources:
		var result := Compiler.compile(_scope().read(source), source, _resource_path(output_for(source)), _scope())
		if not result.ok:
			for diagnostic in result.diagnostics: _fail_source(diagnostic)
		else: compiled.append({"source": source, "output": output_for(source), "result": result})
	if not _report.diagnostics.is_empty(): return _report
	compiled = _validation_order(compiled)
	if not _report.diagnostics.is_empty(): return _report
	var writes: Dictionary = {}
	for item in compiled:
		_report.outputs.append(item.output)
		writes[item.output] = item.result.code.to_utf8_buffer()
		writes[item.output + ".map.json"] = item.result.source_map.serialize().to_utf8_buffer()
	for path in writes:
		if not _safe(_project.path_join(path)): return _report
	# Stage new bytes; retain old files by rename so rollback preserves their
	# content and timestamps. No filesystem notifications until commit succeeds.
	var stage := _project.path_join(".godot/estragon/transaction-%d" % get_instance_id())
	_staging = stage
	if not _safe(stage): return _report
	if DirAccess.make_dir_recursive_absolute(stage) != OK:
		_fail("Cannot create native Gogo staging directory")
		return _report
	var operations: Array[Dictionary] = []
	for path in writes:
		var target := _project.path_join(path)
		var exists := FileAccess.file_exists(target)
		var bytes: Variant = writes[path]
		if bytes == null and not exists: continue
		if exists:
			var old_file := FileAccess.open(target, FileAccess.READ)
			if old_file == null:
				_fail("Cannot read existing generated output: " + path)
				_cleanup(operations)
				return _report
			var old_bytes := old_file.get_buffer(old_file.get_length())
			old_file.close()
			if path.ends_with(".gd"): _previous_code[path] = old_bytes.get_string_from_utf8()
			if bytes != null and old_bytes == bytes: continue
		var operation := {"path": path, "target": target, "old": stage.path_join("old-%d" % operations.size()), "new": stage.path_join("new-%d" % operations.size()), "existed": exists, "installed": false, "backed_up": false}
		if not _safe(operation.old) or not _safe(operation.new): return _report
		operations.append(operation)
		if bytes != null:
			var file := FileAccess.open(operation.new, FileAccess.WRITE)
			if file == null:
				_fail("Cannot stage generated output: " + path)
				_cleanup(operations)
				return _report
			file.store_buffer(bytes)
			file.flush()
			var write_error := file.get_error()
			file.close()
			if write_error != OK:
				_fail("Cannot write generated output: " + path)
				_cleanup(operations)
				return _report
	for operation in operations:
		if DirAccess.make_dir_recursive_absolute(operation.target.get_base_dir()) != OK:
			_fail("Cannot create generated directory: " + operation.path)
			break
		if operation.existed:
			if DirAccess.rename_absolute(operation.target, operation.old) != OK:
				_fail("Cannot back up generated output: " + operation.path)
				break
			operation.backed_up = true
		if writes[operation.path] != null:
			if DirAccess.rename_absolute(operation.new, operation.target) != OK:
				_fail("Cannot publish generated output: " + operation.path)
				break
			operation.installed = true
	var cache_state: Array[Dictionary] = []
	var isolated := Validation.supports_isolated_path()
	_report.isolated_preflight = {"status": "UNTESTED" if isolated else "BLOCKED", "reason": "" if isolated else "Unavailable native path API; mandatory transactional actual-path validation used instead"}
	if _report.diagnostics.is_empty():
		for item in compiled:
			if isolated:
				var checked := Validation.validate(item.result, _resource_path(item.output))
				for diagnostic in checked.diagnostics: _fail_source(diagnostic)
				if not checked.ok:
					_report.isolated_preflight.status = "FAIL"
					break
			# Owner-approved older-engine capability contract: isolated validation is unavailable,
			# never simulated with a cached Script. Native actual-path reload is
			# mandatory, including no-op builds, before this transaction can commit.
			_refresh_cache(item, cache_state)
			if not _report.diagnostics.is_empty(): break
	if not _report.diagnostics.is_empty():
		_rollback(operations)
		_restore_cache(cache_state)
	else:
		if isolated and not compiled.is_empty(): _report.isolated_preflight.status = "PASS"
		for operation in operations: _report.changed.append(operation.path)
		_report.ok = true
	_cleanup(operations)
	return _report

func _rollback(operations: Array[Dictionary]) -> void:
	for index in range(operations.size() - 1, -1, -1):
		var operation := operations[index]
		if operation.installed and DirAccess.remove_absolute(operation.target) != OK:
			_fail("Cannot remove rejected output during rollback: " + operation.path)
		if operation.backed_up and DirAccess.rename_absolute(operation.old, operation.target) != OK:
			_fail("Cannot restore output; backup retained at " + operation.old)
			operation.backed_up = false # Preserve the backup for manual recovery.

func _cleanup(operations: Array[Dictionary]) -> void:
	for operation in operations:
		DirAccess.remove_absolute(operation.new)
		if operation.backed_up: DirAccess.remove_absolute(operation.old)
	DirAccess.remove_absolute(_staging)

func _resource_path(output: String) -> String:
	return "res://" + output if _project == ProjectSettings.globalize_path("res://").trim_suffix("/") else _project.path_join(output)

func _refresh_cache(item: Dictionary, state: Array[Dictionary]) -> void:
	# GDScript also has an internal cache not exposed by get_cached_ref().
	# Loading the validated path retrieves its existing Script identity.
	var path := _resource_path(item.output)
	var was_cached := ResourceLoader.has_cached(path)
	var script: GDScript
	if not Validation.supports_isolated_path() and not was_cached and not _previous_code.has(item.output):
		# First publication has no previous resource to preserve. Establish the
		# actual native path inside the transaction and compile exactly once.
		script = GDScript.new()
		script.resource_path = path
	else:
		script = ResourceLoader.load(path, "GDScript") as GDScript
	if script == null:
		_fail("Cannot load validated generated script: " + item.output)
		return
	# Matching source bytes cannot prove which implementation is compiled.
	# Reload the actual Script even on no-op builds; keep_state preserves owners.
	state.append({"script": script, "previous": script.source_code if was_cached else _previous_code.get(item.output), "output": item.output})
	var checked := Validation.reload_script(item.result, script, true)
	for diagnostic in checked.diagnostics: _fail_source(diagnostic)

func _restore_cache(state: Array[Dictionary]) -> void:
	for item in state:
		if item.previous == null:
			# Failed first publication must not leave an invalid cached resource.
			item.script.resource_path = ""
		else: item.script.source_code = item.previous
	for item in state:
		if item.previous != null and item.script.reload(true) != OK: _fail("Cannot restore cached script: " + item.output)

func _validation_order(compiled: Array[Dictionary]) -> Array[Dictionary]:
	var by_path: Dictionary = {}
	for item in compiled:
		by_path[_resource_path(item.output)] = item
		item.dependency_locations = {}
		item.dependencies = Dependencies.paths(item.result.code, _resource_path(item.output),item.dependency_locations)
	var ordered: Array[Dictionary] = []
	var visited: Dictionary = {}
	for item in compiled: _visit_dependencies(_resource_path(item.output),item,by_path,visited,[],ordered)
	return ordered

func _dependency_error(item: Dictionary, path: String, message: String) -> void:
	var generated = item.dependency_locations.get(path)
	var point = item.result.source_map.original_position(generated.line,generated.column) if generated != null else null
	var source = item.result.source_map.source
	source.fail(message,point.index if point != null else 0)
	_fail_source(source.diagnostics[0])

func _visit_dependencies(path: String, origin: Dictionary, by_path: Dictionary, visited: Dictionary, chain: Array, ordered: Array[Dictionary]) -> void:
	if not _report.diagnostics.is_empty(): return
	if visited.get(path,0)==1:
		_dependency_error(origin,path,"Cyclic Gogo/source preload dependency: "+" -> ".join(chain+[path]))
		return
	if visited.get(path,0)==2: return
	visited[path] = 1
	var dependencies: PackedStringArray = []
	if by_path.has(path):
		origin = by_path[path]
		dependencies = origin.dependencies
	elif path.get_base_dir().get_file()=="generated" and (FileAccess.file_exists(path+".map.json") or FileAccess.file_exists(path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename()+".gogo"))):
		_dependency_error(origin,path,"Gogo dependency is missing or outside configured source roots: "+path)
		return
	elif path.ends_with(".gd") and FileAccess.file_exists(path) and ProjectSettings.globalize_path(path).begins_with(_project+"/"):
		if not _safe(ProjectSettings.globalize_path(path)): return
		dependencies = Dependencies.paths(FileAccess.get_file_as_string(path),path)
	for dependency in dependencies: _visit_dependencies(dependency,origin,by_path,visited,chain+[path],ordered)
	visited[path] = 2
	if by_path.has(path): ordered.append(by_path[path])

## Same discovery exclusions/containment as builds; no writes or config changes.
static func creation_check(path: String) -> Dictionary:
	var relative := path.trim_prefix("res://")
	if not path.begins_with("res://") or path.get_extension() != "gogo" or "\\" in relative or ":" in relative:
		return {"ok":false,"message":"Choose a .gogo file beneath res://."}
	for part in relative.split("/"):
		if part.is_empty() or not part.is_valid_filename() or part.begins_with(".") or part in EXCLUDED: return {"ok":false,"message":"This path is invalid or excluded from Gogo compilation. Choose a valid filename in a configured source root."}
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return {"ok":false,"message":"A file or directory already exists. New Gogo Component never overwrites existing source; choose another filename."}
	if not DirAccess.dir_exists_absolute(path.get_base_dir()): return {"ok":false,"message":"Create/select an existing project directory first."}
	var check := new()
	check._project = ProjectSettings.globalize_path("res://").trim_suffix("/")
	if not check._safe(ProjectSettings.globalize_path(path)): return {"ok":false,"message":"Unsafe source path: "+str(check._report.diagnostics)}
	if not FileAccess.file_exists("res://"+CONFIG):
		return {"ok":not relative.begins_with("addons/"),"message":"Default discovery excludes the top-level addons directory; choose a project source directory."}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string("res://"+CONFIG)) != OK: return {"ok":false,"message":CONFIG+": "+json.get_error_message()}
	var config: Variant = json.data
	if not config is Dictionary or config.size() != 2 or config.get("version") != 1 or not config.get("source_roots") is Array or config.source_roots.is_empty():
		return {"ok":false,"message":CONFIG+": expected version 1 and nonempty source_roots."}
	var eligible := false
	for root in config.source_roots:
		if not root is String or root.is_empty() or root.is_absolute_path() or ":" in root or "\\" in root: return {"ok":false,"message":CONFIG+": invalid source root"}
		for part in root.split("/"):
			if part.begins_with(".") or part in EXCLUDED: return {"ok":false,"message":CONFIG+": invalid source root"}
		if relative == root or relative.begins_with(root.trim_suffix("/")+"/"): eligible = true
	return {"ok":eligible,"message":"Choose a location included by gogo.config.json source_roots: "+str(config.source_roots)}
