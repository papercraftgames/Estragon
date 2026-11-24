@tool
extends RefCounted
func field(probe,name:String) -> EditorProperty:
	for node in probe.interface.get_inspector().find_children("*","EditorProperty",true,false):
		if node.get_edited_property()==name: return node
	return null
func run(probe):
	var scene=probe.interface.get_edited_scene_root()
	var box=preload("res://addons/estragon/runtime/node/box.gd").new();box.name="ScrollbarInspector";scene.add_child(box);box.owner=scene
	probe.interface.inspect_object(box)
	if await probe.until(func(): return field(probe,"scrollbar_size")!=null and field(probe,"scrollbar_size").get_edited_object()==box,"scrollbar Length Inspector"):
		field(probe,"scrollbar_size").input.text_submitted.emit("5%")
		await probe.wait()
		probe.check(box.scrollbar_size=="5%","Inspector retains percentage thickness")
		var manager=probe.get_undo_redo();var history=manager.get_history_undo_redo(manager.get_object_history_id(box))
		probe.check(history.undo() and box.scrollbar_size==12 and history.redo() and box.scrollbar_size=="5%","Inspector native undo/redo thickness")
		field(probe,"scrollbar_size").input.text_submitted.emit("auto")
		probe.check(box.scrollbar_size=="5%" and not field(probe,"scrollbar_size").input.tooltip_text.is_empty(),"Inspector rejects shared auto atomically")
		field(probe,"vertical_scrollbar_width").input.text_submitted.emit("20px");await probe.wait();field(probe,"vertical_scrollbar_width").input.text_submitted.emit("auto");await probe.wait()
		probe.check(box.vertical_scrollbar_width=="auto","Inspector axis auto restores fallback")
		var style=field(probe,"scrollbar_style");style.emit_changed("scrollbar_style",{"thumb_color":"#dedede"});await probe.wait()
		probe.check(box.scrollbar_style=={"thumb_color":"#dedede"},"native Dictionary Inspector applies validated skin")
		var packed=PackedScene.new();probe.check(packed.pack(box)==OK and ResourceSaver.save(packed,"res://u03-inspector.tscn")==OK,"Inspector targets and Dictionary saved")
		var restored=load("res://u03-inspector.tscn").instantiate();probe.check(restored.scrollbar_size=="5%" and restored.scrollbar_style==box.scrollbar_style,"Inspector saved scene reload preserves target/style");restored.free()
		RenderingServer.force_draw(false);probe.get_viewport().get_texture().get_image().save_png("res://scrollbar-inspector.png")
	probe.interface.inspect_object(scene);scene.remove_child(box);box.free()
