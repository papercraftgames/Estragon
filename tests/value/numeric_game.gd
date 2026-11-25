extends RefCounted
const Contract=preload("res://addons/estragon/runtime/node/internal/numeric_contract.gd")
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_NUMERIC ",label,": ",test)
func near(a,b): return absf(float(a)-float(b))<1e-7
func frames(tree):
	for i in range(8): await tree.process_frame
func key(tree,code,unicode_value:int=0):
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.unicode=unicode_value if down else 0;event.pressed=down;Input.parse_input_event(event);await frames(tree)
func mouse(tree,point,down):
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=down;Input.parse_input_event(event);await frames(tree)
func click(tree,point): await mouse(tree,point,true);await mouse(tree,point,false)
func run(host):
	var tree=host.get_tree();await frames(tree)
	var h=host.get_node("UI/Ranges").get_child(0).get_node("Horizontal")
	var n=host.get_node("UI/Ranges").get_child(0).get_node("Number")
	var integer=host.get_node("UI/Ranges").get_child(0).get_node("Integer")
	var v=host.get_node("UI/Ranges/Vertical")
	var hn=h.get_native_control();var vn=v.get_native_control();var spin=n.get_native_control();var line=n.get_focus_control()
	check(hn is HSlider and vn is VSlider and spin is SpinBox,"actual horizontal/vertical Range and SpinBox delegates")
	check(near(h.value,0.5) and near(v.value,0.5) and near(n.value,0.5) and integer.value==3 and typeof(integer.value)==TYPE_INT,"initial exact float/int projection")
	check(hn.position==h.get_content_rect().position and hn.size==h.get_content_rect().size and vn.size==v.get_content_rect().size,"native endpoints occupy host content rect on both physical axes")
	var events:Array=[];var writes:Array=[]
	h.value_changed.connect(func(a,b):events.append([a,b]));host.model.volume_changed.connect(func(a,b):writes.append([a,b]))
	h.value=0.76;await frames(tree)
	check(near(h.value,0.75) and near(host.model.volume,0.75) and near(v.value,0.75) and near(n.value,0.75) and events.size()==1 and writes.size()==1,"programmatic float setter snaps once and synchronizes exact model/peers")
	h.value=0.751;await frames(tree)
	check(events.size()==1 and writes.size()==1,"same canonical value is quiet")
	host.model.volume=0.25;await frames(tree)
	check(events.size()==2 and writes.size()==2 and near(hn.value,0.25),"model projection notifies once without source feedback")
	h.grab_focus();await key(tree,KEY_RIGHT)
	check(near(host.model.volume,0.3) and near(v.value,0.3),"horizontal native keyboard edits float model")
	v.grab_focus();await key(tree,KEY_UP)
	check(near(host.model.volume,0.35) and near(h.value,0.35),"vertical native keyboard edits same float model")
	await key(tree,KEY_HOME)
	check(near(v.value,0.0),"vertical native Home chooses minimum")
	await key(tree,KEY_END)
	check(near(v.value,1.0),"vertical native End chooses maximum")
	await click(tree,hn.get_global_rect().position+Vector2(8,hn.size.y*0.5))
	check(h.value<=0.1 and near(host.model.volume,h.value),"horizontal track pointer edits real native Range")
	await click(tree,vn.get_global_rect().position+Vector2(vn.size.x*0.5,8))
	check(v.value>=0.9 and near(h.value,v.value),"vertical track pointer edits opposite physical axis")
	var center=hn.get_global_rect().get_center()
	await mouse(tree,center,true)
	var motion:=InputEventMouseMotion.new();motion.position=hn.get_global_rect().end-Vector2(8,hn.size.y*0.5);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(motion);await frames(tree)
	await mouse(tree,motion.position,false)
	check(h.value>=0.9 and near(v.value,h.value),"horizontal native drag/capture synchronizes peer")
	host.model.volume=0.5;await frames(tree)
	n.grab_focus();line.select_all()
	await key(tree,KEY_MINUS,45)
	check(near(host.model.volume,0.5) and line.text=="-","partial minus stays native text without publishing invalid model")
	var caret:int=line.caret_column
	host.revision+=1;await frames(tree)
	check(line.text=="-" and line.caret_column==caret and n.has_focus(),"unrelated Gogo render retains partial edit/caret/native focus")
	await key(tree,KEY_ESCAPE)
	check(near(n.value,0.5) and not n.has_focus() and line.text!="-","Escape reverts partial edit and releases focus")
	n.grab_focus();line.select_all()
	for code in [KEY_0,KEY_PERIOD,KEY_7,KEY_5]: await key(tree,code,code if code!=KEY_PERIOD else 46)
	await key(tree,KEY_ENTER)
	check(near(n.value,0.75) and near(host.model.volume,0.75) and near(h.value,0.75),"native SpinBox Enter applies valid decimal transaction")
	integer.grab_focus();var iline=integer.get_focus_control();iline.select_all();await key(tree,KEY_7,55);await key(tree,KEY_ENTER)
	check(integer.value==7 and host.model.lives==7 and typeof(integer.value)==TYPE_INT,"IntegerInput publishes exact int from native editing")
	var icount:=0;var integer_events:Array=[];integer.value_changed.connect(func(a,b):integer_events.append([a,b]))
	integer.value=8;integer.value=8;await frames(tree)
	check(integer_events==[[7,8]] and host.model.lives==8,"integer programmatic notification/equality uses same binding")
	n.read_only=true;n.grab_focus();line.select_all();await key(tree,KEY_9,57);await key(tree,KEY_ENTER)
	check(n.has_focus() and near(n.value,0.75) and line.text!="9","read-only native editor permits focus/selection but no edits")
	n.read_only=false;n.disabled=true;n.grab_focus();await key(tree,KEY_UP)
	check(not n.has_focus() and near(n.value,0.75),"disabled numeric editor refuses focus/edits")
	n.disabled=false
	h.read_only=true;h.grab_focus();await key(tree,KEY_LEFT);await click(tree,hn.get_global_rect().position+Vector2(8,8))
	check(near(h.value,0.75),"read-only Slider does not commit pointer or key changes")
	h.read_only=false
	h.grab_focus();var hid:int=h.get_instance_id();var old:WeakRef=weakref(hn)
	h.orientation="vertical";await frames(tree)
	check(h.get_instance_id()==hid and old.get_ref()==null and h.get_native_control() is VSlider and h.has_focus(),"runtime orientation retains host, replaces only private endpoint and transfers focus")
	h.orientation="horizontal";await frames(tree)
	var repaired:Callable=func(_previous,next):
		if near(next,0.8): host.model.volume=0.5
	host.model.volume_changed.connect(repaired);h.value=0.8;await frames(tree)
	check(near(h.value,0.5) and near(v.value,0.5) and near(host.model.volume,0.5),"numeric reentrant model repair wins without projection echo")
	host.model.volume_changed.disconnect(repaired)
	var snapshot=host.get_node("UI/Snapshot")
	snapshot.value=0.25;await frames(tree)
	check(near(host.model.volume,0.5) and near(snapshot.value,0.25),"numeric local snapshot has no implicit writer")
	host.revision+=1;await frames(tree)
	check(near(snapshot.value,0.5),"snapshot reprojects canonical model on relevant render")
	var integer_native=integer.get_native_control()
	await click(tree,integer_native.get_global_rect().position+Vector2(integer_native.size.x-5,integer_native.size.y*0.25))
	check(integer.value==9 and host.model.lives==9,"actual native SpinBox increment button publishes one integer step")
	var old_model=host.model
	host.model=old_model.get_script().new();await frames(tree)
	h.value=0.65;await frames(tree)
	check(near(host.model.volume,0.65) and near(old_model.volume,0.5),"float source replacement disconnects stale model")
	integer.value=9;await frames(tree)
	check(host.model.lives==9 and old_model.lives==9,"int source replacement disconnects stale model")
	var clip=host.get_node("UI/ClipRow/Clip")
	var clipped=clip.get_layout_child("ClippedSlider")
	check(not preload("res://addons/estragon/runtime/node/internal/focus.tres").eligible(clipped.get_focus_control()),"fully clipped Slider is ineligible")
	clip.scroll_offset=Vector2(0,1000);await frames(tree)
	clipped.grab_focus();await key(tree,KEY_RIGHT)
	check(clipped.has_focus() and near(clipped.value,0.55),"scroll reveal enables actual Slider native keyboard")
	clip.scroll_offset=Vector2.ZERO;await frames(tree)
	check(not clipped.has_focus(),"clipped movement releases stale native Slider focus")
	var packed:=PackedScene.new()
	var editor_flag:=OS.get_environment("UI05_EDITOR");OS.set_environment("UI05_EDITOR","0")
	check(packed.pack(host)==OK,"value gallery packs authored host without private delegates")
	var reopened=packed.instantiate();tree.root.add_child(reopened);OS.set_environment("UI05_EDITOR",editor_flag);await frames(tree)
	var reopened_h=reopened.get_node("UI/Ranges").get_child(0).get_node("Horizontal")
	check(reopened_h.value==0.5 and reopened_h.get_child_count(true)==1 and reopened_h.get_native_control().owner==null,"pack/reopen reconstructs one native endpoint and authored default")
	reopened.free();await frames(tree)
	var scope=preload("res://addons/estragon/runtime/composition/state.tres").records[host.get_instance_id()]
	var runs:int=scope.runs;var measures:int=h.layout.model.measure_count
	for i in range(10): h.value=h.value
	await frames(tree)
	check(scope.runs==runs and h.layout.model.measure_count==measures,"equal writes/idle perform no render or layout work")
	var standalone=preload("res://addons/estragon/runtime/node/number_input.gd").new()
	host.get_node("UI").add_child(standalone)
	var coherent:Array=[]
	standalone.value_changed.connect(func(_a,_b): coherent.append(standalone.get_native_control().value==standalone.value and standalone.get_native_control().min_value==standalone.min_value and standalone.get_native_control().max_value==standalone.max_value))
	var range_events:Array=[];standalone.value_changed.connect(func(a,b):range_events.append([a,b]))
	standalone._apply_numeric({"min_value":5.5,"max_value":8.0,"step":0.25,"value":5.65})
	check(near(standalone.value,5.75) and range_events==[[0.0,5.75]],"coherent native min-offset range/value transaction notifies once")
	standalone._apply_numeric({"min_value":7.0,"max_value":7.0,"step":0.25})
	check(near(standalone.value,7.0) and range_events.size()==2 and coherent==[true,true],"min equals max is one immobile actual value")
	standalone.free()
	for kind in [preload("res://addons/estragon/runtime/node/number_input.gd"),preload("res://addons/estragon/runtime/node/integer_input.gd"),preload("res://addons/estragon/runtime/node/slider.gd")]:
		var authored=kind.new()
		var integral:bool=Contract.integer(kind)
		var positive={"min_value":200,"max_value":300,"step":1,"value":201} if integral else {"min_value":200.0,"max_value":300.0,"step":0.25,"value":201.5}
		var negative={"min_value":-300,"max_value":-200,"step":1,"value":-201} if integral else {"min_value":-300.0,"max_value":-200.0,"step":0.25,"value":-201.5}
		for configuration in [positive,negative]:
			authored._apply_numeric(configuration)
			var scene:=PackedScene.new()
			var saved:bool=scene.pack(authored)==OK
			var restored=scene.instantiate()
			check(saved and restored.min_value==configuration.min_value and restored.max_value==configuration.max_value and restored.step==configuration.step and restored.value==configuration.value,"native scene restores complete typed range atomically "+kind.resource_path+" "+str(configuration.min_value))
			restored.free()
		authored.free()

	var native_range:=HSlider.new()
	native_range.min_value=-10;native_range.max_value=10;native_range.step=0.25
	var native_equal:=true
	for midpoint in [-6.375,-0.125,0.125,0.375,5.625]:
		native_range.value=midpoint
		native_equal = native_equal and native_range.value==Contract.canonical(midpoint,-10,10,0.25)
	check(native_equal,"canonical midpoint rounding matches actual native Range including negative ties")
	native_range.free()
	for config in [{"min_value":0.0,"max_value":1.0,"step":0.05,"value":0.3},{"min_value":-8.0,"max_value":-5.5,"step":0.25,"value":-6.25},{"min_value":0.0,"max_value":1e-8,"step":1e-10,"value":3e-10},{"min_value":1e14,"max_value":1e15,"step":1.0,"value":1e14},{"min_value":0.0,"max_value":1.0,"step":0.0,"value":0.333}]:
		check(not Contract.configuration(config,false,true).has("error"),"finite decimal/small/large/continuous range "+str(config))
	await RenderingServer.frame_post_draw
	var pixels=tree.root.get_texture().get_image()
	var horizontal=h.get_native_control()
	var icon_size=horizontal.get_theme_icon("grabber").get_size()
	var thumb=horizontal.get_global_rect().position+Vector2(icon_size.x*0.5+(horizontal.size.x-icon_size.x)*h.value,horizontal.size.y*0.5)
	check(pixels.get_pixelv(Vector2i(thumb)).r>0.6,"actual horizontal thumb pixels follow normalized float value")
	var vicon=vn.get_theme_icon("grabber").get_size()
	var vthumb=vn.get_global_rect().position+Vector2(vn.size.x*0.5,vn.size.y-vicon.y*0.5-(vn.size.y-vicon.y)*v.value)
	check(pixels.get_pixelv(Vector2i(vthumb)).r>0.6,"actual vertical thumb pixels follow reversed physical axis")
	tree.root.get_texture().get_image().save_png("res://numeric-gallery.png")
	return {"ok":ok,"checks":checks}
