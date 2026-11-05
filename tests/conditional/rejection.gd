extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func settle() -> void:
	for index in range(6): await process_frame
func check(value: bool, message: String) -> void:
	print("CONDITIONAL_REJECTION_CHECK ",message,": ",value)
	if not value: failures += 1
func run() -> void:
	var script := GDScript.new()
	script.source_code = 'extends "res://examples/conditional/generated/Counter.gd"\nfunc build_view() -> Element:\n\tvar view: Element = super.build_view()\n\tif count==3: view.children[0].children[1].properties.name = "Always"\n\treturn view\n'
	if script.reload()!=OK: quit(1); return
	var scene = script.new()
	root.add_child(scene)
	await settle()
	var record = State.records[scene.get_instance_id()]
	var prompt = scene.get_node("UI/Panel/Prompt")
	var before := [record.allocations,record.frees,record.writes,record.runs]
	scene.count = 3
	await settle()
	check(scene.get_node("UI/Panel/Prompt")==prompt and not scene.has_node("UI/Panel/Action"),"invalid desired branch retains previous mounted Nodes")
	check(before==[record.allocations,record.frees,record.writes,record.runs],"whole-tree rejection performs zero writes/allocations/frees")
	scene.count = 0
	await settle()
	check(scene.get_node("UI/Panel/Prompt")==prompt and record.runs==before[3]+1,"repair recovers through existing source subscription")
	scene.free()
	if failures==0: print("CONDITIONAL_REJECTION_OK")
	quit(1 if failures else 0)
