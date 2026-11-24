extends SceneTree
const Core=preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Geometry=preload("res://addons/estragon/runtime/node/internal/scrollbar_geometry.gd")
const Length=preload("res://addons/estragon/runtime/node/internal/length.gd")
var failed:=false
var checks:=0
func check(ok:bool,label:String):
	checks+=1;failed=failed or not ok;print("U04_MATH ",label,": ",ok)
func near_rect(a:Rect2,b:Rect2): return a.position.distance_to(b.position)<0.001 and a.size.distance_to(b.size)<0.001
func model(axes:Vector2=Vector2(1,1),border:Vector4=Vector4(5,5,5,5),padding:Vector4=Vector4(20,20,20,20),outer:Vector2=Vector2(400,300),vertical=12,horizontal=16):
	var c=Core.new();c.configure(Vector3(outer.x,outer.y,0),0,false,1);c.border=border;c.padding=padding;c.scroll_axes=axes
	c.length_specs.vertical_scrollbar_width=Length.parse(vertical,"edge");c.length_specs.horizontal_scrollbar_height=Length.parse(horizontal,"edge")
	var child=Core.new();child.configure(Vector3(-1,700,0),0,false);child.length_specs.width=Length.parse("100%","extent");c.set_children([child]);c.measure();c.arrange(Vector3(outer.x,outer.y,0));return c
func _initialize():
	var c=model(Vector2(0,1));var g=c.scroll_geometry
	check(g.chrome==Rect2(5,5,390,290) and g.inner==Rect2(25,25,350,250),"A independent border-inner B and pre-gutter P")
	check(g.viewport==Rect2(25,25,338,250) and g.vertical==Rect2(383,5,12,290),"A track383..395, viewport25..363 unchanged")
	check(g.vertical.position.x-g.viewport.end.x==20 and c.children[0].size.x==338 and c.size.x==400,"A inside right padding gap and unchanged child/owner width")
	c=model();g=c.scroll_geometry
	check(g.viewport==Rect2(25,25,338,234),"B exact child clip V")
	check(g.vertical==Rect2(383,5,12,274) and g.horizontal==Rect2(5,279,378,16) and g.corner==Rect2(383,279,12,16),"B exact tracks and corner at border edge")
	check(not g.viewport.intersects(g.vertical) and not g.viewport.intersects(g.horizontal) and not g.viewport.intersects(g.corner) and not g.vertical.intersects(g.horizontal),"B all physical regions disjoint")
	c=model(Vector2(1,0));g=c.scroll_geometry
	check(g.viewport==Rect2(25,25,350,234) and g.horizontal==Rect2(5,279,390,16) and g.vertical.size.x==0,"horizontal only spans all B width")
	c=model(Vector2.ZERO);g=c.scroll_geometry
	check(g.viewport==g.inner and g.thickness==Vector2.ZERO,"disabled axes consume no gutters")
	c=model(Vector2(1,1),Vector4(3,7,9,11),Vector4(13,17,19,23),Vector2(420,280),"5%","10%");g=c.scroll_geometry
	check(g.chrome==Rect2(3,7,408,262) and g.inner==Rect2(16,24,376,222),"asymmetric B/P")
	check(near_rect(g.viewport,Rect2(16,24,357.2,199.8)) and near_rect(g.vertical,Rect2(392.2,7,18.8,239.8)) and near_rect(g.horizontal,Rect2(3,246.8,389.2,22.2)),"asymmetric fractional percent geometry")
	check(absf(g.vertical.position.x-g.viewport.end.x-19)<0.001 and absf(g.horizontal.position.y-g.viewport.end.y-23)<0.001,"right/bottom padding remains between content and track")
	c=model(Vector2(0,1),Vector4(5,5,5,5),Vector4(20,20,20,20),Vector2(400,300),"5%");g=c.scroll_geometry
	check(g.thickness.x==17.5 and g.viewport.size.x==332.5 and g.vertical==Rect2(377.5,5,17.5,290),"5% still uses P350, never chrome B390")
	for target in [0,"150%"]:
		c=model(Vector2(1,1),Vector4(5,5,5,5),Vector4(20,20,20,20),Vector2(400,300),target,target);g=c.scroll_geometry
		check(g.thickness==(Vector2.ZERO if target is int else Vector2(350,250)),"zero/oversized cap still uses P "+str(target))
		check(g.viewport.size.x>=0 and g.viewport.size.y>=0 and g.vertical.end.x<=395 and g.horizontal.end.y<=295,"capped tracks stay inside border "+str(target))
	for axes in [Vector2.ZERO,Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
		for outer in [Vector2(8,7),Vector2(0,0),Vector2(40,35)]:
			c=model(axes,Vector4(10,10,10,10),Vector4(20,20,20,20),outer,"150%","150%");g=c.scroll_geometry
			var safe=true
			for key in ["vertical","horizontal","corner"]:
				var rect:Rect2=g[key];safe=safe and rect.size.x>=0 and rect.size.y>=0 and rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=outer.x and rect.end.y<=outer.y
			check(safe and g.thickness==Vector2.ZERO,"tiny/zero border box, no physical strip "+str(axes)+str(outer))
	print("U04_MATH_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("U04_MATH_OK")
	quit(1 if failed else 0)
