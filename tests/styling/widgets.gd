extends RefCounted
const Text = preload("res://addons/estragon/runtime/node/text.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
const Toggle = preload("res://addons/estragon/runtime/node/toggle.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Build = preload("res://addons/estragon/editor/build_service.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
class SinglePaint:
	extends Node2D
	func _draw() -> void:
		draw_rect(Rect2(0,0,20,20),Color("#2288aa80"))
var events: Array = []
func edited(value: bool) -> void: events.append(value)
func layout_trace(node) -> Array:
	return [node.get_layout_stats(),node.lengths.parse_count,node.get_visual_style_stats()]
func run(p) -> void:
	var entry = Entry.new()
	entry.width = 600
	entry.height = 400
	p.root.add_child(entry)
	var label = Text.new()
	label.text = "First\nSecond"
	label.padding = 6
	label.padding_left = 11
	label.border_width = 2
	entry.add_child(label)
	var button = UiButton.new()
	button.text = "Continue"
	entry.add_child(button)
	await p.frames()
	p.check(label.layout_size==label._measure_label()+Vector2(21,16) and label.get_label_origin()==Vector2(13,8),"S02 text natural metrics add shared padding/border once; baseline origin inside content")
	p.check(button.layout_size==button._measure_label()+Vector2(28,16) and button.padding=="auto" and button.padding_left=="auto","S02 unstyled UiButton preserves14x8 as local defaults, with no authored side overrides")
	for value in [10,0,"2.5px","auto"]:
		button.padding = value
		await p.frames()
		var edge: Vector4 = Vector4(14,8,14,8) if value is String and value=="auto" else Vector4.ONE*float(value if not value is String else 2.5)
		p.check(button.layout.model.padding==edge,"S02 authored uniform padding replaces class defaults including zero: "+str(value))
	button.padding_right = "3px"
	button.padding = 10
	button.padding_left = "5%"
	button.border_width = 2
	button.width = 240
	button.height = 80
	await p.frames()
	p.check(button.layout.model.padding==Vector4(30,10,3,10),"S02 percentage padding side and shorthand precedence are immediate-parent based")
	var expected: Vector2 = button.get_content_rect().position+(button.get_content_rect().size-button._measure_label())/2
	p.check(button.get_label_origin().is_equal_approx(expected),"S02 UiButton label centers in asymmetric border+padding content")
	var size: Vector2 = label.layout_size
	label.text += " longer"
	await p.frames()
	p.check(label.layout_size.x>size.x,"S02 text change remeasures intrinsic text")
	size = label.layout_size
	label.font_size += 4
	await p.frames()
	p.check(label.layout_size.y>size.y,"S02 font size change reflows text")
	var font := FontVariation.new()
	font.base_font = label.font
	label.font = font
	await p.frames()
	var changes: int = label.get_layout_stats().measure
	var old_width: float = label.layout_size.x
	font.spacing_glyph = 4
	await p.frames()
	p.check(label.layout_size.x>old_width and label.get_layout_stats().measure>changes and font.changed.is_connected(label._content_changed),"S02 native font Resource metric change remains observed")
	var rect = Rect.new()
	p.check(rect.fill==Color.WHITE and rect.get_background_color()==Color.WHITE,"S02 unstyled Rect remains white")
	rect.background_color = "#12345680"
	p.check(rect.fill==Color("#12345680") and rect.background_color is String,"S02 canonical background retains string and fill reads normalized drawn Color")
	rect.fill = Color.CORAL
	p.check(rect.get_background_color()==Color.CORAL and rect.background_color==Color.CORAL,"S02 native fill alias shares one canonical background, last write wins")
	rect.background_color = "#123456"
	var packed := PackedScene.new()
	packed.pack(rect)
	var restored = packed.instantiate()
	p.check(restored.background_color=="#123456" and restored.fill==Color("#123456"),"S02 Rect pack/reload stores canonical authored type without alias overwrite")
	restored.free()
	rect.free()
	var copy := PackedScene.new()
	button.padding = "auto"
	copy.pack(button)
	restored = copy.instantiate()
	p.check(restored.padding=="auto" and restored.padding_right=="3px","S02 native UiButton padding fallback and explicit sides survive pack/reload")
	restored.free()
	for spec in [[false,false,false,"#514174"],[true,false,false,"#705a9e"],[true,true,false,"#302440"],[false,true,false,"#514174"],[true,true,true,"#38343f"]]:
		button.disabled = spec[2]
		button._set_pointer_state(spec[0],spec[1])
		p.check(button.get_background_color()==Color(spec[3]),"S02 original unstyled pointer palette/precedence "+str(spec))
	entry.free()
	await p.frames()
	await gallery(p)
	await language(p)
func gallery(p) -> void:
	var host = load("res://app/generated/WidgetGallery.gd").new()
	p.root.add_child(host)
	await p.frames()
	var panel = host.get_node("UI/Panel")
	var normal = panel.get_node("Buttons/Normal")
	var hover = panel.get_node("Buttons/Hover")
	var held = panel.get_node("Buttons/Held")
	var disabled = panel.get_node("Buttons/Disabled")
	var toggle = panel.get_node("Edits/Controlled")
	var native = panel.get_node("Edits/Native")
	var caption = panel.get_node("Caption")
	var styled = panel.get_node("Rects/Styled")
	var record = State.records[host.get_instance_id()]
	var identities: Array = host.find_children("*","",true,false).map(func(n): return [n.get_instance_id(),n.get_parent().get_instance_id(),n.owner])
	events.clear()
	toggle.value_changed.connect(edited)
	for viewport in [Vector2i(640,480),Vector2i(1000,800)]:
		p.root.size = viewport
		await p.frames()
		p.check(identities==host.find_children("*","",true,false).map(func(n): return [n.get_instance_id(),n.get_parent().get_instance_id(),n.owner]),"S02 all widget/nested/native IDs, parents and owners survive responsive resize")
		hover._set_pointer_state(true,false)
		held._set_pointer_state(true,true)
		await p.frames()
		var image: Image = p.capture("widgets-"+str(viewport.x))
		for sample in [[caption,Color("#142a3a")],[styled,Color("#2288aa")],[normal,Color("#355e92")],[hover,Color("#477dbb")],[held,Color("#23446e")],[disabled,Color("#313947")],[toggle,Color("#227a60")]]:
			var node = sample[0]
			var point: Vector2i = Vector2i(node.global_position+Vector2(5,5))
			p.check(p.close_color(image.get_pixelv(point),sample[1]),"S02 native widget background pixel "+str(node.name)+" at"+str(viewport))
		var point: Vector2i = Vector2i(styled.global_position+Vector2(1,10))
		p.check(p.close_color(image.get_pixelv(point),Color("#e9efff")),"S02 Rect border stays visible over canonical fill")
		point = Vector2i(toggle.global_position+Vector2(10,toggle.layout_size.y-5))
		p.check(p.close_color(image.get_pixelv(point),Color("#65f4b0")),"S02 checked indicator preserves its native display color inside border")
	# Compare translucent Rect to one independent native draw_rect, not a formula
	# tied to a renderer color-space assumption or a second framework painter.
	var reference := SinglePaint.new()
	styled.get_parent().add_child(reference)
	reference.position = styled.position+Vector2(150,0)
	styled.background_color = "#2288aa80"
	await p.frames()
	var alpha_image: Image = p.capture("widgets-alpha")
	p.check(p.close_color(alpha_image.get_pixelv(Vector2i(styled.global_position+Vector2(5,5))),alpha_image.get_pixelv(Vector2i(reference.global_position+Vector2(5,5)))),"S02 translucent Rect matches exactly one native background pass")
	reference.free()
	styled.background_color = "#2288aa"
	var content: Rect2 = normal.get_content_rect()
	var glyphs := 0
	var caption_glyphs := 0
	for y in range(int(normal.layout_size.y)):
		for x in range(int(normal.layout_size.x)):
			var pixel: Color = alpha_image.get_pixelv(Vector2i(normal.global_position)+Vector2i(x,y))
			if p.close_color(pixel,Color.WHITE):
				glyphs += 1
				p.check(content.grow(1).has_point(Vector2(x,y)),"S02 foreground label pixel lies in centered inner content") if glyphs==1 else null
	var caption_content: Rect2 = caption.get_content_rect()
	for y in range(int(caption.layout_size.y)):
		for x in range(int(caption.layout_size.x)):
			var pixel: Color = alpha_image.get_pixelv(Vector2i(caption.global_position)+Vector2i(x,y))
			if p.close_color(pixel,Color("#ffcc66")):
				caption_glyphs += 1
				p.check(caption_content.has_point(Vector2(x,y)),"S02 direct Text glyph pixel begins after border and padding") if caption_glyphs==1 else null
	p.check(glyphs>0 and caption_glyphs>0,"S02 actual legible label and explicit-color Text foreground pixels are present")
	var toggle_before := [toggle.get_layout_stats(),toggle.lengths.parse_count,record.runs]
	toggle.checked_background_color = "#207050"
	toggle._set_pointer_state(true,true)
	await p.frames()
	p.check(toggle.get_background_color()==Color("#207050") and toggle_before==[toggle.get_layout_stats(),toggle.lengths.parse_count,record.runs],"S02 checked color wins over hover/pressed with redraw-only scheduling")
	toggle.disabled = true
	await p.frames()
	p.check(toggle.get_background_color()==Color("#38343f"),"S02 disabled color wins over checked")
	toggle.disabled = false
	toggle._set_pointer_state(false,false)
	p.click(normal,normal.layout_size)
	p.click(native,native.size)
	p.click(disabled,disabled.layout_size)
	await p.frames()
	p.check(host.clicks==1 and host.native_clicks==1,"S02 native and styled Buttons activate exactly once; disabled blocks activation")
	p.click(toggle,toggle.layout_size)
	await p.frames()
	p.check(not host.enabled and not toggle.value and events==[false],"S02 controlled Toggle emits exactly one edit and updates Gogo bool")
	host.enabled = true
	await p.frames()
	p.check(toggle.value and events==[false],"S02 model-to-Toggle projection never emits reciprocal user edit")
	var before := [panel.get_layout_stats(),normal.get_layout_stats(),normal.lengths.parse_count,record.runs]
	var draw: int = normal.get_visual_style_stats().draw
	normal.background_color = "#102030"
	normal.hover_background_color = "#304050"
	normal.pressed_background_color = Color("#506070")
	normal.disabled_background_color = "#708090"
	normal._set_pointer_state(true,true)
	await p.frames()
	p.check(before==[panel.get_layout_stats(),normal.get_layout_stats(),normal.lengths.parse_count,record.runs] and normal.get_visual_style_stats().draw>draw,"S02 local state/color updates redraw without layout, length parse or recomposition")
	print("S02_STATE_COUNTERS ",JSON.stringify({"before":before,"after":[panel.get_layout_stats(),normal.get_layout_stats(),normal.lengths.parse_count,record.runs],"draw_before":draw,"paint_after":normal.get_visual_style_stats()}))
	var idle := layout_trace(normal)
	normal.pressed_background_color = Color("#506070")
	normal._set_pointer_state(true,true)
	await p.frames()
	p.check(idle==layout_trace(normal),"S02 equal state/color writes and idle frames are quiet")
	var measure: int = normal.get_layout_stats().measure
	normal.padding = 12
	await p.frames()
	p.check(normal.get_layout_stats().measure>measure,"S02 widget padding change remeasures shared layout")
	var key1 = panel.get_node("Keys/Key1")
	host.flipped = true
	host.extra = true
	await p.frames()
	p.check(panel.get_node("Keys/Key1")==key1 and panel.has_node("Extra") and panel.get_node("Buttons/Normal")==normal,"S02 keyed/conditional reconciliation keeps existing widget identities")
	host.extra = false
	await p.frames()
	p.check(not panel.has_node("Extra") and toggle.value_changed.is_connected(edited),"S02 conditional removal preserves surviving widget subscriptions")
	var count := 0
	for connection in normal.draw.get_connections():
		if connection.callable.get_method()=="_paint_visual_style": count += 1
	p.check(count==1,"S02 exactly one native shared background/border hook per widget")
	var parent = normal.get_parent()
	parent.remove_child(normal)
	parent.add_child(normal)
	await p.frames()
	count = 0
	for connection in normal.draw.get_connections():
		if connection.callable.get_method()=="_paint_visual_style": count += 1
	p.check(count==1,"S02 widget re-entry reconnects the shared hook once")
	# Native hit testing applies the complete parent transform to the OUTER box.
	parent.position += Vector2(17,19)
	parent.rotation = 0.12
	parent.scale = Vector2(1.1,0.9)
	await p.frames()
	var outer: Vector2 = normal.get_global_transform_with_canvas()*Vector2(1,1)
	p.check(normal._pointer_contains(outer) and not normal._pointer_contains(normal.get_global_transform_with_canvas()*Vector2(-1,-1)),"S02 transformed UiButton outer border-box, including padding/border, is the native hit area")
	p.click(normal,Vector2(2,2))
	await p.frames()
	p.check(host.clicks==2,"S02 actual transformed outer-edge click activates exactly once")
	var rejected = Element.new(Rect,{"fill":Color.WHITE,"background_color":"#123456"},{},[],"WidgetGallery.gogo:7:3")
	p.check(not record._preflight(rejected,null,host) and record.validation_error.contains("WidgetGallery.gogo:7:3: Rect fill and background_color conflict"),"S02 dynamic Rect dual fill conflict is source-located before commit")
	for pair in [[UiButton,"hover_background_color"],[UiButton,"pressed_background_color"],[UiButton,"disabled_background_color"],[Toggle,"checked_background_color"],[Rect,"fill"]]:
		var props := {str(pair[1]):"#invalid"}
		rejected = Element.new(pair[0],props,{},[],"WidgetGallery.gogo:8:3")
		p.check(not record._preflight(rejected,null,host) and record.validation_error.begins_with("WidgetGallery.gogo:8:3:"),"S02 dynamic invalid widget color preflight "+str(pair[1]))
	p.check(normal.get_background_color()!=Color.BLACK and normal.get_parent()==parent,"S02 rejected descriptions leave live native state/tree intact")
	normal.width = 0
	normal.height = 0
	await p.frames()
	var commands: int = normal.get_visual_style_stats().commands
	normal.background_color = "#abcdef"
	normal.border_color = "#fedcba"
	await p.frames()
	p.check(normal.get_content_rect().size==Vector2.ZERO and normal.get_visual_style_stats().commands==commands,"S02 zero-size widget emits no background/border rectangles or invalid geometry")
	host.free()
	await p.frames()
func language(p) -> void:
	var path := "res://app/WidgetGallery.gogo"
	var original := FileAccess.get_file_as_string(path)
	var output := "res://app/generated/WidgetGallery.gd"
	var code := FileAccess.get_file_as_bytes(output)
	var maps := FileAccess.get_file_as_bytes(output+".map.json")
	var script = load(output)
	for invalid in ['background_color="#xx"','fill={Color.WHITE} background_color="#2288aa"','hover_background_color="#xx"','checked_background_color={true}']:
		var changed: String = original.replace('background_color="#2288aa"',invalid) if not invalid.begins_with("hover_") and not invalid.begins_with("checked_") else original.replace('hover_background_color="#477dbb"',invalid) if invalid.begins_with("hover_") else original.replace('checked_background_color="#227a60"',invalid)
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(changed)
		file.close()
		var report := Build.run_build()
		p.check(not report.ok and not report.source_diagnostics.is_empty() and FileAccess.get_file_as_bytes(output)==code and FileAccess.get_file_as_bytes(output+".map.json")==maps and load(output)==script,"S02 invalid widget source transaction retains code/maps/cached Script: "+invalid)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(original)
	file.close()
	p.check(Build.run_build().ok,"S02 widget source repair restores actual-path build")
	var head := 'extends Node2D\nconst Widget = preload("res://addons/estragon/runtime/node/rect.gd")\nfunc view(): return '
	for attrs in ['fill={Color.WHITE} background_color="#123456"','background_color="#123456" fill={Color.WHITE}']:
		var result := Compiler.compile(head+'<Widget '+attrs+' />\n',"res://conflict.gogo","res://generated/Conflict.gd")
		p.check(not result.ok and result.diagnostics[0].message.contains("conflict"),"S02 Rect conflict rejects both source assignment orders")
