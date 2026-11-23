extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var checks := 0
var failed := false
func check(value: bool,label: String):
	checks += 1
	print("UI02_REJECTION ",label,": ",value)
	failed = failed or not value
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var source='extends Node2D\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")\nconst Checkbox = preload("res://addons/estragon/runtime/node/checkbox.gd")\nconst Model = preload("res://app/generated/Model.gd")\n@bindable var model: Model = Model.new()\n@bindable var props: Dictionary = {}\nfunc build_view() -> Element:\n    return <Entry name="UI"><Checkbox name="Check" value={self.model.flag} {...self.props} /></Entry>\n'
	var result = Compiler.compile(source,"app/Rejection.gogo","res://app/generated/Rejection.gd")
	check(result.ok,"rejection fixture compiles")
	if not result.ok: quit(1); return
	var script := GDScript.new()
	script.resource_path = "res://app/generated/Rejection.gd"
	script.source_code = result.code
	check(script.reload()==OK,"rejection fixture native semantics")
	var host = script.new()
	root.add_child(host)
	await frames()
	var node = host.get_node("UI/Check")
	var record = State.records[host.get_instance_id()]
	for props in [{"disabled":"bad"},{"value":3},{"checked_background_color":"bad"},{"width":"bad"}]:
		print("UI02_EXPECTED_REJECTION_BEGIN")
		host.props = props
		await frames()
		print("UI02_EXPECTED_REJECTION_END")
		check(host.get_node("UI/Check")==node and record.validation_error.contains("app/Rejection.gogo:"),"dynamic invalid props retain whole native view with authored diagnostic")
		host.props = {}
		await frames()
		check(host.get_node("UI/Check")==node and record.validation_error.is_empty(),"repair retains native Checkbox identity")
	var previous = host.model
	print("UI02_EXPECTED_REJECTION_BEGIN")
	host.model = null
	await frames()
	print("UI02_EXPECTED_REJECTION_END")
	check(host.get_node("UI/Check")==node and record.validation_error.contains("app/Rejection.gogo:9:") and record.validation_error.contains("Bool binding endpoint"),"present null path rejects atomically at authored value span")
	node.value = true
	check(not previous.flag,"stale retained control cannot edit disconnected current model path")
	host.model = previous.get_script().new()
	await frames()
	check(not node.value and record.validation_error.is_empty(),"new source signal alone repairs invalid null binding")
	var scene := PackedScene.new()
	check(scene.pack(host)==OK,"authored Checkbox host packs independently of native managed output")
	var copy = scene.instantiate()
	root.add_child(copy)
	await frames()
	var restored = copy.get_node("UI/Check")
	restored.value = true
	check(copy.model.flag and restored.value_changed.get_connections().size()==1 and copy.get_meta_list().is_empty(),"pack/reload reconstructs one implicit binding and no metadata on user Nodes")
	copy.free()
	host.free()
	await frames()
	check(State.records.is_empty(),"disposing rejected/repaired hosts releases all records")
	print("UI02_REJECTION_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI02_REJECTION_OK")
	quit(1 if failed else 0)
