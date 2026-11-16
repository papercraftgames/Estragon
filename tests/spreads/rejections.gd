extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var failed := false
func frames() -> void:
	for frame in range(5): await process_frame
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S03_REJECTION_CHECK ",label,": ",ok)
	if not ok: failed = true
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var host = load("res://app/generated/RejectionHost.gd").new()
	root.add_child(host)
	await frames()
	var record = State.records[host.get_instance_id()]
	var cases: Array = [
		["button",null,"Dictionary"],["button",false,"Dictionary"],["button",[1],"Dictionary"],
		["button",{1:true},"key 1"],["button",{"":true},"nonempty"],["button",{NodePath("text"):"bad"},"String/StringName"],
		["button",{"key":"bad"},"'key'"],["button",{"bind:value":true},"'bind:value'"],
		["button",{"style":{}},"'style'"],["button",{"min-width":4},"'min-width'"],
		["button",{"owner":null},"'owner'"],["button",{"script":null},"'script'"],["button",{"multiplayer":null},"'multiplayer'"],
		["button",{"position":"wrong"},"'position'"],["button",{"disabled":"false"},"'disabled'"],
		["button",{"background_color":"bad"},"'background_color'"],["button",{"background_color":Color(NAN,0,0)},"'background_color'"],
		["button",{"min_width":"bad"},"'min_width'"],["button",{"min_height":-1},"'min_height'"],["button",{"padding":INF},"'padding'"],["button",{"border_width":true},"'border_width'"],
		["button",{"pressed":Callable()},"'pressed'"],["button",{"pressed":"pressed"},"'pressed'"],["button",{"pressed":host.wrong_arity},"arity"],
		["rect",{"fill":Color.RED,"background_color":"#ff0000"},"fill and background_color"],["rect",{"fill":"#ff0000"},"finite native Color"],
		["sprite",{"texture":Resource.new()},"Object class"],
		["box",{"direction":"diagonal"},"direction"],["box",{"direction":"row","horizontal_align":"stretch"},"horizontal_align"],
		["toggle",{"value":true},"value"],["toggle",{"value_changed":host.pressed},"value_changed"]
	]
	print("S03_EXPECTED_REJECTION_BEGIN")
	await process_frame
	for item in cases:
		host.kind = item[0]
		var valid := {"width":160,"height":40}
		if item[0]=="sprite": valid = {"visible":true}
		host.props = valid.duplicate()
		await frames()
		var ui = host.get_node("UI")
		var target = ui.get_node("Target")
		var identity := [ui.get_instance_id(),target.get_instance_id(),target.get_parent(),target.owner,record.runs,record.allocations,record.frees]
		var geometry: Vector2 = target.layout_size if item[0]!="sprite" else target.position
		host.props = item[1]
		await frames()
		check(identity==[ui.get_instance_id(),target.get_instance_id(),target.get_parent(),target.owner,record.runs,record.allocations,record.frees] and geometry==(target.layout_size if item[0]!="sprite" else target.position),"rejected computation retains complete tree/geometry "+str(item[2]))
		check(record.validation_error.contains("app/RejectionHost.gogo:") and record.validation_error.contains(item[2]),"spread expression/key diagnostic "+str(item[2]))
		host.props = valid.duplicate()
		await frames()
		check(record.runs==identity[4]+1 and target==ui.get_node("Target"),"repair resumes retained native computation")
	await process_frame
	print("S03_EXPECTED_REJECTION_END")
	host.free()
	await frames()
	print("S03_REJECTION_ASSERTIONS ",checks," failed=",failed," expected_errors=",cases.size())
	if not failed: print("S03_REJECTIONS_OK")
	quit(1 if failed else 0)
