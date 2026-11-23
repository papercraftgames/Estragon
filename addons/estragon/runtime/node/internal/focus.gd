@tool
extends Resource
## One native GUI focus owner. This registry only joins native GUI roots for Tab.
## Weak Entries; no retained focus graph, Node metadata or frame callbacks.
const Pointer = preload("pointer_2d.gd")
var viewports: Dictionary = {}
var refreshes := 0
var queued := false
func add(entry: Node) -> void:
	if Engine.is_editor_hint(): return
	var viewport := entry.get_viewport()
	var id := viewport.get_instance_id()
	if not viewports.has(id):
		var changed := _owner_changed.bind(weakref(viewport))
		viewports[id] = {"viewport":weakref(viewport),"entries":[],"changed":changed,"owner":null,"gui":Callable()}
		viewport.gui_focus_changed.connect(changed)
	for reference in viewports[id].entries:
		if reference.get_ref()==entry: return
	viewports[id].entries.append(weakref(entry))
	_owner_changed(viewport.gui_get_focus_owner(),weakref(viewport))
	var tree := entry.get_tree()
	if not tree.tree_changed.is_connected(refresh): tree.tree_changed.connect(refresh)
	refresh()
func remove(entry: Node) -> void:
	var tree := entry.get_tree()
	for id in viewports.keys():
		var refs: Array = viewports[id].entries
		for index in range(refs.size()-1,-1,-1):
			if refs[index].get_ref()==null or refs[index].get_ref()==entry: refs.remove_at(index)
		if refs.is_empty():
			var record: Dictionary = viewports[id]
			_disconnect_owner(record)
			var viewport = record.viewport.get_ref()
			if viewport!=null and viewport.gui_focus_changed.is_connected(record.changed): viewport.gui_focus_changed.disconnect(record.changed)
			viewports.erase(id)
	if viewports.is_empty() and tree.tree_changed.is_connected(refresh): tree.tree_changed.disconnect(refresh)
func _disconnect_owner(record: Dictionary) -> void:
	var owner = record.owner.get_ref() if record.owner!=null else null
	if owner!=null and record.gui.is_valid() and owner.gui_input.is_connected(record.gui): owner.gui_input.disconnect(record.gui)
	record.owner = null
	record.gui = Callable()
func _owner_changed(owner: Control, reference: WeakRef) -> void:
	var viewport = reference.get_ref()
	if viewport==null or not viewports.has(viewport.get_instance_id()): return
	var record: Dictionary = viewports[viewport.get_instance_id()]
	_disconnect_owner(record)
	if owner is BaseButton and contains(owner):
		record.owner = weakref(owner)
		record.gui = _native_button_key.bind(weakref(owner))
		owner.gui_input.connect(record.gui)
func _native_button_key(event: InputEvent, reference: WeakRef) -> void:
	var owner = reference.get_ref()
	# Native BaseButton activates Enter but leaves it unhandled on both engines.
	# Its gui_input signal precedes native processing: accept without re-emitting
	# or forwarding the event, keeping one native activation and no game key echo.
	if owner!=null and event is InputEventKey and event.is_action("ui_accept"): owner.accept_event()
func refresh() -> void:
	if queued: return
	queued = true
	_validate.call_deferred()
func _validate() -> void:
	queued = false
	refreshes += 1
	for record in viewports.values():
		var viewport = record.viewport.get_ref()
		if viewport==null: continue
		var owner = viewport.gui_get_focus_owner()
		if owner!=null and contains(owner) and not eligible(owner): owner.release_focus()
func contains(control: Control) -> bool:
	var record: Dictionary = viewports.get(control.get_viewport().get_instance_id(),{})
	for reference in record.get("entries",[]):
		var entry = reference.get_ref()
		if entry!=null and (control==entry or entry.is_ancestor_of(control)): return true
	return false
static func owns(control: Control) -> bool:
	return control.has_method("_estragon_focus_host")
static func rectangle(control: Control) -> PackedVector2Array:
	var transform := control.get_global_transform_with_canvas()
	var extent := control.size
	return PackedVector2Array([transform*Vector2.ZERO,transform*Vector2(extent.x,0),transform*extent,transform*Vector2(0,extent.y)])
static func eligible(control: Control, tab: bool = false) -> bool:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.is_queued_for_deletion() or not control.is_visible_in_tree() or not control.can_process(): return false
	if control.focus_mode==Control.FOCUS_NONE or tab and control.focus_mode!=Control.FOCUS_ALL: return false
	if control is BaseButton and control.disabled: return false
	if owns(control):
		var host = control._estragon_focus_host()
		if host==null or host.disabled or host.is_queued_for_deletion(): return false
	if control.size.x<=0 or control.size.y<=0: return false
	var transform := control.get_global_transform_with_canvas()
	if is_zero_approx(transform.x.cross(transform.y)): return false
	var visible := control.get_viewport_rect()
	var boundary := PackedVector2Array([visible.position,Vector2(visible.end.x,visible.position.y),visible.end,Vector2(visible.position.x,visible.end.y)])
	var region: Array = Geometry2D.intersect_polygons(rectangle(control),boundary)
	if region.is_empty(): return false
	var parent := control.get_parent()
	while parent!=null:
		if parent.is_queued_for_deletion(): return false
		if parent is Control and parent.clip_contents:
			var next: Array = []
			for polygon in region: next.append_array(Geometry2D.intersect_polygons(polygon,rectangle(parent)))
			region = next
			if region.is_empty(): return false
		parent = parent.get_parent()
	return true
func _collect(node: Node, viewport: Viewport, output: Array) -> void:
	if node.get_viewport()!=viewport: return
	if node is Control and eligible(node,true) and not output.has(node): output.append(node)
	for child in node.get_children(true): _collect(child,viewport,output)
func candidates(viewport: Viewport) -> Array:
	var output: Array = []
	var record: Dictionary = viewports.get(viewport.get_instance_id(),{})
	for reference in record.get("entries",[]):
		var entry = reference.get_ref()
		if entry!=null and entry.is_inside_tree(): _collect(entry,viewport,output)
	output.sort_custom(func(a,b): return b.is_greater_than(a))
	return output
func key(viewport: Viewport, event: InputEvent) -> bool:
	if not event is InputEventKey or event.keycode!=KEY_TAB or event.alt_pressed or event.ctrl_pressed or event.meta_pressed: return false
	var list := candidates(viewport)
	var owner := viewport.gui_get_focus_owner()
	# Native Controls outside the participating Entry keep their native behavior.
	if owner!=null and not contains(owner): return false
	if list.is_empty(): return false
	if not event.pressed or event.echo: return true
	var path := NodePath()
	if owner!=null: path = owner.focus_previous if event.shift_pressed else owner.focus_next
	if owner!=null and not path.is_empty():
		var explicit = owner.get_node_or_null(path)
		if explicit is Control and eligible(explicit,true): explicit.grab_focus(); return true
	var index := list.find(owner)
	if index<0: index = 0 if event.shift_pressed else -1
	list[posmod(index+(-1 if event.shift_pressed else 1),list.size())].grab_focus()
	return true
func pointer_entry(viewport: Viewport, point: Vector2) -> Node:
	var found
	var result
	var record: Dictionary = viewports.get(viewport.get_instance_id(),{})
	for reference in record.get("entries",[]):
		var entry = reference.get_ref()
		if entry==null or not entry.is_inside_tree(): continue
		var pointer = entry._get_pointer_router()
		if pointer.has_capture(): return entry
		var button = pointer.pick(point)
		if button!=null and (found==null or pointer._z(button)>pointer._z(found) or pointer._z(button)==pointer._z(found) and button.is_greater_than(found)):
			found = button
			result = entry
	return result
