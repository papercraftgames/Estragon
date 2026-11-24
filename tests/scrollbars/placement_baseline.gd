extends SceneTree
const Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box=preload("res://addons/estragon/runtime/node/box.gd")
const ButtonScript=preload("res://addons/estragon/runtime/node/button.gd")
func _initialize(): run.call_deferred()
func run():
	root.size=Vector2i(900,420)
	var entry=Entry.new();entry.width=900;entry.height=420;entry.padding=20;entry.gap=20
	for horizontal in [false,true]:
		var body=Box.new();body.width=400;body.height=300;body.direction="column";body.border_width=5;body.border_color="#ababab";body.padding=20;body.vertical_scroll=true;body.horizontal_scroll=horizontal;body.horizontal_scrollbar_height=16;body.background_color="#383838";body.scrollbar_style={"track_color":"#202828","thumb_color":"#38a58c","thumb_hover_color":"#58c5ac","thumb_pressed_color":"#18856c"}
		var button=ButtonScript.new();button.width="100%";button.text="Full width / right edge";body.add_child(button)
		var wrap=Box.new();wrap.width="100%";wrap.wrap=true;wrap.gap=8
		for i in range(3):
			var item=ButtonScript.new();item.width=160;item.height=44;item.text="Action "+str(i);wrap.add_child(item)
		body.add_child(wrap)
		var nested=Box.new();nested.width="100%";nested.height=80;nested.vertical_scroll=true
		var native=Button.new();native.text="Native nested content";native.custom_minimum_size=Vector2(150,240);nested.add_child(native);body.add_child(nested)
		var tall=Box.new();tall.width=600;tall.height=500;tall.background_color="#537666";body.add_child(tall);entry.add_child(body)
	root.add_child(entry)
	for i in range(12): await process_frame
	for body in entry.get_layout_children():
		var service=body._scroll
		print("U04_BASELINE dual=",body.horizontal_scroll," owner=",body.layout_size," P=",body.get_content_rect()," V=",Rect2(service._clip.position,service._clip.size)," vertical=",Rect2(service._vertical.position,service._vertical.size*service._vertical.scale)," horizontal=",Rect2(service._horizontal.position,service._horizontal.size*service._horizontal.scale)," range=",body.scroll_range)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://u04-before.png")
	entry.free();quit()
