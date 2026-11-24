extends "game.gd"
func check(ok:bool,label:String):
	checks+=1;failed=failed or not ok;print("U04_NATIVE ",label,": ",ok)
func physical(bar:ScrollBar) -> Rect2: return Rect2(bar.position,bar.size*bar.scale)
func near_rect(a:Rect2,b:Rect2): return a.position.distance_to(b.position)<0.001 and a.size.distance_to(b.size)<0.001
func run(context:SceneTree):
	tree=context;root=tree.root;root.size=Vector2i(900,740)
	var entry=Entry.new();entry.width=900;entry.height=740;entry.padding=20;entry.direction="column"
	var body=box(400,300);body.direction="column";body.border_width=5;body.border_color="#ababab";body.padding=20;body.vertical_scroll=true;body.background_color="#383838";body.horizontal_scrollbar_height=16
	var teal={"track_color":"#202828","thumb_color":"#38a58c","thumb_hover_color":"#58c5ac","thumb_pressed_color":"#18856c"};body.scrollbar_style=teal
	var edge=ButtonScript.new();edge.width="100%";edge.height=44;edge.text="Full width / right edge";edge.pressed.connect(hit);body.add_child(edge)
	var wrap=box("100%","auto");wrap.wrap=true;wrap.gap=8
	for i in range(3):
		var item=ButtonScript.new();item.width=160;item.height=44;item.text="Action "+str(i);wrap.add_child(item)
	body.add_child(wrap)
	var nested=box("100%",80);nested.vertical_scroll=true
	var native=Button.new();native.text="Native nested content";native.custom_minimum_size=Vector2(150,240);native.pressed.connect(hit);nested.add_child(native);body.add_child(nested)
	var tall=box(600,500);tall.background_color="#537666";body.add_child(tall);entry.add_child(body)
	var unrelated=box(100,30);entry.add_child(unrelated);root.add_child(entry);await frames()
	var service=body._scroll;var bar=service._vertical
	check(service._clip.position==Vector2(25,25) and service._clip.size==Vector2(338,250) and edge.layout_size.x==338 and body.layout_size.x==400,"A content and owner unchanged")
	check(physical(bar)==Rect2(383,5,12,290) and bar.page==250,"A bar abuts border and spans top/bottom padding")
	await click(body.global_position+Vector2(369,40));check(hits==0 and body.scroll_offset==Vector2.ZERO,"old track band is padding, never content or bar hit")
	await click(edge.global_position+Vector2(336,22));check(hits==1,"right edge content remains clickable before padding gap")
	var thumb=body.global_position+Vector2(389,20);await hover(thumb)
	check((await pixel(thumb)).is_equal_approx(Color("#58c5ac")),"native hover in new top-padding track region")
	mouse(thumb,MOUSE_BUTTON_LEFT);await frames();check((await pixel(thumb)).is_equal_approx(Color("#18856c")),"native pressed skin at new coordinates")
	var motion=InputEventMouseMotion.new();motion.position=thumb+Vector2(0,45);motion.relative=Vector2(0,45);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion);await frames();mouse(motion.position,MOUSE_BUTTON_LEFT,false);await frames()
	check(body.scroll_offset.y>0 and hits==1,"native thumb drag at new border edge")
	body.scroll_offset=Vector2.ZERO;await click(body.global_position+Vector2(389,260));check(body.scroll_offset.y>0 and hits==1,"new border-edge track click scrolls without activating content")
	body.scroll_offset=Vector2.ZERO;body.horizontal_scroll=true;await frames()
	check(service._clip.size==Vector2(338,234) and physical(bar)==Rect2(383,5,12,274) and physical(service._horizontal)==Rect2(5,279,378,16) and Rect2(service._corner.position,service._corner.size)==Rect2(383,279,12,16),"B exact dual native clip/tracks/corner")
	check(bar.page==234 and service._horizontal.page==338 and body.scroll_range==Vector2(262,486),"B unchanged native page/range from V")
	await click(body.global_position+Vector2(300,286));check(body.scroll_offset.x>0 and hits==1,"horizontal track click beside bottom border")
	var offset=body.scroll_offset;await click(body.global_position+Vector2(389,286));check(hits==1 and body.scroll_offset==offset,"neutral corner neither content nor overlapping bars")
	body.vertical_scroll=false;await frames();check(not bar.visible and physical(service._horizontal)==Rect2(5,279,390,16) and service._clip.size==Vector2(350,234),"horizontal-only native track spans B width")
	body.horizontal_scroll=false;await frames();check(not bar.visible and not service._horizontal.visible and not service._corner.visible and service._clip.size==Vector2(350,250) and body.scroll_range==Vector2.ZERO,"disabled axes release gutters and physical chrome")
	body.vertical_scroll=true;body.scroll_offset=Vector2.ZERO;await frames()
	var geometry=service._geometry.duplicate(true);var samples=[]
	for amount in [0,body.scroll_range.y*0.5,body.scroll_range.y]:
		body.scroll_offset=Vector2(0,amount);await frames();await hover(Vector2.ZERO)
		var start=edge.global_position-body.global_position;var end=tall.global_position+tall.layout_size-body.global_position
		check(service._geometry==geometry and physical(bar)==Rect2(383,5,12,290) and service._clip.position==Vector2(25,25),"tracks and clip fixed at offset "+str(amount))
		check(near(start.y,25-amount) and service._content.position==Vector2(-25,-25-amount) and near(body.scroll_range.y,body.content_extent.y-250),"unchanged content translation and extent at "+str(amount))
		check((await pixel(body.global_position+Vector2(370,40))).is_equal_approx(Color("#383838")),"padding band stays background at "+str(amount))
		samples.append({"offset":amount,"first_top":start.y,"last_bottom":end.y,"clip":str(Rect2(service._clip.position,service._clip.size)),"vertical":str(physical(bar)),"range":body.scroll_range.y})
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://u04-offset-"+str(int(amount))+".png")
	check(near(samples[0].first_top,25) and near(samples[-1].last_bottom,275),"start/end contents align V edges; no moving inset bands added")
	body.scroll_offset=Vector2.ZERO;await frames();var point=nested.global_position+Vector2(30,30)
	mouse(point,MOUSE_BUTTON_WHEEL_DOWN);await frames();check(nested.scroll_offset.y==40 and body.scroll_offset.y==0,"nested wheel still chooses inner viewport")
	nested.scroll_offset=Vector2(0,nested.scroll_range.y);mouse(point,MOUSE_BUTTON_WHEEL_DOWN);await frames();check(body.scroll_offset.y==40,"exhausted nested viewport bubbles outer")
	var sibling_stats=unrelated.get_layout_stats();var identities=[body.get_instance_id(),edge.get_instance_id(),bar.get_instance_id()]
	body.width=360;await frames();check(wrap.layout_size.x==298 and wrap.layout_size.y==148 and body.scroll_range.y==body.content_extent.y-250 and physical(bar).position==Vector2(343,5),"responsive Wrap uses same reduced V while track follows border")
	check(sibling_stats==unrelated.get_layout_stats(),"unrelated sibling remains settled")
	var styles=service.style_updates;body.padding=24;await frames();check(physical(bar)==Rect2(343,5,12,290) and service._clip.position==Vector2(29,29) and service.style_updates==styles,"padding moves content only, no track/style churn")
	body.width=400;body.padding=20;await frames()
	for child in [wrap,nested,tall]: child.hide()
	await frames();check(not bar.visible and service._clip.size==Vector2(338,250) and body.scroll_range==Vector2.ZERO,"hidden no-overflow bar keeps same gutter")
	await click(body.global_position+Vector2(389,40));check(hits==1,"hidden track never clicks obscured authored content")
	for child in [wrap,nested,tall]: child.show()
	body.vertical_scrollbar_width=0;await frames();body.scroll_offset=Vector2(0,80);var programmatic=body.scroll_offset.y==80;mouse(body.global_position+Vector2(30,40),MOUSE_BUTTON_WHEEL_DOWN);await frames();check(not bar.visible and service._clip.size.x==350 and programmatic and body.scroll_offset.y==120,"zero has no physical track, wheel/programmatic scroll retained")
	body.vertical_scrollbar_width="5%";await frames();check(physical(bar)==Rect2(377.5,5,17.5,290) and service._clip.size.x==332.5 and body.vertical_scrollbar_width=="5%","percentage basis P350 retained at border position")
	var image=Image.create(2,2,false,Image.FORMAT_RGBA8);image.fill(Color("#edc957"));var skin=StyleBoxTexture.new();skin.texture=ImageTexture.create_from_image(image);skin.expand_margin_left=200;skin.content_margin_left=80
	body.scrollbar_style={"track_stylebox":skin,"thumb_stylebox":skin,"thumb_hover_stylebox":skin,"thumb_pressed_stylebox":skin};await frames();await hover(Vector2.ZERO)
	check(bar.get_theme_stylebox("scroll")==skin and near_rect(physical(bar),Rect2(377.5,5,17.5,290)),"custom texture/minimum retains identity within border strip")
	check((await pixel(body.global_position+Vector2(397,40))).is_equal_approx(Color("#ababab")) and (await pixel(body.global_position+Vector2(370,40)))!=Color("#edc957"),"custom expansion never paints over border or padding")
	body.vertical_scrollbar_width="150%";body.horizontal_scroll=true;body.horizontal_scrollbar_height="150%";await frames();check(service._clip.size==Vector2.ZERO and physical(bar)==Rect2(45,5,350,40) and physical(service._horizontal)==Rect2(5,45,40,250) and body.vertical_scrollbar_width=="150%","oversized thickness caps to P while physical chrome stays inside B")
	body.vertical_scrollbar_width="5%";body.scrollbar_style=teal;body.width=420;body.height=280;body.border_left_width=3;body.border_top_width=7;body.border_right_width=9;body.border_bottom_width=11;body.padding_left=13;body.padding_top=17;body.padding_right=19;body.padding_bottom=23;body.horizontal_scroll=true;body.horizontal_scrollbar_height="10%";await frames()
	check(near_rect(physical(bar),Rect2(392.2,7,18.8,239.8)) and near_rect(physical(service._horizontal),Rect2(3,246.8,389.2,22.2)) and near_rect(Rect2(service._clip.position,service._clip.size),Rect2(16,24,357.2,199.8)),"native asymmetric fractional rectangles match pure snapshot")
	var idle=[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates,body.lengths.parse_count];body.vertical_scrollbar_width="5%";await frames();check(idle==[body.get_layout_stats(),wrap.get_layout_stats(),service.style_updates,body.lengths.parse_count],"unchanged targets and idle do no layout/parse/skin work")
	check(identities==[body.get_instance_id(),edge.get_instance_id(),bar.get_instance_id()],"native identities retained through all runtime changes")
	body.width=8;body.height=7;body.padding=20;body.border_width=10;body.vertical_scrollbar_width="150%";body.horizontal_scrollbar_height="150%";await frames();check(not bar.visible and not service._horizontal.visible and service._clip.size==Vector2.ZERO,"tiny actual owner has no physical hit tracks or negative clip")
	entry.free();await frames()
	var persistent=Entry.new();persistent.width=400;persistent.height=300;persistent.name="Persistent";persistent.border_width=5;persistent.padding=20;persistent.vertical_scroll=true;persistent.horizontal_scroll=true;persistent.horizontal_scrollbar_height=16;persistent.scrollbar_style=teal
	var content=box(600,600);content.name="Content";persistent.add_child(content);content.owner=persistent;root.add_child(persistent);await frames();persistent.scroll_offset=Vector2(40,60)
	var packed=PackedScene.new();check(packed.pack(persistent)==OK and ResourceSaver.save(packed,"res://u04-pack.tscn")==OK,"padded native scroll scene packs")
	persistent.free();await frames();persistent=load("res://u04-pack.tscn").instantiate();root.add_child(persistent);await frames();check(persistent.get_layout_child("Content").owner==persistent and persistent.scroll_offset==Vector2(40,60) and physical(persistent._scroll._vertical)==Rect2(383,5,12,274),"scene reload retains owner/offset and new border-edge track")
	persistent.free();await frames()
	var host=load("res://app/generated/Scrollbars.gd").new();root.add_child(host);await frames()
	var inset=host.get_node("UI/InsetBody");var editor=inset.get_layout_child("Editor");editor.grab_focus();editor.get_focus_control().caret_column=3;inset.scroll_offset=Vector2(20,60)
	var ids=[inset.get_instance_id(),editor.get_instance_id(),inset._scroll._vertical.get_instance_id()]
	host.thickness="5%";await frames();check(inset._scroll._clip.size.x==332.5 and near_rect(physical(inset._scroll._vertical),Rect2(377.5,5,17.5,234)) and editor.has_focus() and editor.get_focus_control().caret_column==3 and inset.scroll_offset==Vector2(20,60),"GGX thickness re-render retains border geometry, caret/focus/offset")
	host.revision+=1;await frames();check(ids==[inset.get_instance_id(),editor.get_instance_id(),inset._scroll._vertical.get_instance_id()],"GGX unrelated re-render retains native chrome and inputs")
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://u04-ggx.png")
	host.free();await frames()
	var file=FileAccess.open("res://u04-padding-observations.json",FileAccess.WRITE);file.store_string(JSON.stringify(samples));file.close()
	return {"ok":not failed,"checks":checks}
