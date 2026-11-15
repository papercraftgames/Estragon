extends RefCounted
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Entry3D = preload("res://addons/estragon/runtime/node/estragon_3d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Length = preload("res://addons/estragon/runtime/node/internal/length.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
class ProofRoot extends Node2D:
	var layout = preload("res://addons/estragon/runtime/node/internal/coordinator.gd").new(self,2)
	func _enter_tree() -> void:
		layout.model.set_lengths({"width":Length.parse("50%","extent")},0,0,1,0)
		layout.start()
	func _exit_tree() -> void: layout.stop()
	func apply_layout_size(_size: Vector3) -> void: pass
func run(t) -> void:
	var home = load("res://app/generated/RootHome.gd").new()
	t.root.add_child(home)
	await t.frames()
	var entry = home.get_node("UI")
	var column = home.get_node("UI/Column")
	var space = column.get_node("Space")
	var hello = column.get_node("Hello")
	var settings = column.get_node("Settings")
	var button: Button = settings.get_node("Row/Exit")
	var rose = column.get_node("Rose").get_child(0)
	var ids := [entry.get_instance_id(),space.get_instance_id(),button.get_instance_id(),rose.get_instance_id()]
	var record = State.get("records")[home.get_instance_id()]
	var runs: int = record.runs
	var trace: Array = []
	for viewport in [Vector2i(640,480),Vector2i(1000,800),Vector2i(320,240),Vector2i(640,480)]:
		t.root.size = viewport
		await t.frames()
		var occupied := 0.0
		for child in column.layout.model.children:
			if child!=space.layout.model: occupied += child.measured.y+child.outer_extent().y
		var bottom: float = rose.global_position.y+rose.layout_size.y
		t.check(entry.layout_size==Vector2(viewport) and column.layout_size==Vector2(viewport) and space.layout_size==Vector2(viewport.x*0.5,maxf(0,viewport.y-occupied)) and absf(bottom-viewport.y)<0.01,"L07 exact owner root100% remaining-space footer "+str(viewport))
		t.check(entry.width=="100%" and entry.height=="100%" and space.height=="auto" and ids==[entry.get_instance_id(),space.get_instance_id(),button.get_instance_id(),rose.get_instance_id()] and record.runs==runs,"L07 resize preserves source specs/identity without recomposition")
		var clicks: int = settings.clicks
		t.click(button,button.size)
		t.check(settings.clicks==clicks+1,"L07 real native Exit signal at "+str(viewport))
		var before := [entry.layout_size,column.layout_size,space.layout_size,hello.position,button.global_position,rose.global_position]
		entry.width = "100vw"
		entry.height = "100vh"
		await t.frames()
		t.check(before==[entry.layout_size,column.layout_size,space.layout_size,hello.position,button.global_position,rose.global_position],"L07 root% and explicit viewport units are geometrically identical")
		entry.width = "100%"
		entry.height = "100%"
		await t.frames()
		t.capture("l07-root-grow-"+str(viewport.x))
		space.height = "100%"
		await t.frames()
		t.check(space.layout_size.y==viewport.y and hello.position.y==viewport.y and rose.global_position.y+rose.layout_size.y>viewport.y,"L07 full inner100% consumes entire content and siblings overflow without shrink")
		trace.append({"viewport":str(viewport),"root":str(entry.layout_size),"occupied":occupied,"grow_height":before[2].y,"grow_bottom":bottom,"full_height":space.layout_size.y,"following_text_y":hello.position.y,"overflow_bottom":rose.global_position.y+rose.layout_size.y})
		t.capture("l07-root-full-"+str(viewport.x))
		space.height = "auto"
		await t.frames()
	entry.height = "50%"
	await t.frames()
	t.check(entry.layout_size==Vector2(640,240) and space.layout_size.x==320,"L07 half viewport root height is240, not zero or remaining space")
	entry.height = "150%"
	await t.frames()
	t.check(entry.layout_size.y==720 and rose.global_position.y+rose.layout_size.y==720,"L07 root150% intentionally overflows visible viewport")
	entry.height = "100%"
	await t.frames()
	var idle := [entry.get_layout_stats(),space.get_layout_stats(),entry.lengths.parse_count,space.lengths.parse_count,record.runs]
	await t.frames()
	t.check(idle==[entry.get_layout_stats(),space.get_layout_stats(),entry.lengths.parse_count,space.lengths.parse_count,record.runs],"L07 zero idle parse/measure/arrange/recomposition")
	rose.text += "\nRose grows naturally"
	await t.frames()
	t.check(rose.global_position.y+rose.layout_size.y==480 and record.runs==runs,"L07 nested intrinsic change reflows remaining space without parent rerender")
	var parse_count: int = entry.lengths.parse_count
	t.root.size = Vector2i(1000,800)
	await t.frames()
	t.check(entry.lengths.parse_count==parse_count and not entry.layout.model._reported_unanchored,"L07 valid root% resize never reparses or warns unanchored")
	home.free()
	await t.frames()
	var file := FileAccess.open("res://l07-root-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace))
	file.close()
	await references(t)
func references(t) -> void:
	# Every eligible root spec uses the viewport, even with a fractional root.
	t.root.size = Vector2i(640,480)
	var entry := Entry.new()
	entry.position = Vector2(7,11)
	entry.width = "50%"
	entry.height = "50%"
	entry.padding = "10%"
	entry.margin = "2%"
	entry.gap = "1%"
	entry.x = "10%"
	entry.y = "-5%"
	var box := Box.new()
	box.width = "100%"
	box.height = "100%"
	box.padding = "5%"
	var leaf := Rect.new()
	leaf.width = "50%"
	leaf.height = "50%"
	box.add_child(leaf)
	entry.add_child(box)
	t.root.add_child(entry)
	await t.frames()
	t.check(entry.layout_size==Vector2(320,240) and entry.layout.model.padding==Vector4(64,48,64,48) and entry.position==Vector2(71,-13),"L07 fractional root dimensions/insets/additive axes share viewport containing rectangle")
	t.check(entry.layout.model.margin.is_equal_approx(Vector4(12.8,9.6,12.8,9.6)) and is_equal_approx(entry.layout.model.gap,6.4),"L07 root margin/gap use viewport but margin has no allocating parent")
	t.check(box.layout_size==Vector2(192,144) and box.layout.model.padding.is_equal_approx(Vector4(9.6,7.2,9.6,7.2)) and leaf.layout_size.is_equal_approx(Vector2(86.4,64.8)),"L07 ordinary child percentages use actual immediate padded content, never viewport fallback")
	entry.direction = "column"
	await t.frames()
	t.check(is_equal_approx(entry.layout.model.gap,4.8),"L07 root gap percentage follows its selected stack axis")
	t.root.size = Vector2i(1000,800)
	await t.frames()
	t.check(entry.layout_size==Vector2(500,400) and entry.position==Vector2(107,-29),"L07 percentage offset applies viewport resize delta once")
	var plain := Node2D.new()
	box.add_child(plain)
	var independent := Entry.new()
	independent.width = "100%"
	independent.height = "50%"
	plain.add_child(independent)
	await t.frames()
	t.check(independent.layout_size==Vector2(1000,400) and independent.get_layout_root()==independent and not box.layout.model.children.has(independent.layout.model),"L07 nested independent Entry ignores enclosing content and plain boundary")
	entry.free()
	await t.frames()
	var view := SubViewport.new()
	view.size = Vector2i(400,300)
	t.root.add_child(view)
	entry = Entry.new()
	entry.width = "100%"
	entry.height = "50%"
	view.add_child(entry)
	await t.frames()
	t.check(entry.layout_size==Vector2(400,150),"L07 Entry percent uses its containing SubViewport")
	view.size = Vector2i(200,160)
	await t.frames()
	t.check(entry.layout_size==Vector2(200,80),"L07 SubViewport size_changed updates root percentages")
	view.remove_child(entry)
	view.size = Vector2i(500,240)
	view.add_child(entry)
	await t.frames()
	t.check(entry.layout_size==Vector2(500,120),"L07 detached Entry reconnects and resolves the current viewport")
	view.free()
	await t.frames()
	# Native stretch owns the logical visible rectangle, independently of OS size.
	var old_mode: int = t.root.content_scale_mode
	var old_size: Vector2i = t.root.content_scale_size
	t.root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	t.root.content_scale_size = Vector2i(400,300)
	entry = Entry.new()
	entry.width = "100%"
	entry.height = "100%"
	t.root.add_child(entry)
	await t.frames()
	t.check(entry.layout_size==t.root.get_visible_rect().size and entry.layout_size!=Vector2(t.root.size),"L07 native project stretch uses visible logical viewport, not OS window size")
	entry.free()
	t.root.content_scale_mode = old_mode
	t.root.content_scale_size = old_size
	await t.frames()
	# An auto content axis is still indefinite for ordinary descendants.
	entry = Entry.new()
	box = Box.new()
	leaf = Rect.new()
	leaf.width = "50%"
	box.add_child(leaf)
	entry.add_child(box)
	t.root.add_child(entry)
	await t.frames()
	t.check(leaf.layout_size.x==0 and leaf.layout.model.parent_reference.x<0 and leaf.layout.model._reported_unanchored,"L07 ordinary cyclic/auto percentage retains zero plus warning")
	entry.free()
	await t.frames()
	var core := Core.new()
	core.set_lengths({"width":Length.parse("50%","extent")},0,0,1,0)
	core.prepare(Vector3(-1,-1,-1),Vector2(640,480))
	core.arrange(core.measure())
	t.check(core.size.x==0 and core._reported_unanchored,"L07 pure unanchored/proof context gains no global viewport fallback")
	var proof := ProofRoot.new()
	t.root.add_child(proof)
	await t.frames()
	t.check(proof.layout.model.size.x==0 and proof.layout.model.parent_reference.x<0,"L07 actual proof coordinator has no implicit Entry viewport reference")
	proof.free()
	await t.frames()
	var space := Entry3D.new()
	space.width = "50%"
	space.height = "50%"
	t.root.add_child(space)
	await t.frames()
	t.check(space.layout_size==Vector3.ZERO and space.layout.model.parent_reference==Vector3(-1,-1,-1),"L07 bounded3D percent contract remains unchanged without inferred viewport plane")
	space.free()
	await t.frames()
