extends SceneTree
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const HBox = preload("res://addons/estragon/runtime/node/hbox.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Pixels = preload("res://addons/estragon/runtime/node/internal/pixel_contract.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L01_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(8): await process_frame
func _initialize() -> void: run.call_deferred()
func model(extent: Vector3, inner := Vector4.ZERO, outer := Vector4.ZERO, axis := 0, fill := Vector3.ZERO):
	var result := Core.new()
	check(result.configure(extent,0,false,axis,fill,Vector3.ZERO,inner,outer)==OK,"valid core configuration")
	return result
func core_proof() -> void:
	var row = model(Vector3(200,80,0),Vector4(10,20,30,10))
	var first = model(Vector3(40,10,0),Vector4.ZERO,Vector4(2,3,4,5))
	var flexible = model(Vector3(-1,-1,0),Vector4.ZERO,Vector4(6,7,8,9),0,Vector3(1,1,0))
	row.gap = 12
	row.set_children([first,flexible])
	row.arrange(row.measure())
	check(first.offset==Vector3(12,23,0) and first.size==Vector3(40,10,0),"border box excludes margins; asymmetric content origin")
	check(flexible.offset==Vector3(74,27,0) and flexible.size==Vector3(88,34,0),"padding margins gaps reserved once before both-axis fill")
	row.configure(Vector3(-1,-1,0),12,false,0,Vector3.ZERO,Vector3.ZERO,Vector4(10,20,30,10))
	check(row.measure()==Vector3(112,48,0),"auto aggregates outer child extents plus padding")
	row.configure(Vector3(20,10,0),12,false,0,Vector3.ZERO,Vector3.ZERO,Vector4(10,20,30,10))
	row.arrange(row.measure())
	check(flexible.size==Vector3.ZERO and first.size==Vector3(40,10,0) and flexible.offset==Vector3(74,27,0),"too-small content clamps zero; fixed children sequentially overflow")
	row.configure(Vector3(200,80,0),12,true,0,Vector3.ZERO,Vector3.ZERO,Vector4(10,20,30,10))
	flexible.configure(Vector3(20,10,0),0,false,0,Vector3.ZERO,Vector3.ZERO,Vector4.ZERO,Vector4(6,7,8,9))
	row.arrange(row.measure())
	check(first.offset.x==46 and flexible.offset.x==108,"center aligns the complete outer row inside content")
	check(row.configure(Vector3.ZERO,0,false,0,Vector3.ZERO,Vector3.ZERO,Vector4(-1,0,0,0))==ERR_INVALID_PARAMETER,"core rejects invalid insets")
	check(row.configure(Vector3.ZERO,0,false,0,Vector3.ZERO,Vector3.ZERO,Vector4(INF,0,0,0))==ERR_INVALID_PARAMETER,"core rejects nonfinite insets")
	row.set_children([])
func compiler_proof() -> void:
	var header := 'extends Node2D\nconst Box = preload("res://addons/estragon/runtime/node/box.gd")\nfunc view(): return '
	for attrs in ['width="100" height="auto" padding={2.5} margin_left={0}', 'padding_left={3} padding={8} width={100}', 'padding={8} padding_left={3}']:
		var source: String = header+'<Box '+attrs+' />\n'
		var result := Compiler.compile(source,"res://pixels.gogo","res://Generated.gd")
		check(result.ok,"native typed inherited pixel attributes "+attrs)
		if result.ok:
			check(result.code==Compiler.compile(source,"res://pixels.gogo","res://Generated.gd").code,"deterministic pixel emission")
			var script := GDScript.new()
			script.resource_path = "res://_gogo_memory_%d.gd" % script.get_instance_id()
			script.source_code = result.code
			check(script.reload()==OK,"generated pixel native semantics")
	for attrs in ['width="100%"','height="1px"','padding="12"','margin={-2}','padding_top={-1}','padding={NAN}','margin={INF}','paddding={4}']:
		var result := Compiler.compile(header+'<Box '+attrs+' />\n',"res://invalid-pixels.gogo")
		check(not result.ok and not result.diagnostics.is_empty() and result.diagnostics[0].span.start.line==3 and result.diagnostics[0].span.start.column>20,"authored pixel diagnostics "+attrs)
	for value in [-2.0,NAN,INF,"12",true]:
		check(not Pixels.valid(value,"inset"),"dynamic inset domain rejects "+str(value))
func click_at(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func capture(name: String) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
func run() -> void:
	core_proof()
	compiler_proof()
	var home = load("res://app/Home.tscn").instantiate()
	root.add_child(home)
	await frames()
	var entry = home.get_node("UI")
	var column = home.get_node("UI/Column")
	var button = column.get_node("Action")
	var settings = column.get_node("Settings")
	var row = settings.get_node("Row")
	var h := HBox.new()
	var v := VBox.new()
	check(column is Box and h.get_script().get_base_script()==Box and v.get_script().get_base_script()==Box,"shared real native Box hierarchy")
	h.free()
	v.free()
	check(column.position==Vector2(10,10) and column.layout_size==Vector2(480,380),"Entry padding uses same core; fill bounds exclude parent padding")
	check(button.position==Vector2(29,17) and button.layout_size==Vector2(180,40),"shorthand + leading override independent from attribute order")
	check(settings.position==Vector2(35,77) and row.position==Vector2.ZERO and row.layout_size==Vector2(84,28),"nested Gogo forwards margin once with root at local zero")
	check(row.get_node("Red").position==Vector2(4,4) and row.get_node("Blue").position==Vector2(50,4),"nested row padding and gap use native child transforms")
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	var red_point: Vector2 = row.get_node("Red").global_position+Vector2(5,5)
	check(image.get_pixelv(Vector2i(red_point)).is_equal_approx(Color.RED),"rendered pixels match nested padding/margin transforms")
	capture("before")
	click_at(button.global_position+Vector2(-2,10))
	check(home.clicks==0,"margin pixels are outside button hit bounds")
	click_at(button.global_position+Vector2(10,10))
	check(home.clicks==1,"arranged button pixels receive native pointer once")
	var record = State.get("records")[home.get_instance_id()]
	for invalid in [-2.0,NAN,INF,"12",true]:
		check(not record._preflight(Element.new(Box,{"width":17.0,"padding":invalid}),null,column) and column.width==-1 and column.padding==12,"dynamic invalid inset rejects complete description before writes "+str(invalid))
	var ids := [column.get_instance_id(),button.get_instance_id(),settings.get_instance_id(),row.get_instance_id()]
	var cached: int = row.layout.model.measure_count
	home.inset = 20.0
	await frames()
	check(ids==[column.get_instance_id(),button.get_instance_id(),settings.get_instance_id(),row.get_instance_id()] and button.global_position==Vector2(39,35),"bindable padding recomposes in place with native identity")
	check(row.layout.model.measure_count==cached,"clean nested siblings remain measured once")
	capture("after")
	row.margin_left = 21
	await frames()
	check(settings.position.x==45 and row.position==Vector2.ZERO,"root margin signal updates forwarded host exactly once")
	entry.width = 600
	entry.height = 450
	await frames()
	check(column.layout_size==Vector2(580,430),"resized root allocates the content rectangle")
	var stats := [entry.get_layout_stats(),column.get_layout_stats()]
	column.padding = 20
	column.padding = NAN
	column.padding = -2
	await frames()
	check(stats==[entry.get_layout_stats(),column.get_layout_stats()],"equal and invalid setters leave layout quiet")
	check(column.padding==20,"invalid native setter retains last valid value")
	var flushes: int = entry.layout.flush_count
	column.padding = 21
	column.padding = 22
	column.padding = 23
	await frames()
	check(entry.layout.flush_count==flushes+1 and column.padding_left==24,"inset burst coalesces one flush and preserves explicit edges")
	column.padding_left = -1
	await frames()
	check(column._padding_insets()==Vector4(23,23,23,23),"native unset edge restores shorthand deterministically")
	var packed := PackedScene.new()
	var stored := VBox.new()
	stored.padding = 10
	stored.padding_left = 0
	stored.margin = 6
	stored.margin_right = 2
	packed.pack(stored)
	stored.free()
	stored = packed.instantiate()
	check(stored._padding_insets()==Vector4(0,10,10,10) and stored._margin_insets()==Vector4(6,6,2,6),"scene packing preserves explicit zero edge precedence")
	stored.free()
	root.remove_child(home)
	root.add_child(home)
	await frames()
	check(home.get_node("UI/Column/Settings/Row").position==Vector2.ZERO,"native detach/reentry keeps nested margin ownership")
	home.free()
	await frames()
	var natural := Entry.new()
	var horizontal := HBox.new()
	var vertical := VBox.new()
	for box in [horizontal,vertical]:
		box.gap = 5
		for extent in [Vector2(30,20),Vector2(40,10)]:
			var leaf := Rect.new()
			leaf.set_extent(extent)
			box.add_child(leaf)
		natural.add_child(box)
	root.add_child(natural)
	await frames()
	check(horizontal.layout_size==Vector2(75,20) and vertical.layout_size==Vector2(40,35),"zero-inset HBox/VBox dimensions retain pre-refactor geometry")
	check(horizontal.get_child(1).position==Vector2(35,0) and vertical.get_child(1).position==Vector2(0,25),"zero-inset native sibling placement remains equivalent")
	natural.free()
	var counter = load("res://app/generated/Counter.gd").new()
	root.add_child(counter)
	await frames()
	var increment = counter.get_node("UI/Panel/Actions/Increment")
	var identity: int = increment.get_instance_id()
	click_at(increment.global_position+Vector2(4,4))
	await frames()
	check(counter.count==1 and counter.get_node("UI/Panel/Count").text=="Count: 1" and increment.get_instance_id()==identity,"current Counter remains retained and reactive with native pointer input")
	capture("counter")
	counter.free()
	var demo = load("res://app/generated/BoxModel.gd").new()
	root.add_child(demo)
	await frames()
	var action = demo.get_node("UI/Panel/Action")
	var demo_id: int = action.get_instance_id()
	click_at(action.global_position+Vector2(4,4))
	await frames()
	check(demo.inset==24 and demo.get_node("UI/Panel").padding==24 and action.get_instance_id()==demo_id,"runnable Box model example changes padding with retained native input")
	capture("example")
	demo.free()
	await frames()
	language()
	print("L01_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L01_RUNTIME_OK")
	quit(1 if failed else 0)

func language() -> void:
	var original := FileAccess.get_file_as_string("res://app/Home.gogo")
	var output := "res://app/generated/Home.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script: Script = load(output)
	for invalid in ['padding="12"','padding={-2}','padding={NAN}','padding="100%"']:
		preload("build.gd").write("res://app/Home.gogo",original.replace("padding={self.inset}",invalid))
		var report := Build.run_build()
		check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"invalid authored inset preserves actual-path Script/maps "+invalid)
	preload("build.gd").write("res://app/Home.gogo",original)
	check(Build.run_build().ok,"repair recovers native pixel compilation")
