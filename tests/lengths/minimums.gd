extends RefCounted
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Length = preload("res://addons/estragon/runtime/node/internal/length.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const Native2D = preload("res://addons/estragon/runtime/node/native_2d.gd")
const Spatial = preload("res://addons/estragon/runtime/node/component_3d.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
var edits: Array = []
func edited(value: bool) -> void: edits.append(value)
func run(p) -> void:
	var entry = Entry.new()
	entry.width = 400
	entry.height = 300
	p.root.add_child(entry)
	var box = Box.new()
	box.width = 80
	box.height = 40
	box.min_width = "120px"
	box.min_height = 60
	box.border_width = 2
	box.padding_left = 10
	box.padding_right = 20
	var child = Rect.new()
	child.width = "100%"
	child.height = "100%"
	box.add_child(child)
	entry.add_child(box)
	await p.frames()
	p.check(box.width==80 and box.height==40 and box.layout_size==Vector2(120,60),"L11 explicit authored extents stay readable while allocated border-box clamps to minima")
	p.check(child.layout_size==Vector2(86,56) and child.position==Vector2(12,2),"L11 percentage child uses clamped content after asymmetric border+padding once")
	for width in [120,150,80]:
		box.width = width
		await p.frames()
		p.check(box.layout_size.x==maxi(width,120),"L11 requested width below/equal/above minimum: "+str(width))
	box.min_width = "50%"
	box.min_height = "25%"
	await p.frames()
	p.check(box.layout_size==Vector2(200,75),"L11 per-axis percent minima reference immediate parent content")
	box.min_width = "2.5in"
	box.min_height = "12pt"
	await p.frames()
	p.check(box.layout_size==Vector2(240,40),"L11 minima share existing physical/reference unit conversion")
	box.min_width = "auto"
	box.min_height = "auto"
	await p.frames()
	p.check(box.layout_size==Vector2(80,40) and box.min_width=="auto" and box.layout.model.authored_minimum==Vector3.ZERO,"L11 explicit auto clears minimum and preserves authored getter")
	box.min_width = 0
	box.width = 0
	box.height = 0
	box.min_height = 0
	await p.frames()
	p.check(box.layout_size==Vector2.ZERO and child.layout_size==Vector2.ZERO,"L11 zero minimum and zero border-box preserve clamped nonnegative content")
	var text = Text.new()
	text.text = "I"
	text.min_width = 120
	text.min_height = 50
	entry.add_child(text)
	var button = UiButton.new()
	button.text = "Go"
	button.min_width = 140
	button.min_height = 64
	entry.add_child(button)
	await p.frames()
	p.check(text.layout_size==Vector2(120,50) and text.get_label_origin()==Vector2.ZERO,"L11 natural Text uses minimum without adding insets or moving baseline twice")
	p.check(button.layout_size==Vector2(140,64) and button.get_label_origin().is_equal_approx((button.layout_size-button._measure_label())/2),"L11 natural Button retains padding and centers label inside enlarged minimum box")
	button.min_width = 20
	await p.frames()
	p.check(button.layout_size.x==button._measure_label().x+28,"L11 minimum never replaces a larger intrinsic preferred size")
	var model = Core.new()
	model.allocation_minimum = Vector3(90,40,0)
	model.set_lengths({"min_width":Length.parse(120,"edge"),"min_height":Length.parse(20,"edge")},0,0,1,0)
	model.configure(Vector3(10,10,0),0,false)
	model.prepare(Vector3(400,300,0),Vector2(640,480))
	model.arrange(Vector3(10,10,0))
	p.check(model.minimum()==Vector3(120,40,0) and model.size==Vector3(120,40,0) and model.allocation_minimum==Vector3(90,40,0),"L11 authored/native floors combine by max without overwriting native allocation authority")
	var native = Native2D.new()
	native.width = 10
	native.height = 10
	native.min_width = 100
	native.min_height = 50
	native.background_color = "#2288aa"
	entry.add_child(native)
	await p.frames()
	p.check(native.layout_size==Vector2(100,50) and native.scale==Vector2.ONE,"L11 bounded Native2D minima enlarge allocated slot without stretching native geometry")
	var draws: int = native.get_visual_style_stats().draw
	native.min_width = 120
	await p.frames()
	p.check(native.layout_size.x==120 and native.get_visual_style_stats().draw>draws,"L11 bounded Native2D redraws its common border-box paint when a minimum enlarges allocation")
	var spatial = Spatial.new()
	p.check(not Length.registered(Spatial,"min_width") and not "min_width" in spatial,"L11 3D has no registered minimum length contract")
	spatial.free()
	entry.width = 10
	entry.height = 10
	entry.min_width = "50vw"
	entry.min_height = "10%"
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		p.root.size = viewport
		await p.frames()
		p.check(entry.layout_size.is_equal_approx(Vector2(viewport.x*0.5,viewport.y*0.1)),"L11 independent Entry minimum viewport/percent units resize through existing context")
	entry.free()
	await p.frames()
	await allocations(p)
	await gallery(p)
	await language(p)
func allocations(p) -> void:
	var entry = Entry.new()
	entry.width = 100
	entry.height = 30
	var row = Box.new()
	row.width = "100%"
	row.height = "100%"
	row.gap = 5
	var first = Rect.new()
	first.min_width = 70
	first.min_height = 50
	first.grow = 1
	first.stretch = 1
	first.margin = 2
	var second = Rect.new()
	second.min_width = 60
	second.grow = 1
	row.add_child(first)
	row.add_child(second)
	entry.add_child(row)
	p.root.add_child(entry)
	await p.frames()
	p.check(first.layout_size==Vector2(70,50) and second.layout_size.x==60 and second.position.x==79,"L11 over-constrained grow/stretch preserves minima, margins/gap and forward sibling overflow")
	p.check(row.layout_size==Vector2(100,30) and first.position==Vector2(2,2),"L11 child overflow does not enlarge definite parent or create negative centered slots")
	entry.width = 200
	await p.frames()
	p.check(first.layout_size.x==100.5 and second.layout_size.x==90.5,"L11 grow shares remaining space after preferred minima and outer spacing")
	# Native Control expand slots retain their existing water-filling floor.
	first.queue_free()
	second.queue_free()
	await p.frames()
	var control := Button.new()
	control.custom_minimum_size = Vector2(70,20)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	var sibling = Rect.new()
	sibling.width = 20
	sibling.height = 10
	row.add_child(sibling)
	entry.width = 60
	await p.frames()
	p.check(control.size.x>=70 and sibling.position.x>=control.position.x+control.size.x+5,"L11 native Control intrinsic minimum and subsequent slot order remain authoritative during overflow")
	entry.free()
	await p.frames()
	var auto_entry = Entry.new()
	var auto_box = Box.new()
	auto_box.min_width = 100
	var percent = Rect.new()
	percent.min_width = "50%"
	auto_box.add_child(percent)
	auto_entry.add_child(auto_box)
	p.root.add_child(auto_entry)
	await p.frames()
	p.check(auto_box.layout_size.x==100 and percent.layout_size.x==0,"L11 auto minimum floor does not invent a cyclic descendant percent reference")
	var idle := [auto_entry.get_layout_stats(),auto_box.get_layout_stats(),percent.get_layout_stats()]
	await p.frames()
	p.check(idle==[auto_entry.get_layout_stats(),auto_box.get_layout_stats(),percent.get_layout_stats()],"L11 indefinite percent minima settle without per-frame churn")
	auto_entry.free()
	await p.frames()
func gallery(p) -> void:
	var host = load("res://app/generated/MinimumGallery.gd").new()
	p.root.add_child(host)
	await p.frames()
	var panel = host.get_node("UI/Panel")
	var button = panel.get_node("Continue")
	var toggle = panel.get_node("Enabled")
	var native = panel.get_node("Native")
	var nested = panel.get_node("Nested")
	var body = nested.get_node("Body")
	var record = State.records[host.get_instance_id()]
	var ids: Array = host.find_children("*","",true,false).map(func(node): return [node.get_instance_id(),node.get_parent().get_instance_id(),node.owner])
	edits.clear()
	toggle.value_changed.connect(edited)
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		p.root.size = viewport
		await p.frames()
		p.check(panel.layout_size.x==viewport.x-24 and button.layout_size.x==panel.get_content_rect().size.x/2 and button.layout_size.y==36,"L11 rendered min-size example retains percent width and clamped Button height at"+str(viewport))
		p.check(ids==host.find_children("*","",true,false).map(func(node): return [node.get_instance_id(),node.get_parent().get_instance_id(),node.owner]),"L11 viewport resize retains all nested native identities/owners")
		p.click(button,button.layout_size)
		p.click(native,native.size)
		p.click(toggle,toggle.layout_size)
		await p.frames()
		p.capture("minimums-"+str(viewport.x))
	p.click(button,Vector2(2,2))
	await p.frames()
	p.check(host.clicks==3 and host.native_clicks==2 and edits==[true,false],"L11 constrained Button/Toggle whole outer area and native Control produce exactly one edit/click")
	var before: int = record.runs
	var measures: int = button.get_layout_stats().measure
	var leaf_measure: int = panel.get_node("Caption").get_layout_stats().measure
	button.min_width = 700
	button.min_height = 60
	await p.frames()
	p.check(button.layout_size==Vector2(700,60) and record.runs==before and button.get_layout_stats().measure>measures and panel.get_node("Caption").get_layout_stats().measure==leaf_measure,"L11 dynamic native minima reflow affected branch without recomposition or remeasuring unaffected Text")
	body.min_width = 1100
	await p.frames()
	p.check(State.records[nested.get_instance_id()].layout_host.layout.model.size.x==1100 and body.layout_size.x==1100,"L11 transparent nested Gogo host forwards a live root minimum to parent allocation")
	body.min_width = 0
	await p.frames()
	p.check(State.records[nested.get_instance_id()].layout_host.layout.model.size.x==panel.get_content_rect().size.x,"L11 nested root minimum removal restores percentage allocation without host reconstruction")
	var idle := [button.get_layout_stats(),panel.get_layout_stats(),button.lengths.parse_count,record.runs]
	button.min_width = 700
	button.min_height = 60
	await p.frames()
	p.check(idle==[button.get_layout_stats(),panel.get_layout_stats(),button.lengths.parse_count,record.runs],"L11 unchanged minimum writes and idle frames perform zero parse/layout/recomposition work")
	print("L11_COUNTERS ",JSON.stringify({"before_equal":idle,"after_equal":[button.get_layout_stats(),panel.get_layout_stats(),button.lengths.parse_count,record.runs]}))
	host.floor_width = "1100px"
	await p.frames()
	p.check(panel.layout_size.x==1100 and panel==host.get_node("UI/Panel"),"L11 bindable GGX minimum changes commit a new floor on the retained panel")
	host.constrained = false
	await p.frames()
	p.check(panel==host.get_node("UI/Panel") and panel.min_width==0 and panel.min_height==0,"L11 omitted reconciled minima reset to zero on retained native Node")
	var packed := PackedScene.new()
	packed.pack(button)
	var restored = packed.instantiate()
	p.check(restored.min_width==700 and restored.min_height==60 and restored.width=="50%","L11 native pack/reload preserves independent authored dimensions and minima")
	restored.free()
	var invalid = Element.new(UiButton,{"min_width":"broken"},{},[],"MinimumGallery.gogo:25:5")
	p.check(not record._preflight(invalid,null,host) and record.validation_error.contains("MinimumGallery.gogo:25:5: invalid length 'min_width'"),"L11 dynamic minimum preflight is authored-source located before any commit")
	p.check(button.layout_size==Vector2(700,60) and button.get_parent()==panel,"L11 invalid description leaves valid native geometry/tree intact")
	host.free()
	await p.frames()
func language(p) -> void:
	var head := 'extends Node2D\nconst Rect = preload("res://addons/estragon/runtime/node/rect.gd")\nfunc view(): return '
	for attrs in ['width="80px" min_width="120px"','min_width="120px" width="80px"','min_height="auto"','min_width="25%" min_height="10vh"']:
		p.check(Compiler.compile(head+'<Rect '+attrs+' />\n',"res://minimum.gogo").ok,"L11 static unit/assignment-order minimum authoring "+attrs)
	var path := "res://app/MinimumGallery.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/MinimumGallery.gd"
	var code := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script = load(output)
	for invalid in ['min_width="bad"','min_width="-1px"','min_height={NAN}','min_height={true}','min_width="1e13px"']:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(original.replace('min_width="96px"',invalid))
		file.close()
		var report := Build.run_build()
		p.check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==code and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"L11 invalid literal minimum retains compiled source/maps/cache: "+invalid)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	p.check(Build.run_build().ok,"L11 repaired minimum source resumes actual-path compilation")
