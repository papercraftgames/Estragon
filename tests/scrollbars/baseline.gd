extends SceneTree
const Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box=preload("res://addons/estragon/runtime/node/box.gd")
const ButtonScript=preload("res://addons/estragon/runtime/node/button.gd")
func _initialize(): run.call_deferred()
func run():
	root.size=Vector2i(480,380)
	var entry=Entry.new();entry.width=480;entry.height=380;entry.padding=20
	var body=Box.new();body.direction="column";body.width=400;body.height=300;body.vertical_scroll=true;body.background_color="#383838"
	var button=ButtonScript.new();button.width="100%";button.text="Full width / right edge";body.add_child(button)
	var wrap=Box.new();wrap.width="100%";wrap.wrap=true;wrap.gap=8
	for i in range(3):
		var item=ButtonScript.new();item.width=186;item.text="Wrapped action "+str(i);wrap.add_child(item)
	body.add_child(wrap)
	var nested=Box.new();nested.width="100%";nested.height=80;nested.vertical_scroll=true
	var inner=Box.new();inner.width="100%";inner.height=200;inner.background_color="#737373";nested.add_child(inner);body.add_child(nested)
	var tall=Box.new();tall.height=600;tall.width="100%";tall.background_color="#537666";body.add_child(tall);entry.add_child(body);root.add_child(entry)
	for i in range(12): await process_frame
	print("U03_BASELINE outer=",body.layout_size," content=",body.get_content_rect()," clip=",body._scroll._clip.size," bar=",body._scroll._vertical.get_rect()," child=",button.layout_size," range=",body.scroll_range)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://scrollbar-before.png")
	entry.free();quit()
