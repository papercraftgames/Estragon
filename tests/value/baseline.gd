extends SceneTree
func _initialize():
	for kind in ["OptionButton","PopupMenu","HSlider","VSlider","SpinBox"]:
		var node = ClassDB.instantiate(kind)
		var properties: Array = []
		for field in node.get_property_list():
			if field.name in ["editable","value","min_value","max_value","step","rounded","allow_greater","allow_lesser","update_on_text_changed","scrollable","select_all_on_focus","selected","disabled"]: properties.append(field.name)
		print("UI05_API ",kind," ",properties)
		for method in ["get_line_edit","get_popup","select","apply","set_value_no_signal"]:
			if node.has_method(method): print("UI05_METHOD ",kind," ",method)
		if node is OptionButton:
			node.add_item("First");node.add_item("Second")
			print("UI05_BASELINE_NATIVE_SELECTION ",node.selected)
			node.select(-1)
			print("UI05_API_CLEAR ",node.selected)
		if node is Range:
			node.min_value=5.5;node.max_value=8;node.step=0.25;node.value=5.65
			print("UI05_API_SNAP ",kind," ",node.value)
		node.free()
	var binding = preload("res://addons/estragon/runtime/composition/binding.gd").new(null,Callable(),&"value",Callable(),"",0.5,TYPE_FLOAT)
	print("UI05_BASELINE_FLOAT_BINDING ",binding.valid)
	quit()
