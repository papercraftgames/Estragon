@tool
extends RefCounted
## TextFile opening has no public ScriptEditor entry point on 4.0.
## Activate only a native FileSystemDock item authenticated by its full path.
## No private method, guessed basename/index, or menu injection is used.
var interface: EditorInterface
var active := true
func _init(editor_interface: EditorInterface) -> void: interface = editor_interface
func stop() -> void: active = false
func open(path: String) -> void:
	if not active or not path.begins_with("res://") or not FileAccess.file_exists(path): return
	var version := Engine.get_version_info()
	if version.major != 4 or version.minor > 7:
		interface.select_file(path)
		return
	var dock := interface.get_file_system_dock()
	dock.navigate_to_path(path)
	var deadline := Time.get_ticks_msec()+5000
	while active and Time.get_ticks_msec() < deadline:
		for tree in dock.find_children("*","Tree",true,false):
			var selected: TreeItem = tree.get_selected()
			if selected != null and selected.get_metadata(0) is String and selected.get_metadata(0) == path:
				tree.item_activated.emit()
				return
		for list in dock.find_children("*","ItemList",true,false):
			for index in list.get_selected_items():
				if list.get_item_metadata(index) is String and list.get_item_metadata(index) == path:
					list.item_activated.emit(index)
					return
		await dock.get_tree().process_frame
