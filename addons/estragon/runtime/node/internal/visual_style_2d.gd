@tool
extends RefCounted
## Local values and native paint only. No parent lookup, cascade or Nodes.
const COLORS := ["background_color","border_color"]
var colors := {"background_color":Color.TRANSPARENT,"border_color":Color.TRANSPARENT}
var parse_count := 0
var draw_count := 0
var command_count := 0
var redraw_count := 0
static func has_api(script) -> bool:
	while script is Script:
		if script.get_script_constant_map().get("ESTRAGON_VISUAL_STYLE",false): return true
		script = script.get_base_script()
	return false
static func supported(script) -> bool:
	var current = script
	while current is Script:
		if current.get_script_constant_map().get("ESTRAGON_LEGACY_PAINT",false): return false
		current = current.get_base_script()
	return has_api(script)
static func property(name: String) -> bool:
	return name in COLORS or name in ["border_width","border_top_width","border_right_width","border_bottom_width","border_left_width"]
static func registered(script, name: String) -> bool:
	return name in COLORS and supported(script)
static func parse_color(value) -> Dictionary:
	if value is Color:
		for channel in [value.r,value.g,value.b,value.a]:
			if not is_finite(channel): return {"error":"Color channels must be finite"}
		return {"color":value}
	if value is String:
		var text: String = value.strip_edges()
		if text=="transparent": return {"color":Color.TRANSPARENT}
		if text.begins_with("#") and text.length() in [4,5,7,9]:
			var valid := true
			for index in range(1,text.length()):
				if not text[index].to_lower() in "0123456789abcdef": valid = false
			if valid: return {"color":Color(text)}
	return {"error":"Color requires a native Color, #rgb/#rgba/#rrggbb/#rrggbbaa or transparent"}
func assign(name: String, value) -> bool:
	var parsed := parse_color(value)
	parse_count += 1
	if parsed.has("error"):
		push_error("Estragon style '"+name+"': "+parsed.error)
		return false
	colors[name] = parsed.color
	return true
func _rect(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	if rect.size.x<=0 or rect.size.y<=0 or color.a<=0: return
	canvas.draw_rect(rect,color)
	command_count += 1
func paint(canvas: CanvasItem, extent: Vector2, border: Vector4) -> void:
	draw_count += 1
	if extent.x<=0 or extent.y<=0: return
	_rect(canvas,Rect2(Vector2.ZERO,extent),colors.background_color)
	# Filled strips stay inside the border-box, including fractional/huge edges.
	# Top/bottom own the corners; side strips never double-blend those pixels.
	var left := minf(border.x,extent.x)
	var right := minf(border.z,maxf(0,extent.x-left))
	var top := minf(border.y,extent.y)
	var bottom := minf(border.w,maxf(0,extent.y-top))
	var color: Color = colors.border_color
	_rect(canvas,Rect2(0,0,extent.x,top),color)
	_rect(canvas,Rect2(0,extent.y-bottom,extent.x,bottom),color)
	_rect(canvas,Rect2(0,top,left,maxf(0,extent.y-top-bottom)),color)
	_rect(canvas,Rect2(extent.x-right,top,right,maxf(0,extent.y-top-bottom)),color)
