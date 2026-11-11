extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
var checks := 0
var home: Node2D
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L03_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for index in range(8): await process_frame
func capture(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://"+name+".png")
func rect(node: Node2D) -> Rect2:
	return Rect2(node.global_position,node.layout_size)
func snapshot(label: String) -> void:
	var data := {}
	for path in ["UI/Column/Hello","UI/Column/Fun","UI/Column/Settings/Row/Exit","UI/Column/Rose/Row/RoseText","UI/Column/Rose/Row/RoseButton"]:
		var node = home.get_node_or_null(path)
		if node != null: data[path] = {"position":str(node.global_position),"size":str(node.layout_size)}
	var file := FileAccess.open("res://"+label+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	print("L03_GEOMETRY ",label," ",JSON.stringify(data))
func click(node: Node2D) -> void:
	var point: Vector2 = node.get_global_transform_with_canvas()*(node.layout_size/2)
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	home = load("res://app/generated/Home.gd").new()
	home.name = "Home"
	root.add_child(home)
	await frames()
	var column = home.get_node("UI/Column")
	var settings = column.get_node("Settings")
	var rose = column.get_node("Rose")
	var exit_button = settings.get_node("Row/Exit")
	var rose_text = rose.get_node("Row/RoseText")
	var before := OS.get_environment("L03_BEFORE")=="1"
	snapshot("before" if before else "after")
	await capture("before" if before else "after")
	if before:
		print("L03_BEFORE_OK")
		home.free()
		await frames()
		quit(); return
	check(rose_text.layout_size.x>0 and rose_text.layout_size.y>0,"nested Rose Text receives nonzero allocation")
	check(exit_button.global_position.y>=column.get_node("Fun").global_position.y+column.get_node("Fun").layout_size.y,"Settings Exit follows outer texts below flex spacer")
	check(rose_text.global_position.y>=rect(exit_button).end.y and rect(rose_text).end.y<=home.extent.y+0.1,"Rose follows Settings in bottom VBox region without overlap")
	check(settings.get_node("Row").position==Vector2.ZERO and settings.position.y>0,"host placement does not duplicate root offset")
	check(settings.owner==null and exit_button.owner==null,"managed hosts and views remain transient native Nodes")
	if OS.get_environment("L03_EXIT")=="1":
		print("L03_EXIT_READY")
		await click(exit_button)
		check(false,"actual Exit handler must quit the child process")
		quit(1); return
	print("L03_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L03_RUNTIME_OK")
	home.free()
	await frames()
	quit(1 if failed else 0)
