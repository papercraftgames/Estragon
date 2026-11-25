extends SceneTree
var checks := 0
var ok := true
func check(test: bool,label: String):
	checks += 1
	print("UI04_REJECTION_CHECK ",label,": ",test)
	ok = ok and test
func frames():
	for i in range(10): await process_frame
func _initialize(): run.call_deferred()
func run():
	var host = load("res://examples/radio/generated/Radios.gd").new()
	root.add_child(host)
	await frames()
	var row = host.get_node("UI/Grid/Row")
	var a = row.get_node("Optiona")
	var b = row.get_node("Optionb")
	b.grab_focus()
	var identity: int = b.get_instance_id()
	var events: Array = []
	row.value_changed.connect(func(previous,next): events.append([previous,next]))
	for values in [{"c":{"value":"b"}},{"c":{"value":""}},{"c":{"value":false}}]:
		print("UI04_EXPECTED_BEGIN")
		host.option_values = values
		await frames()
		print("UI04_EXPECTED_END")
		check(row.get_node("Optionb").get_instance_id()==identity and b.has_focus() and b.is_selected() and row.value=="b" and events.is_empty(),"invalid desired option set retains mounted identity/focus/value atomically "+str(values))
		host.option_values = {}
		await frames()
		check(row.get_node("Optionc").value=="c" and b.has_focus(),"repair reuses prior native options")
	print("UI04_EXPECTED_BEGIN")
	host.group_props = {"value":false}
	await frames()
	print("UI04_EXPECTED_END")
	check(row.value=="b" and b.has_focus() and events.is_empty(),"wrong group String type rejected before any mounted mutation")
	host.group_props = {}
	await frames()
	print("UI04_EXPECTED_BEGIN")
	a.value = "b"
	print("UI04_EXPECTED_END")
	check(a.value=="a" and row.value=="b" and b.is_selected(),"native duplicate assignment rejects and preserves identity/selection")
	print("UI04_EXPECTED_BEGIN")
	a.value = ""
	print("UI04_EXPECTED_END")
	check(a.value=="a","native empty identity rejects")
	var staged = preload("res://addons/estragon/runtime/node/radio_group.gd").new()
	var staged_a = preload("res://addons/estragon/runtime/node/radio.gd").new()
	staged_a.value = "a"
	staged.add_child(staged_a)
	staged.options()
	var staged_b = preload("res://addons/estragon/runtime/node/radio.gd").new()
	staged_b.value = "b"
	staged.add_child(staged_b)
	print("UI04_EXPECTED_BEGIN")
	staged_a.value = "b"
	print("UI04_EXPECTED_END")
	check(staged_a.value=="a","native duplicate setter rejects after membership changes outside SceneTree")
	staged.free()
	host.option_values = {"a":{"value":"b"},"b":{"value":"a"}}
	await frames()
	check(a.value=="b" and b.value=="a" and a.is_selected() and not b.is_selected(),"valid simultaneous identity swap commits without transient duplicate setter rejection")
	host.option_values = {}
	await frames()
	row.value = "pending"
	await frames()
	check(row.value=="pending" and host.model.choice=="pending" and row.options().all(func(option): return not option.is_selected()),"unknown String is a valid stable pending selection")
	var scope = preload("res://addons/estragon/runtime/composition/state.tres").records[host.get_instance_id()]
	var runs: int = scope.runs
	await frames()
	check(scope.runs==runs,"unmatched pending value has no warning or invalidation loop")
	var source := 'extends Node2D\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")\nconst Group = preload("res://addons/estragon/runtime/node/radio_group.gd")\nconst Model = preload("res://examples/radio/generated/Model.gd")\n@bindable var model: Model = Model.new()\nfunc build_view() -> Element: return <Entry name="NullUI"><Group name="NullGroup" value={self.model.choice} /></Entry>\n'
	var compiled = preload("res://addons/estragon/compiler/compiler.gd").compile(source,"examples/radio/Null.gogo","res://examples/radio/generated/Null.gd")
	var script := GDScript.new()
	script.resource_path = "res://examples/radio/generated/Null.gd"
	script.source_code = compiled.code
	check(compiled.ok and script.reload()==OK,"present null source fixture has native typed String contract")
	var null_host = script.new()
	root.add_child(null_host)
	await frames()
	var mounted = null_host.get_node("NullUI/NullGroup")
	var previous_model = null_host.model
	print("UI04_EXPECTED_BEGIN")
	null_host.model = null
	await frames()
	print("UI04_EXPECTED_END")
	check(mounted.value=="b" and is_instance_valid(mounted),"present null String source rejects and retains mounted output")
	null_host.model = previous_model
	await frames()
	check(null_host.get_node("NullUI/NullGroup")==mounted,"null path repair retains native group")
	null_host.free()

	var nested_source := 'extends Node2D\nconst Element = preload("res://addons/estragon/runtime/composition/element.gd")\nconst Radio = preload("res://addons/estragon/runtime/node/radio.gd")\n@bindable var identity: String = "b"\nfunc build_view() -> Element: return <Radio name="Nested" value={self.identity} />\n'
	var nested_compiled = preload("res://addons/estragon/compiler/compiler.gd").compile(nested_source,"examples/radio/Nested.gogo","res://examples/radio/generated/Nested.gd")
	var nested_script := GDScript.new()
	nested_script.resource_path = "res://examples/radio/generated/Nested.gd"
	nested_script.source_code = nested_compiled.code
	check(nested_compiled.ok and nested_script.reload()==OK,"nested reactive option compiles through existing GGX host")
	var group = preload("res://addons/estragon/runtime/node/radio_group.gd").new()
	group.value = "b"
	var sibling = preload("res://addons/estragon/runtime/node/radio.gd").new()
	sibling.value = "a"
	group.add_child(sibling)
	var nested_host = nested_script.new()
	group.add_child(nested_host)
	var entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd").new()
	entry.add_child(group)
	root.add_child(entry)
	await frames()
	var nested = nested_host.get_node("Nested")
	var nested_id: int = nested.get_instance_id()
	print("UI04_EXPECTED_BEGIN")
	nested_host.identity = "a"
	await frames()
	print("UI04_EXPECTED_END")
	check(nested.value=="b" and nested.get_instance_id()==nested_id and group.value=="b","child composition rejects collisions against nearest native group's retained siblings")
	nested_host.identity = "c"
	await frames()
	check(nested.value=="c" and group.value=="b","nested identity repair retains node and pending group selection")
	entry.free()

	host.free()
	await frames()
	print("UI04_REJECTION_ASSERTIONS ",checks," ok=",ok)
	if ok: print("UI04_REJECTIONS_OK")
	quit(0 if ok else 1)
