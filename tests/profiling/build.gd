extends SceneTree
const Computation = preload("res://addons/estragon/runtime/composition/computation.gd")
func _initialize() -> void:
    var report := preload("res://addons/estragon/editor/build_service.gd").run_build()
    if not report.ok:
        push_error(str(report.diagnostics))
        quit(1)
        return
    print("PROFILING_BUILD_OK")
    quit()
