extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Grid = preload("res://addons/estragon/runtime/node/grid.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L0910_RUNTIME_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for index in range(8): await process_frame
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var entry := Entry.new()
	entry.width = 700
	entry.height = 500
	var wrap := Box.new()
	wrap.wrap = true
	wrap.width = 160
	wrap.gap = 10
	wrap.row_gap = 12
	for i in range(3):
		var child := Rect.new()
		child.width = 70
		child.height = 20
		wrap.add_child(child)
	entry.add_child(wrap)
	root.add_child(entry)
	await frames()
	var ids: Array = []
	for child in wrap.get_children(): ids.append(child.get_instance_id())
	check(wrap.layout_size==Vector2(160,52) and wrap.get_child(2).position==Vector2(0,32),"native wrap exact 160 geometry")
	wrap.width = 230
	await frames()
	check(wrap.layout_size==Vector2(230,20) and wrap.get_child(2).position==Vector2(160,0),"230 one row")
	wrap.width = 160
	await frames()
	check(wrap.layout_size.y==52 and wrap.get_child(2).get_instance_id()==ids[2],"160 repair retained IDs")
	wrap.get_child(0).hide()
	await frames()
	check(wrap.layout_size.y==20 and wrap.get_child(2).position==Vector2(80,0),"native visibility repacks affected branch")
	wrap.get_child(0).show()
	await frames()
	var grid := Grid.new()
	grid.width = 320
	grid.columns = 3
	grid.gap = 10
	for i in range(5):
		var child := Rect.new()
		child.height = 20
		grid.add_child(child)
	entry.add_child(grid)
	await frames()
	check(grid.layout_size==Vector2(320,50) and grid.get_child(2).position==Vector2(220,0) and grid.get_child(4).position==Vector2(110,30) and grid.get_child(0).layout_size==Vector2(100,20),"native Grid three100 tracks five items")
	var grid_id := grid.get_child(4).get_instance_id()
	grid.width = 620
	await frames()
	check(grid.get_child(2).position.x==420 and grid.get_child(0).layout_size.x==200 and grid.get_child(4).get_instance_id()==grid_id,"native Grid resize620 retained slots")
	var native := Button.new()
	native.text = "Native minimum"
	grid.add_child(native)
	await frames()
	check(native.size.x>=native.get_combined_minimum_size().x and native.position.x==420,"native Control allocated sixth cell")
	var unaffected := wrap.get_layout_stats()
	native.text = "Native minimum becomes significantly wider"
	await frames()
	check(native.size.x>=native.get_combined_minimum_size().x,"native minimum/font event changes tracks without polling")
	check(unaffected==wrap.get_layout_stats(),"Control minimum change leaves unrelated Wrap branch quiet")
	var idle := [grid.get_layout_stats(),wrap.get_layout_stats()]
	await frames()
	check(idle==[grid.get_layout_stats(),wrap.get_layout_stats()],"native idle quiet")
	entry.free()
	await frames()
	var host = load("res://app/generated/ResponsiveGallery.gd").new()
	root.add_child(host)
	await frames()
	var record = State.records[host.get_instance_id()]
	check(record.mounted!=null,"source-authored combined gallery mounts")
	if record.mounted!=null:
		var ui = host.get_node("UI")
		var cards = ui.get_node("Content/Cards")
		var named = ui.get_node("Content/Named")
		check(named.get_child(2).position.x==162 and named.get_child(2).position.y==70,"Gogo project component area bridge")
		var runs: int = record.runs
		var card_id: int = cards.get_node("a").get_instance_id()
		host.order = ["d","c","b","a"]
		await frames()
		check(cards.get_child(0).name=="d" and cards.get_node("a").get_instance_id()==card_id,"keyed Wrap reorder retained identity")
		host.order = ["a","b"]
		await frames()
		check(cards.get_child_count()==2 and cards.get_node("a").get_instance_id()==card_id,"keyed removal releases lines")
		var header = named.get_node("Header")
		check(header is Button and not header.has_meta("area") and header.position==Vector2(12,12),"native Control receives GGX area slot without foreign properties or metadata")
		var extra_id: int = ui.get_node("Content/Automatic/One").get_instance_id()
		host.show_extra = false
		await frames()
		check(not ui.has_node("Content/Automatic/Extra") and ui.get_node("Content/Automatic/One").get_instance_id()==extra_id,"conditional Grid removal retains other cells")
		host.show_extra = true
		await frames()
		var mounted_id: int = ui.get_instance_id()
		var old_width = named.width
		print("L0910_EXPECTED_REJECTION_BEGIN")
		var invalid_configs := [
			{"width":501,"columns":["1fr","0fr"]}, {"columns":0}, {"columns":257}, {"columns":["NaNfr"]}, {"columns":["-1px"]},
			{"columns":2,"rows":1,"areas":["a a","b c"]}, {"columns":2,"rows":2,"areas":["a a","a b"]},
			{"template":"bad"}, {"template":"a a, auto\n\\ 1fr 1fr","columns":2},
			{"columns":2,"horizontal_align":"space-between"}, {"columns":2,"row_gap":"-1px"}, {"columns":2,"column_gap":INF}
		]
		for config in invalid_configs:
			var merged := {"columns":["140px","1fr"],"rows":["48px","auto"],"areas":["header header","sidebar main"]}
			merged.merge(config,true)
			host.grid_props = merged
			await frames()
			check(ui.get_instance_id()==mounted_id and named.width==old_width and named.columns==["140px","1fr"],"invalid complete config rollback "+str(config))
		print("L0910_EXPECTED_REJECTION_END")
		check(ui.get_instance_id()==mounted_id and named.width==old_width and named.columns==["140px","1fr"],"invalid spread tracks preserve whole mounted description")
		host.grid_props = {"template":"header header, 48px\nsidebar main, auto\n\\ 140px 1fr"}
		await frames()
		check(named.template.length()>0 and named.columns==null and named.get_child(2).position==Vector2(162,70),"template repair atomic reset and equivalent slots")
		print("L0910_EXPECTED_REJECTION_BEGIN")
		for placement in [{"area":"header"},{"area":"missing"},{"row":-1},{"row_span":0},{"row":0,"column":0},{"area":"main","row":1}]:
			host.placement = placement
			await frames()
			check(named.get_child(2).position==Vector2(162,70),"invalid placement rollback "+str(placement))
		print("L0910_EXPECTED_REJECTION_END")
		check(named.get_child(2).position==Vector2(162,70),"conflicting dynamic placement preserves entire tree")
		host.placement = {"area":"main"}
		await frames()
		check(named.get_child(2).get_instance_id()!=0 and record.runs>runs,"placement repair replays valid description")
		print("L0910_EXPECTED_REJECTION_BEGIN")
		for props in [{"anchor_left":0.5},{"rotation":0.5},{"scale":Vector2(2,1)}]:
			host.header_props = props
			await frames()
			check(header.position==Vector2(12,12) and header.scale==Vector2.ONE and header.anchor_left==0 and header.rotation==0,"incompatible bound Control retains whole description "+str(props))
		print("L0910_EXPECTED_REJECTION_END")
		host.header_props = {}
		await frames()
		var header_id: int = header.get_instance_id()
		named.remove_child(header)
		await frames()
		named.add_child(header)
		await frames()
		check(header.position==Vector2(12,12) and header.get_instance_id()==header_id,"native removal/re-entry preserves external area and instance")
		header.free()
		await frames()
		check(not preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres").placements.has(header_id),"native individual free prunes weak placement without parent recomposition")
	host.free()
	await frames()
	check(preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres").placements.is_empty(),"placement records released on unmount")
	print("L0910_RUNTIME_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L0910_RUNTIME_OK")
	quit(1 if failed else 0)
