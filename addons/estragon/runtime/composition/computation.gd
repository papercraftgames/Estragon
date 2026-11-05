extends RefCounted
## F01 computation and retained static-shape records external to native objects.
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
class Mounted extends RefCounted:
	var node: WeakRef
	var type: Variant
	var properties: Dictionary = {}
	var handlers: Dictionary = {}
	var children: Array = []
var host: WeakRef
var state: WeakRef
var mounted: Mounted
var subscriptions: Dictionary = {}
var queued := false
var active := true
var disposed := false
var runs := 0
var allocations := 0
var writes := 0
var _rendering := false
var _again := false
var _consecutive := 0
func _init(owner: Node, manager: Resource) -> void:
	host = weakref(owner)
	state = weakref(manager)
func schedule(_previous: Variant = null, _value: Variant = null) -> void:
	if not active or disposed: return
	if _rendering: _again = true
	if not queued:
		queued = true
		_flush.call_deferred()
func suspend() -> void:
	active = false
	_disconnect()
func resume() -> void:
	active = true
	schedule()
func _disconnect() -> void:
	for pair in subscriptions.values():
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],schedule): source.disconnect(pair[1],schedule)
	subscriptions.clear()
func _subscribe(next: Dictionary) -> void:
	for key in subscriptions.keys():
		if next.has(key): continue
		var pair: Array = subscriptions[key]
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],schedule): source.disconnect(pair[1],schedule)
	for key in next:
		if subscriptions.has(key): continue
		var pair: Array = next[key]
		var source = pair[0].get_ref()
		if source != null and source.connect(pair[1],schedule) != OK: push_error("F01 observation connection failed")
	subscriptions = next
func _flush() -> void:
	queued = false
	var owner = host.get_ref()
	var manager = state.get_ref()
	if disposed or not active or owner == null or not owner.is_inside_tree() or manager == null: return
	_rendering = true
	_again = false
	manager.begin()
	var desired = owner.call("build_view")
	var reads: Dictionary = manager.finish()
	_rendering = false
	if not desired is Element or not _valid(desired,mounted) or mounted == null and not _boundary_clear(desired,owner):
		push_error("F01 composition requires a valid fixed-shape Element subtree; previous tree retained")
		return
	_subscribe(reads)
	# Catch mutation after a read during first composition/commit as a later
	# pass. Source-side effects are unsupported, but never recurse into SceneTree.
	_rendering = true
	if mounted == null: mounted = _mount(desired,owner,owner)
	else: _commit(desired,mounted)
	_rendering = false
	runs += 1
	if _again:
		_consecutive += 1
		if _consecutive > 16:
			suspend()
			push_error("F01 composition invalidated itself repeatedly; move mutations out of build_view")
		else: schedule()
	else: _consecutive = 0
func _valid(desired: Element, previous: Mounted) -> bool:
	if desired.type == null: return false
	if desired.type is String:
		if not ClassDB.class_exists(desired.type) or not ClassDB.is_parent_class(desired.type,"Node") or not ClassDB.can_instantiate(desired.type): return false
	elif desired.type is Script:
		if not desired.type.can_instantiate() or not ClassDB.is_parent_class(desired.type.get_instance_base_type(),"Node"): return false
	else: return false
	if previous != null and (previous.type != desired.type or previous.children.size()!=desired.children.size() or previous.node.get_ref()==null): return false
	if previous != null and (previous.properties.keys()!=desired.properties.keys() or previous.handlers.keys()!=desired.handlers.keys()): return false
	for handler in desired.handlers.values():
		if not handler is Callable or not handler.is_valid(): return false
	var names := {}
	for index in range(desired.children.size()):
		if not desired.children[index] is Element or not _valid(desired.children[index],previous.children[index] if previous != null else null): return false
		var name: String = str(desired.children[index].properties.get("name",""))
		if not name.is_empty():
			if names.has(name): return false
			names[name] = true
	return true
func _boundary_clear(desired: Element, parent: Node) -> bool:
	var name: String = str(desired.properties.get("name",""))
	if name.is_empty(): return true
	for child in parent.get_children():
		if str(child.name)==name: return false
	return true
func _mount(desired: Element, parent: Node, owner: Node) -> Mounted:
	var record := Mounted.new()
	var node: Node = ClassDB.instantiate(desired.type) if desired.type is String else desired.type.new()
	allocations += 1
	record.node = weakref(node)
	record.type = desired.type
	_apply(desired,record)
	parent.add_child(node)
	# F01 managed views are runtime output, intentionally not serialized into
	# PackedScene. Reload mounts descriptions once; authored host ownership is
	# untouched. Persisting adopted managed regions belongs to later cutover.
	for child in desired.children: record.children.append(_mount(child,node,owner))
	return record
func _apply(desired: Element, record: Mounted) -> void:
	var node: Node = record.node.get_ref()
	for key in desired.properties:
		if not record.properties.has(key) or not is_same(record.properties[key],desired.properties[key]):
			node.set(key,desired.properties[key])
			writes += 1
	for event in record.handlers:
		if not desired.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if node.is_connected(event,record.handlers[event]): node.disconnect(event,record.handlers[event])
	for event in desired.handlers:
		if not record.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if node.connect(event,desired.handlers[event],Object.CONNECT_PERSIST)!=OK: push_error("F01 native handler connection failed: "+desired.source)
	record.properties = desired.properties.duplicate()
	record.handlers = desired.handlers.duplicate()
func _commit(desired: Element, record: Mounted) -> void:
	_apply(desired,record)
	for index in range(record.children.size()): _commit(desired.children[index],record.children[index])
func _free_managed(record: Mounted) -> void:
	for child in record.children: _free_managed(child)
	var node = record.node.get_ref()
	if node == null: return
	# Foreign descendants have no record. Move them outside the managed region
	# before removing its Nodes; never recursively free application-owned actors.
	var owner = host.get_ref()
	for child in node.get_children():
		var persisted_owner: Node = child.owner
		node.remove_child(child)
		if owner != null:
			owner.add_child(child)
			if persisted_owner != null and persisted_owner.is_ancestor_of(child): child.owner = persisted_owner
	node.free()
func dispose(remove_nodes: bool) -> void:
	if disposed: return
	disposed = true
	suspend()
	if remove_nodes and mounted != null: _free_managed(mounted)
	mounted = null
