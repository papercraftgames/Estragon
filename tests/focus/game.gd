extends RefCounted
const Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
var checks := 0
var ok := true
func check(value: bool,label: String):
	checks += 1
	print("UI01_GAME_CHECK ",label,": ",value)
	ok = ok and value
func frames(tree: SceneTree):
	for i in range(10): await tree.process_frame
func key(host: Node,code: int,pressed: bool=true,echo: bool=false):
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	await host.get_tree().process_frame
	await host.get_tree().process_frame
func tap(host: Node,code: int):
	await key(host,code)
	await key(host,code,false)
func run(host: Node):
	var tree := host.get_tree()
	await frames(tree)
	var entry = host.get_node("UI")
	var actions = entry.get_layout_child("Actions")
	var first = actions.get_layout_child("First")
	var toggle = actions.get_layout_child("Toggle")
	var native = actions.get_layout_child("Native")
	var prototype = actions.get_layout_child("Prototype")
	var identity: int = first.get_instance_id()
	first.grab_focus()
	check(first.has_focus(),"actual composed Node2D acquires native GUI focus")
	for size in [Vector2i(640,480),Vector2i(1000,700)]:
		tree.root.size = size
		await frames(tree)
		host.caption = "Retained focus at "+str(size.x)
		await frames(tree)
		check(first.get_instance_id()==identity and first.has_focus() and actions.get_layout_child("First")==first,"parent rerender/resize retains native Node, endpoint and focus")
		await key(host,KEY_SPACE)
		await key(host,KEY_SPACE,true,true)
		await key(host,KEY_SPACE,false)
		await frames(tree)
		check(host.clicks==(1 if size.x==640 else 2),"actual composed keyboard handler exactly once")
		await RenderingServer.frame_post_draw
		tree.root.get_texture().get_image().save_png("res://focus-game-"+str(size.x)+".png")
	host.reversed = true
	await frames(tree)
	check(actions.get_layout_child("First")==first and first.has_focus(),"keyed parent reorder preserves focused native instance")
	await tap(host,KEY_TAB)
	check(tree.root.gui_get_focus_owner()==native,"new tree order traversal skips disabled target")
	await tap(host,KEY_ENTER)
	check(host.native_clicks==1,"mixed native GUI activation has one owner")
	await tap(host,KEY_TAB)
	check(tree.root.gui_get_focus_owner()==prototype.editor,"native text delegate participates across Node2D roots")
	var editor: LineEdit = prototype.editor
	editor.text = "Unicode Ω"
	editor.caret_column = editor.text.length()
	var event := InputEventKey.new()
	event.keycode = KEY_EXCLAM
	event.unicode = 33
	event.pressed = true
	Input.parse_input_event(event)
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	editor.select(0,7)
	var caret := editor.caret_column
	host.caption = "Editing delegate retained"
	await frames(tree)
	check(prototype.editor==editor and editor.text=="Unicode Ω!" and editor.has_selection() and editor.caret_column==caret and editor.has_focus(),"native delegate text/caret/selection/focus survive parent rerender")
	check(editor.get_parent()==prototype and editor.owner==null,"delegate keeps real native ancestry and transient ownership")
	print("UI01_IME ",JSON.stringify({"feature":DisplayServer.has_feature(DisplayServer.FEATURE_IME),"backend":DisplayServer.get_name(),"os_composition":"UNTESTED: no OS IME composition under Xvfb; native LineEdit owns platform IME"}))
	first.grab_focus()
	await key(host,KEY_ENTER)
	host.show_first = false
	await frames(tree)
	await key(host,KEY_ENTER,false)
	check(not is_instance_valid(first) and host.clicks==2 and tree.root.gui_get_focus_owner()==null,"reactive focused removal cancels held key without stale target")
	toggle.grab_focus()
	await tap(host,KEY_SPACE)
	await frames(tree)
	check(host.selected and toggle.value,"keyboard Toggle uses existing controlled bool binding")
	Profile.set_enabled(true)
	Profile.reset()
	await frames(tree)
	var snapshot: Dictionary = Profile.snapshot()
	Profile.set_enabled(false)
	check(snapshot.counts.get("views",0)==0 and snapshot.timings_us.is_empty(),"idle composed frames do not rerender")
	var result := {"ok":ok,"checks":checks,"clicks":host.clicks,"native_clicks":host.native_clicks,"selected":host.selected,"ime_os_composition":"UNTESTED"}
	var file := FileAccess.open("res://.godot/ui01-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
	DirAccess.rename_absolute("res://.godot/ui01-game.tmp","res://.godot/ui01-game.json")
	print("UI01_GAME ",JSON.stringify(result))
	return result
