@tool
extends RefCounted
## User-invoked creation only. Never overwrites source or edits project config.
const Build = preload("build_service.gd")
const Source = preload("../compiler/source.gd")
const Element = preload("../runtime/composition/element.gd")
var dialog: Variant
var dimension: OptionButton
var error: AcceptDialog
var interface: EditorInterface
var navigation: RefCounted
var active := true
func _init(editor_interface: EditorInterface, navigator: RefCounted) -> void:
	interface = editor_interface
	navigation = navigator
func start(parent: Node) -> void:
	# 4.0 registers EditorFileDialog abstract; do not reference its unavailable
	# constructor even in a dead branch. Both paths use public native dialogs.
	dialog = ClassDB.instantiate("EditorFileDialog") if ClassDB.can_instantiate("EditorFileDialog") else FileDialog.new()
	dialog.name = "NewGogoComponent"
	if dialog is FileDialog: dialog.mode_overrides_title = false
	dialog.title = "New Gogo Component"
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	if dialog is EditorFileDialog: dialog.disable_overwrite_warning = true
	# Native save filters append their suffix even to explicit wrong extensions
	# (Bad.txt becomes Bad.txt.gogo). Let the shared validator own suffixes.
	dialog.add_filter("*","Gogo Component (.gogo)")
	dimension = OptionButton.new()
	dimension.name = "GogoTemplate"
	dimension.add_item("Node2D — blank component")
	dimension.add_item("Node3D — blank component")
	dialog.get_vbox().add_child(dimension)
	dialog.file_selected.connect(_selected)
	parent.add_child(dialog)
	error = AcceptDialog.new()
	error.title = "New Gogo Component"
	parent.add_child(error)
func show_dialog(context_directory: String = "", spatial: bool = false) -> void:
	if not active: return
	var directory := context_directory if not context_directory.is_empty() else interface.get_current_directory()
	if not directory.begins_with("res://") or not DirAccess.dir_exists_absolute(directory): directory = "res://"
	dialog.current_dir = directory
	dialog.current_file = "NewComponent.gogo"
	dimension.select(1 if spatial else 0)
	dialog.popup_centered_ratio(0.65)
static func template(path: String, spatial: bool) -> String:
	var kind := "Node3D" if spatial else "Node2D"
	var directory := Build.output_for(path).get_base_dir()
	var element := JSON.stringify(Source.relative_path(directory,(Element as Script).resource_path))
	# Ordinary native grouping node: no drawing, layout scope or configuration.
	return "extends "+kind+"\nconst Element = preload("+element+")\n\nfunc build_view() -> Element:\n\treturn <"+kind+" />\n"
func _selected(path: String) -> void:
	if not active: return
	if path.get_extension().is_empty(): path += ".gogo"
	var check := Build.creation_check(path)
	if not check.ok:
		error.dialog_text = check.message
		error.popup_centered()
		return
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		error.dialog_text = "Cannot create "+path+": "+error_string(FileAccess.get_open_error())
		error.popup_centered()
		return
	file.store_string(template(path,dimension.selected == 1))
	file.close()
	interface.get_resource_filesystem().scan()
	_open_after_scan(path)
func _open_after_scan(path: String) -> void:
	var filesystem := interface.get_resource_filesystem()
	while active and filesystem.is_scanning(): await dialog.get_tree().process_frame
	if active: navigation.open(path)
func stop() -> void:
	active = false
	if dialog != null: dialog.free(); dialog = null
	if error != null: error.free(); error = null
