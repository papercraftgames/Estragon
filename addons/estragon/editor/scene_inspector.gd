@tool
extends EditorInspectorPlugin
## Authored-source presentation alongside the untouched native Script property.
var service: WeakRef
func _can_handle(object: Object) -> bool:
	var owner = service.get_ref() if service != null else null
	return owner != null and owner.active and object is Node and owner.editable(object)
func _parse_begin(object: Object) -> void:
	var owner = service.get_ref() if service != null else null
	if owner == null: return
	var panel := VBoxContainer.new()
	panel.name = "GogoSceneComponent"
	var label := Label.new()
	var source: String = owner.source_for(object.get_script())
	label.text = "Gogo Component" if source.is_empty() else "Gogo source: "+source
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	if not source.is_empty():
		var open := Button.new()
		open.text = "Open Gogo Source"
		open.pressed.connect(owner.open_source.bind(source))
		panel.add_child(open)
	for mode in ["attach","add"]:
		var button := Button.new()
		button.text = "Attach/Change Gogo Component…" if mode == "attach" else "Add Gogo Child…"
		button.pressed.connect(owner.choose.bind(mode,weakref(object)))
		panel.add_child(button)
	owner.controls = owner.controls.filter(func(reference): return reference.get_ref() != null)
	owner.controls.append(weakref(panel))
	add_custom_control(panel)
