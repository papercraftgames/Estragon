extends RefCounted
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const VBox = preload("res://addons/estragon/runtime/node/vbox.gd")
const Spacer = preload("res://addons/estragon/runtime/node/spacer.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Grid = preload("res://addons/estragon/runtime/node/internal/grid_definition.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("build.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
func run(t) -> void:
	var definition := Grid.normalize(["220px","1fr"],["64px","1fr"],["header header","sidebar main"],[{"area":"header"},{"area":"sidebar"},{"area":"main"}])
	t.check(not definition.has("error") and definition.bounds.header=={"row":0,"column":0,"row_span":1,"column_span":2} and definition.placements[2]=={"row":1,"column":1,"row_span":1,"column_span":1},"L07A serializable rectangular GridDefinition")
	for invalid in [Grid.normalize(2,2,["a a","a b"]),Grid.normalize(2,2,["a","b c"]),Grid.normalize(2,2,[],[{"area":"unknown"}]),Grid.normalize(2,2,["a a","b c"],[{"area":"a"},{"area":"a"}]),Grid.normalize(2,2,[],[{"row":0,"column":0,"row_span":3}]),Grid.normalize(["0fr"],1),Grid.normalize(["1em"],1)]:
		t.check(invalid.has("error"),"L07A invalid grid rejects "+str(invalid))
	var source := Build.header("res://app/Test.gogo",["Element","Box","VBox","Spacer"])
	for invalid in ['<Box horizontal_align="stretch" />','<VBox vertical_align="stretch" />','<VBox direction="row" />','<Box horizontal_align="space-between" />','<Spacer flex={1} />']:
		var result := Compiler.compile(source+"func view() -> Element:\n\treturn "+invalid+"\n","res://app/Test.gogo")
		t.check(not result.ok and not result.diagnostics.is_empty(),"L07A source-positioned policy/migration rejects "+invalid)
	var footer = load("res://app/generated/Footer.gd").new()
	var native := Button.new()
	native.text = "Native Button — click"
	native.pressed.connect(func(): footer.clicks += 1)
	footer.add_child(native)
	native.owner = footer
	t.root.add_child(footer)
	await t.frames()
	var column = footer.get_node("UI/Column")
	var spacer = column.get_node("Space")
	var id: int = spacer.get_instance_id()
	var record = State.get("records")[footer.get_instance_id()]
	var runs: int = record.runs
	var trace: Array = []
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		t.root.size = viewport
		await t.frames()
		var occupied := column.layout.model.gap*(column.layout.model.children.size()-1)
		var last := 0.0
		for child in column.layout.model.children:
			if child!=spacer.layout.model: occupied += child.measured.y+child.outer_extent().y
			t.check(child.offset.y>=last-0.01,"L07A footer sequential nonoverlap")
			last = child.offset.y+child.size.y
		t.check(absf(spacer.layout_size.y-maxf(0,viewport.y-occupied))<0.01 and absf(last-viewport.y)<0.01 and spacer.layout_size.x==viewport.x/2.0,"L07A exact bottom remaining-space spacer "+str(viewport))
		t.check(spacer.get_instance_id()==id and native.get_parent()==footer and native.owner==footer and record.runs==runs,"L07A retained borrowed/nested/native ownership; resize without recomposition")
		t.click(native,native.size)
		trace.append({"viewport":str(viewport),"spacer":str(spacer.layout_size),"last_bottom":last,"occupied":occupied})
		t.capture("l07a-bottom-"+str(viewport.x))
	t.check(footer.clicks==2,"L07A real native GUI click at both viewport sizes")
	var idle := [column.get_layout_stats(),spacer.lengths.parse_count,record.runs]
	await t.frames()
	t.check(idle==[column.get_layout_stats(),spacer.lengths.parse_count,record.runs],"L07A zero idle layout/parsing/recomposition")
	var rose = column.get_node("Rose").get_child(0)
	rose.text = "Rose changes natural size\nA second line"
	await t.frames()
	t.check(absf(native.global_position.y+native.size.y-t.root.size.y)<0.01 and record.runs==runs,"L07A nested intrinsic resize reclaims spacer without parent recomposition")
	footer.free()
	await t.frames()
	var file := FileAccess.open("res://l07a-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(trace))
	file.close()
	# The same slot policy on both axes: nonzero preferred basis plus growth.
	for axis in range(2):
		var entry := Entry.new()
		entry.width = 600
		entry.height = 400
		var box := Box.new()
		box.direction = "row" if axis==0 else "column"
		box.width = "100%"
		box.height = "100%"
		box.padding = 10
		box.gap = 8
		var one := Rect.new()
		one.grow = 1
		one.margin = 2
		var two := Spacer.new()
		two.grow = 2
		var fixed := Rect.new()
		fixed.width = 40
		fixed.height = 30
		box.add_child(one)
		box.add_child(two)
		box.add_child(fixed)
		entry.add_child(box)
		t.root.add_child(entry)
		await t.frames()
		var free: float = (580 if axis==0 else 380)-(40 if axis==0 else 30)-16-4
		t.check(absf(one.layout_size[axis]-free/3)<0.01 and absf(two.layout_size[axis]-free*2/3)<0.01,"L07A X/Y 1:2 growth subtracts padding margins gap once")
		var node_id: int = fixed.get_instance_id()
		one.grow = 0
		two.grow = 0
		if axis==0: box.horizontal_align = "end"
		else: box.vertical_align = "center"
		await t.frames()
		var expected: float = free if axis==0 else free/2
		t.check(absf(one.position[axis]-(12+expected))<0.01 and fixed.get_instance_id()==node_id,"L07A parent policy changes slots preserving native children")
		box.width = 20
		box.height = 20
		await t.frames()
		t.check(fixed.layout_size==Vector2(40,30),"L07A constrained parent never shrinks explicit children")
		entry.free()
		await t.frames()
