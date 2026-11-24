@tool
extends RefCounted
## One noncircular snapshot: own pre-gutter P -> V, tracks and corner.
const Length=preload("length.gd")
static func thickness(inner: Vector2,axes: Vector2,specs: Dictionary,viewport: Vector2) -> Vector2:
	var shared: Dictionary=specs.get("scrollbar_size",{"unit":"native","value":12.0})
	var vertical: Dictionary=specs.get("vertical_scrollbar_width",shared)
	var horizontal: Dictionary=specs.get("horizontal_scrollbar_height",shared)
	if vertical.unit=="auto": vertical=shared
	if horizontal.unit=="auto": horizontal=shared
	var result=Vector2.ZERO
	if axes.y>0: result.x=maxf(0,Length.resolve(vertical,inner.x,viewport))
	if axes.x>0: result.y=maxf(0,Length.resolve(horizontal,inner.y,viewport))
	if inner.x>=0: result.x=minf(inner.x,result.x)
	if inner.y>=0: result.y=minf(inner.y,result.y)
	return result
static func snapshot(inner: Rect2,axes: Vector2,specs: Dictionary,viewport: Vector2) -> Dictionary:
	var strips=thickness(inner.size,axes,specs,viewport)
	var size=Vector2(maxf(0,inner.size.x-strips.x),maxf(0,inner.size.y-strips.y))
	return {"inner":inner,"viewport":Rect2(inner.position,size),"thickness":strips,"vertical":Rect2(inner.position+Vector2(size.x,0),Vector2(strips.x,size.y)),"horizontal":Rect2(inner.position+Vector2(0,size.y),Vector2(size.x,strips.y)),"corner":Rect2(inner.position+size,strips)}
