extends SceneTree
func _initialize() -> void:
	var box = preload("res://addons/estragon/runtime/node/box.gd").new()
	box.background_color = "#123456"
	box.border_width = 2
	var failed := false
	for value in ["#xx","black","#12","",true,[],Color(NAN,0,0,1)]:
		print("S01_EXPECTED_REJECTION_BEGIN")
		box.background_color = value
		print("S01_EXPECTED_REJECTION_END")
		if box.background_color!="#123456": failed = true
	for value in [-1,"auto","-2px",NAN,INF,"1em",true,[]]:
		print("S01_EXPECTED_REJECTION_BEGIN")
		box.border_width = value
		print("S01_EXPECTED_REJECTION_END")
		if box.border_width!=2: failed = true
	box.free()
	if not failed: print("S01_REJECTIONS_OK")
	quit(1 if failed else 0)
