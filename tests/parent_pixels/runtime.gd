extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Pixels = preload("res://addons/estragon/runtime/composition/pixels.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L02_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(15): await process_frame
func _initialize() -> void: run.call_deferred()
func capture(name: String, panel: Node) -> void:
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
	var file := FileAccess.open("res://"+name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"width":panel.width,"height":panel.height,"size":str(panel.layout_size),"position":str(panel.global_position)}))
	file.close()
func click(button: Node) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func record(host: Node): return State.get("records")[host.get_instance_id()]
func run() -> void:
	root.size = Vector2i(1000,720)
	var home = load("res://app/Home.tscn").instantiate()
	root.add_child(home)
	await frames()
	var entry = home.get_node("UI")
	var outer = entry.get_node("Outer")
	var host = outer.get_node("Panel")
	var panel = host.get_node("Panel")
	var nested = panel.get_node("Nested/Nested")
	var ids := [host.get_instance_id(),panel.get_instance_id(),nested.get_instance_id(),panel.get_node("Action").get_instance_id()]
	for extent in [Vector2(640,400),Vector2(800,600),Vector2(520,320)]:
		entry.set_extent(extent)
		await frames()
		var content: Vector2 = extent-Vector2(40,40)
		check(panel.layout_size==Vector2(content.x*0.5,content.y*0.75) and panel.width==content.x*0.5 and panel.height==content.y*0.75,"persistent50/75 ordinary pixel lengths at "+str(extent))
		check(nested.layout_size==Vector2((panel.width-16)*0.5,(panel.height-16)*0.5),"deep child uses immediate parent content instead of viewport")
		check(outer.get_node("Flex").layout_size.x==maxf(0,content.x-panel.width-10-40-20),"percent sibling margins fixed pixels and gaps reserve before fill")
		capture("parent-"+str(int(extent.x)),panel)
	check(ids==[host.get_instance_id(),panel.get_instance_id(),nested.get_instance_id(),panel.get_node("Action").get_instance_id()],"resize retains native component/root/input identities")
	home.flipped = true
	await frames()
	check(outer.get_child(2)==host and panel.get_instance_id()==ids[1] and panel.width==240,"keyed sibling reordering retains native percent root and current pixel size")
	click(panel.get_node("Action"))
	check(host.clicks==1,"native pointer activation follows resized percent geometry")
	var counts := [record(home).runs,record(host).runs,record(panel.get_node("Nested")).runs,entry.get_layout_stats(),outer.get_layout_stats()]
	await frames()
	check(counts==[record(home).runs,record(host).runs,record(panel.get_node("Nested")).runs,entry.get_layout_stats(),outer.get_layout_stats()],"idle frames perform zero rerender/measure/arrange/flush work")
	var unchanged: int = outer.get_node("Fixed").layout.model.measure_count
	var parent_runs: int = record(home).runs
	outer.padding_left = 30
	await frames()
	check(panel.width==(entry.width-50)*0.5 and record(home).runs==parent_runs and outer.get_node("Fixed").layout.model.measure_count==unchanged,"padding change observes affected geometry without parent/sibling recomposition")
	outer.margin = 10
	await frames()
	check(panel.width==(entry.width-70)*0.5,"parent margins affect allocated bounds once, not a second content deduction")
	outer.margin = 0
	await frames()
	host.percent_x = 25.5
	host.percent_y = 120.0
	await frames()
	check(is_equal_approx(panel.width,(entry.width-50)*0.255) and is_equal_approx(panel.height,(entry.height-40)*1.2),"fractional pixels and above100 overflow stay ordinary finite pixel values")
	capture("overflow",panel)
	host.percent_x = 0
	host.percent_y = 0
	await frames()
	check(panel.width==0 and panel.height==0 and panel.layout_size==Vector2.ZERO,"zero percentages are fixed zero pixels, independent of fill flags")
	host.percent_x = 25.5
	host.percent_y = 120.0
	await frames()
	# Burst size writes coalesce and affect only relevant component computations.
	var before_runs: int = record(host).runs
	entry.width = 610
	entry.width = 620
	entry.width = 630
	await frames()
	check(record(host).runs==before_runs+1 and is_equal_approx(panel.width,580*0.255),"parent resize burst coalesces one ordinary composition")
	entry.viewport_width_scale = 0.8
	entry.viewport_height_scale = 0.75
	for extent in [Vector2i(1000,720),Vector2i(1200,800)]:
		root.size = extent
		await frames()
		check(is_equal_approx(panel.width,(root.get_visible_rect().size.x*0.8-50)*0.255) and is_equal_approx(panel.height,(root.get_visible_rect().size.y*0.75-40)*1.2),"viewport-driven fill ancestors publish explicit parent content basis")
	# Native reparent preserves the component itself and retargets weak sources.
	var other := Box.new()
	other.width = 240
	other.height = 160
	other.padding = 10
	entry.add_child(other)
	host.reparent(other)
	await frames()
	check(is_equal_approx(panel.width,220*0.255) and is_equal_approx(panel.height,140*1.2),"native reparent retargets helper to new immediate content parent")
	var old_runs: int = record(host).runs
	outer.padding = 50
	await frames()
	check(record(host).runs==old_runs,"old parent signal no longer schedules moved component")
	var natural := VBox.new()
	other.add_child(natural)
	host.reparent(natural)
	await frames()
	check(panel.width==0 and panel.height==0 and natural.layout_size==Vector2(10,10),"auto-size parent depending on percent child resolves zero without fixed-point iteration")
	var stable: int = record(host).runs
	await frames()
	check(stable==record(host).runs,"auto/percent cycle fallback remains settled without scheduler work")
	natural.width = 10
	natural.height = 10
	await frames()
	check(is_equal_approx(panel.width,10*0.255) and is_equal_approx(panel.height,12),"auto-to-fixed policy change wakes dependencies even when previous arranged bounds equal fixed bounds")
	natural.padding = 20
	await frames()
	check(panel.width==0 and panel.height==0,"padding larger than bounds exposes clamped zero content")
	home.free()
	await frames()
	await multiple_and_projection()
	await wrappers()
	await scope_and_invalid()
	await current_examples()
	language()
	check(State.scopes.is_empty() and State.composing_hosts.is_empty(),"composition observation/context stacks unwind together")
	print("L02_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L02_RUNTIME_OK")
	quit(1 if failed else 0)
func wrappers() -> void:
	var entry := Entry.new()
	entry.width = 600
	entry.height = 400
	var outer := Box.new()
	outer.fill_width = true
	outer.fill_height = true
	outer.padding = 20
	entry.add_child(outer)
	var wrapper = load("res://app/generated/Wrapper.gd").new()
	outer.add_child(wrapper)
	root.add_child(entry)
	await frames()
	var panel = wrapper.get_node("Wrapped/Panel")
	check(panel.layout_size==Vector2(280,270),"transparent Gogo root chains do not invent self-referential content boxes")
	entry.width = 800
	await frames()
	check(panel.width==380 and panel.height==270,"transparent ancestor context remains responsive")
	entry.free()
	await frames()
func scope_and_invalid() -> void:
	var detached = load("res://app/generated/PercentPanel.gd").new()
	root.add_child(detached)
	await frames()
	check(detached.get_node("Panel").layout_size==Vector2.ZERO,"missing layout parent returns zero without viewport inference")
	detached.free()
	var entry := Entry.new()
	entry.width = 1000
	entry.height = 800
	var boundary = load("res://app/generated/Boundary.gd").new()
	entry.add_child(boundary)
	root.add_child(entry)
	await frames()
	var host = boundary.get_node("Independent/Panel")
	check(host.get_node("Panel").layout_size==Vector2(150,150),"independent Entry reference stops at its own300x200 scope")
	State.begin(host)
	for bad in [-1.0,NAN,INF,-INF]:
		check(Pixels.parent_width(host,bad)==0,"invalid percentage fallback "+str(bad))
	check(Pixels.parent_width(host,1e308)==0 and Pixels.parent_width(host,1e40)==0,"overflowing helper result falls back before native vector storage")
	check(Pixels.parent_height(entry,50)==0,"another Node cannot become an arbitrary cross-sibling geometry context")
	State.finish()
	check(Pixels.parent_width(host,50)==0,"outside composition is a bounded fallback rather than an implicit binding")
	entry.free()
	await frames()
func language() -> void:
	var original := FileAccess.get_file_as_string("res://app/PercentPanel.gogo")
	var output := "res://app/generated/PercentPanel.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script: Script = load(output)
	for invalid in ['width="50%"','width="12px"','width="bad"']:
		preload("build.gd").write("res://app/PercentPanel.gogo",original.replace('width={Pixels.parent_width(self,self.percent_x)}',invalid))
		var report := Build.run_build()
		check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"percentage helper leaves authored unit diagnostics/Script/maps fail closed "+invalid)
	preload("build.gd").write("res://app/PercentPanel.gogo",original)
	check(Build.run_build().ok,"repair recovers native helper semantics")

func multiple_and_projection() -> void:
	var entry := Entry.new()
	var box := Box.new()
	box.width = 400
	box.height = 200
	box.padding = 10
	box.gap = 6
	var a = load("res://app/generated/PercentPanel.gd").new()
	var b = load("res://app/generated/PercentPanel.gd").new()
	box.add_child(a)
	box.add_child(b)
	entry.add_child(box)
	root.add_child(entry)
	await frames()
	check(a.get_node("Panel").width==190 and b.get_node("Panel").width==190 and b.position==Vector2(221,15),"multiple percent siblings each use full parent content; margins/gaps may overflow")
	var native := Control.new()
	native.custom_minimum_size = Vector2(80,20)
	native.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(native)
	await frames()
	check(native.size.x==80 and a.get_node("Panel").width==190 and b.get_node("Panel").width==190,"native minimum floor overflows alongside fixed percent pixels instead of shrinking or weighting them")
	var other := Box.new()
	other.width = 200
	other.height = 100
	entry.add_child(other)
	# E08 logical-parent changes can happen without native exit/re-entry.
	var hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
	var owner := RefCounted.new()
	hosts.replace_projection(owner,{a.get_instance_id():[a,other]},{})
	await frames()
	check(a.get_parent()==box and a.get_node("Panel").width==100 and a.get_node("Panel").height==75,"logical projection retargets observed parent without native reparent or polling")
	var packed := PackedScene.new()
	var home = load("res://app/Home.tscn").instantiate()
	packed.pack(home)
	home.free()
	home = packed.instantiate()
	root.add_child(home)
	await frames()
	check(home.get_node("UI/Outer/Panel/Panel").layout_size==Vector2(300,270) and home.get_child_count()==1,"scene pack/reopen rebuilds percent view once from authored host")
	home.free()
	hosts.replace_projection(owner,{}, {})
	entry.free()
	await frames()

func current_examples() -> void:
	var counter = load("res://app/generated/Counter.gd").new()
	root.add_child(counter)
	await frames()
	var button = counter.get_node("UI/Panel/Actions/Increment")
	var identity: int = button.get_instance_id()
	click(button)
	await frames()
	check(counter.count==1 and counter.get_node("UI/Panel/Count").text=="Count: 1" and button.get_instance_id()==identity,"current Counter remains retained and reactive with native input")
	counter.free()
	var demo = load("res://app/generated/ResponsiveHome.gd").new()
	root.add_child(demo)
	await frames()
	var context = demo.get_node("UI/Page/Content")
	var host = context.get_node("Panel")
	var panel = host.get_node("Panel")
	check(panel.width==context.layout.model.content_reference.x*0.5 and panel.height==context.layout.model.content_reference.y*0.75,"runnable installed example uses optional helper for50/75 of parent content")
	click(panel.get_node("Action"))
	await frames()
	check(host.width_percent==25 and panel.width==context.layout.model.content_reference.x*0.25,"example changes an ordinary bindable percentage through retained input")
	capture("example",panel)
	demo.free()
	await frames()
