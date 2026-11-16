extends SceneTree
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Length = preload("res://addons/estragon/runtime/node/internal/length.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
var failed := false
var overflow_clicks := 0
func clicked(): overflow_clicks += 1
func check(ok: bool, label: String):
	print("UX01_C ",label,": ",ok)
	failed = failed or not ok
func model(width, minimum, maximum):
	var result := Core.new()
	result.set_lengths({"width":Length.parse(width,"extent"),"min_width":Length.parse(minimum,"edge"),"max_width":Length.parse(maximum,"edge")},0,0,1,0)
	result.prepare(Vector3(600,100,0),Vector2(1000,800))
	return result
func _initialize(): run.call_deferred()
func run():
	check(model(500,0,300).measure().x==300,"explicit500 max300")
	check(model(100,140,"auto").measure().x==140,"minimum wins width100")
	check(model(500,140,120).measure().x==140,"minimum wins conflicting maximum")
	check(model(500,0,0).measure().x==0,"zero max")
	check(model(500,0,"50%").measure().x==300,"parent percent max")
	check(model(500,0,"20vw").measure().x==200,"viewport max")
	var parent := Core.new()
	parent.configure(Vector3(500,100,0),0,false)
	var first = model("auto",0,100)
	first.grow = 1
	var second = model("auto",0,"auto")
	second.grow = 1
	parent.set_children([first,second])
	parent.arrange(parent.measure())
	check(first.size.x==100 and second.size.x==400,"growth water-fills after maximum, no double allocation")
	for strategy in ["stack","wrap","grid"]:
		var containing := Core.new()
		containing.configure(Vector3(500,200,0),0,false)
		containing.strategy = strategy
		if strategy=="grid": containing.grid_config = {"columns":1}
		containing.alignment = ["end","stretch","start"]
		var capped := Core.new()
		capped.set_lengths({"width":Length.parse(400,"extent"),"height":Length.parse("auto","extent"),"max_width":Length.parse(120,"edge"),"max_height":Length.parse(60,"edge")},0,0,1,0)
		containing.set_children([capped])
		containing.arrange(containing.measure())
		check(capped.size.x==120 and capped.size.y<=60,"shared "+strategy+" two-axis cap before alignment/stretch")
	var native_floor = model(500,0,50)
	native_floor.allocation_minimum = Vector3(80,0,0)
	check(native_floor.measure().x==80,"native allocation floor wins maximum")
	var entry := Entry.new()
	entry.width = 640
	entry.height = 240
	var box := Box.new()
	box.direction = "column"
	box.width = 500
	box.max_width = 300
	var child := Rect.new()
	child.width = 500
	child.height = 30
	child.background_color = "#00ff00"
	box.add_child(child)
	var action = preload("res://addons/estragon/runtime/node/button.gd").new()
	action.width = 500
	action.height = 40
	action.pressed.connect(clicked)
	box.add_child(action)
	entry.add_child(box)
	root.add_child(entry)
	for frame in range(8): await process_frame
	check(box.layout_size.x==300 and child.layout_size.x==500 and box.clip_children==0,"max caps owner only, no descendant clip or shrink")
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_pixel(450,10).g>0.9,"actual child paints beyond max-limited parent")
	var input := InputEventMouseButton.new()
	input.position = Vector2(450,50)
	input.button_index = MOUSE_BUTTON_LEFT
	input.pressed = true
	root.push_input(input,true)
	input = input.duplicate()
	input.pressed = false
	root.push_input(input,true)
	check(overflow_clicks==1,"ordinary visible overflow keeps actual outside-parent hit target")
	image.save_png("res://ux01-visible-overflow.png")
	entry.free()
	for frame in range(5): await process_frame
	if not failed: print("UX01_C_OK")
	quit(1 if failed else 0)
