extends RefCounted
const Compiler=preload("res://addons/estragon/compiler/compiler.gd")
const State=preload("res://addons/estragon/runtime/composition/state.tres")
var tree: SceneTree
var root: Window
var checks:=0
var failed:=false
func check(ok:bool,label:String): checks+=1;failed=failed or not ok;print("U03_RETAIN ",label,": ",ok)
func frames():
	for i in range(8): await tree.process_frame
func run(context: SceneTree, negatives:bool=true):
	tree=context;root=tree.root
	var host=load("res://app/generated/Scrollbars.gd").new();root.add_child(host);await frames()
	var body=host.get_node("UI/Body");var record=State.records[host.get_instance_id()];var wrap=body.get_layout_child("Wrapped").get_node("Panel")
	check(wrap.layout_size.x==388,"transparent Gogo root gets post-gutter reference")
	var input=body.get_layout_child("Editor");input.grab_focus();input.get_focus_control().caret_column=4;body.scroll_offset=Vector2(20,60)
	host.thickness="5%";await frames();check(wrap.layout_size.x==380 and input.has_focus() and input.get_focus_control().caret_column==4 and body.scroll_offset==Vector2(20,60),"reactive target retains native input focus caret and offsets")
	body.scrollbar_size=16;host.revision+=1;await frames();check(body.scrollbar_size==16 and host.get_node("UI/Body")==body,"unchanged GGX desired thickness preserves imperative override")
	host.thickness=12;await frames();check(body.scrollbar_size==12,"genuinely changed desired thickness applies")
	var resource=StyleBoxFlat.new();host.chrome={"scrollbar_style":{"thumb_stylebox":resource},"vertical_scrollbar_width":20};await frames();check(body._scroll._vertical.get_theme_stylebox("grabber")==resource and wrap.layout_size.x==380,"GGX explicit StyleBox identity and axis override")
	host.chrome={};await frames();check(body.scrollbar_style=={} and body.vertical_scrollbar_width=="auto" and wrap.layout_size.x==388,"omission restores previously GGX-owned class defaults")
	body.scrollbar_style={"thumb_color":"#ededed"};host.revision+=1;await frames();check(body.scrollbar_style=={"thumb_color":"#ededed"},"unowned imperative style survives unrelated recompose")
	if not negatives:
		host.free();await frames();return {"ok":not failed,"checks":checks}
	for props in [{"scrollbar_size":"auto"},{"vertical_scrollbar_width":-1},{"horizontal_scrollbar_height":NAN},{"scrollbar_style":{"unknown":0}},{"scrollbar_style":{"vertical":{"horizontal":{}}}},{"scrollbar_style":{"thumb_color":false}},{"scrollbar_style":{"thumb_stylebox":false}}]:
		print("U03_EXPECTED_BEGIN");host.chrome=props;await frames();print("U03_EXPECTED_END")
		check(host.get_node("UI/Body")==body and not record.validation_error.is_empty() and record.validation_error.contains("app/Scrollbars.gogo:"),"preflight rejects whole desired tree "+str(props))
		host.chrome={};await frames();check(record.validation_error.is_empty(),"repair succeeds without replacing nodes")
	for pair in [["scrollbar_size",-1],["scrollbar_size","auto"],["vertical_scrollbar_width",INF],["horizontal_scrollbar_height","calc(1px)"],["scrollbar_style",{"track_color":Color(INF,0,0)}]]:
		var before=body.get(pair[0]);print("U03_EXPECTED_BEGIN");body.set(pair[0],pair[1]);await frames();print("U03_EXPECTED_END");check(body.get(pair[0])==before,"native invalid setter atomic "+pair[0])
	for attributes in ['scrollbar_size="auto"','vertical_scrollbar_width="-1px"','horizontal_scrollbar_height="3em"','scrollbar_style="invalid"']:
		var result=Compiler.compile('extends Node2D\nconst Box=preload("res://addons/estragon/runtime/node/box.gd")\nfunc view(): return <Box '+attributes+' />\n',"app/Bad.gogo","res://app/generated/Bad.gd")
		check(not result.ok and result.diagnostics[0].span.start.line==3,"compiler authored-span invalid "+attributes)
	host.free();await frames()
	return {"ok":not failed,"checks":checks}
