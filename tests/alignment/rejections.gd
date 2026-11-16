extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L08_REJECTION_CHECK ",label,": ",ok)
	if not ok: failed = true
func frames() -> void:
	for frame in range(5): await process_frame
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var host = load("res://app/generated/RejectionHost.gd").new()
	root.add_child(host)
	await frames()
	var record = State.records[host.get_instance_id()]
	print("L08_EXPECTED_REJECTION_BEGIN")
	await process_frame
	var cases := [
		["box",{"horizontal_align":"stretch"}], ["box",{"vertical_align":"space-between"}], ["box",{"vertical_align":"space-around"}], ["box",{"vertical_align":"space-evenly"}],
		["box",{"direction":"column","vertical_align":"stretch"}], ["box",{"direction":"column","horizontal_align":"space-between"}], ["box",{"direction":"column","horizontal_align":"space-around"}], ["box",{"direction":"column","horizontal_align":"space-evenly"}],
		["box",{"horizontal_align":"bad"}], ["box",{"vertical_align":true}], ["box",{"direction":"bad"}], ["row",{"direction":"column"}], ["column",{"direction":"row"}],
		["box",{"align_self":"space-between"}], ["box",{"align_self":true}], ["box",{"justify":"center"}], ["box",{"align":"end"}]
	]
	for item in cases:
		host.kind = item[0]
		host.props = {"width":300,"height":80}
		await frames()
		var node = host.get_node("UI/Target")
		var before := [node.get_instance_id(),node.get_parent(),node.owner,node.layout_size,record.runs,record.writes]
		host.props = item[1]
		await frames()
		check(before==[node.get_instance_id(),node.get_parent(),node.owner,node.layout_size,record.runs,record.writes] and node==host.get_node("UI/Target"),"invalid final spread retains complete tree/geometry "+str(item))
		check(record.validation_error.contains("app/RejectionHost.gogo:") and record.validation_error.contains("spread key"),"spread/key authored origin "+str(item))
		host.props = {"width":300,"height":80}
		await frames()
		check(record.runs==before[4]+1,"repair recomposes retained node")
	host.kind = "box"
	await frames()
	var child = host.get_node("UI/Target/Child")
	var before: Vector2 = child.position
	host.own = "space-around"
	await frames()
	check(child.position==before and record.validation_error.contains("align_self") and record.validation_error.contains("app/RejectionHost.gogo:"),"direct dynamic align_self rejects with authored source and unchanged placement")
	host.own = "end"
	await frames()
	check(child.align_self=="end","dynamic self repair")
	var box := Box.new()
	var rect := Rect.new()
	box.vertical_align = "space-between"
	box.horizontal_align = "stretch"
	rect.align_self = "space-evenly"
	check(box.vertical_align=="start" and box.horizontal_align=="start" and rect.align_self=="auto","native invalid enum setters preserve prior fields")
	box.free()
	rect.free()
	await process_frame
	print("L08_EXPECTED_REJECTION_END")
	host.free()
	await frames()
	print("L08_REJECTION_ASSERTIONS ",checks," failed=",failed," expected_errors=21")
	if not failed: print("L08_REJECTIONS_OK")
	quit(1 if failed else 0)
