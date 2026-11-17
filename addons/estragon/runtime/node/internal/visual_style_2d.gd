@tool
extends RefCounted
## Local values and native paint only. No parent lookup, cascade or Nodes.
const COLORS := ["background_color","border_color","hover_background_color","pressed_background_color","disabled_background_color","checked_background_color"]
const RADII := ["corner_radius","corner_radius_top_left","corner_radius_top_right","corner_radius_bottom_right","corner_radius_bottom_left"]
const SURFACE := ["background_texture","background_texture_mode"]
var radii: Dictionary = {}
var texture: Texture2D
var texture_mode := "stretch"
var _canvas_texture: CanvasTexture
var _gradient: Gradient
var _host: WeakRef
var _viewport: Viewport
var _cache_key: Array = []
var _outer := PackedVector2Array()
var _inner := PackedVector2Array()
var _uv := PackedVector2Array()
var _border_mesh: ArrayMesh
var _rounded := false
var geometry_count := 0
var resource_notifications := 0
var colors := {"background_color":Color.TRANSPARENT,"border_color":Color.TRANSPARENT,"hover_background_color":Color("#705a9e"),"pressed_background_color":Color("#302440"),"disabled_background_color":Color("#38343f"),"checked_background_color":Color("#227a60")}
var parse_count := 0
var draw_count := 0
var command_count := 0
var redraw_count := 0
static func marked(script, marker: String) -> bool:
	while script is Script:
		if script.get_script_constant_map().get(marker,false): return true
		script = script.get_base_script()
	return false
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
	return name in COLORS or name in RADII or name in SURFACE or name in ["border_width","border_top_width","border_right_width","border_bottom_width","border_left_width"]
static func surface_error(name: String, value) -> String:
	if name=="background_texture" and value!=null and not value is Texture2D: return "background_texture requires Texture2D or null"
	if name=="background_texture_mode" and (not value is String or value not in ["stretch","tile"]): return "background_texture_mode requires stretch or tile"
	return ""
func start(host: Node) -> void:
	_host = weakref(host)
	_connect_texture()
	sync_viewport()
func stop() -> void:
	_disconnect_texture()
	if _viewport!=null and _viewport.size_changed.is_connected(_viewport_changed): _viewport.size_changed.disconnect(_viewport_changed)
	_viewport = null
	_host = null
func sync_viewport() -> void:
	var relative := false
	for spec in radii.values():
		if spec.unit in ["vw","vh","vmin","vmax"]: relative = true
	var host = _host.get_ref() if _host!=null else null
	var viewport: Viewport = host.get_viewport() if relative and host!=null and host.is_inside_tree() else null
	if viewport==_viewport: return
	if _viewport!=null and _viewport.size_changed.is_connected(_viewport_changed): _viewport.size_changed.disconnect(_viewport_changed)
	_viewport = viewport
	if _viewport!=null: _viewport.size_changed.connect(_viewport_changed)
func _viewport_changed() -> void:
	var host = _host.get_ref() if _host!=null else null
	if host!=null: host._queue_style_redraw()
func _disconnect_texture() -> void:
	if texture!=null and texture.changed.is_connected(_resource_changed): texture.changed.disconnect(_resource_changed)
	if _gradient!=null and _gradient.changed.is_connected(_resource_changed): _gradient.changed.disconnect(_resource_changed)
	_gradient = null
func _connect_texture() -> void:
	if _host==null or _host.get_ref()==null or texture==null: return
	if not texture.changed.is_connected(_resource_changed): texture.changed.connect(_resource_changed)
	var gradient: Gradient = texture.gradient if texture is GradientTexture2D else null
	if _gradient!=gradient:
		if _gradient!=null and _gradient.changed.is_connected(_resource_changed): _gradient.changed.disconnect(_resource_changed)
		_gradient = gradient
		if _gradient!=null: _gradient.changed.connect(_resource_changed)
func set_texture(value: Texture2D) -> void:
	_disconnect_texture()
	texture = value
	_rebuild_texture()
	_connect_texture()
func _rebuild_texture() -> void:
	_canvas_texture = null
	if texture!=null:
		_canvas_texture = texture.duplicate() if texture is CanvasTexture else CanvasTexture.new()
		if not texture is CanvasTexture: _canvas_texture.diffuse_texture = texture
		_canvas_texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if texture_mode=="tile" else CanvasItem.TEXTURE_REPEAT_DISABLED
	_cache_key = []
func set_texture_mode(value: String) -> void:
	texture_mode = value
	if _canvas_texture!=null: _canvas_texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if value=="tile" else CanvasItem.TEXTURE_REPEAT_DISABLED
	_cache_key = []
func _resource_changed() -> void:
	resource_notifications += 1
	_connect_texture()
	_rebuild_texture()
	var host = _host.get_ref() if _host!=null else null
	if host!=null: host._queue_style_redraw()

# Fixed 16 chords per quarter arc; fractional coordinates never round to native
# StyleBoxFlat integer border widths. Contours/UVs/mesh persist between draws.
func _contour(rect: Rect2, horizontal: Vector4, vertical: Vector4) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers := [rect.position+Vector2(horizontal.x,vertical.x),rect.position+Vector2(rect.size.x-horizontal.y,vertical.y),rect.end-Vector2(horizontal.z,vertical.z),rect.position+Vector2(horizontal.w,rect.size.y-vertical.w)]
	for corner in range(4):
		for step in range(17):
			var angle := PI+corner*PI/2+step*PI/32
			points.append(centers[corner]+Vector2(cos(angle)*horizontal[corner],sin(angle)*vertical[corner]))
	return points
func _unique(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		if result.is_empty() or not result[-1].is_equal_approx(point): result.append(point)
	if result.size()>1 and result[0].is_equal_approx(result[-1]): result.remove_at(result.size()-1)
	return result
func _ray_edge(center: Vector2, direction: Vector2, contour: PackedVector2Array) -> Vector2:
	var distance := INF
	for index in range(contour.size()):
		var point: Vector2 = contour[index]-center
		var edge: Vector2 = contour[(index+1)%contour.size()]-contour[index]
		var denominator := direction.cross(edge)
		if absf(denominator)<1e-10: continue
		var along := point.cross(edge)/denominator
		var across := point.cross(direction)/denominator
		if along>=-0.001 and across>=-0.001 and across<=1.001: distance = minf(distance,maxf(0,along))
	return center+direction*distance
func _ring() -> void:
	# Both contours are convex. Rays through the union of their vertices form
	# nonoverlapping bands even when extreme asymmetric insets clip a corner.
	var center := Vector2.ZERO
	for point in _inner: center += point
	center /= _inner.size()
	var angles: Array = []
	for contour in [_outer,_inner]:
		for point in contour: angles.append((point-center).angle())
	angles.sort()
	var outside := PackedVector2Array()
	var inside := PackedVector2Array()
	for angle in angles:
		var direction := Vector2(cos(angle),sin(angle))
		outside.append(_ray_edge(center,direction,_outer))
		inside.append(_ray_edge(center,direction,_inner))
	var vertices := PackedVector3Array()
	for index in range(angles.size()):
		var next := (index+1)%angles.size()
		for point in [outside[index],outside[next],inside[next],outside[index],inside[next],inside[index]]: vertices.append(Vector3(point.x,point.y,0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	_border_mesh = ArrayMesh.new()
	_border_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
func prepare(extent: Vector2, border: Vector4, resolved: Vector4) -> bool:
	var key := [extent,border,resolved,texture_mode,texture.get_size() if texture!=null else Vector2.ZERO]
	if key==_cache_key: return false
	_cache_key = key
	_rounded = resolved!=Vector4.ZERO
	_outer = PackedVector2Array()
	_inner = PackedVector2Array()
	_uv = PackedVector2Array()
	_border_mesh = null
	if not _rounded and texture==null: return false # Exact S01/S02 fast path.
	geometry_count += 1
	if extent.x<=0 or extent.y<=0: return true
	var radius := resolved
	var scale := 1.0
	for edge in [[extent.x,radius.x+radius.y],[extent.x,radius.w+radius.z],[extent.y,radius.x+radius.w],[extent.y,radius.y+radius.z]]:
		if edge[1]>0: scale = minf(scale,edge[0]/edge[1])
	radius *= scale
	var left := minf(border.x,extent.x)
	var right := minf(border.z,maxf(0,extent.x-left))
	var top := minf(border.y,extent.y)
	var bottom := minf(border.w,maxf(0,extent.y-top))
	var inner_rect := Rect2(left,top,maxf(0,extent.x-left-right),maxf(0,extent.y-top-bottom))
	var outer := _contour(Rect2(Vector2.ZERO,extent),radius,radius)
	_outer = _unique(outer)
	if inner_rect.size.x<=0 or inner_rect.size.y<=0: return true
	var rx := Vector4(maxf(0,radius.x-left),maxf(0,radius.y-right),maxf(0,radius.z-right),maxf(0,radius.w-left))
	var ry := Vector4(maxf(0,radius.x-top),maxf(0,radius.y-top),maxf(0,radius.z-bottom),maxf(0,radius.w-bottom))
	var inner_scale := 1.0
	for edge in [[inner_rect.size.x,rx.x+rx.y],[inner_rect.size.x,rx.w+rx.z],[inner_rect.size.y,ry.x+ry.w],[inner_rect.size.y,ry.y+ry.z]]:
		if edge[1]>0: inner_scale = minf(inner_scale,edge[0]/edge[1])
	rx *= inner_scale
	ry *= inner_scale
	var inner := _contour(inner_rect,rx,ry)
	_inner = _unique(inner)
	if _rounded:
		var intersection := Geometry2D.intersect_polygons(_outer,_inner)
		_inner = _unique(intersection[0]) if not intersection.is_empty() else PackedVector2Array()
	if _inner.size()<3: return true
	if texture!=null:
		var basis := texture.get_size() if texture_mode=="tile" else inner_rect.size
		basis = Vector2(maxf(1,basis.x),maxf(1,basis.y))
		for point in _inner: _uv.append((point-inner_rect.position)/basis)
	if _rounded and border!=Vector4.ZERO:
		_ring()
	return true
static func registered(script, name: String) -> bool:
	if not supported(script): return false
	if name in ["background_color","border_color"]: return true
	if name=="checked_background_color": return marked(script,"ESTRAGON_TOGGLE_STYLE")
	return name in COLORS and marked(script,"ESTRAGON_BUTTON_STYLE")
static func rect_conflict(script, names: Array) -> bool:
	return marked(script,"ESTRAGON_RECT_STYLE") and "fill" in names and "background_color" in names
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
func paint(canvas: CanvasItem, extent: Vector2, border: Vector4, background: Color) -> void:
	draw_count += 1
	if extent.x<=0 or extent.y<=0: return
	if _rounded:
		if background.a>0:
			canvas.draw_colored_polygon(_outer,background)
			command_count += 1
		_paint_texture(canvas)
		if colors.border_color.a>0 and border!=Vector4.ZERO:
			if _border_mesh!=null: canvas.draw_mesh(_border_mesh,null,Transform2D.IDENTITY,colors.border_color)
			else: canvas.draw_colored_polygon(_outer,colors.border_color)
			command_count += 1
		return
	_rect(canvas,Rect2(Vector2.ZERO,extent),background)
	_paint_texture(canvas)
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
func _paint_texture(canvas: CanvasItem) -> void:
	if _canvas_texture==null or _inner.size()<3: return
	canvas.draw_colored_polygon(_inner,Color.WHITE,_uv,_canvas_texture)
	command_count += 1
