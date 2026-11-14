extends SceneTree
const Length = preload("res://addons/estragon/runtime/node/internal/length.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Entry3D = preload("res://addons/estragon/runtime/node/estragon_3d.gd")
const Spatial = preload("res://addons/estragon/runtime/node/component_3d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var failed := false
var clicks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L06_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(8): await process_frame
func click(button: Node, size: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func capture(name: String) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
func _initialize() -> void: run.call_deferred()
func parser() -> void:
	var cases := [[200,200],[200.0,200],["200",200],["200px",200],["50%",300],["10vw",80],["10vh",60],["10vmin",60],["10vmax",80],["2.5in",240],["1cm",96.0/2.54],["10mm",96.0/2.54],["4q",96.0/25.4],["12pt",16],["1pc",16],["auto",-1],[" .5in ",48],["+2e1px",20]]
	for item in cases:
		var spec := Length.parse(item[0],"extent")
		check(not spec.has("error") and is_equal_approx(Length.resolve(spec,600,Vector2(800,600)),float(item[1])),"canonical conversion "+str(item[0]))
	for invalid in ["1em","1rem","1ex","1ch","calc(2px)","2PX","", "--2px","1 px","1e999px","-1px",-1,NAN,INF,true,[],"NaN","100oops"]:
		check(not Length.valid(invalid,"extent"),"reject invalid extent "+str(invalid))
	check(Length.valid("-10px","offset") and not Length.valid("auto","offset") and not Length.valid("auto","inset") and not Length.valid(-1,"inset"),"offset signs and auto domains")
	check(Length.resolve(Length.parse("2.5in","extent"),0,Vector2.ZERO,100)==2.4 and Length.resolve(Length.parse(200,"extent"),0,Vector2.ZERO,100)==2.0,"3D numeric and pixel strings share explicit100px/world-unit scale")
func run() -> void:
	parser()
	compiler_units()
	var home = load("res://app/Home.tscn").instantiate()
	root.add_child(home)
	await frames()
	var entry = home.get_node("UI")
	var column = home.get_node("UI/Column")
	var panel = column.get_node("Inline")
	var settings = column.get_node("Settings")
	var borrowed: Button = home.get_node("Borrowed")
	var identity: int = panel.get_instance_id()
	var runs: int = State.get("records")[home.get_instance_id()].runs
	var samples: Array = []
	for size in [Vector2i(1152,648),Vector2i(1440,900),Vector2i(800,500)]:
		root.size = size
		await frames()
		var content: Vector3 = column.layout.model.content_reference
		check(panel.layout_size==Vector2(content.x*0.5,content.y*0.75) and panel.width=="50%" and panel.get_instance_id()==identity,"inline owner demo50/75% actual content "+str(size))
		check(settings.get_node("Row").layout_size.x==content.x*0.5,"nested Gogo host percentage skips transparent proxy "+str(size))
		check(borrowed.get_parent()==home and borrowed.owner==home and borrowed.global_position.y>panel.global_position.y,"borrowed native Control keeps parent/owner and receives flow slot")
		samples.append({"viewport":str(size),"content":str(content),"panel":str(panel.layout_size),"position":str(panel.global_position)})
		capture("owner-"+str(size.x))
	var trace := FileAccess.open("res://geometry.json",FileAccess.WRITE)
	trace.store_string(JSON.stringify(samples))
	trace.close()
	check(State.get("records")[home.get_instance_id()].runs==runs,"viewport changes never rerun build_view")
	var record = State.get("records")[home.get_instance_id()]
	var rejected = Element.new(Entry,{"width":"100vw"},{},[Element.new(Rect,{"width":"bad-unit"})])
	check(not record._preflight(rejected,record.mounted,home) and panel.get_instance_id()==identity and panel.width=="50%","dynamic invalid descendant rejects before any property/tree commit")
	var action = settings.get_node("Row/Action")
	click(action,action.layout_size)
	check(settings.clicks==1,"actual UiButton input in percent nested host")
	borrowed.pressed.connect(func(): clicks += 1)
	click(borrowed,borrowed.size)
	check(clicks==1,"native borrowed Button GUI signal survives layout")
	var a = column.get_node("A")
	var a_id: int = a.get_instance_id()
	home.flipped = true
	await frames()
	check(column.get_node("A").get_instance_id()==a_id and a.get_index()>column.get_node("B").get_index(),"keyed retained percentage children reorder")
	var idle := [entry.get_layout_stats(),panel.get_layout_stats(),panel.lengths.parse_count,panel.layout.model.resolution_count,State.get("records")[home.get_instance_id()].runs]
	await frames()
	check(idle==[entry.get_layout_stats(),panel.get_layout_stats(),panel.lengths.parse_count,panel.layout.model.resolution_count,State.get("records")[home.get_instance_id()].runs],"steady idle zero parse/resolve/measure/arrange/recomposition")
	var flex_home = load("res://app/generated/FlexHome.gd").new()
	root.add_child(flex_home)
	await frames()
	var footer = flex_home.get_child(0).get_child(0).get_child(1)
	check(footer.global_position.y+footer.layout_size.y==root.get_visible_rect().size.y,"flex bottom spacer remains distinct from100% height")
	capture("flex-bottom")
	flex_home.free()
	home.free()
	await frames()
	await native_lengths()
	await viewport_and_spatial()
	await language()
	check(State.get("records").is_empty(),"composition teardown releases all records")
	print("L06_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L06_RUNTIME_OK")
	quit(1 if failed else 0)
func compiler_units() -> void:
	var header := 'extends Node2D\nconst Box = preload("res://addons/estragon/runtime/node/box.gd")\nfunc view(): return '
	for unit in ["200","200px","50%","10vw","10vh","10vmin","10vmax","2.5in","1cm","10mm","4q","12pt","1pc"]:
		var source: String = header+'<Box width="'+unit+'" height="'+unit+'" x="'+unit+'" y="-10px" gap="'+unit+'" padding="'+unit+'" margin="'+unit+'" />\n'
		var result := Compiler.compile(source,"res://unit.gogo","res://generated/Unit.gd")
		check(result.ok and result.code.contains('"'+unit+'"'),"all length properties compile and retain quoted spec "+unit)
		if result.ok:
			var script := GDScript.new()
			script.source_code = result.code
			check(script.reload()==OK,"generated mixed unit native semantics "+unit)
func native_lengths() -> void:
	var entry := Entry.new()
	entry.width = 600
	entry.height = 400
	entry.padding = "10%"
	var row := Box.new()
	row.width = "100%"
	row.height = "100%"
	row.gap = "2%"
	row.padding_left = "5%"
	var first := UiButton.new()
	first.text = "Offset"
	first.width = "50%"
	first.height = "1pc"
	first.x = "-10px"
	first.y = "25%"
	first.margin = "1%"
	first.pressed.connect(func(): clicks += 1)
	var second := Rect.new()
	second.flex = 2
	second.stretch = 1
	var third := Rect.new()
	third.flex = 1
	row.add_child(first)
	row.add_child(second)
	row.add_child(third)
	entry.add_child(row)
	root.add_child(entry)
	await frames()
	check(entry.layout.model.padding==Vector4.ZERO,"unanchored root percent insets explicitly resolve zero")
	check(row.layout.model.padding.x==30 and first.layout_size.x==285 and first.layout_size.y==16,"native string assignment content-box widths and absolute units")
	check(first.position==Vector2(30+5.7-10,4+100),"axis-aware percent margins and negative additive slot offsets")
	check(is_equal_approx(second.layout_size.x,third.layout_size.x*2) and second.layout_size.y==400,"weighted flex2:1 and explicit cross stretch")
	var count := clicks
	click(first,first.layout_size)
	check(clicks==count+1,"negative offset remains pointer hit-testable")
	first.x = "50%"
	await frames()
	check(is_equal_approx(first.position.x,30+5.7+285),"x50% uses immediate content axis and survives layout flush")
	# Native intrinsic changes must not reset already-resolved Box padding.
	row.padding = "10px"
	await frames()
	first.text = "A changed intrinsic label"
	await frames()
	check(row.layout.model.padding==Vector4(30,10,10,10),"intrinsic invalidation preserves retained unit padding and explicit edge")
	row.padding = 0
	await frames()
	first.width = "125%"
	await frames()
	check(first.layout_size.x==712.5 and second.layout_size.x==0,"intentional overflow above100% reserves remaining-space zero")
	var packed := PackedScene.new()
	packed.pack(first)
	var restored = packed.instantiate()
	check(restored.width=="125%" and restored.x=="50%","native scene pack preserves authored unit specs")
	restored.free()
	var alternate := Box.new()
	alternate.width = 200
	alternate.height = 100
	entry.add_child(alternate)
	row.remove_child(first)
	alternate.add_child(first)
	await frames()
	check(first.layout_size.x==250 and first.position.x==102,"native reparent immediately uses new logical parent reference")
	entry.free()
	await frames()
func viewport_and_spatial() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(400,300)
	root.add_child(view)
	var entry := Entry.new()
	entry.width = "50vh"
	entry.height = "10vmax"
	view.add_child(entry)
	await frames()
	check(entry.layout_size==Vector2(150,40),"cross-axis viewport units use containing SubViewport")
	view.size = Vector2i(800,200)
	await frames()
	check(entry.layout_size==Vector2(100,80),"SubViewport resize remains signal-driven")
	view.remove_child(entry)
	check(not view.size_changed.is_connected(entry.layout._viewport_changed),"viewport disconnect on exit")
	view.add_child(entry)
	await frames()
	check(entry.layout_size==Vector2(100,80),"detached viewport entry reconnects")
	var space := Entry3D.new()
	space.width = "100vw"
	space.height = "100vh"
	space.depth = "2.5in"
	var child := Spatial.new()
	child.width = "50%"
	child.height = "50%"
	child.depth = 200
	child.x = "10%"
	child.z = "-10px"
	space.add_child(child)
	view.add_child(space)
	await frames()
	check(space.layout_size==Vector3(8,2,2.4) and child.layout_size==Vector3(4,1,2),"bounded3D uses identical parser and explicit100px/world-unit scale")
	check(child.position==Vector3(0.8,0,-0.1),"3D parent-relative x and signed z offset preserve orientation")
	space.pixels_per_unit = 200
	await frames()
	check(space.layout_size==Vector3(4,1,1.2) and child.layout_size==Vector3(2,0.5,2),"3D scale is per participant; percentage world references stay coherent")
	view.free()
	await frames()
func language() -> void:
	var path := "res://app/Home.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/Home.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script: Script = load(output)
	for invalid in ['width="1em"','width="garbage"','width={-1}','width={NAN}','gap="auto"','fill_height={true}','viewport_width_scale={1}']:
		preload("build.gd").write(path,original.replace('width="50%"',invalid))
		var report := Build.run_build()
		check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"invalid unit/removed API preserves committed Script/maps "+invalid)
	preload("build.gd").write(path,original)
	check(Build.run_build().ok,"source repair recovers actual-path compilation")
