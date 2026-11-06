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
    check(FileAccess.file_exists("res://addons/estragon/editor/plugin.cfg"),"documented plugin path exists after explicit copy")
    check(not FileAccess.file_exists("res://addons/estragon/package.json"),"addon root contains no package manager/runtime payload")
    scene.free()
    await settle()
    check(preload("res://addons/estragon/runtime/composition/state.tres").records.is_empty(),"consumer free releases external view records")
    print("PACKAGE_RUNTIME_ASSERTIONS ",checks," failures=",failures)
    if failures==0: print("PACKAGE_RUNTIME_OK")
    quit(1 if failures else 0)
