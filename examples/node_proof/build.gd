extends SceneTree
## Explicit, Godot-only B1 build command. No editor/default compiler selection.
const Proof = preload("res://addons/estragon/compiler/node_proof/compiler.gd")
const Validation = preload("res://addons/estragon/compiler/script_validation.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const TYPES := {
	"Probe2D": preload("res://examples/node_proof/probe_2d.gd"),
	"Probe3D": preload("res://examples/node_proof/probe_3d.gd"),
}
const INPUT := "res://examples/node_proof/.proof/Composition.gogo"
const OUTPUT := "res://examples/node_proof/generated/Composition.gd"

static func build() -> Dictionary:
	var compiled := Proof.compile(FileAccess.get_file_as_string(INPUT), INPUT, TYPES)
	return publish(compiled, OUTPUT)

## Proof-only single-output transaction at the actual path. Restore disk/map and
## cached Script source on semantic failure. Never authorize from reload == OK
## alone: the separate runtime tests assert actual native execution.
static func publish(compiled: Compiler.Compilation, output: String) -> Dictionary:
	if not compiled.ok:
		var errors: Array[String] = []
		for diagnostic in compiled.diagnostics: errors.append(diagnostic.format())
		return {"ok": false, "diagnostics": errors}
	var writes := {output: compiled.code, output + ".map.json": compiled.source_map.serialize()}
	var changed: Array[String] = []
	for path in writes:
		if FileAccess.file_exists(path) and FileAccess.get_file_as_string(path) == writes[path]: continue
		if FileAccess.file_exists(path + ".b1-stage") or FileAccess.file_exists(path + ".b1-backup"):
			return {"ok": false, "diagnostics": ["Unfinished B1 transaction at " + path]}
		changed.append(path)
	if DirAccess.make_dir_recursive_absolute(output.get_base_dir()) != OK:
		return {"ok": false, "diagnostics": ["Cannot create " + output.get_base_dir()]}
	var published: Array[String] = []
	var backups: Array[String] = []
	for path in changed:
		var file := FileAccess.open(path + ".b1-stage", FileAccess.WRITE)
		if file == null:
			_rollback(changed, published, backups)
			return {"ok": false, "diagnostics": ["Cannot stage " + path]}
		file.store_string(writes[path])
		var write_error := file.get_error()
		file.close()
		if write_error != OK:
			_rollback(changed, published, backups)
			return {"ok": false, "diagnostics": ["Cannot write " + path]}
	for path in changed:
		if FileAccess.file_exists(path):
			if DirAccess.rename_absolute(path, path + ".b1-backup") != OK:
				_rollback(changed, published, backups)
				return {"ok": false, "diagnostics": ["Cannot back up " + path]}
			backups.append(path)
		if DirAccess.rename_absolute(path + ".b1-stage", path) != OK:
			_rollback(changed, published, backups)
			return {"ok": false, "diagnostics": ["Cannot publish " + path]}
		published.append(path)
	var cached := ResourceLoader.has_cached(output)
	var script: GDScript = load(output) if cached else GDScript.new()
	var previous := script.source_code
	if not cached: script.resource_path = output
	var checked := Validation.reload_script(compiled, script, true)
	if not checked.ok:
		var restored := _rollback(changed, published, backups)
		if cached:
			script.source_code = previous
			restored = script.reload(true) == OK and restored
		else: script.resource_path = ""
		var errors: Array[String] = []
		for diagnostic in checked.diagnostics: errors.append(diagnostic.format())
		if not restored: errors.append("B1 rollback failed; inspect backup files")
		return {"ok": false, "diagnostics": errors}
	for path in backups: DirAccess.remove_absolute(path + ".b1-backup")
	return {"ok": true, "script": script, "compilation": compiled}

static func _rollback(changed: Array[String], published: Array[String], backups: Array[String]) -> bool:
	var ok := true
	for path in published:
		ok = DirAccess.remove_absolute(path) == OK and ok
	for path in backups:
		ok = DirAccess.rename_absolute(path + ".b1-backup", path) == OK and ok
	for path in changed:
		if FileAccess.file_exists(path + ".b1-stage"):
			ok = DirAccess.remove_absolute(path + ".b1-stage") == OK and ok
	return ok

func _initialize() -> void:
	var result := build()
	if not result.ok:
		for diagnostic in result.diagnostics: printerr(diagnostic)
		quit(1)
	else:
		print("GGX_B1_BUILD_OK")
		quit()
