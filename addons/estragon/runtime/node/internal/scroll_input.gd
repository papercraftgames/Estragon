@tool
extends RefCounted
## Event-driven native GUI capture guard, including opaque Container descendants.
## Weak subscriptions only; no layout, property mutation, input polling or user data.
const Pointer = preload("pointer_2d.gd")
var root: WeakRef
var watched: Dictionary = {}
func start(node: Node) -> void:
	root = weakref(node)
	_watch(node)
func stop() -> void:
	for id in watched.keys(): _remove(id)
	root = null
func _watch(node: Node) -> void:
	var id := node.get_instance_id()
	if watched.has(id): return
	var reference: WeakRef = weakref(node)
	var child_callback := _watch
	var exit_callback := _left.bind(id,reference)
	var gui_callback := _gui.bind(reference)
	node.child_entered_tree.connect(child_callback)
	node.tree_exited.connect(exit_callback)
	if node is Control: node.gui_input.connect(gui_callback)
	watched[id] = [reference,child_callback,exit_callback,gui_callback]
	for child in node.get_children(true): _watch(child)
func _left(id: int, reference: WeakRef) -> void:
	_prune.call_deferred(id,reference)
func _prune(id: int, reference: WeakRef) -> void:
	if not watched.has(id) or watched[id][0]!=reference: return
	var node = reference.get_ref()
	var owner = root.get_ref() if root!=null else null
	if node==null or owner==null or node!=owner and not owner.is_ancestor_of(node): _remove(id)
func _remove(id: int) -> void:
	var entry: Array = watched[id]
	watched.erase(id)
	var node = entry[0].get_ref()
	if node==null: return
	if node.child_entered_tree.is_connected(entry[1]): node.child_entered_tree.disconnect(entry[1])
	if node.tree_exited.is_connected(entry[2]): node.tree_exited.disconnect(entry[2])
	if node is Control and node.gui_input.is_connected(entry[3]): node.gui_input.disconnect(entry[3])
func _gui(event: InputEvent, reference: WeakRef) -> void:
	if not event is InputEventMouse: return
	var node = reference.get_ref()
	if node==null: return
	var point: Vector2 = node.get_global_transform_with_canvas()*event.position
	# Signal precedes native BaseButton processing (verified4.0.4/4.7).
	# BaseButton release uses cached pressing_inside, not the event position.
	# The public scroll notification cancels that press; an outside-local point
	# also keeps custom Control handlers from treating capture as an inside hit.
	# Native GUI already chooses the topmost scrollbar. Bar exclusion belongs
	# only to Estragon's separate custom picker, never to native GUI events.
	if not Pointer.inside_clips(node,point,false):
		if node is BaseButton: node.notification(Control.NOTIFICATION_SCROLL_BEGIN)
		event.position = Vector2(-1,-1)

func cancel() -> void:
	for entry in watched.values():
		var node = entry[0].get_ref()
		if node is BaseButton: node.notification(Control.NOTIFICATION_SCROLL_BEGIN)
