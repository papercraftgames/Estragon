extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
    checks += 1
    if not value:
        failures += 1
        push_error("Package: "+message)
func _initialize() -> void: run.call_deferred()
func settle() -> void:
    for index in range(6): await process_frame
func click(button: Node2D) -> void:
    var point: Vector2 = button.get_global_transform_with_canvas()*(button.layout_size*0.5)
    for down in [true,false]:
        var event := InputEventMouseButton.new()
        event.position = point
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        Input.parse_input_event(event)
        await process_frame
func run() -> void:
    check(OS.get_environment("PATH").ends_with("no-tools"),"native consumer authoring/runtime has no external compiler PATH")
    check(not FileAccess.file_exists("res://tools/pack-addon.ts") and not FileAccess.file_exists("res://bun.lock"),"consumer has no repository contributor toolchain")
    root.size = Vector2i(640,420)
    var scene: Node = load("res://examples/counter/Counter.tscn").instantiate()
    root.add_child(scene)
    await settle()
    var label = scene.ui.get_node("Panel/Count")
    var button = scene.ui.get_node("Panel/Actions/Increment")
    var original_id: int = label.get_instance_id()
    check(scene.count==0 and label.text=="Count: 0","package-built canonical reactive Counter mounts")
    await click(button)
    await settle()
    check(scene.count==1 and label.text=="Count: 1" and label.get_instance_id()==original_id,"native pointer updates model and retained label through installed addon")
    scene.count += 2
    await settle()
    check(label.text=="Count: 3" and button.pressed.get_connections().size()==1,"native source signal updates without duplicate handlers")
    check(FileAccess.file_exists("res://addons/estragon/editor/plugin.cfg"),"configured plugin path exists in the installed tree")
    check(not FileAccess.file_exists("res://addons/estragon/package.json"),"addon root contains no package manager/runtime payload")
    var viewport_connections: int = root.get_signal_connection_list("size_changed").size()
    var root_children: int = root.get_child_count()
    var spatial = preload("res://addons/estragon/runtime/node/estragon_3d.gd").new()
    check(spatial.pixels_per_unit==100.0,"installed Node3D entry defaults to100 logical pixels per world unit")
    check(spatial.set_extent(Vector3(3,4,5))==OK,"numeric Node3D set_extent accepts all three length axes")
    root.add_child(spatial)
    await settle()
    check(spatial.get_layout_root()==spatial and spatial.get_layout_stats().flush>0,"installed Node3D entry coordinator actively flushes its independent scope")
    check(spatial.layout_size.is_equal_approx(Vector3(0.03,0.04,0.05)),"default100 Node3D numeric lengths convert to world extents")
    print("PACKAGE_SPATIAL_DEFAULT ",spatial.pixels_per_unit," ",spatial.layout_size)
    var child = preload("res://addons/estragon/runtime/node/component_3d.gd").new()
    child.width = "50%"
    child.height = "50%"
    child.depth = "50%"
    spatial.add_child(child)
    var independent = preload("res://addons/estragon/runtime/node/estragon_3d.gd").new()
    independent.pixels_per_unit = 1.0
    check(independent.set_extent(Vector3(3,4,5))==OK,"explicit1 Node3D set_extent accepts historical world-unit numerics")
    independent.position = Vector3(7,8,9)
    spatial.add_child(independent)
    await settle()
    check(child.layout_size.is_equal_approx(Vector3(0.015,0.02,0.025)),"Node3D percentages use parent content already converted to world units")
    check(independent.get_layout_root()==independent and independent.layout_size.is_equal_approx(Vector3(3,4,5)) and independent.position==Vector3(7,8,9),"nested explicit Node3D Entry keeps independent size and native position")
    spatial.width = "3px"
    spatial.height = "4px"
    spatial.depth = "5px"
    await settle()
    check(spatial.layout_size.is_equal_approx(Vector3(0.03,0.04,0.05)) and spatial.width=="3px" and spatial.height=="4px" and spatial.depth=="5px","Node3D px strings retain specs and match default numeric conversion")
    spatial.pixels_per_unit = 1.0
    check(spatial.set_extent(Vector3(3,4,5))==OK,"explicit1 migration selects scale before assigning numeric extent")
    await settle()
    check(spatial.layout_size.is_equal_approx(Vector3(3,4,5)),"explicit1 Node3D numeric lengths retain historical world extents")
    check(child.layout_size.is_equal_approx(Vector3(1.5,2,2.5)) and independent.layout_size.is_equal_approx(Vector3(3,4,5)),"Node3D scale change updates percentage descendants without changing independent Entry size")
    print("PACKAGE_SPATIAL_EXPLICIT ",spatial.pixels_per_unit," ",spatial.layout_size," child=",child.layout_size)
    var spatial_ref: WeakRef = weakref(spatial)
    var child_ref: WeakRef = weakref(child)
    var independent_ref: WeakRef = weakref(independent)
    spatial.free()
    await settle()
    check(spatial_ref.get_ref()==null and child_ref.get_ref()==null and independent_ref.get_ref()==null,"free releases Node3D entries and their actual native children")
    check(root.get_child_count()==root_children and root.get_signal_connection_list("size_changed").size()==viewport_connections,"Node3D teardown restores root membership and viewport subscriptions")
    var binding = load("res://examples/counter/generated/Binding.gd").new()
    root.add_child(binding)
    await settle()
    var toggle = binding.get_node("Toggle")
    check(not binding.enabled and not toggle.value,"relocated two-way binding mounts")
    toggle.pressed.emit()
    await settle()
    check(binding.enabled and toggle.value,"native edit commits through generated relocated binding")
    binding.enabled = false
    await settle()
    check(not toggle.value,"bindable projection reaches retained native toggle")
    binding.free()
    scene.free()
    await settle()
    check(preload("res://addons/estragon/runtime/composition/state.tres").records.is_empty(),"consumer free releases external view records")
    print("PACKAGE_RUNTIME_ASSERTIONS ",checks," failures=",failures)
    if failures==0: print("PACKAGE_RUNTIME_OK")
    quit(1 if failures else 0)
