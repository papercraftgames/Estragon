extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
const Focus = preload("res://addons/estragon/runtime/node/internal/focus.tres")
class Fallback extends Node:
	var text_keys := 0
	func _unhandled_key_input(event: InputEvent):
		if event is InputEventKey and event.pressed and event.unicode>0: text_keys += 1
var checks := 0
var ok := true
func selection(editor: LineEdit) -> String:
	return editor.text.substr(editor.get_selection_from_column(),editor.get_selection_to_column()-editor.get_selection_from_column()) if editor.has_selection() else ""
func check(value: bool,label: String):
	checks += 1
	ok = ok and value
	print("UI03_GAME_CHECK ",label,": ",value)
func frames(tree: SceneTree):
	for i in range(4): await tree.process_frame
func key(tree: SceneTree,code: int,unicode: int=0,ctrl: bool=false,shift: bool=false):
	var event := InputEventKey.new()
	event.keycode = code
	event.unicode = unicode
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await frames(tree)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(tree)
func pointer(tree: SceneTree,point: Vector2,down: bool):
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	Input.parse_input_event(event)
	await frames(tree)
func click(tree: SceneTree,node: Control,offset: Vector2=Vector2(12,10)):
	var point = node.get_global_transform_with_canvas()*offset
	await pointer(tree,point,true)
	await pointer(tree,point,false)
func run(host: Node):
	var tree := host.get_tree()
	await frames(tree)
	var bound = host.get_node("UI/Controls/Bound")
	var peer = host.get_node("UI/Controls/Peer")
	var editor: LineEdit = bound.get_focus_control()
	var scope = State.records[host.get_instance_id()]
	var fallback := Fallback.new()
	tree.root.add_child(fallback)
	check(editor is LineEdit and editor.owner==null and bound.get_child_count()==0 and bound.get_child_count(true)==1,"one private native LineEdit, not an authored wrapper or layout child")
	check(editor.position==bound.get_content_rect().position and editor.size==bound.get_content_rect().size,"native editor exactly occupies the arranged content rect")
	check(host.submits.is_empty() and host.cancels==0 and editor.text=="Hello","initial projection and named handlers do not execute during render")
	var changes: Array = []
	var writes: Array = []
	bound.value_changed.connect(func(a,b): changes.append([a,b]))
	host.model.text_changed.connect(func(a,b): writes.append([a,b]))
	await click(tree,editor)
	check(bound.has_focus() and tree.root.gui_get_focus_owner()==editor,"actual pointer focuses the native editing endpoint")
	await key(tree,KEY_A,0,true)
	check(editor.has_selection() and selection(editor)=="Hello","native keyboard select-all")
	for pair in [[KEY_A,97],[KEY_E,0x00e9],[KEY_O,0x03a9]]: await key(tree,pair[0],pair[1])
	check(fallback.text_keys==0,"native editing owns text key delivery before game fallback")
	check(bound.value=="aéΩ" and host.model.text=="aéΩ" and peer.value=="aéΩ" and changes.size()==3 and writes.size()==3,"real Unicode typing edits one source and notifies once per native edit")
	await key(tree,KEY_BACKSPACE)
	check(host.model.text=="aé","native backspace")
	await key(tree,KEY_HOME)
	await key(tree,KEY_DELETE)
	check(host.model.text=="é" and editor.caret_column==0,"native Home/Delete navigation")
	await key(tree,KEY_END)
	await key(tree,KEY_LEFT,0,false,true)
	check(selection(editor)=="é","native shift navigation selects Unicode text")
	await key(tree,KEY_BACKSPACE)
	check(host.model.text.is_empty(),"backspace deletes the native selection")
	bound.value = "Copy Ω"
	await frames(tree)
	await key(tree,KEY_A,0,true)
	await key(tree,KEY_C,0,true)
	check(DisplayServer.clipboard_get()=="Copy Ω","native copy uses platform clipboard")
	var count := changes.size()
	await key(tree,KEY_X,0,true)
	check(host.model.text=="" and changes.size()==count+1,"native cut edits exactly once")
	await key(tree,KEY_V,0,true)
	check(host.model.text=="Copy Ω" and changes.size()==count+2,"native paste edits exactly once")
	# Real mouse drag, with native font positions and platform mouse-mask state.
	bound.value = "abcdef"
	await frames(tree)
	var start: Vector2 = editor.get_global_transform_with_canvas()*Vector2(1,editor.size.y*0.5)
	var finish: Vector2 = editor.get_global_transform_with_canvas()*Vector2(bound.font.get_string_size("abc",HORIZONTAL_ALIGNMENT_LEFT,-1,bound.font_size).x,editor.size.y*0.5)
	await pointer(tree,start,true)
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	motion.relative = finish-start
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await frames(tree)
	await pointer(tree,finish,false)
	check(editor.has_selection() and not selection(editor).is_empty(),"native mouse drag selects text")
	var identity := bound.get_instance_id()
	var caret := editor.caret_column
	var selected := selection(editor)
	host.revision += 1
	await frames(tree)
	check(host.get_node("UI/Controls/Bound")==bound and bound.get_focus_control()==editor and editor.caret_column==caret and selection(editor)==selected,"parent recompute retains native identity, caret and selection")
	await key(tree,KEY_ENTER)
	check(host.submits==["abcdef"] and host.model.text=="abcdef","native Enter submits once without a value write")
	await key(tree,KEY_ESCAPE)
	check(host.cancels==1 and not bound.has_focus() and host.model.text=="abcdef","Escape emits cancel once and releases focus without implicit rollback")
	var runs: int = scope.runs
	count = writes.size()
	bound.value = "Independent"
	check(host.model.text=="Independent" and writes.size()==count+1,"independent Input value assignment writes source synchronously")
	await frames(tree)
	check(scope.runs==runs+1 and peer.value=="Independent","independent write coalesces to one view commit")
	count = writes.size()
	host.model.text = "Projected"
	await frames(tree)
	check(bound.value=="Projected" and editor.text=="Projected" and writes.size()==count+1,"model projection notifies native value without reciprocal source write")
	count = changes.size()
	bound.value = "Projected"
	await frames(tree)
	check(changes.size()==count,"same String value is quiet")
	var snapshot = host.get_node("UI/Controls/Snapshot")
	var computed = host.get_node("UI/Controls/Computed")
	snapshot.value = "Local"
	computed.value = "Local"
	check(host.model.text=="Projected","snapshot/computed controls stay one-way")
	host.revision += 1
	await frames(tree)
	check(snapshot.value=="Projected" and computed.value=="PROJECTED","relevant render restores one-way model projection")
	host.get_node("UI/Controls/Parameter").value = "Parameter"
	check(host.model.text=="Parameter","typed direct parameter String path is two-way")
	await frames(tree)
	var readonly = host.get_node("UI/Grid/ReadOnly")
	var readonly_editor: LineEdit = readonly.get_focus_control()
	await click(tree,readonly_editor)
	await key(tree,KEY_A,0,true)
	await key(tree,KEY_C,0,true)
	check(readonly.has_focus() and DisplayServer.clipboard_get()==readonly.value,"read-only retains native focus, selection and copy")
	await key(tree,KEY_Z,122)
	await key(tree,KEY_BACKSPACE)
	check(readonly.value=="Read only / copy","read-only rejects keyboard edits")
	var disabled = host.get_node("UI/Grid/Disabled")
	await click(tree,disabled.get_focus_control())
	await key(tree,KEY_Z,122)
	check(not disabled.has_focus() and disabled.value=="Disabled","disabled cannot focus or edit")
	bound.grab_focus()
	bound.hide()
	await frames(tree)
	check(not bound.has_focus(),"hidden Input loses native focus")
	bound.show()
	bound.disabled = true
	bound.grab_focus()
	check(not bound.has_focus(),"disabled source-bound Input refuses explicit focus")
	bound.disabled = false
	# Reentrant source changes win over an edit's intermediate value.
	var reentrant: Callable = func(_before,next):
		if next=="Restore": host.model.text = "Restored"
	host.model.text_changed.connect(reentrant)
	bound.value = "Restore"
	await frames(tree)
	check(host.model.text=="Restored" and editor.text=="Restored","reentrant model restore wins without feedback")
	host.model.text_changed.disconnect(reentrant)
	var old = host.model
	var weak: WeakRef = weakref(old)
	var stale = bound.value_changed.get_connections()[0].callable
	host.model = old.get_script().new()
	if stale.is_valid(): stale.call("Restored","stale")
	check(old.text=="Restored" and host.model.text=="Hello","replaced-path edit callback inert before deferred commit")
	await frames(tree)
	check(bound.get_instance_id()==identity and editor==bound.get_focus_control() and bound.value=="Hello" and bound.value_changed.get_connections().size()==2,"replacement retains Input/editor and exactly one mounted binding")
	old = null
	check(weak.get_ref()==null,"replacement releases former model and parameter linkage")
	if stale.is_valid(): stale.call("Hello","stale")
	check(host.model.text=="Hello","captured disconnected edit cannot update replacement")
	var a = host.get_node("UI/Grid/A")
	var ae: LineEdit = a.get_focus_control()
	a.grab_focus()
	ae.caret_column = 4
	ae.select(1,4)
	host.reverse = true
	await frames(tree)
	check(host.get_node("UI/Grid/A")==a and a.has_focus() and ae.caret_column==4 and selection(ae)=="eta","keyed conditional move retains Input, native caret/selection and focus")
	await key(tree,KEY_TAB)
	check(readonly.has_focus(),"shared Tab follows keyed Input order to read-only native endpoint")
	await key(tree,KEY_TAB)
	check(host.get_node("UI/Grid/Invalid").has_focus(),"shared Tab skips disabled Input")
	var clipped = host.get_node("UI/Clip").get_layout_child("Clipped")
	var ce: LineEdit = clipped.get_focus_control()
	check(bound.layout_size.x>=216 and a.layout_size.y>=a.font.get_height(a.font_size)+16 and ce.size==clipped.get_content_rect().size,"natural sizes and exact native content geometry in nested Box/Grid")
	var outside: Vector2 = ce.get_global_transform_with_canvas()*Vector2(260,10)
	await pointer(tree,outside,true)
	await pointer(tree,outside,false)
	check(not clipped.has_focus(),"native ancestor clip excludes outside Input hit area")
	await click(tree,ce)
	check(clipped.has_focus(),"visible clipped Input remains natively editable")
	check(ce.owner==null and preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres").find(ce)==null,"delegate has no layout adapter or scene owner")
	for size in [Vector2i(640,700),Vector2i(1000,800)]:
		tree.root.size = size
		await frames(tree)
		a.grab_focus()
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://input-"+str(size.x)+".png")
	print("UI03_NATIVE_TEXT backend=",DisplayServer.get_name()," ime_capability=",DisplayServer.has_feature(DisplayServer.FEATURE_IME)," actual_os_composition=UNTESTED")
	host.model = null
	await frames(tree)
	check(not host.has_node("UI/Controls") and not is_instance_valid(bound) and not is_instance_valid(editor),"null conditional unmount releases Input and native editor")
	host.model = load("res://app/generated/Model.gd").new()
	await frames(tree)
	var live = host.get_node("UI/Controls/Bound")
	check(live.value=="Hello" and live.value_changed.get_connections().size()==1,"repair mounts one clean String binding")
	var callback = live.value_changed.get_connections()[0].callable
	host.show = false
	await frames(tree)
	if callback.is_valid(): callback.call("Hello","stale")
	check(not is_instance_valid(live) and host.model.text=="Hello","unmount disconnects stale edits")
	host.show = true
	await frames(tree)
	Profile.set_enabled(true)
	Profile.reset()
	await frames(tree)
	var stats: Dictionary = Profile.snapshot()
	Profile.set_enabled(false)
	check(stats.counts.get("views",0)==0 and stats.timings_us.is_empty(),"zero idle composition work")
	fallback.free()
	var result := {"ok":ok,"checks":checks,"submits":host.submits.size(),"cancels":host.cancels}
	var file := FileAccess.open("res://.godot/ui03-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/ui03-game.tmp","res://.godot/ui03-game.json")
	print("UI03_GAME ",JSON.stringify(result))
	return result
