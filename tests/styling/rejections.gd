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
	var button = preload("res://addons/estragon/runtime/node/button.gd").new()
	for name in ["hover_background_color","pressed_background_color","disabled_background_color"]:
		var previous = button.get(name)
		button.set(name,"#xx")
		if button.get(name)!=previous: failed = true
	button.padding = "broken"
	if button.padding!="auto": failed = true
	button.free()
	var toggle = preload("res://addons/estragon/runtime/node/toggle.gd").new()
	var checked = toggle.checked_background_color
	toggle.checked_background_color = "#xx"
	if toggle.checked_background_color!=checked: failed = true
	toggle.free()
	var rect = preload("res://addons/estragon/runtime/node/rect.gd").new()
	rect.fill = Color(NAN,0,0,1)
	if rect.fill!=Color.WHITE: failed = true
	rect.free()
	# Flush the two native output streams before closing the exact-error bracket.
	await process_frame
	await process_frame
	print("S01_EXPECTED_REJECTION_END")
	box.free()
	if not failed: print("S01_REJECTIONS_OK")
	quit(1 if failed else 0)
