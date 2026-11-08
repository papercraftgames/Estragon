@tool
extends RefCounted
## Editor-only registry/transactions. Native Script references + compiler maps
## provide the durable authored association; no fields/meta on user Nodes.
const Build = preload("build_service.gd")
const Inspector = preload("scene_inspector.gd")
var plugin: EditorPlugin
var interface: EditorInterface
var navigation: RefCounted
var active := true
var items: Dictionary = {}
var registered: Dictionary = {}
var controls: Array[WeakRef] = []
var inspector: EditorInspectorPlugin
var picker: ConfirmationDialog
var list: ItemList
var message: Label
var error: AcceptDialog
var replace: ConfirmationDialog
var target: WeakRef
var scene: WeakRef
var previous: Script
var mode := "attach"
var pending := ""
func _init(owner: EditorPlugin, navigator: RefCounted) -> void:
	plugin = owner
	interface = owner.get_editor_interface()
	navigation = navigator
func start() -> void:
	inspector = Inspector.new()
	inspector.service = weakref(self)
	plugin.add_inspector_plugin(inspector)
	picker = ConfirmationDialog.new()
	picker.name = "GogoScenePicker"
	picker.title = "Choose Gogo Component"
	picker.min_size = Vector2i(640,360)
	var box := VBoxContainer.new()
	picker.add_child(box)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(620,240)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	list.item_selected.connect(func(_index): picker.get_ok_button().disabled = false)
	list.item_activated.connect(func(_index): _accepted())
	picker.confirmed.connect(_accepted)
	plugin.add_child(picker)
	error = AcceptDialog.new()
	error.title = "Gogo Component"
	plugin.add_child(error)
	replace = ConfirmationDialog.new()
	replace.title = "Replace attached script?"
	replace.confirmed.connect(_replace_confirmed)
	plugin.add_child(replace)
static func _res(path: String) -> String:
	return path if path.begins_with("res://") else "res://"+path
static func source_for(script: Script) -> String:
	if script == null or script.resource_path.is_empty(): return ""
	var path := script.resource_path
	if not FileAccess.file_exists(path+".map.json"): return ""
	var map = JSON.parse_string(FileAccess.get_file_as_string(path+".map.json"))
	if not map is Dictionary or map.get("format") != "estragon.gogo.source-map" or map.get("version") != 1 or not map.get("sourceName") is String: return ""
	var source := _res(map.sourceName)
	return source if Build.output_for(source) == path else ""
static func eligible(script: Script) -> bool:
	if not script is GDScript: return false
	var base := script.get_instance_base_type()
	if not ClassDB.class_exists(base) or not ClassDB.is_parent_class(base,"Node") or not ClassDB.can_instantiate(base): return false
	# Non-tool can_instantiate() is false in editor even for valid scene scripts.
	if script.has_method("is_abstract") and script.call("is_abstract"): return false
	var current := script
	while current != null:
		for method in current.get_script_method_list():
			if method.name == "_init" and method.args.size() > method.default_args.size(): return false
		current = current.get_base_script()
	return true
func refresh(report: Dictionary) -> void:
	if not active: return
	var next := {}
	var counts := {}
	if report.get("ok",false):
		for output in report.get("outputs",[]):
			var path := _res(str(output))
			var script: Script = load(path)
			var source := source_for(script)
			if source.is_empty() or not FileAccess.file_exists(source) or not eligible(script): continue
			var name := source.get_file().get_basename()
			counts[name] = int(counts.get(name,0))+1
			next[source] = {"source":source,"output":path,"script":script,"base":script.get_instance_base_type(),"name":name}
	for source in next:
		var item: Dictionary = next[source]
		item.label = item.name+(" ["+source.get_base_dir().trim_prefix("res://")+"]" if counts[item.name] > 1 else "")+" (Gogo Component)"
		item.fingerprint = item.label+"|"+item.base+"|"+item.output+"|"+str(item.script.get_instance_id())
	for source in registered.keys():
		if next.has(source) and registered[source].fingerprint == next[source].fingerprint: continue
		plugin.remove_custom_type(registered[source].label)
		registered.erase(source)
	for source in next:
		if registered.has(source): continue
		var item: Dictionary = next[source]
		var icon := interface.get_base_control().get_theme_icon(item.base,"EditorIcons") if interface.get_base_control().has_theme_icon(item.base,"EditorIcons") else null
		plugin.add_custom_type(item.label,item.base,item.script,icon)
		registered[source] = item
	items = next
func editable(node: Node) -> bool:
	if not active or not is_instance_valid(node): return false
	var root := interface.get_edited_scene_root()
	return root != null and (node == root or root.is_ancestor_of(node) and node.owner == root)
func _selected() -> WeakRef:
	var selected := interface.get_selection().get_selected_nodes()
	return weakref(selected[0]) if selected.size() == 1 else null
func attach_selected() -> void: choose("attach",_selected())
func add_selected() -> void: choose("add",_selected())
func choose(action: String, selected: WeakRef) -> void:
	if not active: return
	var node = selected.get_ref() if selected != null else null
	if node == null or not editable(node): _fail("Select one local scene Node first."); return
	if not plugin._build_sources(): _fail("Fix the Gogo build diagnostics before choosing a component."); return
	target = selected
	scene = weakref(interface.get_edited_scene_root())
	previous = node.get_script()
	mode = action
	list.clear()
	var sources := items.keys()
	sources.sort()
	for source in sources:
		var item: Dictionary = items[source]
		list.add_item(item.label+" — "+item.base+"\n"+source)
		list.set_item_metadata(list.item_count-1,source)
	message.text = "Attach to "+str(node.name) if mode == "attach" else "Add a native child beneath "+str(node.name)
	if sources.is_empty(): message.text += "\nNo eligible Node components. Create/fix a Gogo component in the configured source roots."
	picker.get_ok_button().disabled = true
	picker.popup_centered()
func _accepted() -> void:
	if not active or list.get_selected_items().is_empty(): return
	pending = str(list.get_item_metadata(list.get_selected_items()[0]))
	picker.hide()
	_prepare.call_deferred()
func _valid_target() -> Node:
	var node = target.get_ref() if target != null else null
	var root = scene.get_ref() if scene != null else null
	if node == null or root != interface.get_edited_scene_root() or not editable(node): return null
	if node.get_script() != previous: return null
	return node
func _prepare() -> void:
	if not active: return
	var node := _valid_target()
	if node == null: _fail("The scene, node or attached script changed. Choose the component again."); return
	if not plugin._build_sources() or not items.has(pending): _fail("Component is missing, invalid or outside the configured source roots. Repair/reselect it."); return
	var item: Dictionary = items[pending]
	if mode == "attach" and not ClassDB.is_parent_class(node.get_class(),item.base): _fail("This component requires "+item.base+"; selected node is "+node.get_class()+"."); return
	if mode == "attach" and previous == item.script: return
	if mode == "attach" and previous != null:
		replace.dialog_text = "Replace "+(source_for(previous) if not source_for(previous).is_empty() else previous.resource_path)+" with "+pending+"? Undo restores the previous script and stored properties."
		replace.popup_centered()
	else: _commit()
func _replace_confirmed() -> void:
	replace.hide()
	_commit.call_deferred()
func _commit() -> void:
	if not active: return
	var node := _valid_target()
	if node == null or not plugin._build_sources() or not items.has(pending): _fail("Scene/component changed; repair and choose again."); return
	var item: Dictionary = items[pending]
	var root := interface.get_edited_scene_root()
	var undo := plugin.get_undo_redo()
	if mode == "attach":
		if not ClassDB.is_parent_class(node.get_class(),item.base): _fail("Component host type changed; choose a compatible node."); return
		var values := {}
		if previous != null:
			# Placeholder/editor property lists do not consistently carry the
			# SCRIPT_VARIABLE bit. Script metadata identifies owned stored fields.
			for prop in previous.get_script_property_list():
				if prop.name != "script" and int(prop.usage) & PROPERTY_USAGE_STORAGE: values[prop.name] = node.get(prop.name)
		undo.create_action("Attach Gogo Component",UndoRedo.MERGE_DISABLE,root)
		undo.add_do_method(node,"set_script",item.script)
		undo.add_undo_method(node,"set_script",previous)
		for name in values: undo.add_undo_property(node,name,values[name])
		undo.add_do_method(node,"notify_property_list_changed")
		undo.add_undo_method(node,"notify_property_list_changed")
	else:
		var child: Node = ClassDB.instantiate(item.base)
		child.name = str(item.name).validate_node_name()
		child.set_script(item.script)
		undo.create_action("Add Gogo Component",UndoRedo.MERGE_DISABLE,root)
		undo.add_do_method(node,"add_child",child,true)
		undo.add_do_property(child,"owner",root)
		undo.add_undo_method(node,"remove_child",child)
		undo.add_do_reference(child)
	undo.commit_action()
func open_source(source: String) -> void:
	if not active: return
	if not FileAccess.file_exists(source): _fail("Gogo source is missing: "+source+". Restore it or attach a replacement."); return
	navigation.open(source)
func _fail(text: String) -> void:
	if not active: return
	error.dialog_text = text
	error.popup_centered()
func _script_error(script: Script) -> String:
	var source := source_for(script)
	if source.is_empty(): return ""
	if not items.has(source): return "Attached Gogo component is missing, invalid or excluded: "+source+". Restore/recompile or reattach it before Play."
	return ""
func validate_scenes() -> String:
	var root := interface.get_edited_scene_root()
	if root != null:
		var problem := _validate_node(root)
		if not problem.is_empty(): return problem
	var paths := Array(interface.get_open_scenes())
	var main := str(ProjectSettings.get_setting("application/run/main_scene",""))
	if not main.is_empty(): paths.append(main)
	var visited := {}
	for path in paths:
		if root != null and path == root.scene_file_path: continue
		var problem := _validate_saved(str(path),visited)
		if not problem.is_empty(): return problem
	return ""
func _validate_node(node: Node) -> String:
	var problem := _script_error(node.get_script())
	if not problem.is_empty(): return problem
	for child in node.get_children():
		problem = _validate_node(child)
		if not problem.is_empty(): return problem
	return ""
func _validate_saved(path: String, visited: Dictionary) -> String:
	if path.is_empty() or visited.has(path): return ""
	visited[path] = true
	if not ResourceLoader.exists(path,"PackedScene"): return "Cannot validate scene before Play: "+path
	var packed: PackedScene = load(path)
	if packed == null: return "Cannot load scene before Play: "+path
	var state := packed.get_state()
	for index in range(state.get_node_count()):
		for prop in range(state.get_node_property_count(index)):
			if state.get_node_property_name(index,prop) == "script":
				var problem := _script_error(state.get_node_property_value(index,prop))
				if not problem.is_empty(): return problem
	# Native dependency data includes inherited/instanced scenes on 4.0 too.
	for dependency in ResourceLoader.get_dependencies(path):
		for part in str(dependency).split("::"):
			if part.begins_with("res://") and part.get_extension() in ["tscn","scn"]:
				var problem := _validate_saved(part,visited)
				if not problem.is_empty(): return problem
	return ""
func stop() -> void:
	active = false
	for item in registered.values(): plugin.remove_custom_type(item.label)
	registered.clear()
	items.clear()
	plugin.remove_inspector_plugin(inspector)
	inspector.service = null
	inspector = null
	for reference in controls:
		var control = reference.get_ref()
		if control != null: control.free()
	controls.clear()
	for dialog in [picker,error,replace]: dialog.free()
