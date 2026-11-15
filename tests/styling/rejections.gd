extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	print("S01_EXPECTED_REJECTION_BEGIN")
	await process_frame
	var box = preload("res://addons/estragon/runtime/node/box.gd").new()
	box.background_color = "#123456"
	box.border_width = 2
	var failed := false
	for value in ["#xx","black","#12","",true,[],Color(NAN,0,0,1)]:
		box.background_color = value
		if box.background_color!="#123456": failed = true
	for value in [-1,"auto","-2px",NAN,INF,"1em",true,[]]:
		box.border_width = value
		if box.border_width!=2: failed = true
	for script in [preload("res://addons/estragon/runtime/node/text.gd"),preload("res://addons/estragon/runtime/node/rect.gd"),preload("res://addons/estragon/runtime/node/button.gd")]:
		var widget = script.new()
		widget.background_color = "#123456"
		if widget.background_color!="transparent": failed = true
		widget.free()
	# Flush the two native output streams before closing the exact-error bracket.
	await process_frame
	await process_frame
	print("S01_EXPECTED_REJECTION_END")
	box.free()
	if not failed: print("S01_REJECTIONS_OK")
	quit(1 if failed else 0)
