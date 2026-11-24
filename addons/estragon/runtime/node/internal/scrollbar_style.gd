@tool
extends RefCounted
## Local native scrollbar skin contract. No themes, Nodes or layout policy.
const Length=preload("length.gd")
const Visual=preload("visual_style_2d.gd")
const COLORS=["track_color","thumb_color","thumb_hover_color","thumb_pressed_color","corner_color","track_border_color","thumb_border_color"]
const LENGTHS=["track_corner_radius","thumb_corner_radius","track_border_width","thumb_border_width"]
const BOXES=["track_stylebox","thumb_stylebox","thumb_hover_stylebox","thumb_pressed_stylebox"]
const DEFAULTS={"track_color":"#292929","thumb_color":"#727272","thumb_hover_color":"#919191","thumb_pressed_color":"#aaaaaa","corner_color":"#383838","track_border_color":"transparent","thumb_border_color":"transparent","track_corner_radius":0,"thumb_corner_radius":0,"track_border_width":0,"thumb_border_width":0}
static func error(value, nested: bool=false) -> String:
	if not value is Dictionary: return "scrollbar_style requires Dictionary"
	for key in value:
		if not key is String: return "scrollbar_style keys require String"
		var item=value[key]
		if key in ["vertical","horizontal"] and not nested:
			var problem=error(item,true)
			if not problem.is_empty(): return key+": "+problem
		elif key in COLORS:
			if Visual.parse_color(item).has("error"): return key+" requires a finite Color, hex or transparent"
		elif key in LENGTHS:
			if Length.parse(item,"inset").has("error"): return key+" requires a finite nonnegative Length"
		elif key in BOXES:
			if not item is StyleBox: return key+" requires StyleBox Resource"
		else: return "unknown scrollbar_style key "+key
	return ""
static func values(style: Dictionary, axis: String) -> Dictionary:
	var result=DEFAULTS.duplicate()
	for key in style:
		if key not in ["vertical","horizontal"]: result[key]=style[key]
	result.merge(style.get(axis,{}),true)
	return result
static func color(style: Dictionary,key: String) -> Color: return Visual.parse_color(style[key]).color
static func box(style: Dictionary,part: String,state: String,rect: Vector2,viewport: Vector2) -> StyleBox:
	var key=part+state+"_stylebox"
	if style.has(key): return style[key]
	var result=StyleBoxFlat.new()
	var tint=part+state+"_color"
	result.bg_color=color(style,tint)
	result.border_color=color(style,part+"_border_color")
	var reference=minf(rect.x,rect.y)
	var border=mini(ceili(reference*0.5),ceili(Length.resolve(Length.parse(style[part+"_border_width"],"inset"),reference,viewport)))
	var radius=mini(ceili(reference*0.5),ceili(Length.resolve(Length.parse(style[part+"_corner_radius"],"inset"),reference,viewport)))
	for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		result.set_border_width(edge,border)
		result.set_content_margin(edge,0)
	for corner in range(4): result.set_corner_radius(corner,radius)
	return result
