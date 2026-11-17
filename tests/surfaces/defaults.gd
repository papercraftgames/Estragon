extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/vbox.gd")
var failed := false
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var ui := Entry.new()
	var samples: Array = []
	ui.width = 640
	ui.height = 480
	ui.background_color = "#142536"
	for row in range(5):
		var kind = [Box,preload("res://addons/estragon/runtime/node/rect.gd"),preload("res://addons/estragon/runtime/node/text.gd"),preload("res://addons/estragon/runtime/node/button.gd"),preload("res://addons/estragon/runtime/node/toggle.gd")][row]
		for col in range(3):
			var node = kind.new()
			node.width = 180
			node.height = 65
			node.x = 16+col*204
			node.y = 12+row*88
			if "text" in node: node.text = "Native surface"
			if col>0:
				node.background_color = Color(0.25,0.5,0.8,0.4 if col==2 else 1.0)
				node.border_color = Color(1,0.3,0.1,0.6)
				node.border_width = 1.25
				node.border_left_width = 2.75
				node.border_right_width = 4.5
				node.border_bottom_width = 3.25
				node.padding = 5.5
			ui.add_child(node)
			samples.append([node,5 if col>0 else (1 if row in [1,3,4] else 0)])
	var geometry := Box.new()
	geometry.width = 300
	geometry.height = 20
	geometry.border_left_width = 2
	geometry.border_right_width = 4
	geometry.padding_left = 10
	geometry.padding_right = 20
	ui.add_child(geometry)
	root.add_child(ui)
	var native := Button.new()
	native.text = "Native"
	native.position = Vector2(440,440)
	native.size = Vector2(100,32)
	root.add_child(native)
	var sprite := Sprite2D.new()
	var pixels := Image.create(8,8,false,Image.FORMAT_RGBA8)
	pixels.fill(Color.CYAN)
	sprite.texture = ImageTexture.create_from_image(pixels)
	sprite.position = Vector2(600,454)
	root.add_child(sprite)
	for i in range(8): await process_frame
	# Explicit offsets are additive to normal stack slots; the fixture uses a
	# zero-size plain parent below an Entry to place independent participants.
	for node in ui.get_children():
		if node!=geometry: node.position = Vector2(float(node.x),float(node.y))
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://surface-defaults.png")
	failed = geometry.get_content_rect()!=Rect2(12,0,264,20)
	for sample in samples:
		var stats: Dictionary = sample[0].get_visual_style_stats()
		failed = failed or sample[0]._scroll!=null or stats.commands!=stats.draw*sample[1]
	var label := "4.0.4" if Engine.get_version_info().minor==0 else "4.7"
	# D07 deliberately changes only the two unstyled Button/Toggle fills.
	# Historical S04 captures remain immutable; current baseline is charcoal.
	var historical := "res://tests/surfaces/evidence/"+label+"/surface-defaults.png"
	if FileAccess.file_exists(historical):
		var old := Image.load_from_file(historical)
		var changed := 0
		var outside := 0
		for y in range(480):
			for x in range(640):
				if old.get_pixel(x,y)!=image.get_pixel(x,y):
					changed += 1
					if not (x>=16 and x<196 and ((y>=276 and y<341) or (y>=364 and y<429))): outside += 1
		failed = failed or changed==0 or outside!=0
		print("D07_PALETTE_ONLY changed=",changed," outside=",outside)
	var baseline := "res://tests/surfaces/baseline/"+label+".png"
	if FileAccess.file_exists(baseline):
		var original := Image.load_from_file(baseline)
		failed = failed or original.get_data()!=image.get_data()
		print("S04_DEFAULT_PIXEL_IDENTICAL ",not failed)
	else:
		print("S04_BASELINE_CAPTURE ",not failed)
	ui.free()
	native.free()
	sprite.free()
	if not failed: print("S04_DEFAULTS_OK")
	quit(1 if failed else 0)
