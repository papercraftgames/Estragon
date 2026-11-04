extends SceneTree
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
var failures: int = 0
var assertions: int = 0
var resized: bool = false
func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		printerr("B2 ASSERTION FAILED: " + message)

func _initialize() -> void:
	var row := Core.new()
	var first := Core.new()
	var second := Core.new()
	check(first.configure(Vector3(10, 5, 0), 0, false) == OK, "fixed2d")
	second.configure(Vector3(20, 7, 0), 0, false)
	row.configure(Vector3(100, -1, 0), 2, true)
	check(row.set_children([first, second]) == OK, "attach")
	check(row.measure() == Vector3(100, 7, 0), "fixed X overrides natural 32")
	row.arrange(row.measured)
	check(first.offset == Vector3(34, 0, 0) and second.offset == Vector3(46, 0, 0), "numeric centered positions")
	check(first.size == Vector3(10, 5, 0) and second.size == Vector3(20, 7, 0), "no stretch")
	var cached := second.measure_count
	var arranged := second.arrange_count
	first.configure(Vector3(14, 5, 0), 0, false)
	row.arrange(row.measure())
	check(first.offset.x == 32 and second.offset.x == 48, "updated exact geometry")
	check(second.measure_count == cached and second.arrange_count == arranged, "unaffected subtree cached")
	first.arranged.connect(resize_once.bind(second))
	first.configure(Vector3(15,5,0),0,false)
	row.arrange(row.measure())
	row.arrange(row.measure())
	check(second.size.x == 21, "callback-triggered mutation gets a bounded follow-up arrangement")
	first.arranged.disconnect(resize_once.bind(second))
	var count := row.measure_count
	row.arrange(row.measure())
	check(row.measure_count == count, "clean root cache")
	row.configure(Vector3(-1,-1,-1), 0.5, false)
	first.configure(Vector3(1,2,3), 0, false)
	second.configure(Vector3(2,1,4), 0, false)
	check(row.measure() == Vector3(3.5,2,4), "natural world3d numbers")
	row.arrange(row.measured)
	check(second.offset == Vector3(1.5,0,0), "world3d X ordering")
	check(row.set_children([first,first]) == ERR_INVALID_PARAMETER, "duplicate rejection")
	check(first.set_children([row]) == ERR_INVALID_PARAMETER, "cycle rejection")
	check(row.configure(Vector3(-2,0,0),0,false) == ERR_INVALID_PARAMETER, "negative invalid")
	check(row.configure(Vector3(INF,0,0),0,false) == ERR_INVALID_PARAMETER, "infinite invalid")
	check(row.configure(Vector3.ZERO,-1,false) == ERR_INVALID_PARAMETER, "gap invalid")
	row.set_children([])
	check(row.measure() == Vector3.ZERO, "empty natural extent")
	row.configure(Vector3(0,0,0),0,false)
	row.set_children([first])
	row.arrange(row.measure())
	check(first.size == Vector3(1,2,3), "zero parent does not shrink/clip child")
	print("B2_CORE_ASSERTIONS ", assertions)
	if failures == 0: print("GGX_B2_CORE_OK")
	quit(1 if failures else 0)

func resize_once(_size: Vector3, target) -> void:
	if resized: return
	resized = true
	target.configure(Vector3(21,7,0),0,false)
