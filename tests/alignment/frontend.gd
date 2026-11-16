extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
var checks := 0
var failed := false
const HEAD := 'extends Node2D\nconst Layout = preload("res://addons/estragon/runtime/node/box.gd")\nconst Row = preload("res://addons/estragon/runtime/node/hbox.gd")\nconst Column = preload("res://addons/estragon/runtime/node/vbox.gd")\nconst Rect = preload("res://addons/estragon/runtime/node/rect.gd")\nconst Spatial = preload("res://addons/estragon/runtime/node/component_3d.gd")\nfunc view(): return '
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L08_FRONTEND_CHECK ",label,": ",ok)
	if not ok: failed = true
func _initialize() -> void:
	for attrs in ['horizontal_align="space-between" vertical_align="center"','direction="column" vertical_align="space-evenly" horizontal_align="stretch"','horizontal_align="stretch" vertical_align="space-around" direction="column"','{...{"direction":"column","vertical_align":"space-between"}}']:
		var built := Compiler.compile(HEAD+'<Layout '+attrs+' />\n',"valid.gogo")
		check(built.ok,"valid physical-axis literal/order/spread "+attrs)
	for own in ["auto","start","center","end","stretch"]:
		check(Compiler.compile(HEAD+'<Rect align_self="'+own+'" />\n',"self.gogo").ok,"eligible child override "+own)
	for body in ['<Layout horizontal_align="stretch" />','<Layout vertical_align="space-between" />','<Layout direction="column" horizontal_align="space-around" />','<Column direction="row" />','<Row direction="column" />','<Rect align_self="space-evenly" />','<Rect align_self="bad" />','<Button align_self="end" />','<Spatial align_self="end" />','<Layout justify="center" />','<Layout align="end" />','<Layout align-items="center" />','<Layout justify-content="end" />']:
		var result := Compiler.compile(HEAD+body+'\n',"negative.gogo")
		check(not result.ok and result.diagnostics[0].source_name=="negative.gogo" and result.diagnostics[0].span.start.line==7,"source-located literal/alias/native/3D rejection "+body)
	var path := "res://app/AlignmentGallery.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/AlignmentGallery.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script = load(output)
	for invalid in ['horizontal_align="stretch"','vertical_align="space-around"']:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(original.replace('horizontal_align="space-evenly" vertical_align="center"',invalid))
		file.close()
		var report := Build.run_build()
		check(not report.ok and str(report.diagnostics).contains("app/AlignmentGallery.gogo:") and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"invalid source retains generated code/maps/cache "+invalid)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	check(Build.run_build().ok,"repair resumes actual-path compilation")
	print("L08_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L08_FRONTEND_OK")
	quit(1 if failed else 0)
