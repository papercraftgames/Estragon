extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Action = preload("res://addons/estragon/runtime/node/button.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
var failed := false
var checks := 0
func check(ok: bool,label: String):
	checks += 1
	print("D07_CHECK ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func close(a: Color,b: Color) -> bool: return absf(a.r-b.r)<0.02 and absf(a.g-b.g)<0.02 and absf(a.b-b.b)<0.02
func press(point: Vector2,down: bool):
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	root.push_input(event,true)
func click(node: Node):
	var point: Vector2 = node.get_global_transform_with_canvas()*Vector2(20,20)
	press(point,true)
	press(point,false)
func pixels() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var host = load("res://app/generated/Buttons.gd").new()
	root.add_child(host)
	await frames()
	var ui = host.get_node("UI")
	var column = ui.get_layout_child("Column")
	var kinds = column.get_node("Kinds")
	var action = kinds.get_node("Action")
	var native = kinds.get_node("Native")
	var unimported = kinds.get_node("Unimported")
	var native_only = unimported.get_node("Godot")
	var disabled = column.get_node("Disabled")
	var toggle = column.get_node("Toggle")
	var surface = column.get_node("Surface")
	check(action is Node2D and not action is Control and action.get_script().resource_path.ends_with("/node/button.gd"),"explicit imported Button is the real Estragon Node2D")
	check(native is Button and native_only is Button and native_only.get_script()==null,"same-file explicit native Script and unimported Godot Button stay native")
	var constructed: Array = host.constructors()
	check(constructed[0] is Action and constructed[1] is Action and constructed[2] is Button and constructed[3] is Button,"lexical constructors/alias and explicit ClassDB qualification")
	for node in constructed: node.free()
	var plain: Button = unimported.construct()
	check(plain is Button and host.typed(action)==action and host.member_and_string()=="Button member","native type/constructor and lowered imported type preserve expressions and member data")
	plain.free()
	host.selected = action
	await frames()
	check(column.get_node("Typed").supplied==action and column.get_node("Typed").get_child(0).text.contains("Estragon Button"),"bindable imported types and imported Gogo property metadata preserve Script identity")
	var identity: int = action.get_instance_id()
	var stats: Dictionary = action.get_layout_stats()
	var runs: int = State.records[host.get_instance_id()].runs
	var geometry: int = action._visual_style.geometry_count
	check(action.background_color==Color("#383838") and action.hover_background_color==Color("#505050") and action.pressed_background_color==Color("#252525") and action.disabled_background_color==Color("#303030"),"four exact neutral property defaults before user writes")
	check(action._visual_style.colors.background_color==action.background_color and action._visual_style.colors.hover_background_color==action.hover_background_color and action._visual_style.colors.pressed_background_color==action.pressed_background_color and action._visual_style.colors.disabled_background_color==action.disabled_background_color,"initial cached palette matches native property defaults")
	var sample: Vector2i = Vector2i(action.global_position+Vector2(80,5))
	for state in [[false,false,false,"#383838"],[true,false,false,"#505050"],[true,true,false,"#252525"],[false,false,true,"#303030"],[false,false,false,"#383838"]]:
		action.disabled = state[2]
		action._set_pointer_state(state[0],state[1])
		await frames()
		var image: Image = await pixels()
		check(close(image.get_pixelv(sample),Color(state[3])) and action.get_background_color()==Color(state[3]),"actual neutral state pixel "+state[3])
		image.save_png("res://button-state-"+str(state[3]).trim_prefix("#")+".png")
	check(stats==action.get_layout_stats() and runs==State.records[host.get_instance_id()].runs and geometry==action._visual_style.geometry_count,"pointer palette changes are draw-only, no geometry/layout/recomposition")
	check(action.padding=="auto" and action._default_padding()==Vector4(14,8,14,8) and action.corner_radius==0.0 and action.get_label_origin().x>=14,"square corners, white native text alignment and14/8 local padding preserved")
	var image: Image = await pixels()
	check(close(image.get_pixelv(Vector2i(disabled.global_position+Vector2(80,5))),Color("#303030")) and close(image.get_pixelv(Vector2i(toggle.global_position+Vector2(80,5))),Color("#383838")),"initial disabled Button and unchecked Toggle are charcoal")
	click(action)
	click(native)
	click(native_only)
	click(toggle)
	await frames()
	check(host.clicks==1 and host.native_clicks==1 and unimported.clicks==1 and host.checked,"each real native/custom pressed/value_changed fires once")
	check(action.get_signal_connection_list("pressed").size()==1 and native.get_signal_connection_list("pressed").size()==1 and toggle.get_signal_connection_list("value_changed").size()==1,"no duplicated handlers on imported/native/controlled Toggle")
	image = await pixels()
	check(toggle.get_background_color()==Color("#227a60") and close(image.get_pixelv(Vector2i(toggle.global_position+Vector2(80,5))),Color("#227a60")),"checked Toggle remains teal")
	toggle.disabled = true
	await frames()
	check(toggle.get_background_color()==Color("#303030"),"disabled charcoal precedence over checked teal")
	toggle.disabled = false
	var offset: Vector2 = ui.scroll_offset
	var before_props: Dictionary = action.get_layout_stats()
	host.props = {"background_color":"#aa3322","hover_background_color":"#112233","corner_radius":"12px"}
	await frames()
	action._set_pointer_state(false,false)
	await frames()
	check(action.get_instance_id()==identity and action.get_background_color()==Color("#aa3322") and action.corner_radius=="12px" and action.get_layout_stats()==before_props,"explicit spread color/S04 radius remains authoritative and visual-only")
	host.props = {}
	await frames()
	check(action.background_color==Color("#383838") and action.corner_radius==0.0 and ui.scroll_offset==offset,"spread omission restores charcoal/native defaults on retained node")
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800)]:
		root.size = size
		await frames()
		check(action.get_instance_id()==identity and ui.layout_size==Vector2(size) and surface.background_texture is GradientTexture2D,"responsive Wrap/scroll/S04 native surface retained at "+str(size))
		ui.scroll_offset = Vector2.ZERO
		await frames()
		image = await pixels()
		image.save_png("res://buttons-"+str(size.x)+".png")
	var idle := [action.get_visual_style_stats(),ui.get_layout_stats(),State.records[host.get_instance_id()].runs]
	await frames()
	check(idle==[action.get_visual_style_stats(),ui.get_layout_stats(),State.records[host.get_instance_id()].runs],"settled imported palette/scene idle quiet")
	host.selected = null
	var packed := PackedScene.new()
	check(packed.pack(host)==OK and ResourceSaver.save(packed,"res://d07-packed.tscn")==OK,"source host packs without transient Button output")
	host.free()
	await frames()
	host = load("res://d07-packed.tscn").instantiate()
	root.add_child(host)
	await frames()
	check(host.get_node("UI").get_layout_child("Column").get_node("Kinds/Action").background_color==Color("#383838"),"PackedScene reload remounts imported Button with neutral defaults")
	host.free()
	await frames()
	var legacy = load("res://app/generated/LegacyAlias.gd").new()
	var entry := Entry.new()
	entry.width = 640
	entry.height = 240
	entry.add_child(legacy)
	root.add_child(entry)
	await frames()
	var old_action = legacy.get_node("OldUserAlias")
	click(old_action)
	await frames()
	check(old_action is Action and legacy.clicks==1,"old explicitly imported UiButton user source still runs unchanged")
	entry.free()
	await frames()
	check(State.records.is_empty(),"all imported/native composition subscriptions released")
	print("D07_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("D07_RUNTIME_OK")
	quit(1 if failed else 0)
