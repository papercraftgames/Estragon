extends RefCounted
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_SELECT ",label,": ",test)
func frames(tree):
	for i in range(8): await tree.process_frame
func key(tree,code):
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(tree)
func click(tree,point):
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down;Input.parse_input_event(event);await frames(tree)
func run(host):
	var tree=host.get_tree();await frames(tree)
	var select=host.get_node("UI/Select");var native=select.get_native_control();var popup=native.get_popup()
	var events:Array=[];select.value_changed.connect(func(a,b):events.append([a,b]))
	check(select.value=="explore" and native.selected==1 and native.text=="Explore" and events.is_empty(),"initial String projection has no fabricated change")
	check(select.layout_size.x==220 and select.layout_size.y<70 and select._select_options().size()==3,"nonvisual option records have no measured rows")
	select.value="";await frames(tree)
	check(native.selected==-1 and host.model.mode=="" and native.text==select.placeholder,"clear stays empty without forced first selection")
	select.grab_focus();await key(tree,KEY_SPACE)
	check(popup.visible,"actual native keyboard opens owned popup")
	await key(tree,KEY_HOME);await key(tree,KEY_ENTER)
	check(select.value=="build" and host.model.mode=="build" and not popup.visible,"popup keyboard selects String identity once")
	host.model.mode="explore";await frames(tree)
	var count:=events.size();var id:int=native.get_instance_id()
	host.items.move(1,0);await frames(tree)
	check(native.get_instance_id()==id and native.selected==0 and native.text=="Explore" and events.size()==count,"keyed reorder retains trigger and String authority")
	host.items.at(0).label="Explore renamed";await frames(tree)
	check(native.text=="Explore renamed" and events.size()==count,"label projection never edits value")
	host.items.at(0).hidden=true;await frames(tree)
	check(select.value=="explore" and native.selected==-1 and native.item_count==2,"hidden selected ID stays pending")
	host.items.at(0).hidden=false;await frames(tree)
	check(native.text=="Explore renamed" and native.selected==0,"eligible restored ID restores label")
	host.items.at(0).disabled=true;await frames(tree)
	check(native.selected==-1 and native.is_item_disabled(0) and select.value=="explore","disabled selected ID stays pending")
	host.items.at(0).disabled=false;await frames(tree)
	select.read_only=true;select.grab_focus();await key(tree,KEY_SPACE)
	check(select.has_focus() and not popup.visible and select.value=="explore","read-only retains native focus and prevents popup edits")
	select.read_only=false;select.disabled=true;select.grab_focus();await key(tree,KEY_SPACE)
	check(not select.has_focus() and not popup.visible,"disabled refuses focus and popup")
	select.disabled=false
	await click(tree,native.get_global_rect().get_center())
	check(popup.visible,"actual native pointer opens popup")
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png("res://select-popup.png")
	await click(tree,native.get_global_rect().position+Vector2(20,native.size.y+40))
	check(select.value=="build" and host.model.mode=="build" and not popup.visible,"actual native popup item pointer maps index to String ID")
	host.model.mode="explore";await frames(tree)
	select.grab_focus();await key(tree,KEY_SPACE)
	await key(tree,KEY_ESCAPE)
	check(not popup.visible and select.has_focus(),"Escape closes native popup and returns eligible focus")
	await click(tree,native.get_global_rect().get_center())
	host.items.move(0,1);await frames(tree)
	check(not popup.visible and native.get_instance_id()==id,"membership change closes old popup indices safely")
	var current_model=host.model
	select.grab_focus();await key(tree,KEY_SPACE)
	host.model=current_model.get_script().new();await frames(tree)
	check(not popup.visible and native.get_instance_id()==id,"same-valued source replacement closes popup and retains trigger")
	select.value="build";await frames(tree)
	check(host.model.mode=="build" and current_model.mode=="explore","replacement disconnects old String source writer")
	host.model.mode="pending";await frames(tree)
	check(native.selected==-1 and select.value=="pending","unknown String remains pending without fabricated selection")
	host.model.mode="explore";await frames(tree)
	var clip=host.get_node("UI/ClipRow/Clip")
	var clipped=clip.get_layout_child("ClippedSelect")
	var endpoint=clipped.get_native_control()
	await click(tree,endpoint.get_global_rect().get_center())
	check(endpoint.get_popup().visible,"native popup opens from nested padded scroll trigger")
	await key(tree,KEY_ESCAPE)
	clip.scroll_offset=Vector2(0,1000);await frames(tree)
	clipped.grab_focus()
	check(not clipped.has_focus() and not endpoint.get_popup().visible,"fully clipped Select cannot focus or open popup")
	clip.scroll_offset=Vector2.ZERO;await frames(tree)
	for width in [220,290]:
		clip.width=width;await frames(tree)
		check(endpoint.size.x==clipped.get_content_rect().size.x and clipped.layout_size.x==clip._scroll._clip.size.x,"nested percent/gutter trigger width "+str(width))
	await RenderingServer.frame_post_draw
	tree.root.get_texture().get_image().save_png("res://select-gallery.png")
	return {"ok":ok,"checks":checks}
