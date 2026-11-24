extends RefCounted
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Grid = preload("res://addons/estragon/runtime/node/grid.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Hosts = preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
var tree: SceneTree
var root: Window
var checks := 0
var failed := false
func check(value: bool,label: String):
	checks += 1;failed = failed or not value
	print("L12_NATIVE ",label,": ",value)
func near(a: float,b: float) -> bool: return absf(a-b)<0.01
func frames():
	for i in range(10): await tree.process_frame
func box(width: Variant="auto",height: Variant="auto"):
	var value=Box.new();value.width=width;value.height=height;return value
func run(context: SceneTree):
	tree = context;root = tree.root
	var records_before = State.records.keys()
	var controls_before = Hosts.controls.keys()
	root.size = Vector2i(640,800)
	var entry=Entry.new();entry.width=600;entry.height=700;entry.direction="column"
	var row=box(300,100);row.column_gap=20
	var a=box("25%",20);var b=box("75%",20)
	row.add_child(a);row.add_child(b);entry.add_child(row);root.add_child(entry);await frames()
	check(near(a.layout_size.x,70) and near(b.layout_size.x,210) and near(b.position.x,90),"real row 70/210 at0/90")
	check(a.width=="25%" and b.width=="75%","geometry never rewrites percentage targets")
	var identity=a.get_instance_id()
	var zero=box(0,0);row.add_child(zero);await frames()
	check(near(a.layout_size.x,65) and near(b.layout_size.x,195),"later participating sibling changes earlier budget")
	zero.hide();await frames()
	check(near(a.layout_size.x,70) and near(b.layout_size.x,210),"hidden child removes its gap from stack budget")
	zero.show();await frames();row.move_child(b,0);await frames()
	check(near(a.position.x,215) and a.get_instance_id()==identity,"native reorder updates slots, retains Node")
	zero.free();await frames();row.move_child(a,0);await frames()
	var parse=a.lengths.parse_count
	a.width="250px";await frames()
	check(a.width=="250px" and near(a.layout_size.x,250),"runtime px setter applies latest retained target")
	a.width=250;await frames()
	check(a.width is int and near(a.layout_size.x,250),"runtime numeric target retains type")
	a.width="25%";await frames()
	check(a.width=="25%" and near(a.layout_size.x,70) and a.lengths.parse_count==parse+3,"px numeric percent parse once each")
	a.width="auto";await frames()
	check(a.width=="auto" and near(a.layout_size.x,0),"auto restores natural target")
	a.width="25%";await frames()
	var before=[row.get_layout_stats(),a.get_layout_stats(),a.lengths.parse_count,a.layout.model.resolution_count]
	a.width="25%";await frames()
	check(before==[row.get_layout_stats(),a.get_layout_stats(),a.lengths.parse_count,a.layout.model.resolution_count],"same target and settled idle do no work")
	var notifications: Array=[]
	row.layout_applied.connect(func(size): notifications.append(size))
	row.invalidate_layout();await frames()
	check(not notifications.is_empty() and row.layout_size==Vector2(300,100),"layout_applied remains arrangement completion, not size-changed")
	var calls: Array=[]
	var react: Callable=func(_size):
		if calls.is_empty(): calls.append(true);a.width=150
	row.layout_applied.connect(react)
	var flushes=entry.layout.flush_count
	row.invalidate_layout();await frames();row.layout_applied.disconnect(react)
	check(calls.size()==1 and a.width==150 and near(a.layout_size.x,150) and entry.layout.flush_count==flushes+2,"reentrant target change gets exactly one genuine follow-up flush")
	# Independent axes / native floors and no invisible shrink.
	var native=Button.new();native.custom_minimum_size=Vector2(120,30);row.add_child(native);a.width="25%";await frames()
	check(native.size.x>=120 and near(a.layout_size.x,65),"native Control floor does not rebase ratio into leftover space")
	native.hide();await frames();check(near(a.layout_size.x,70),"hidden native Control is nonparticipating")
	native.free()
	# Fractional viewport versus intrinsic auto rows, using the same Grid policy.
	for explicit in [false,true]:
		var grid=Grid.new();grid.width=300;grid.height=200
		if explicit: grid.rows=["auto","1fr"]
		var header=box("auto",30);grid.add_child(header)
		var body=box();body.direction="column";body.vertical_scroll=true
		var tall=box("auto",300);body.add_child(tall)
		var grow=box();grow.grow=1;body.add_child(grow);grid.add_child(body);entry.add_child(grid);await frames()
		check(near(body.layout_size.y,170 if explicit else 300) and near(body.scroll_range.y,130 if explicit else 0),"fr bounded viewport vs intrinsic auto row "+str(explicit))
		check(near(grow.layout_size.y,0),"overflow has no positive growth remainder "+str(explicit))
		if explicit:
			check(body._scroll._vertical.visible and body._scroll._clip.size==body.get_content_rect().size-Vector2(12,0),"bounded viewport native bar/clip geometry")
			body.scroll_offset=Vector2(0,80);await frames()
			check(near(body.scroll_offset.y,80) and body._scroll._content.position.y==-body.get_content_rect().position.y-80,"bounded native scroll translation")
			tall.free();await frames()
			check(near(grow.layout_size.y,170) and near(body.scroll_range.y,0),"empty grow consumes actual viewport remainder once")
			var percent=box("auto","100%");grow.add_child(percent);await frames()
			check(near(percent.layout_size.y,170),"grow actual size is its own descendant reference inside scroll")
		grid.free();await frames()
	entry.free();await frames()
	# Authored Gogo layout declarations and transparent managed roots.
	var host=load("res://app/generated/Layout.gd").new()
	var borrowed=Button.new();borrowed.text="Borrowed native Control";host.add_child(borrowed);borrowed.owner=host;host.borrowed=borrowed
	root.add_child(host);root.size=Vector2i(340,720);await frames()
	var grid=host.get_node("UI/Grid")
	var panel=grid.get_node("Panel")
	var body=panel.get_node("Body")
	var nested=body.get_node("Nested")
	check(borrowed.get_parent()==host and borrowed.owner==host and Hosts.projected_parent(borrowed)==host.get_node("UI"),"borrowed native Control keeps actual parent/owner with logical flow")
	var scope=State.records[host.get_instance_id()]
	var panel_scope=State.records[panel.get_instance_id()]
	check(near(body.layout_size.x,210) and near(nested.layout_size.x,160) and near(grid.get_node("Side").layout_size.x,70),"layout const Grid + transparent Body210 -> nested160")
	check(nested.width=="100%" and near(nested.get_node("ThreeQuarters").layout_size.x,120),"nested Wrap uses immediate actual content")
	var bridge_row=box(300,30);bridge_row.column_gap=20
	var quarter=box("25%",20);bridge_row.add_child(quarter)
	var bridge_host=panel.get_script().new();bridge_row.add_child(bridge_host);var bridge_entry=Entry.new();bridge_entry.width=300;bridge_entry.height=200;bridge_entry.add_child(bridge_row);root.add_child(bridge_entry);await frames()
	check(near(quarter.layout_size.x,70),"visible transparent participant contributes one stack gap")
	bridge_host.get_node("Body").hide();await frames()
	check(near(quarter.layout_size.x,75),"hidden managed root removes transparent participant gap")
	bridge_host.get_node("Body").show();await frames()
	check(near(quarter.layout_size.x,70),"restored managed root reattaches transparent participant")
	bridge_entry.free();await frames()
	var ids=[body.get_instance_id(),nested.get_instance_id()]
	body.width="250px";await frames();host.revision+=1;await frames()
	check(body.width=="250px" and near(body.layout_size.x,250) and panel_scope.runs>1,"unchanged GGX target preserves intervening imperative width during rerender")
	host.target="60%";await frames()
	check(body.width=="60%" and near(body.layout_size.x,168) and near(nested.layout_size.x,118),"genuinely changed GGX target60% applies once")
	var runs=[scope.runs,panel_scope.runs]
	root.size=Vector2i(640,800);await frames()
	check(body.width=="60%" and near(body.layout_size.x,348) and near(nested.layout_size.x,298) and runs==[scope.runs,panel_scope.runs],"viewport invalidates contexts without GGX rerender or target writeback")
	check(ids==[body.get_instance_id(),nested.get_instance_id()],"native identities retained across target and viewport updates")
	host.target="75%";await frames()
	for size in [Vector2i(640,800),Vector2i(900,850)]:
		root.size=size;await frames();await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://proportions-"+str(size.x)+".png")
	var counts=[scope.runs,panel_scope.runs,grid.get_layout_stats(),body.get_layout_stats(),nested.get_layout_stats(),body.lengths.parse_count,body.layout.model.resolution_count]
	await frames()
	check(counts==[scope.runs,panel_scope.runs,grid.get_layout_stats(),body.get_layout_stats(),nested.get_layout_stats(),body.lengths.parse_count,body.layout.model.resolution_count],"settled native layout/composition/cache idle is quiet")
	host.free();await frames()
	check(State.records.keys()==records_before and Hosts.controls.keys()==controls_before,"teardown releases composition and borrowed/native adapters")
	print("L12_NATIVE_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L12_NATIVE_OK")
	return {"ok":not failed,"checks":checks}
