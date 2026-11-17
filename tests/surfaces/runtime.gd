extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/vbox.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Action = preload("res://addons/estragon/runtime/node/button.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var checks := 0
var hits := 0
func hit(): hits += 1
func check(ok: bool, label: String):
	checks += 1
	print("S04_CHECK ",label,": ",ok)
	failed = failed or not ok
func frames():
	for i in range(8): await process_frame
func image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func close(a: Color,b: Color) -> bool: return absf(a.r-b.r)<0.025 and absf(a.g-b.g)<0.025 and absf(a.b-b.b)<0.025
func press(point: Vector2, down: bool):
	var event := InputEventMouseButton.new()
	event.position = point
	event.pressed = down
	event.button_index = MOUSE_BUTTON_LEFT
	root.push_input(event,true)
func click(point: Vector2): press(point,true); press(point,false)
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var ui := Entry.new()
	ui.width = 640
	ui.height = 480
	ui.background_color = "#142536"
	var panel := Rect.new()
	panel.width = 180
	panel.height = 140
	panel.corner_radius = 40
	panel.background_color = Color.GREEN
	panel.border_color = Color.WHITE
	panel.border_left_width = 12.5
	panel.border_width = 2.5
	ui.add_child(panel)
	root.add_child(ui)
	await frames()
	var pixels: Image = await image()
	check(close(pixels.get_pixel(0,0),Color("#142536")) and close(pixels.get_pixel(90,60),Color.GREEN),"rounded outer corners transparent, interior colored")
	check(close(pixels.get_pixel(4,70),Color.WHITE) and close(pixels.get_pixel(20,70),Color.GREEN),"asymmetric fractional border remains inside box")
	var gradient := GradientTexture2D.new()
	gradient.width = 16
	gradient.height = 16
	gradient.gradient = Gradient.new()
	gradient.gradient.colors = PackedColorArray([Color.RED,Color.YELLOW])
	panel.background_texture = gradient
	await frames()
	pixels = await image()
	check(close(pixels.get_pixel(0,0),Color("#142536")) and close(pixels.get_pixel(4,70),Color.WHITE) and pixels.get_pixel(40,60).r>0.9,"native texture masked to rounded contour and excluded from border")
	var red: Color = pixels.get_pixel(25,70)
	var yellow: Color = pixels.get_pixel(150,70)
	check(yellow.g>red.g+0.5,"stretch UVs span native gradient across interior")
	var unrelated := Rect.new()
	unrelated.width = 10
	unrelated.height = 10
	ui.add_child(unrelated)
	await frames()
	var unrelated_draw := unrelated.get_visual_style_stats()
	panel.background_texture_mode = "tile"
	await frames()
	pixels = await image()
	check(close(pixels.get_pixel(28,70),pixels.get_pixel(44,70)),"native CanvasTexture tile repeat has texture-pixel period")
	var layout_stats := [ui.get_layout_stats(),panel.get_layout_stats()]
	var before_draw: int = panel.get_visual_style_stats().draw
	gradient.gradient.set_color(0,Color.BLUE)
	await frames()
	pixels = await image()
	check(panel.get_visual_style_stats().draw>before_draw and pixels.get_pixel(29,70).b>0.1 and layout_stats==[ui.get_layout_stats(),panel.get_layout_stats()],"nested Gradient mutation redraws referenced surface without layout")
	check(unrelated_draw==unrelated.get_visual_style_stats(),"resource mutation leaves nonreferencing surfaces quiet")
	panel.background_texture = null
	await frames()
	var after_null := panel.get_visual_style_stats()
	gradient.gradient.set_color(0,Color.RED)
	await frames()
	check(after_null==panel.get_visual_style_stats() and not gradient.changed.is_connected(panel._visual_style._resource_changed) and not gradient.gradient.changed.is_connected(panel._visual_style._resource_changed),"texture replacement disconnects both native resource signals")
	panel.corner_radius = "25%"
	await frames()
	check(panel._visual_style._outer[0].is_equal_approx(Vector2(0,35)),"radius percentage uses minimum local border-box axis")
	panel.corner_radius = "5vw"
	await frames()
	check(panel._visual_style._outer[0].is_equal_approx(Vector2(0,32)),"radius viewport units resolve without layout specifications")
	var fixed_stats: Dictionary = panel.get_layout_stats()
	root.size = Vector2i(800,480)
	await frames()
	check(panel._visual_style._outer[0].is_equal_approx(Vector2(0,40)) and panel.get_layout_stats()==fixed_stats,"fixed-size surface viewport radius refreshes without layout")
	root.size = Vector2i(640,480)
	await frames()
	var texture_image := Image.create(4,4,false,Image.FORMAT_RGBA8)
	texture_image.fill(Color(1,0,0,0.5))
	panel.background_texture = ImageTexture.create_from_image(texture_image)
	panel.background_color = Color.BLUE
	await frames()
	pixels = await image()
	check(close(pixels.get_pixel(90,70),Color(0.5,0,0.5)) and close(pixels.get_pixel(0,0),Color("#142536")),"ImageTexture alpha composes once over base fill without square bleed")
	panel.corner_radius = 60
	panel.border_left_width = 130
	panel.border_right_width = 0
	await frames()
	pixels = await image()
	check(close(pixels.get_pixel(178,2),Color("#142536")) and pixels.get_pixel(160,70).r>0.3,"extreme asymmetric inset cannot push textured inner corners outside outer contour")
	panel.border_left_width = 12.5
	panel.border_right_width = "auto"
	panel.background_texture = null
	await frames()
	layout_stats = [ui.get_layout_stats(),panel.get_layout_stats()]
	panel.corner_radius = "50%"
	panel.corner_radius_top_left = 0
	await frames()
	check(panel._visual_style._outer[0]==Vector2.ZERO and panel._visual_style._outer.size()>4 and layout_stats==[ui.get_layout_stats(),panel.get_layout_stats()],"local radius percentage/override is visual-only")
	panel.corner_radius_top_left = "auto"
	panel.corner_radius = 1e12
	await frames()
	check(panel._visual_style._outer[0].is_equal_approx(Vector2(0,70)),"huge radius safely normalizes to min border-box half")
	for extent in [Vector2.ZERO,Vector2(0.01,0.02),Vector2(30,10)]:
		panel.width = extent.x
		panel.height = extent.y
		panel.border_width = 1000
		await frames()
		await image()
		check(panel.layout_size==extent,"zero/near-zero and oversized border safe: "+str(extent))
	panel.width = 180
	panel.height = 140
	panel.border_width = 2.5
	panel.corner_radius = "30px"
	panel.background_texture = gradient
	panel.owner = ui
	await frames()
	var scene := PackedScene.new()
	check(scene.pack(ui)==OK and ResourceSaver.save(scene,"res://s04-resource.tscn")==OK,"native rounded texture Resource scene saves")
	ui.free()
	await frames()
	check(gradient.changed.get_connections().is_empty() and gradient.gradient.changed.get_connections().size()<=1,"free disconnects surface texture and nested gradient subscriptions")
	var restored = load("res://s04-resource.tscn").instantiate()
	root.add_child(restored)
	await frames()
	var surface = restored.get_layout_children()[0]
	check(surface.background_texture is GradientTexture2D and surface.corner_radius=="30px" and surface.layout_size==Vector2(180,140),"native texture/radius PackedScene reload retains values and native drawing")
	restored.free()
	await frames()
	await states()
	await clipping()
	await gallery()
	check(State.records.is_empty(),"all surface description records released")
	print("S04_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S04_RUNTIME_OK")
	quit(1 if failed else 0)
func states():
	var ui := Entry.new()
	ui.direction = "column"
	ui.width = 300
	ui.height = 180
	ui.background_color = "#142536"
	var button := Action.new()
	button.width = 200
	button.height = 80
	button.corner_radius = 24
	button.text = "Native"
	ui.add_child(button)
	var toggle = preload("res://addons/estragon/runtime/node/toggle.gd").new()
	toggle.width = 200
	toggle.height = 80
	toggle.corner_radius = 24
	ui.add_child(toggle)
	root.add_child(ui)
	await frames()
	var geometry: int = button._visual_style.geometry_count
	var stats: Dictionary = button.get_layout_stats()
	for pair in [[true,false,"#505050"],[true,true,"#252525"],[false,false,"#383838"]]:
		button._set_pointer_state(pair[0],pair[1])
		await frames()
		var pixels: Image = await image()
		check(close(pixels.get_pixel(80,6),Color(pair[2])) and close(pixels.get_pixel(0,0),Color("#142536")),"rounded shared effective pointer state "+pair[2])
	button.disabled = true
	toggle.value = true
	await frames()
	var pixels: Image = await image()
	check(close(pixels.get_pixel(80,6),Color("#303030")) and close(pixels.get_pixel(80,86),Color("#227a60")),"rounded disabled/checked colors preserve native widget precedence")
	check(button._visual_style.geometry_count==geometry and button.get_layout_stats()==stats and button.get_label_origin().x>=14,"pointer/state redraws reuse contour and normal label/padding geometry")
	ui.free()
	await frames()
func clipping():
	var ui := Entry.new()
	ui.width = 600
	ui.height = 400
	ui.background_color = "#142536"
	var box := Box.new()
	box.width = 300
	box.height = 160
	box.padding = 10
	box.border_width = 2
	var custom := Action.new()
	custom.width = 500
	custom.height = 60
	custom.background_color = Color.GREEN
	custom.hover_background_color = Color.GREEN
	custom.pressed.connect(hit)
	box.add_child(custom)
	var native := Button.new()
	native.custom_minimum_size = Vector2(500,60)
	native.pressed.connect(hit)
	box.add_child(native)
	ui.add_child(box)
	box.owner = ui
	custom.owner = ui
	native.owner = ui
	root.add_child(ui)
	await frames()
	click(Vector2(450,30))
	click(Vector2(450,100))
	await frames()
	check(hits==2 and box._scroll==null,"default 500px native/custom overflow clicks outside 300px box")
	var identity := custom.get_instance_id()
	box.clip_content = true
	await frames()
	var pixels: Image = await image()
	click(Vector2(450,30))
	click(Vector2(450,100))
	press(Vector2(30,100),true)
	press(Vector2(450,100),false)
	await frames()
	check(hits==2 and close(pixels.get_pixel(450,30),Color("#142536")) and pixels.get_pixel(30,30).g>0.9,"clip_content clips paint and captured native/custom input to content rectangle")
	click(Vector2(30,100))
	await frames()
	check(hits==3 and native.has_focus(),"clipped native Control retains native focus and once-only click")
	var stats := [box.get_layout_stats(),custom.get_layout_stats()]
	box.clip_content = false
	await frames()
	click(Vector2(450,30))
	await frames()
	check(hits==4 and custom.get_instance_id()==identity and native.owner==ui and stats==[box.get_layout_stats(),custom.get_layout_stats()],"disable clip restores overflow on retained nodes without remeasure")
	box.clip_content = true
	box.vertical_scroll = true
	await frames()
	check(box._scroll._content.get_child_count()==2 and box.get_child_count(true)==3,"scroll and explicit clip share one helper ancestry")
	box.vertical_scroll = false
	await frames()
	check(box._scroll._clip.clip_contents and box.scroll_range==Vector2.ZERO,"disabling scroll retains explicit rectangular clip")
	box.scale = Vector2(1.1,1.2)
	box.position = Vector2(30,40)
	press(box.get_global_transform_with_canvas()*Vector2(30,100),true)
	press(box.get_global_transform_with_canvas()*Vector2(450,100),false)
	await frames()
	check(hits==4,"transformed clipping cancels outside native release")
	var scene := PackedScene.new()
	box.owner = ui
	custom.owner = ui
	native.owner = ui
	check(scene.pack(ui)==OK and ResourceSaver.save(scene,"res://s04-clipped.tscn")==OK,"native clip persistence packs owners and private ancestry")
	ui.free()
	await frames()
	var restored = load("res://s04-clipped.tscn").instantiate()
	root.add_child(restored)
	await frames()
	var restored_box = restored.get_layout_children()[0]
	check(restored_box.clip_content and restored_box.get_layout_children().size()==2,"native clip PackedScene reload preserves direct children")
	restored.free()
	await frames()
func gallery():
	var host = load("res://app/generated/SurfaceGallery.gd").new()
	root.add_child(host)
	await frames()
	var ui = host.get_node("UI")
	var panels = ui.get_layout_child("Panels")
	var round = panels.get_layout_child("Round")
	var identity: int = round.get_instance_id()
	for size in [Vector2i(320,240),Vector2i(640,480),Vector2i(1000,800)]:
		root.size = size
		await frames()
		check(ui.layout_size==Vector2(size) and round.get_instance_id()==identity,"responsive native surface gallery identity at "+str(size))
		var pixels: Image = await image()
		pixels.save_png("res://surface-gallery-"+str(size.x)+".png")
		ui.scroll_offset = Vector2(0,ui.scroll_range.y)
		await frames()
		pixels = await image()
		pixels.save_png("res://surface-gallery-end-"+str(size.x)+".png")
	var runs: int = State.records[host.get_instance_id()].runs
	var stats: Dictionary = round.get_layout_stats()
	round.corner_radius = "4vw"
	round.background_color = Color.PINK
	await frames()
	check(stats==round.get_layout_stats() and State.records[host.get_instance_id()].runs==runs,"imperative visual writes never recompose or relayout")
	host.props = {"corner_radius_top_left":"0px","background_texture":host.PANEL_TEXTURE}
	await frames()
	host.props = {}
	await frames()
	check(round.corner_radius_top_left=="auto" and round.background_texture==null and round.get_instance_id()==identity,"spread omission restores local surface defaults")
	host.radius = "12px"
	await frames()
	check(round.corner_radius=="12px" and round.get_layout_stats()==stats,"reactive Gogo radius changes retain geometry and identity")
	var idle := [ui.get_layout_stats(),round.get_visual_style_stats(),round._visual_style.geometry_count]
	round.corner_radius = round.corner_radius
	round.background_texture = round.background_texture
	await frames()
	check(idle==[ui.get_layout_stats(),round.get_visual_style_stats(),round._visual_style.geometry_count],"settled surface geometry and redraw counters idle quiet")
	host.free()
	await frames()
