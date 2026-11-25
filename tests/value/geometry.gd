extends SceneTree
var checks:=0
var ok:=true
func check(test:bool,label:String):
	checks+=1;ok=ok and test;print("UI05_GEOMETRY ",label,": ",test)
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd").new();entry.direction="column";entry.gap=10;root.add_child(entry)
	var select=preload("res://addons/estragon/runtime/node/select.gd").new();select.width=220
	var option=preload("res://addons/estragon/runtime/node/option.gd").new();option.value="a";option.text="A very long option label that must not grow this stable native trigger"
	select.value="a";select.add_child(option);entry.add_child(select);await frames()
	var native=select.get_native_control()
	check(select.layout_size.x==220 and native.size==select.get_content_rect().size and native.clip_text,"long selected label clips inside stable native trigger allocation")
	option.text="Short";await frames()
	check(select.layout_size.x==220 and native.size==select.get_content_rect().size,"label replacement does not change natural trigger geometry")
	for script in [preload("res://addons/estragon/runtime/node/number_input.gd"),preload("res://addons/estragon/runtime/node/integer_input.gd"),preload("res://addons/estragon/runtime/node/slider.gd")]:
		var control=script.new();control.width=16;control.height=16;entry.add_child(control);await frames()
		check(not control.get_native_control().visible and not control.has_focus(),"undersized content hides native minimum instead of overflowing hit rect "+script.resource_path)
		control.width=250;control.height=70;control.font_size=28;await frames()
		check(control.get_native_control().visible and control.get_native_control().size==control.get_content_rect().size,"resized styled content restores exact native geometry "+script.resource_path)
	entry.free();await frames()
	print("UI05_GEOMETRY_ASSERTIONS ",checks," ok=",ok)
	if ok: print("UI05_GEOMETRY_OK")
	quit(0 if ok else 1)
