extends RefCounted
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
var checks := 0
var ok := true
func check(value: bool,label: String):
	checks += 1
	print("UI02_GAME_CHECK ",label,": ",value)
	ok = ok and value
func frames(tree: SceneTree):
	for i in range(10): await tree.process_frame
func mouse(node: Node2D,down: bool,offset: Vector2=Vector2(8,8)):
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = node.get_global_transform_with_canvas()*offset
	event.pressed = down
	Input.parse_input_event(event)
	await frames(node.get_tree())
func click(node: Node2D):
	await mouse(node,true)
	await mouse(node,false)
func key(host: Node,code: int,down: bool=true,echo: bool=false):
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	event.echo = echo
	Input.parse_input_event(event)
	await frames(host.get_tree())
func run(host: Node):
	var tree := host.get_tree()
	await frames(tree)
	var box = host.get_node("UI/Controls")
	var bound = box.get_node("Bound")
	var toggle = box.get_node("Toggle")
	var snapshot = box.get_node("Snapshot")
	var computed = box.get_node("Computed")
	var parameter = box.get_node("Parameter")
	var scope = State.records[host.get_instance_id()]
	check(host.presses==0 and not bound.value and not toggle.value,"handler references are not invoked during render; initial Bool projection")
	var events: Array = []
	bound.value_changed.connect(func(a,b): events.append([a,b]))
	var writes: Array = []
	host.model.flag_changed.connect(func(a,b): writes.append([a,b]))
	var identity: int = bound.get_instance_id()
	await click(bound)
	check(host.model.flag and bound.value and toggle.value and events==[[false,true]] and writes==[[false,true]] and host.presses==1,"pointer edit updates one model synchronously and projects peers once")
	check(bound.has_focus() and bound.get_focus_control().size==bound.layout_size,"Checkbox shares native pointer focus and exact hit rectangle")
	var runs: int = scope.runs
	bound.value = false
	check(not host.model.flag and events[-1]==[true,false],"independent native control assignment notifies and writes source synchronously")
	await frames(tree)
	check(scope.runs==runs+1 and not toggle.value,"independent write schedules one coalesced view")
	var count := writes.size()
	host.model.flag = true
	await frames(tree)
	check(bound.value and writes.size()==count+1 and events[-1]==[false,true],"reconciliation notifies value observers without reciprocal source writes")
	bound.value = true
	await frames(tree)
	check(writes.size()==count+1,"same-value control assignment is quiet")
	snapshot.value = false
	computed.value = true
	await frames(tree)
	check(host.model.flag,"snapshot and computed controls are one-way")
	host.revision += 1
	await frames(tree)
	check(snapshot.value and not computed.value,"one-way values project from current snapshot on relevant rerender")
	parameter.value = false
	check(not host.model.flag,"direct typed parameter property path is implicitly two-way")
	await frames(tree)
	bound.grab_focus()
	await key(host,KEY_SPACE)
	await key(host,KEY_SPACE,true,true)
	check(not host.model.flag,"keyboard press/repeat do not activate before completed release")
	await key(host,KEY_SPACE,false)
	check(host.model.flag and host.presses==2,"completed focused keyboard activation exactly once")
	await key(host,KEY_ENTER)
	await key(host,KEY_ESCAPE)
	await key(host,KEY_ENTER,false)
	check(host.model.flag and host.presses==2,"cancel consumes held key without activation")
	bound.disabled = true
	await click(bound)
	check(host.model.flag and host.presses==2 and not bound.has_focus(),"disabled Checkbox cannot activate or retain focus")
	bound.disabled = false
	bound.hide()
	await click(bound)
	check(host.model.flag and host.presses==2,"hidden Checkbox cannot activate")
	bound.show()
	var reentrant: Callable = func(_before,next):
		if next: host.model.flag = false
	host.model.flag = false
	await frames(tree)
	host.model.flag_changed.connect(reentrant)
	bound.value = true
	await frames(tree)
	check(not host.model.flag and not bound.value,"reentrant source restore wins without binding feedback loop")
	host.model.flag_changed.disconnect(reentrant)
	var old = host.model
	var weak: WeakRef = weakref(old)
	var stale = bound.value_changed.get_connections()[0].callable
	host.model = old.get_script().new()
	if stale.is_valid(): stale.call(false,true)
	check(not old.flag and not host.model.flag,"stale bound self-path callback inert before replacement commit")
	await frames(tree)
	check(bound.get_instance_id()==identity and bound.value_changed.get_connections().size()==2,"replacement retains native Checkbox and one binding plus observer")
	old = null
	check(weak.get_ref()==null,"replacement releases previous model and parameter-path linkage")
	if stale.is_valid(): stale.call(false,true)
	check(not host.model.flag,"captured disconnected callback stays inert after replacement")
	var rows = host.get_node("UI/Rows")
	var a = rows.get_node("A")
	a.grab_focus()
	host.reverse = true
	await frames(tree)
	check(rows.get_node("A")==a and a.has_focus(),"keyed reorder retains Checkbox identity and focus")
	var grid = host.get_node("UI/Grid/GridCheck")
	check(bound.layout_size.x>=bound._measure_native().x and grid.layout_size.y>=grid._measure_native().y and a.layout_size.x>=a._measure_native().x,"natural square/label dimensions participate in Box/Grid/Wrap")
	check(bound.color==Color.WHITE and bound.font_size==20,"label styling remains local, with no inherited automatic style")
	for size in [Vector2i(640,600),Vector2i(1000,760)]:
		tree.root.size = size
		await frames(tree)
		a.grab_focus()
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://checkbox-"+str(size.x)+".png")
	host.model = null
	await frames(tree)
	check(not host.has_node("UI/Controls") and not is_instance_valid(bound),"null source condition unmounts bound inputs cleanly")
	host.model = load("res://app/generated/Model.gd").new()
	await frames(tree)
	check(host.has_node("UI/Controls") and host.get_node("UI/Controls/Bound").value_changed.get_connections().size()==1,"repair creates one clean implicit binding")
	var live = host.get_node("UI/Controls/Bound")
	var callback = live.value_changed.get_connections()[0].callable
	host.show = false
	await frames(tree)
	if callback.is_valid(): callback.call(false,true)
	check(not host.model.flag and not is_instance_valid(live),"unmount disconnects old control callbacks")
	host.show = true
	await frames(tree)
	Profile.set_enabled(true)
	Profile.reset()
	await frames(tree)
	var stats: Dictionary = Profile.snapshot()
	Profile.set_enabled(false)
	check(stats.counts.get("views",0)==0 and stats.timings_us.is_empty(),"zero idle composition work")
	var result := {"ok":ok,"checks":checks,"presses":host.presses}
	var file := FileAccess.open("res://.godot/ui02-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/ui02-game.tmp","res://.godot/ui02-game.json")
	print("UI02_GAME ",JSON.stringify(result))
	return result
