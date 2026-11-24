extends SceneTree
const Core=preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Geometry=preload("res://addons/estragon/runtime/node/internal/scrollbar_geometry.gd")
const Length=preload("res://addons/estragon/runtime/node/internal/length.gd")
const Styles=preload("res://addons/estragon/runtime/node/internal/scrollbar_style.gd")
var failed:=false
var checks:=0
func check(ok:bool,label:String):
	checks+=1;failed=failed or not ok;print("U03_MATH ",label,": ",ok)
func core(w=400,h=300):
	var c=Core.new();c.configure(Vector3(w,h,0),0,false,1);return c
func spec(c,key,value): c.length_specs[key]=Length.parse(value,Length.domain(key))
func _initialize():
	var owner=core();owner.scroll_axes=Vector2(1,1)
	spec(owner,"vertical_scrollbar_width","5%");spec(owner,"horizontal_scrollbar_height","10%")
	var child=core();spec(child,"width","100%");child.requested.x=-1;child.requested.y=600
	owner.set_children([child]);owner.prepare(Vector3(800,600,0),Vector2(800,600));owner.measure();owner.arrange(Vector3(400,300,0))
	var g=owner.scroll_geometry
	check(g.viewport==Rect2(0,0,380,270) and g.vertical==Rect2(380,0,20,270) and g.horizontal==Rect2(0,270,380,30) and g.corner==Rect2(380,270,20,30),"dual tracks and corner exact")
	check(child.size.x==380 and child.requested.x==380 and owner.size==Vector3(400,300,0),"core prepares child from V without changing parent")
	owner=core();owner.scroll_axes=Vector2(0,1);owner.padding=Vector4(20,20,20,20);owner.border=Vector4(5,5,5,5);spec(owner,"vertical_scrollbar_width","5%")
	child=core(-1,20);spec(child,"width","75%");owner.set_children([child]);owner.measure();owner.arrange(Vector3(400,300,0))
	check(owner.scroll_geometry.thickness.x==17.5 and owner.scroll_geometry.viewport.size.x==332.5 and child.size.x==249.375,"insets precede single percentage gutter")
	owner=core(-1,300);owner.scroll_axes=Vector2(0,1);child=core(100,600);owner.set_children([child]);owner.arrange(owner.measure())
	check(owner.size.x==100 and owner.scroll_geometry.viewport.size.x==88,"gutter never adds outside growth to an auto border-box")
	for record in [[Vector2(0,1),{},Vector2(388,300)],[Vector2(1,0),{"horizontal_scrollbar_height":Length.parse(16,"edge")},Vector2(400,284)],[Vector2.ZERO,{},Vector2(400,300)],[Vector2(1,1),{"scrollbar_size":Length.parse(0,"inset")},Vector2(400,300)],[Vector2(1,1),{"scrollbar_size":Length.parse("150%","inset")},Vector2.ZERO]]:
		g=Geometry.snapshot(Rect2(0,0,400,300),record[0],record[1],Vector2(800,600))
		check(g.viewport.size==record[2] and g.viewport.size.x>=0 and g.viewport.size.y>=0,"axes/zero/capped stable geometry "+str(record[0])+str(record[1]))
	for unit in ["12px",".125in",".3175cm","3.175mm","12.7q","9pt",".75pc","1.5vw","2vh","2vmin","1.5vmax"]:
		g=Geometry.snapshot(Rect2(0,0,400,300),Vector2(0,1),{"scrollbar_size":Length.parse(unit,"inset")},Vector2(800,600))
		check(absf(g.thickness.x-12)<0.001,"shared unit "+unit)
	for value in [-1,NAN,INF,"auto","2em","calc(1px)",false,{},[]]: check(Length.parse(value,"inset").has("error"),"shared rejects "+str(value))
	for value in [{"unknown":0},{"vertical":{"horizontal":{}}},{"track_color":Color(NAN,0,0)},{"thumb_color":false},{"track_border_width":-1},{"thumb_corner_radius":"auto"},{"thumb_stylebox":Texture2D.new()},{"vertical":3},{3:"bad"}]: check(not Styles.error(value).is_empty(),"style rejects "+str(value))
	var explicit=StyleBoxFlat.new();var values=Styles.values({"thumb_stylebox":explicit,"thumb_color":"#ffffff","vertical":{"thumb_color":"#ababab"}},"vertical")
	check(Styles.error(values).is_empty() and Styles.box(values,"thumb","",Vector2(12,300),Vector2(800,600))==explicit and Styles.color(values,"thumb_color")==Color("#ababab"),"axis override and exact explicit Resource identity")
	check(Styles.error({"track_color":"transparent","horizontal":{"track_border_width":"1px","thumb_corner_radius":0}}).is_empty(),"valid flat and axis skins")
	print("U03_MATH_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("U03_MATH_OK")
	quit(1 if failed else 0)
