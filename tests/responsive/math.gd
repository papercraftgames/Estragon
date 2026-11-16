extends SceneTree
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Wrap = preload("res://addons/estragon/runtime/node/internal/wrap_policy.gd")
const Grid = preload("res://addons/estragon/runtime/node/internal/grid_policy.gd")
const Definition = preload("res://addons/estragon/runtime/node/internal/grid_definition.gd")
var failed := false
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L0910_MATH_CHECK ",label,": ",ok)
	if not ok: failed = true
func item(width: float = 0, height: float = 20) -> Dictionary:
	return {"preferred":Vector3(width,height,0),"minimum":Vector3.ZERO,"requested":Vector3(width,height,0),"grow":0.0,"stretch":0,"align_self":"auto","fill":Vector3.ZERO,"outer":Vector3.ZERO,"leading":Vector3.ZERO,"placement":{}}
func _initialize() -> void:
	for axis in range(2):
		var child := item(70,20) if axis==0 else item(20,70)
		var items := [child,child,child]
		var content := Vector3(160,100,0) if axis==0 else Vector3(100,160,0)
		var gaps := Vector2(10,12) if axis==0 else Vector2(12,10)
		var r := Wrap.layout(items,content,axis,gaps,["start","start","start"],"start",Vector2.ONE)
		check(r.slots[0].position==Vector3.ZERO and r.slots[1].position[axis]==80 and r.slots[2].position[axis]==0 and r.slots[2].position[1-axis]==32,"160 transposed exact slots axis%d" % axis)
		check(r.extent[1-axis]==52,"natural auto cross contains lines")
		content[axis] = 230
		r = Wrap.layout(items,content,axis,gaps,["start","start","start"],"start",Vector2.ONE)
		check(r.slots[2].position[axis]==160 and r.lines.size()==1,"230 one line")
		content[axis] = 60
		r = Wrap.layout(items,content,axis,gaps,["start","start","start"],"start",Vector2.ONE)
		check(r.lines.size()==3 and r.slots[2].position[1-axis]==64,"oversize finite single overflowing lines")
		r = Wrap.layout(items,content,axis,gaps,["start","start","start"],"start",Vector2.ZERO)
		check(r.lines.size()==1,"unanchored one finite line")
		for mode in Wrap.CONTENT:
			r = Wrap.layout([],content,axis,gaps,["start","start","start"],mode,Vector2.ONE)
			check(r.slots.is_empty() and r.extent==Vector3.ZERO,"empty "+mode)
	var offsets := {"start":0.0,"center":24.0,"end":48.0,"space-between":0.0,"space-around":12.0,"space-evenly":16.0,"stretch":0.0}
	var second_lines := {"start":32.0,"center":56.0,"end":80.0,"space-between":80.0,"space-around":68.0,"space-evenly":64.0,"stretch":56.0}
	for mode in Wrap.CONTENT:
		var r := Wrap.layout([item(70),item(70),item(70)],Vector3(160,100,0),0,Vector2(10,12),["start","start","start"],mode,Vector2.ONE)
		check(r.slots[0].position.y==offsets[mode] and r.slots[2].position.y==second_lines[mode],"align_content exact "+mode)
		r = Wrap.layout([item(70)],Vector3(160,100,0),0,Vector2(10,12),["start","start","start"],mode,Vector2.ONE)
		var expected := 40 if mode in ["center","space-around","space-evenly"] else (80 if mode=="end" else 0)
		check(r.slots[0].position.y==expected,"single line "+mode)
	var a := item(70,20)
	a.requested.x = -1
	a.grow = 1
	var b := item(70,30)
	var c := item(70,20)
	for mode in ["space-between","space-around","space-evenly"]:
		var r := Wrap.layout([a,b,c],Vector3(160,100,0),0,Vector2(10,12),[mode,"start","start"],"start",Vector2.ONE)
		check(r.slots[0].extent.x==80 and r.slots[1].position.x==90 and r.slots[2].position.y==42,"grow before per-line "+mode)
	for mode in Wrap.CONTENT:
		var r := Wrap.layout([item(70,20),item(70,20),item(70,20)],Vector3(160,100,0),0,Vector2(10,12),["start","start","start"],mode,Vector2.ONE)
		var y0 := 24 if mode in ["center","space-around"] else (48 if mode=="end" else (16 if mode=="space-evenly" else 0))
		var y2 := 56 if mode=="center" else (80 if mode in ["end","space-between"] else (68 if mode=="space-around" else (64 if mode=="space-evenly" else (56 if mode=="stretch" else 32))))
		# space-around for two lines: offset12, second68.
		if mode=="space-around": y0 = 12
		check(is_equal_approx(r.slots[0].position.y,float(y0)) and is_equal_approx(r.slots[2].position.y,float(y2)),"line alignment "+mode)
	var items := [item(),item(),item(),item(),item()]
	var definition := Definition.resolve(3,null,[],"",[{},{},{},{},{}])
	check(not definition.has("error") and definition.rows.size()==2,"implicit row growth")
	for width in [320,620]:
		var r := Grid.layout(items,definition,Vector3(width,-1,0),Vector2(10,12),["stretch","stretch","start"],Vector2(640,480))
		var track: float = (width-20.0)/3
		check(is_equal_approx(r.columns[0],track) and is_equal_approx(r.slots[2].position.x,2*(track+10)) and r.slots[3].position==Vector3(0,32,0),"equal tracks and row-major "+str(width))
	definition = Definition.resolve(["100px","1fr","2fr"],null,[],"",[{},{},{}])
	var r := Grid.layout([item(),item(),item()],definition,Vector3(440,-1,0),Vector2(10,12),["stretch","stretch","start"],Vector2.ZERO)
	check(is_equal_approx(r.columns[0],100) and is_equal_approx(r.columns[1],320.0/3) and is_equal_approx(r.columns[2],640.0/3),"fixed100/1fr/2fr exact fractional tracks")
	var places := [{"area":"header"},{"area":"sidebar"},{"area":"main"}]
	definition = Definition.resolve(["220px","1fr"],["64px","1fr"],["header header","sidebar main"],"",places)
	var compact := Definition.resolve(null,null,[],"header header, 64px\nsidebar main, 1fr\n\\ 220px 1fr",places)
	check(definition==compact,"template canonical equivalence")
	var first := item(30,30)
	first.requested = Vector3(-1,-1,0)
	r = Grid.layout([first,first,first],definition,Vector3(600,400,0),Vector2(12,12),["stretch","stretch","start"],Vector2.ZERO)
	check(r.slots[0].extent==Vector3(600,64,0) and r.slots[2].position==Vector3(232,76,0) and r.slots[2].extent==Vector3(368,324,0),"named spans and physical cells")
	definition = Definition.resolve(3,null,[],"",[{}, {"row":0,"column":0,"column_span":2},{}])
	check(definition.placements[0].column==2 and definition.placements[2].row==1,"explicit before auto reservation")
	for bad in [0,-1,257,[],["0fr"],["-1fr"],["NaNfr"],["1em"],[-1],[INF]]: check(Definition.tracks(bad).has("error"),"invalid tracks "+str(bad))
	for places_bad in [[{"row":-1}],[{"row":0.5}],[{"row_span":0}],[{"column_span":4}],[{"area":"missing"}],[{"row":0,"column":0},{"row":0,"column":0}],[{"row":0,"area":"x"}]]:
		check(Definition.resolve(3,null,[],"",places_bad).has("error"),"placement rejection "+str(places_bad))
	check(Definition.resolve(1,1,[],"",[{},{}]).has("error"),"explicit finite rows reject overflow")
	check(Definition.resolve(2,2,["a a","a ."]).has("error"),"nonrectangle rejection")
	check(Definition.resolve(2,null,[],"a a\n\\ 1fr 1fr").has("error"),"template explicit ambiguity")
	check(Definition.resolve(null,null,[],"a a\n\\ 1fr 1fr\n\\ 1fr 1fr").has("error"),"duplicate column declaration")
	for areas in [["a a","a b"],["a","b b"],["a b","b a"]]: check(Definition.resolve(2,2,areas).has("error"),"malformed named area rectangle "+str(areas))
	check(Definition.resolve(2,null,[],"a a\n\\ 1fr 1fr").has("error"),"ambiguous template and explicit tracks")
	check(Definition.resolve(2,1,[],"",[{}, {}, {}]).has("error"),"explicit finite rows reject overflow")
	var span := item(180,60)
	span.placement = {"column_span":2,"row_span":2}
	definition = Definition.resolve(["auto","1fr"],null,[],"",[span.placement])
	r = Grid.layout([span],definition,Vector3(200,-1,0),Vector2(10,10),["stretch","stretch","start"],Vector2(1000,800))
	check(r.extent.y==60 and r.columns[0]==85 and r.columns[1]==105 and r.rows==[25.0,25.0],"spanning natural floor split and fractional remainder")
	definition = Definition.resolve(["25%","auto","1fr"],null,[],"",[{},{},{}])
	r = Grid.layout([item(),item(40),item()],definition,Vector3(400,-1,0),Vector2(10,0),["stretch","stretch","start"],Vector2.ZERO)
	check(r.columns==[100.0,40.0,240.0],"percentage parent content/fixed auto/fr ordering")
	for mode in ["start","center","end","stretch"]:
		var child := item(20,10)
		child.requested = Vector3(-1,-1,0)
		definition = Definition.resolve([100],[60],[],"",[{}])
		r = Grid.layout([child],definition,Vector3(100,60,0),Vector2.ZERO,[mode,mode,"start"],Vector2.ZERO)
		check(r.slots[0].extent==(Vector3(100,60,0) if mode=="stretch" else Vector3(20,10,0)) and r.slots[0].position==(Vector3(40,25,0) if mode=="center" else (Vector3(80,50,0) if mode=="end" else Vector3.ZERO)),"physical cell alignment "+mode)
	var parent := Core.new()
	parent.configure(Vector3(160,-1,0),0,false,1)
	parent.set_policy(["stretch","start","start"])
	var wrap := Core.new()
	wrap.configure(Vector3(-1,-1,0),10,false)
	wrap.set_strategy("wrap")
	wrap.physical_gaps = Vector2(10,12)
	var children: Array = []
	for index in range(3):
		var child := Core.new()
		child.configure(Vector3(70,20,0),0,false)
		children.append(child)
	wrap.set_children(children)
	parent.set_children([wrap])
	check(parent.measure()==Vector3(160,52,0),"nested allocated auto width remeasures wrap height in same core")
	parent.arrange(parent.measured)
	check(children[2].offset==Vector3(0,32,0),"nested arranged third child")
	var counts := [parent.measure_count,parent.arrange_count,wrap.measure_count,wrap.arrange_count]
	parent.measure()
	parent.arrange(parent.measured)
	check(counts==[parent.measure_count,parent.arrange_count,wrap.measure_count,wrap.arrange_count],"idle unchanged core quiet")
	var grid_core := Core.new()
	grid_core.configure(Vector3(320,100,0),10,false)
	grid_core.set_strategy("grid","start",{"columns":3})
	grid_core.set_policy(["stretch","stretch","start"])
	var percentage := Core.new()
	percentage.set_lengths({"width":Core.Length.parse("50%","extent"),"height":Core.Length.parse(20,"extent")},0,0,1,0)
	percentage.configure(Vector3(-1,20,0),0,false)
	grid_core.set_children([percentage])
	grid_core.measure()
	grid_core.arrange(Vector3(320,100,0))
	check(percentage.requested.x==160 and percentage.size.x==160,"Grid percent child uses immediate parent320, never cell100")
	var native_floor := item(20,20)
	native_floor.minimum = Vector3(180,60,0)
	definition = Definition.resolve(3,null,[],"",[{}])
	r = Grid.layout([native_floor],definition,Vector3(320,-1,0),Vector2(10,12),["stretch","stretch","start"],Vector2.ZERO)
	check(r.columns[0]==180 and r.columns[1]==60 and r.columns[2]==60 and r.rows[0]==60,"fraction water-fill honors authored/native floors without double shares")
	var margin_item := item(20,10)
	margin_item.outer = Vector3(10,6,0)
	margin_item.leading = Vector3(3,2,0)
	definition = Definition.resolve([100],[60],[],"",[{}])
	r = Grid.layout([margin_item],definition,Vector3(100,60,0),Vector2.ZERO,["center","end","start"],Vector2.ZERO)
	check(r.slots[0].position==Vector3(38,46,0),"cell physical align includes asymmetric leading/outer margins once")
	print("L0910_MATH_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L0910_MATH_OK")
	quit(1 if failed else 0)
