@tool
extends EditorPlugin
var interface: EditorInterface
var plugin: EditorPlugin
var checks := 0
var failed := false
var proof: Dictionary = {}
var timer: Timer
func _enter_tree() -> void:
	interface = get_editor_interface()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L06_EDITOR_CHECK ",label,": ",ok)
	if not ok: failed = true
func until(condition: Callable, label: String) -> bool:
	var deadline := Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		if condition.call(): return true
		await get_tree().process_frame
	check(false,label)
	return false
func ready() -> bool:
	for node in get_tree().root.find_children("*","EditorPlugin",true,false):
		if node!=self and node.get_script()!=null and node.get_script().resource_path=="res://addons/estragon/editor/plugin.gd": plugin = node
	return plugin!=null and plugin.last_report.get("ok",false) and not plugin._extensions_pending
func home_code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var code = item.code.get_ref()
		if item.path=="res://app/Home.gogo" and code!=null and code.is_visible_in_tree(): return code
	return null
func settle() -> void:
	for attempt in range(30):
		await until(func(): return not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(),"native filesystem settles")
		var count: int = plugin.build_count
		timer.start(0.15)
		await timer.timeout
		if count==plugin.build_count and not plugin._filesystem_busy() and not plugin._rescan_pending and plugin._timer.is_stopped(): return
	check(false,"bounded editor settle")
func proof_ready() -> bool:
	var path := "res://.godot/l06-game.json"
	if not FileAccess.file_exists(path): return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary or parser.data.is_empty(): return false
	proof = parser.data
	return true
func play(mode: String) -> void:
	await settle()
	var path := "res://.godot/l06-game.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var footer_path := "res://.godot/l07-game.json"
	if FileAccess.file_exists(footer_path): DirAccess.remove_absolute(footer_path)
	var owner_path := "res://.godot/l07-root-game.json"
	if FileAccess.file_exists(owner_path): DirAccess.remove_absolute(owner_path)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(proof_ready,"actual padded game proof"):
		check(proof.samples.size()==3 and proof.samples.all(func(item): return item.width==item.content_x*0.5 and item.height==item.content_y*0.75 and item.identity and item.spec=="50%") and proof.clicks==1,mode+" native game keeps50/75 percent parent sizing through three resizes with retained input")
	if await until(func(): return FileAccess.file_exists(footer_path),"L07A "+mode+" footer game proof"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(footer_path))
		check(result.clicks==2 and result.samples.size()==2 and result.samples.all(func(item): return absf(item.bottom-item.viewport)<0.01 and item.spacer>0),"L07A "+mode+" real editor Play bottom spacer and native click at two sizes")
	if await until(func(): return FileAccess.file_exists(owner_path),"L07 "+mode+" owner root-percent proof"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(owner_path))
		check(result.clicks==3 and result.samples.size()==3 and result.samples.all(func(item): return item.root==item.actual and item.actual==item.viewport and absf(item.bottom-item.viewport)<0.01 and item.width==item.expected_width and item.spacer>0),"L07 "+mode+" exact root100% owner footer/native clicks at three visible viewport sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"native game stops")
func run() -> void:
	if not await until(ready,"installed addon activates"): finish(); return
	var prefs := interface.get_editor_settings()
	if prefs.has_setting("run/window_placement/game_embed_mode"): prefs.set_setting("run/window_placement/game_embed_mode",-1)
	interface.open_scene_from_path("res://app/Home.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null,"authored scene opens")
	await settle()
	await inspector_proof()
	if not FileAccess.file_exists("res://.godot/l06-restart"):
		await plugin._navigation.open("res://app/Home.gogo")
		await until(func(): return home_code()!=null,"native authored source editor opens")
		var code := home_code()
		if code!=null:
			var original := code.text
			var at := original.find('width="50%"')+"wid".length()
			var rows := original.left(at).split("\n")
			code.set_caret_line(rows.size()-1)
			code.set_caret_column(rows[-1].length())
			code.request_code_completion(true)
			for frame in range(5): await get_tree().process_frame
			check(code.get_code_completion_options().any(func(item): return item.insert_text.begins_with("width")),"real CodeEdit completes the union length width property")
			code.cancel_code_completion()
			check(code.text==original and plugin._build_sources(),"native completion preserves valid source and installed imports/maps")
			for fragment in ["<VBox horizontal_a","<VBox gro","<Spa","<VBox min_w","<VBox min_h"]:
				code.text = original+"\nfunc completion_probe():\n\treturn "+fragment
				code.set_caret_line(code.get_line_count()-1)
				code.set_caret_column(code.get_line(code.get_line_count()-1).length())
				code.request_code_completion(true)
				for frame in range(5): await get_tree().process_frame
				var expected := "min_width" if fragment.contains("min_w") else ("min_height" if fragment.contains("min_h") else ("horizontal_align" if fragment.contains("horizontal") else ("grow" if fragment.contains("gro") else "Spacer")))
				check(code.get_code_completion_options().any(func(item): return item.insert_text.begins_with(expected)),"L07A native CodeEdit completes "+expected)
				code.cancel_code_completion()
			code.text = original.replace("Hello World!","Unsaved unit view")
		await play("current")
		check(FileAccess.get_file_as_string("res://app/Home.gogo").contains("Unsaved unit view"),"current Play saves unsaved Gogo buffer before compilation")
		var file := FileAccess.open("res://.godot/l06-restart",FileAccess.WRITE)
		file.store_string("restart")
		file.close()
	await play("main")
	check(interface.get_edited_scene_root().get_child_count()==1,"editor scene preserves transient managed view ownership")
	await minimum_editor_proof()
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://editor.png")
	finish()
func inspector_field(name: String = "width") -> EditorProperty:
	for node in interface.get_inspector().find_children("*","EditorProperty",true,false):
		if node.get_edited_property()==name and node.get_script()!=null and node.get_script().resource_path=="res://addons/estragon/editor/length_property.gd": return node
	return null
func inspector_proof() -> void:
	var scene := interface.get_edited_scene_root()
	var entry = preload("res://addons/estragon/runtime/node/component_2d.gd").new()
	entry.name = "InspectorUnits"
	scene.add_child(entry)
	entry.owner = scene
	interface.inspect_object(entry)
	if await until(func(): return inspector_field()!=null,"public native unit Inspector field"):
		var field := inspector_field()
		field.input.text = "2.5in"
		field.input.text_submitted.emit("2.5in")
		for frame in range(5): await get_tree().process_frame
		check(entry.width=="2.5in","native Inspector accepts and retains string unit")
		var manager := get_undo_redo()
		var history := manager.get_history_undo_redo(manager.get_object_history_id(entry))
		check(history.undo() and entry.width=="auto","native Inspector length undo")
		check(history.redo() and entry.width=="2.5in","native Inspector length redo")
		field = inspector_field()
		field.input.text_submitted.emit("wrong-unit")
		check(entry.width=="2.5in" and not field.input.tooltip_text.is_empty(),"invalid Inspector unit explains rejection and keeps valid spec")
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png("res://inspector.png")
	for name in ["min_width","min_height"]:
		var field := inspector_field(name)
		check(field!=null,"L11 native Inspector exposes "+name)
		if field==null: continue
		field.input.text_submitted.emit("50%")
		for frame in range(5): await get_tree().process_frame
		var manager := get_undo_redo()
		var history := manager.get_history_undo_redo(manager.get_object_history_id(entry))
		check(entry.get(name)=="50%" and history.undo() and entry.get(name)==0 and history.redo() and entry.get(name)=="50%","L11 minimum Inspector union edit/undo/redo "+name)
		field = inspector_field(name)
		field.input.text_submitted.emit("-1px")
		check(entry.get(name)=="50%" and not field.input.tooltip_text.is_empty(),"L11 invalid minimum Inspector input retains valid value "+name)
		field.input.text_submitted.emit("auto")
		for frame in range(5): await get_tree().process_frame
		check(entry.get(name)=="auto","L11 minimum Inspector auto clears local floor "+name)
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png("res://minimum-inspector.png")
	interface.inspect_object(scene)
	scene.remove_child(entry)
	entry.free()
func minimum_code() -> CodeEdit:
	for item in plugin._services.entries.values():
		var code = item.code.get_ref()
		if item.path=="res://app/MinimumGallery.gogo" and code!=null and code.is_visible_in_tree(): return code
	return null
func minimum_play(mode: String) -> void:
	await settle()
	var path := "res://.godot/l11-game.json"
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	if mode=="main": interface.play_main_scene()
	else: interface.play_current_scene()
	if await until(func(): return FileAccess.file_exists(path),"L11 actual minimum game proof"):
		var result = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(result.clicks==2 and result.native==2 and result.edits==[true,false] and result.samples.all(func(item): return item.root and item.width==item.content/2 and item.height==36 and item.border),"L11 "+mode+" real minimum layout/style/input/controlled edits at two sizes")
	interface.stop_playing_scene()
	await until(func(): return not interface.is_playing_scene(),"L11 minimum game stops")
func minimum_editor_proof() -> void:
	var main = ProjectSettings.get_setting("application/run/main_scene")
	interface.open_scene_from_path("res://app/MinimumGallery.tscn")
	await until(func(): return interface.get_edited_scene_root()!=null and interface.get_edited_scene_root().scene_file_path=="res://app/MinimumGallery.tscn","L11 authored minimum scene opens")
	await settle()
	ProjectSettings.set_setting("application/run/main_scene","res://app/MinimumGallery.tscn")
	if not FileAccess.file_exists("res://.godot/l11-tested"):
		await plugin._navigation.open("res://app/MinimumGallery.gogo")
		await until(func(): return minimum_code()!=null,"L11 authored minimum buffer associates")
		var code := minimum_code()
		check(code!=null,"L11 native authored minimum editor opens")
		if code!=null:
			var original := code.text
			var output := "res://app/generated/MinimumGallery.gd"
			var bytes := FileAccess.get_file_as_bytes(output)
			var maps := FileAccess.get_file_as_bytes(output+".map.json")
			var cached = load(output)
			print("L11_EXPECTED_PLAY_REJECTION_BEGIN")
			await get_tree().process_frame
			code.text = original.replace('min_width="96px"','min_width="broken"')
			interface.play_current_scene()
			for frame in range(12): await get_tree().process_frame
			check(not interface.is_playing_scene() and not plugin.last_report.get("ok",true) and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==cached,"L11 invalid unsaved minimum blocks Play and retains generated bytes/maps/Script")
			await get_tree().process_frame
			print("L11_EXPECTED_PLAY_REJECTION_END")
			code.text = original.replace("A readable minimum","Unsaved minimum")
		await minimum_play("current")
		check(FileAccess.get_file_as_string("res://app/MinimumGallery.gogo").contains("Unsaved minimum"),"L11 repaired minimum source saves authored buffer before Play")
		var file := FileAccess.open("res://.godot/l11-tested",FileAccess.WRITE)
		file.store_string("tested")
		file.close()
	await minimum_play("main")
	ProjectSettings.set_setting("application/run/main_scene",main)
func finish() -> void:
	print("L06_EDITOR_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L06_EDITOR_OK")
	get_tree().quit(1 if failed else 0)
