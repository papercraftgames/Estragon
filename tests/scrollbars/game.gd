extends RefCounted
const Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box=preload("res://addons/estragon/runtime/node/box.gd")
const ButtonScript=preload("res://addons/estragon/runtime/node/button.gd")
const InputScript=preload("res://addons/estragon/runtime/node/input.gd")
var tree: SceneTree
var root: Window
var checks:=0
var failed:=false
var hits:=0
func check(ok:bool,label:String):
	checks+=1;failed=failed or not ok;print("U03_NATIVE ",label,": ",ok)
func frames():
	for i in range(8): await tree.process_frame
func box(w="auto",h="auto"):
	var result=Box.new();result.width=w;result.height=h;return result
func near(a,b): return absf(a-b)<0.01
func hit(): hits+=1
func hover(point:Vector2):
	var motion=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true);await frames()
func pixel(point:Vector2):
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().get_pixelv(Vector2i(point))
func mouse(point:Vector2,button:int,pressed=true,shift=false):
	var e=InputEventMouseButton.new();e.position=point;e.button_index=button;e.pressed=pressed;e.shift_pressed=shift;root.push_input(e,true)
func click(point:Vector2):
	mouse(point,MOUSE_BUTTON_LEFT);await frames();mouse(point,MOUSE_BUTTON_LEFT,false);await frames()
func run(context:SceneTree):
	tree=context;root=tree.root;root.size=Vector2i(640,700)
	var entry=Entry.new();entry.width=640;entry.height=700;entry.padding=20;entry.direction="column"
	var body=box(400,300);body.direction="column";body.vertical_scroll=true;body.horizontal_scroll=true;body.vertical_scrollbar_width="5%";body.horizontal_scrollbar_height="10%";body.background_color="#383838"
	var wrap=box("100%","auto");wrap.wrap=true;wrap.column_gap=8;wrap.row_gap=8
	for i in range(3):
		var button=ButtonScript.new();button.width=186;button.height=44;button.text="Right edge "+str(i);button.pressed.connect(hit);wrap.add_child(button)
	var nested=box("100%",100);nested.direction="column";nested.vertical_scroll=true;nested.background_color="#535353"
	var native=Button.new();native.text="Native clipped content";native.custom_minimum_size=Vector2(150,300);native.pressed.connect(hit);nested.add_child(native)
	var input=InputScript.new();input.width="100%";input.value="Retain caret and focus"
	var tall=box(600,500);tall.background_color="#537666"
	body.add_child(wrap);body.add_child(input);body.add_child(nested);body.add_child(tall);entry.add_child(body);root.add_child(entry);await frames()
	var service=body._scroll;var geometry=body.layout.model.scroll_geometry
	check(body.layout_size==Vector2(400,300) and service._clip.size==Vector2(380,270) and wrap.layout_size.x==380,"dual native viewport and full width wrap380")
	check(wrap.layout_size.y==96 and body.scroll_range.y==body.content_extent.y-270,"post-gutter wrap extent drives range")
	check(service._vertical.size*service._vertical.scale==Vector2(20,270) and service._horizontal.size*service._horizontal.scale==Vector2(380,30) and service._corner.size==Vector2(20,30),"native track transforms and corner exact")
	check(service._vertical.page==270 and service._horizontal.page==380 and service._vertical.max_value==body.content_extent.y,"native proportional page/max")
	check(service._vertical.get_theme_stylebox("scroll").bg_color==Color("#292929") and service._vertical.get_theme_stylebox("grabber").corner_radius_top_left==0,"neutral square default")
	var state_idle=[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates]
	var thumb_point=service._vertical.global_position+Vector2(10,15)
	await hover(Vector2.ZERO);check((await pixel(thumb_point)).is_equal_approx(Color("#727272")),"rendered default thumb neutral")
	await hover(thumb_point);check((await pixel(thumb_point)).is_equal_approx(Color("#919191")),"rendered native hover state")
	mouse(thumb_point,MOUSE_BUTTON_LEFT);await frames();check((await pixel(thumb_point)).is_equal_approx(Color("#aaaaaa")),"rendered native pressed state");mouse(thumb_point,MOUSE_BUTTON_LEFT,false);await frames()
	check(state_idle==[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates],"native hover/press does no layout or skin rebuild")
	var right=wrap.get_layout_children()[1];await click(right.global_position+Vector2(180,22));await frames();check(hits==1,"right aligned edge remains clickable beside gutter")
	await click(body.global_position+Vector2(390,250));await frames();check(body.scroll_offset.y>0 and hits==1,"native vertical track click does not click authored content")
	body.scroll_offset=Vector2.ZERO
	# Drag the actual native thumb through delivered mouse events.
	var bar=service._vertical;var point=bar.global_position+Vector2(10,15)
	mouse(point,MOUSE_BUTTON_LEFT);await frames();body.vertical_scrollbar_width=18;await frames();var motion=InputEventMouseMotion.new();motion.position=point+Vector2(0,35);motion.relative=Vector2(0,35);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;root.push_input(motion,true);await frames();mouse(motion.position,MOUSE_BUTTON_LEFT,false);await frames()
	check(body.scroll_offset.y>0 and hits==1,"native thumb drag survives thickness change without content activation");body.vertical_scrollbar_width="5%";await frames()
	body.vertical_scrollbar_width=24;await frames();check(wrap.layout_size.y==148 and body.scroll_range.y==body.content_extent.y-270,"narrow gutter triggers bounded rewrap and updated range");body.vertical_scrollbar_width="5%";await frames()
	body.scroll_offset=Vector2.ZERO
	mouse(body.global_position+Vector2(30,30),MOUSE_BUTTON_WHEEL_DOWN,true,true);await frames();check(body.scroll_offset.x==40 and body.scroll_offset.y==0,"Shift wheel horizontal")
	body.scroll_offset=Vector2.ZERO
	var pan=InputEventPanGesture.new();pan.position=body.global_position+Vector2(30,30);pan.delta=Vector2(1,1);root.push_input(pan,true);await frames();check(body.scroll_offset==Vector2(40,40),"pan both axes")
	body.scroll_offset=Vector2.ZERO
	var np=nested.global_position+Vector2(30,30);mouse(np,MOUSE_BUTTON_WHEEL_DOWN);await frames();check(nested.scroll_offset.y==40 and body.scroll_offset.y==0,"nested wheel chooses inner viewport")
	nested.scroll_offset=Vector2(0,nested.scroll_range.y);mouse(np,MOUSE_BUTTON_WHEEL_DOWN);await frames();check(body.scroll_offset.y==40 and nested.scroll_offset.y==nested.scroll_range.y,"nested exhaustion bubbles outer")
	body.scroll_offset=Vector2.ZERO
	var identities=[body.get_instance_id(),wrap.get_instance_id(),bar.get_instance_id()]
	var before=[body.get_layout_stats(),wrap.get_layout_stats()]
	var custom=StyleBoxFlat.new();custom.bg_color=Color("#cb794f");custom.content_margin_left=60
	body.scrollbar_style={"track_color":"#202020","thumb_color":"#cccccc","thumb_hover_color":"#eeeeee","thumb_pressed_color":"#ffffff","horizontal":{"thumb_color":"#aaaaaa"},"vertical":{"thumb_stylebox":custom}}
	await frames()
	check(before==[body.get_layout_stats(),wrap.get_layout_stats()] and bar.get_theme_stylebox("grabber")==custom,"style-only avoids layout and preserves explicit Resource")
	check(bar.size.x*bar.scale.x<=20.01 and bar.position.x==380,"explicit native minimum stays inside assigned strip")
	check(service._horizontal.get_theme_stylebox("grabber").bg_color==Color("#aaaaaa") and bar.get_theme_stylebox("grabber_highlight").bg_color==Color("#eeeeee"),"axis and interactive state overrides")
	custom.bg_color=Color("#ffcf99");custom.content_margin_left=80;await frames();check(bar.get_theme_stylebox("grabber")==custom and bar.size.x*bar.scale.x<=20.01 and before==[body.get_layout_stats(),wrap.get_layout_stats()],"live Resource edits stay native without child layout")
	var idle=[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates,body.lengths.parse_count]
	body.scrollbar_style=body.scrollbar_style;body.vertical_scrollbar_width="5%";await frames();check(idle==[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates,body.lengths.parse_count],"same targets and idle quiet")
	for target in [12,"5%",0,12]:
		body.scrollbar_size=target;body.vertical_scrollbar_width="auto";body.horizontal_scrollbar_height="auto";body.scroll_offset=Vector2(50,80);await frames()
		var thickness=20 if target is String else target
		check(is_same(body.scrollbar_size,target) and near(wrap.layout_size.x,400-thickness) and body.scroll_offset.y==80 and body.scroll_offset.x<=body.scroll_range.x,"runtime retained target, width and offset "+str(target))
		if target is int and target==0: check(not bar.visible and body.scroll_range.y>0,"zero removes bar only")
	check(identities==[body.get_instance_id(),wrap.get_instance_id(),bar.get_instance_id()],"native identities retained")
	body.vertical_scrollbar_width="150%";await frames();check(service._clip.size.x==0 and body.vertical_scrollbar_width=="150%" and body.layout_size.x==400,"huge target caps actual strip without growing owner")
	body.vertical_scrollbar_width="auto";body.horizontal_scroll=false;body.vertical_scroll=false;body.clip_content=true;await frames();check(service._clip.size==Vector2(400,300) and body.scroll_range==Vector2.ZERO,"clip alone releases both gutters")
	body.vertical_scroll=true;body.horizontal_scroll=true;await frames()
	for child in body.get_layout_children(): child.hide()
	await frames();check(not bar.visible and not service._horizontal.visible and service._clip.size==Vector2(388,288),"range zero hides bars but keeps stable gutters")
	check(not service.pointer_allowed(body.global_position+Vector2(395,50)),"hidden gutter never routes authored input")
	for child in body.get_layout_children(): child.show()
	body.horizontal_scroll=false;body.padding=20;body.border_width=5;body.vertical_scrollbar_width="5%";var quarter=box("75%",10);body.add_child(quarter);await frames();check(near(quarter.layout_size.x,249.375) and near(service._clip.size.x,332.5),"real inset percentage child249.375")
	body.width=210;body.border_width=0;body.vertical_scrollbar_width=12;await frames();check(wrap.layout_size.x==158,"Body210 padding20 -> wrap158")
	body.width=400;body.padding=0;body.vertical_scrollbar_width=12;body.scrollbar_style={};await frames()
	for size in [Vector2i(640,700),Vector2i(900,800)]:
		root.size=size;await frames();await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://scrollbars-"+str(size.x)+".png")
	# Native persistent scene keeps user targets, resources and owners.
	var persistent=box(210,100);persistent.name="Persistent";persistent.vertical_scroll=true;persistent.scrollbar_size="5%";persistent.scrollbar_style={"thumb_stylebox":custom};var content=box("100%",300);content.name="Content";persistent.add_child(content);content.owner=persistent;entry.add_child(persistent);await frames();persistent.scroll_offset=Vector2(0,60)
	var packed=PackedScene.new();check(packed.pack(persistent)==OK and ResourceSaver.save(packed,"res://u03-pack.tscn")==OK,"native scene packs")
	persistent.free();await frames();persistent=load("res://u03-pack.tscn").instantiate();entry.add_child(persistent);await frames();check(persistent.get_layout_child("Content")!=null and persistent.get_layout_child("Content").owner==persistent and persistent.scrollbar_size=="5%" and persistent.scroll_offset.y==60,"native scene reload retains owner target and offset")
	entry.free();await frames()
	return {"ok":not failed,"checks":checks}
