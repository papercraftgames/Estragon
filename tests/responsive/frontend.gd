extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
var checks := 0
var failed := false
const HEAD := 'extends Node2D\nconst Grid = preload("res://addons/estragon/runtime/node/grid.gd")\nconst Box = preload("res://addons/estragon/runtime/node/box.gd")\nconst Rect = preload("res://addons/estragon/runtime/node/rect.gd")\nconst Spatial = preload("res://addons/estragon/runtime/node/component_3d.gd")\nfunc view(): return '
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L0910_FRONTEND_CHECK ",label,": ",ok)
	if not ok: failed = true
func _initialize() -> void:
	for body in ['<Box wrap={true} row_gap="12px" column_gap="auto" align_content="space-around" />','<Grid columns={3}><Button area="header" /></Grid>','<Grid columns={["100px","1fr","2fr"]} rows={["auto"]}><Rect row={0} column={1} column_span={2} /></Grid>','<Grid {...{"columns":3}}><Button {...{"row":0,"column":1}} /></Grid>']:
		var result := Compiler.compile(HEAD+body+'\n',"valid.gogo")
		check(result.ok,"native public imports/placement/spreads "+body)
	for body in ['<Box align_content="bad" />','<Box row_gap="-1px" />','<Box column_gap="1fr" />','<Grid horizontal_align="space-between" />','<Grid vertical_align="bad" />','<Grid template="bad" />','<Box><Button area="header" /></Box>','<Spatial wrap={true} />','<Spatial columns={3} />','<Spatial row_gap="2px" />','<Rect width="1fr" />']:
		var result := Compiler.compile(HEAD+body+'\n',"negative.gogo")
		check(not result.ok and result.diagnostics[0].source_name=="negative.gogo" and result.diagnostics[0].span.start.line==6,"source located contract rejection "+body)
	var path := "res://app/ResponsiveGallery.gogo"
	var source := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/ResponsiveGallery.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script = load(output)
	var timestamp := FileAccess.get_modified_time(output)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(source.replace('row_gap="12px"','row_gap="-1px"'))
	file.close()
	var report := Build.run_build()
	check(not report.ok and str(report.diagnostics).contains("app/ResponsiveGallery.gogo:") and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and FileAccess.get_modified_time(output)==timestamp and load(output)==script,"invalid source retains actual-path code/maps/timestamp/cache identity")
	file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(source)
	file.close()
	check(Build.run_build().ok,"repair actual-path build")
	print("L0910_FRONTEND_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L0910_FRONTEND_OK")
	quit(1 if failed else 0)
