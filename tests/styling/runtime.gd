extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const ButtonUI = preload("res://addons/estragon/runtime/node/button.gd")
const Style = preload("res://addons/estragon/runtime/node/internal/visual_style_2d.gd")
const Length = preload("res://addons/estragon/runtime/node/internal/length.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S01_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(10): await process_frame
func capture(name: String) -> Image:
	RenderingServer.force_draw(false)
	var image := root.get_texture().get_image()
	image.save_png("res://"+name+".png")
	return image
func close_color(a: Color, b: Color) -> bool:
	return absf(a.r-b.r)<0.02 and absf(a.g-b.g)<0.02 and absf(a.b-b.b)<0.02
func click(button: Node, size: Vector2) -> void:
	var position: Vector2 = button.get_global_transform_with_canvas()*(size/2)
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion,true)
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	parser_and_compiler()
	await geometry()
	await gallery()
	await lifecycle()
	await overrides()
	await language()
	check(State.get("records").is_empty(),"composition records released")
	print("S01_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S01_RUNTIME_OK")
	quit(1 if failed else 0)
func parser_and_compiler() -> void:
	for text in ["#abc","#abcd","#123456","#12345678","#AbCdEf"," transparent "]:
		check(not Style.parse_color(text).has("error"),"shared valid color "+text)
	for value in ["black","#12","#gggggg","#123456789","",true,1,[],Color(NAN,0,0,1)]:
		check(Style.parse_color(value).has("error"),"shared invalid color "+str(value))
	check(Style.parse_color("#abcd").color==Color("#aabbccdd"),"short RGBA normalizes without losing authored input")
	var head := 'extends Node2D\nconst Box = preload("res://addons/estragon/runtime/node/box.gd")\nfunc view(): return '
	for attribute in ['background_color="not-color"','border_color="#ggg"','border_width="auto"','border_left_width="-1px"','border_width={NAN}','border_width="1em"','background_color={true}']:
		var report := Compiler.compile(head+'<Box '+attribute+' />\n',"res://styles.gogo","res://generated/Styles.gd")
		check(not report.ok and not report.diagnostics.is_empty(),"source-located style rejection "+attribute)
	for script in ["text","rect","button"]:
		var legacy_head: String = 'extends Node2D\nconst Widget = preload("res://addons/estragon/runtime/node/'+script+'.gd")\nfunc view(): return '
		var legacy := Compiler.compile(legacy_head+'<Widget background_color="#123456" />\n',"res://legacy.gogo")
		check(not legacy.ok,"legacy "+script+" style paint explicitly deferred rather than overpainted")
	var base = preload("res://addons/estragon/runtime/node/component_2d.gd").new()
	base.background_color = "#123456"
	var separate := Box.new()
	base.add_child(separate)
	check(base.background_color=="#123456" and separate.background_color=="transparent" and separate._visual_style.colors.background_color==Color.TRANSPARENT,"base participant style is local; child transparent value is never inherited")
	base.free()
	var valid := Compiler.compile(head+'<Box background_color="#252b38" border_color={Color.WHITE} border_width="2px" border_left_width="auto" />\n',"res://styles.gogo","res://generated/Styles.gd")
	check(valid.ok and valid.code.contains('"#252b38"'),"Color union and border units compile with retained quoted specs")
func geometry() -> void:
	var entry := Entry.new()
	entry.width = 300
	entry.height = 120
	entry.border_width = 2
	entry.border_right_width = 4
	entry.padding_left = 10
	entry.padding_right = 20
	entry.padding_top = 7
	entry.padding_bottom = 9
	entry.background_color = "#252b38"
	entry.border_color = "#8295bc"
	var child := Box.new()
	child.width = "100%"
	child.height = "100%"
	child.background_color = "#344139"
	entry.add_child(child)
	root.add_child(entry)
	await frames()
	check(entry.layout_size==Vector2(300,120) and child.layout_size==Vector2(264,100) and child.position==Vector2(12,9),"300 border-box gives264 content atX12, vertical border/padding once")
	check(entry.layout.model.border==Vector4(2,2,4,2),"asymmetric border resolves centrally")
	entry.border_left_width = "1px"
	entry.border_width = "3px"
	await frames()
	check(entry.layout.model.border==Vector4(1,3,4,3) and child.position.x==11,"edge overrides win when shorthand is assigned later")
	entry.border_left_width = "auto"
	entry.border_right_width = "auto"
	await frames()
	check(entry.layout.model.border==Vector4(3,3,3,3) and child.layout_size.x==264,"explicit auto removes local side override")
	entry.border_width = "1%"
	root.size = Vector2i(640,480)
	await frames()
	check(entry.layout.model.border.is_equal_approx(Vector4(6.4,4.8,6.4,4.8)),"root border percentage shares visible viewport axes")
	root.size = Vector2i(1000,800)
	await frames()
	check(entry.layout.model.border==Vector4(10,8,10,8) and child.layout_size==Vector2(250,88),"root percent border resize reflows actual content without reparsing")
	entry.border_width = 0
	entry.padding_left = 0
	entry.padding_right = 0
	entry.padding_top = 0
	entry.padding_bottom = 0
	child.width = "auto"
	child.height = "auto"
	child.border_width = 3
	var leaf := Rect.new()
	leaf.width = 40
	leaf.height = 20
	child.add_child(leaf)
	await frames()
	check(child.layout_size==Vector2(46,26) and leaf.position==Vector2(3,3),"natural measurement includes border exactly once")
	child.width = "100%"
	child.height = "100%"
	child.border_width = "2%"
	await frames()
	check(child.layout.model.border.is_equal_approx(Vector4(6,2.4,6,2.4)),"ordinary percent borders reference immediate containing content, not viewport")
	entry.width = 0
	entry.height = 0
	entry.border_width = 20
	await frames()
	check(Vector2(entry.layout.model.content_reference.x,entry.layout.model.content_reference.y)==Vector2.ZERO and child.layout_size==Vector2.ZERO,"zero content clamps safely without negative geometry")
	capture("zero-box")
	entry.free()
	await frames()
func gallery() -> void:
	var home = load("res://app/generated/StyleGallery.gd").new()
	root.add_child(home)
	await frames()
	var entry = home.get_node("UI")
	var panel = entry.get_node("Panel")
	var header = panel.get_node("Header")
	var plain = panel.get_node("Plain")
	var settings = panel.get_node("Settings")
	var native: Button = settings.get_node("Controls/Native")
	var ui = settings.get_node("Controls/Ui")
	var rose = panel.get_node("Rose/Rose")
	var identity := [panel.get_instance_id(),native.get_instance_id(),ui.get_instance_id()]
	var record = State.get("records")[home.get_instance_id()]
	var runs: int = record.runs
	var traces: Array = []
	for size in [Vector2i(640,480),Vector2i(1000,800),Vector2i(640,480)]:
		root.size = size
		await frames()
		var content: Vector3 = panel.layout.model.content_reference
		check(header.layout_size.x==content.x/2 and settings.get_node("Controls").layout_size.x==content.x and rose.layout_size.x==content.x,"nested50/100% views use border+padding content at "+str(size))
		check(panel.position==Vector2(16,16) and panel.layout_size==Vector2(size)-Vector2(32,32),"margin stays outside painting and remaining allocation")
		check(identity==[panel.get_instance_id(),native.get_instance_id(),ui.get_instance_id()] and record.runs==runs,"resize preserves native/UI/Gogo identity without recomposition")
		click(native,native.size)
		click(ui,ui.layout_size)
		check(ui._hovered and not ui._held,"Estragon Button native pointer hover/press state remains intact")
		var image := capture("styled-"+str(size.x))
		check(close_color(image.get_pixel(1,1),Color("#171b24")) and close_color(image.get_pixel(20,30),Color("#252b38")) and close_color(image.get_pixel(17,60),Color("#8295bc")),"native pixels show root/panel background and asymmetric border")
		traces.append({"viewport":str(size),"panel":str(panel.layout_size),"content":str(content),"header":str(header.layout_size),"native":str(native.global_position),"ui":str(ui.global_position)})
	check(settings.native_clicks==3 and settings.ui_clicks==3,"actual native Control and Estragon Button clicks survive styled slots")
	check(plain.color==Color.WHITE and rose.get_node("Caption").color==Color("#ffcc66"),"Text direct/default colors never inherit Box styling")
	var plain_measure: int = plain.layout.model.measure_count
	var before := [entry.get_layout_stats(),panel.get_layout_stats(),header.get_layout_stats(),record.runs]
	var drawn: int = panel.get_visual_style_stats().draw
	panel.background_color = Color("#102030")
	panel.border_color = "#ee8844"
	await frames()
	check(before==[entry.get_layout_stats(),panel.get_layout_stats(),header.get_layout_stats(),record.runs] and panel.get_visual_style_stats().draw>drawn,"color-only changes redraw without measure/arrange/recomposition")
	check(panel.background_color is Color and panel.border_color=="#ee8844","authored getters retain Color/string while caches normalize")
	var parses: int = panel.get_visual_style_stats().parse
	var same: int = panel.get_visual_style_stats().draw
	panel.border_color = "#ee8844"
	await frames()
	check(panel.get_visual_style_stats().parse==parses and panel.get_visual_style_stats().draw==same,"equal color writes remain quiet")
	panel.border_bottom_width = "11px"
	await frames()
	check(panel.get_layout_stats().arrange>before[1].arrange and plain.layout.model.measure_count==plain_measure and rose.global_position.y+rose.layout_size.y<=panel.global_position.y+panel.layout_size.y-23+0.01,"border changes reflow content while the unaffected intrinsic leaf stays measured")
	var idle := [entry.get_layout_stats(),panel.get_layout_stats(),panel.get_visual_style_stats(),panel.lengths.parse_count,record.runs]
	await frames()
	check(idle==[entry.get_layout_stats(),panel.get_layout_stats(),panel.get_visual_style_stats(),panel.lengths.parse_count,record.runs],"idle has zero draw/layout/parsing/recomposition work")
	var rejected := Element.new(Box,{"background_color":"#broken"},{},[],"Style.gogo:9:4")
	check(not record._preflight(rejected,null,home) and record.validation_error.contains("Style.gogo:9:4: invalid style"),"computed invalid color preflight is source-located and transactional")
	rejected = Element.new(Text,{"background_color":"#123456"},{},[],"Style.gogo:10:1")
	check(not record._preflight(rejected,null,home) and record.validation_error.contains("deferred to S02"),"dynamic legacy widget style rejects before any native paint/property commit")
	rejected = Element.new(Box,{"border_width":"auto"},{},[],"Style.gogo:10:4")
	check(not record._preflight(rejected,null,home) and record.validation_error.contains("invalid length"),"computed border misuse rejects before any commit")
	capture("changed-style")
	var file := FileAccess.open("res://style-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(traces))
	file.close()
	home.free()
	await frames()
func lifecycle() -> void:
	var entry := Entry.new()
	entry.width = 100
	entry.height = 80
	var custom = preload("custom_box.gd").new()
	custom.width = 40
	custom.height = 30
	custom.background_color = "#123456"
	custom.border_color = "#abcdef"
	custom.border_width = 1
	entry.add_child(custom)
	root.add_child(entry)
	await frames()
	var image := capture("derived-hook")
	check(close_color(image.get_pixel(10,10),Color("#123456")) and close_color(image.get_pixel(2,2),Color.RED),"derived _draw cannot bypass shared native style draw hook")
	entry.remove_child(custom)
	entry.add_child(custom)
	await frames()
	var connected := 0
	for connection in custom.draw.get_connections():
		if connection.callable.get_method()=="_paint_visual_style": connected += 1
	check(connected==1,"native re-entry retains exactly one style hook")
	var packed := PackedScene.new()
	packed.pack(custom)
	var restored = packed.instantiate()
	check(restored.background_color=="#123456" and restored.border_width==1 and restored.border_color=="#abcdef","native pack/reload retains authored style values")
	restored.free()
	entry.free()
	await frames()
func language() -> void:
	var path := "res://app/StyleGallery.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/StyleGallery.gd"
	var bytes := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script: Script = load(output)
	for invalid in ['background_color="garbage"','border_color="#xxzz00"','border_width="auto"','border_width="-2px"','border_width="1em"','border_width={INF}']:
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(original.replace('background_color="#171b24"',invalid))
		file.close()
		var report := Build.run_build()
		check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==bytes and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"invalid style preserves generated bytes/map/Script "+invalid)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	check(Build.run_build().ok,"style source repair recovers actual-path build")

func overrides() -> void:
	var host = load("res://app/generated/Overrides.gd").new()
	root.add_child(host)
	await frames()
	var box = host.get_child(0).get_child(0)
	var id: int = box.get_instance_id()
	check(box.layout.model.border==Vector4(1,3,3,3),"GGX local edge overrides shorthand")
	host.edge = false
	await frames()
	check(box.get_instance_id()==id and box.border_left_width=="auto" and box.layout.model.border==Vector4(3,3,3,3),"omitting a previously declared GGX side restores shorthand on the same node")
	host.free()
	await frames()
