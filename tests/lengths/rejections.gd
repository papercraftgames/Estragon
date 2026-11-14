extends SceneTree
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
func _initialize() -> void:
	var node := Rect.new()
	node.width = "50%"
	for invalid in ["no-unit",-1.0,NAN,INF,true]:
		printerr("L06_EXPECTED_REJECTION_BEGIN")
		node.width = invalid
		printerr("L06_EXPECTED_REJECTION_END")
		if node.width!="50%" or node.lengths.specs.width.unit!="%": quit(1); node.free(); return
	node.free()
	print("L06_REJECTIONS_OK")
	quit()
