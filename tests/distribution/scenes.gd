extends SceneTree
var failures: int = 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	check(not DirAccess.dir_exists_absolute("res://tools") and not FileAccess.file_exists("res://package.json"),"addon distribution has no contributor compiler/toolchain")
	for name in ["counter/Counter","ggx/TwoD","ggx/ThreeD","bindable/Demo","reactive/Demo"]:
		var packed: PackedScene = load("res://examples/"+name+".tscn")
		check(packed!=null and packed.can_instantiate(),"distributed native scene loads: "+name)
		if packed==null: continue
		var scene: Node = packed.instantiate()
		root.add_child(scene)
		for index in range(6): await process_frame
		if name=="counter/Counter":
			check(scene.ui is Node2D and scene.count==0,"native Counter hierarchy")
			scene.increment()
			for index in range(3): await process_frame
			check(scene.count==1 and scene.ui.get_node("Panel/Count").text=="Count: 1","source-authored native Counter executes")
			scene.reset_count()
			check(scene.count==0,"native reset")
		elif name=="bindable/Demo":
			check(scene.model is RefCounted and scene.model.count==5 and scene.events==[[3,4],[4,5]],"source-authored observable model executes from native addon/pack")
		elif name=="reactive/Demo":
			scene.advance()
			for index in range(6): await process_frame
			check(scene.ui.get_node("Panel/Row/Bar").width==160.0 and scene.ui.get_node("Panel/Count").text=="Value: 2","pack contains automatic nested layout/property bindings")
		else:
			check(scene.entry is Node2D if name=="ggx/TwoD" else scene.entry is Node3D,"native dimensional scene hierarchy")
		scene.free()
	check(FileAccess.file_exists("res://examples/counter/Counter.gogo"),"authored source included")
	if failures==0: print("ADDON_DISTRIBUTION_OK")
	quit(0 if failures==0 else 1)
