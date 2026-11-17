extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
var failed := false
var checks := 0
func check(ok: bool,label: String):
	checks += 1
	print("S04_REJECTION ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var head := 'extends Node2D\nconst Rect=preload("res://addons/estragon/runtime/node/rect.gd")\nfunc view(): return '
	for body in ['<Rect corner_radius="-1px" />','<Rect corner_radius={INF} />','<Rect corner_radius="auto" />','<Rect corner_radius_top_left="bad" />','<Rect background_texture_mode="cover" />','<Rect corner_radius="2px" corner_radius="3px" />','<Rect clip_content="true" />','<Node3D corner_radius="2px" />','<Control clip_content />','<Rect fill={Color.RED} background_color="#fff" />','<Rect corner_radius={true} />']:
		var result = Compiler.compile(head+body,"negative.gogo")
		check(not result.ok and not result.diagnostics.is_empty() and result.diagnostics[0].source_name=="negative.gogo" and result.diagnostics[0].span.start.index>=head.length(),"literal authored diagnostic "+body)
	for body in ['<Rect corner_radius="12px" corner_radius_top_left="0px" />','<Rect corner_radius_top_left="0px" corner_radius="12px" />','<Rect background_texture_mode="tile" clip_content />']:
		check(Compiler.compile(head+body,"valid.gogo").ok,"independent shorthand/override metadata "+body)
	var host = load("res://app/generated/SurfaceGallery.gd").new()
	root.add_child(host)
	await frames()
	var round = host.get_node("UI").get_layout_child("Panels").get_layout_child("Round")
	var identity: int = round.get_instance_id()
	var size: Vector2 = round.layout_size
	var normal = round.background_color
	var radius = round.corner_radius
	var resource := Resource.new()
	for invalid in [{"corner_radius":-1},{"corner_radius":NAN},{"corner_radius":"2em"},{"corner_radius_top_right":false},{"background_texture":resource},{"background_texture_mode":"cover"},{"background_texture_mode":1},{"clip_content":1},{"background_color":"broken"},{"scroll_offset":Vector2(INF,0)},{"corner_radius":1e13}]:
		invalid["background_color"] = "#ff0000" if not invalid.has("background_color") else invalid.background_color
		print("S04_EXPECTED_BEGIN")
		host.props = invalid
		await frames()
		print("S04_EXPECTED_END")
		check(round.get_instance_id()==identity and round.layout_size==size and round.background_color==normal and round.corner_radius==radius and round.background_texture==null,"complete-description rejection retains every prior field "+str(invalid))
	host.props = {"corner_radius_top_right":"0px","corner_radius":"8px"}
	await frames()
	check(round.corner_radius=="8px" and round.corner_radius_top_right=="0px","repair commits radius shorthand/override independently")
	host.props = {}
	await frames()
	check(round.corner_radius_top_right=="auto" and round.corner_radius==radius,"omission restores default override and explicit authored shorthand")
	for pair in [["corner_radius",-1],["corner_radius_top_left",INF],["background_texture_mode","cover"],["background_color","bad"]]:
		var before = round.get(pair[0])
		print("S04_EXPECTED_BEGIN")
		round.set(pair[0],pair[1])
		await frames()
		print("S04_EXPECTED_END")
		check(is_same(round.get(pair[0]),before),"native setter preserves good value "+pair[0])
	host.free()
	await frames()
	check(State.records.is_empty(),"negative fixture releases resources and records")
	print("S04_REJECTION_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S04_REJECTIONS_OK")
	quit(1 if failed else 0)
