@tool
extends EditorInspectorPlugin
## Authored-source presentation alongside the untouched native Script property.
const Length = preload("../runtime/node/internal/length.gd")
const LengthProperty = preload("length_property.gd")
var service: WeakRef
func _can_handle(object: Object) -> bool:
	var owner = service.get_ref() if service != null else null
	return owner != null and owner.active and object is Node and (owner.editable(object) or object.has_method("_get_layout_coordinator"))
func _parse_property(object: Object, _type: Variant.Type, name: String, _hint: PropertyHint, _hint_text: String, _usage: int, _wide: bool) -> bool:
	if not Length.registered(object.get_script(),name): return false
	add_property_editor(name,LengthProperty.new())
	return true
func _parse_begin(object: Object) -> void:
	var owner = service.get_ref() if service != null else null
	if owner == null or not owner.editable(object): return
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
		# Navigation/build can rebuild the Inspector and free this sender.
		open.pressed.connect(owner.open_source.bind(source),CONNECT_DEFERRED)
		panel.add_child(open)
	for mode in ["attach","add"]:
		var button := Button.new()
		button.text = "Attach/Change Gogo Component…" if mode == "attach" else "Add Gogo Child…"
		button.pressed.connect(owner.choose.bind(mode,weakref(object)),CONNECT_DEFERRED)
		panel.add_child(button)
	owner.controls = owner.controls.filter(func(reference): return reference.get_ref() != null)
	owner.controls.append(weakref(panel))
	add_custom_control(panel)
