extends SceneTree
const Acceptance = preload("res://addons/estragon/editor/completion_edit.gd")
func snapshot(code: CodeEdit, phase: String) -> void:
	var names: Array = []
	for index in range(code.get_gutter_count()): names.append(code.get_gutter_name(index))
	print("E11_PHASE ",phase," ",JSON.stringify(names))
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var code := CodeEdit.new()
	root.add_child(code)
	code.text = "extends Node\nfunc demo():\n\tpass\n"
	snapshot(code,"native-before")
	code.set_script(Acceptance)
	snapshot(code,"script-attached")
	code.add_gutter(0)
	code.set_gutter_name(0,"Estragon diagnostics")
	snapshot(code,"diagnostic-added")
	code.set_line_as_breakpoint(1,true)
	code.set_draw_line_numbers(true)
	code.notification(Control.NOTIFICATION_THEME_CHANGED)
	for frame in range(3): await process_frame
	code.remove_gutter(0)
	snapshot(code,"diagnostic-removed")
	code.set_script(null)
	snapshot(code,"script-detached")
	code.free()
	print("E11_PROBE_OK")
	quit()
