extends SceneTree
func _initialize():
    var result=preload("res://addons/estragon/editor/build_service.gd").run_build()
    print("LAYOUT01_BUILD ",JSON.stringify(result))
    if result.ok: print("LAYOUT01_BUILD_OK")
    quit(0 if result.ok else 1)
