extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var failed := false
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S03_PUBLICATION_CHECK ",label,": ",ok)
	if not ok: failed = true
func _initialize() -> void:
	var path := "res://app/SpreadGallery.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/SpreadGallery.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var stamp := FileAccess.get_modified_time(output)
	var script = load(output)
	var uid := FileAccess.get_file_as_bytes(output+".uid") if FileAccess.file_exists(output+".uid") else PackedByteArray()
	for expression in ["missing_spread_expression","(1 + )"]:
		var source := original.replace("{...self.panel}","{..."+expression+"}")
		var compilation := Compiler.compile(source,path,output)
		check(compilation.ok,"pure syntax pipeline defers native expression semantics")
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(source)
		file.close()
		print("S03_EXPECTED_SEMANTIC_BEGIN")
		var report := Build.run_build()
		print("S03_EXPECTED_SEMANTIC_END")
		check(not report.ok and str(report.diagnostics).contains("app/SpreadGallery.gogo:"),"actual-path spread expression semantic failure is authored-source located")
		check(FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==stamp and load(output)==script and (not FileAccess.file_exists(output+".uid") or FileAccess.get_file_as_bytes(output+".uid")==uid),"failed semantic publication restores code/maps/timestamp/UID/cache identity")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	check(Build.run_build().ok,"repaired spread semantics recover actual-path publication")
	print("S03_PUBLICATION_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S03_PUBLICATION_OK")
	quit(1 if failed else 0)
