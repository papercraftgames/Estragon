@tool
extends EditorPlugin
## Plugin-free native ScriptTextEditor lazy-tab validation probe. No Estragon API.
var timer: Timer
func _enter_tree() -> void:
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	run.call_deferred()
func wait_idle() -> void:
	timer.start(3.0)
	await timer.timeout
func snapshot(code: CodeEdit, label: String) -> void:
	var names: Array = []
	for index in range(code.get_gutter_count()): names.append(code.get_gutter_name(index))
	print("E11_UPSTREAM_PHASE ",label," ",JSON.stringify({"gutters":names,"lines":code.get_line_count(),"visible":code.is_visible_in_tree()}))
func write(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
func run() -> void:
	var interface := get_editor_interface()
	write("res://Current.gd","extends Node\nfunc current() -> void:\n\tpass\n")
	write("res://Hidden.gd","extends Node\nfunc hidden() -> void:\n\tpass\n")
	interface.edit_script(load("res://Current.gd"),1,0,true)
	interface.set_main_screen_editor("Script")
	for frame in range(8): await get_tree().process_frame
	interface.edit_script(load("res://Hidden.gd"),1,0,false)
	var hidden: CodeEdit
	for editor in interface.get_script_editor().get_open_script_editors():
		var code := editor.get_base_editor() as CodeEdit
		if code != null and code.text.contains("func hidden"): hidden = code
	if hidden == null:
		push_error("E11 native hidden Script tab missing")
		get_tree().quit(1); return
	snapshot(hidden,"lazy-before")
	print("E11_UPSTREAM_EXPECTED_BEGIN")
	hidden.set_caret_line(2)
	hidden.set_caret_column(5)
	hidden.insert_text_at_caret(" # idle native validation")
	await wait_idle()
	print("E11_UPSTREAM_EXPECTED_END")
	# The native supported activation path initializes its own cached indexes.
	interface.edit_script(load("res://Hidden.gd"),1,0,true)
	for frame in range(8): await get_tree().process_frame
	snapshot(hidden,"activated")
	hidden.insert_text_at_caret(" # initialized control")
	await wait_idle()
	print("E11_UPSTREAM_CONTROL_OK")
	get_tree().quit()
