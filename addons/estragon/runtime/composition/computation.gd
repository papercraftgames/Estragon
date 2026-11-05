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
var frees := 0
var moves := 0
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
		state.get_ref().enqueue(self)
func depth() -> int:
	var node = host.get_ref()
	var result := 0
	while node != null:
		result += 1
		node = node.get_parent()
	return result
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
	if not desired is Element or not _valid(desired,mounted) or not _preflight(desired,mounted,owner):
		push_error("Invalid composition output or foreign boundary conflict; previous tree retained")
		return
	_subscribe(reads)
	# Catch mutation after a read during first composition/commit as a later
	# pass. Source-side effects are unsupported, but never recurse into SceneTree.
	_rendering = true
	mounted = _reconcile(desired,mounted,owner,owner)
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
	for handler in desired.handlers.values():
		if not handler is Callable or not handler.is_valid(): return false
	var names := {}
	for child in desired.children:
		if child == null: continue
		if not child is Element or not _valid(child,null): return false
		var name: String = str(child.properties.get("name",""))
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
	for child in desired.children: record.children.append(_mount(child,node,owner) if child != null else null)
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
func _compatible(desired: Element, record: Mounted) -> bool:
	return record != null and record.type==desired.type and record.node.get_ref()!=null
func _reconcile(desired, record, parent: Node, owner: Node):
	if desired == null:
		if record != null: _free_managed(record,owner)
		return null
	if not _compatible(desired,record):
		if record != null: _free_managed(record,owner)
		return _mount(desired,parent,owner)
	_apply(desired,record)
	var node: Node = record.node.get_ref()
	var children: Array = []
	for index in range(maxi(desired.children.size(),record.children.size())):
		var next = desired.children[index] if index < desired.children.size() else null
		var old = record.children[index] if index < record.children.size() else null
		var child = _reconcile(next,old,node,owner)
		if index < desired.children.size(): children.append(child)
	record.children = children
	var position := 0
	for child in children:
		if child == null: continue
		var actual: Node = child.node.get_ref()
		if actual.get_index()!=position:
			node.move_child(actual,position)
			moves += 1
		position += 1
	return record
func _preflight(desired, previous, parent: Node) -> bool:
	if desired == null: return true
	var native: String = desired.type if desired.type is String else desired.type.get_instance_base_type()
	var properties := {}
	var signals := {}
	for prop in ClassDB.class_get_property_list(native): properties[prop.name] = prop
	for event in ClassDB.class_get_signal_list(native): signals[event.name] = event
	var script = desired.type if desired.type is Script else null
	while script != null:
		for prop in script.get_script_property_list(): properties[prop.name] = prop
		for event in script.get_script_signal_list(): signals[event.name] = event
		for method in script.get_script_method_list():
			if method.name=="_init" and method.args.size()>method.default_args.size(): return false
		script = script.get_base_script()
	for key in desired.properties:
		if not properties.has(key) or key in ["script","owner"] or int(properties[key].usage)&PROPERTY_USAGE_READ_ONLY: return false
		var value = desired.properties[key]
		var kind: int = properties[key].type
		if kind!=TYPE_NIL and typeof(value)!=kind and not (kind==TYPE_FLOAT and typeof(value)==TYPE_INT) and not (kind==TYPE_OBJECT and value==null) and not (kind in [TYPE_STRING,TYPE_STRING_NAME] and typeof(value) in [TYPE_STRING,TYPE_STRING_NAME]): return false
	for key in desired.handlers:
		if not signals.has(key): return false
	var node: Node = previous.node.get_ref() if _compatible(desired,previous) else null
	if previous != null and previous.node.get_ref()==null: return false
	if parent != null:
		var name: String = str(desired.properties.get("name",str(node.name) if node != null else ""))
		for existing in parent.get_children():
			if str(existing.name)==name and (previous==null or existing!=previous.node.get_ref()): return false
	var known: Array = []
	if node != null:
		for child in previous.children:
			if child != null and child.node.get_ref()!=null: known.append(child.node.get_ref())
	var names := {}
	for index in range(desired.children.size()):
		var child = desired.children[index]
		if child == null: continue
		var old = previous.children[index] if node!=null and index<previous.children.size() else null
		if not _preflight(child,old,null): return false
		var name: String = str(child.properties.get("name",str(old.node.get_ref().name) if old!=null and _compatible(child,old) else ""))
		if not name.is_empty():
			if names.has(name): return false
			names[name] = true
			if node != null:
				for existing in node.get_children():
					if str(existing.name)==name and not known.has(existing): return false
	return true
func _free_managed(record: Mounted, rescue: Node = null) -> void:
	for child in record.children:
		if child != null: _free_managed(child,rescue)
	var node = record.node.get_ref()
	if node == null: return
	# Foreign descendants have no record. Move them outside the managed region
	# before removing its Nodes; never recursively free application-owned actors.
	var owner: Node = rescue if rescue != null else host.get_ref()
	var manager = state.get_ref()
	if manager != null and manager.records.has(node.get_instance_id()): manager.unmount(node,owner)
	for child in node.get_children():
		var persisted_owner: Node = child.owner
		node.remove_child(child)
		if owner != null:
			owner.add_child(child)
			if persisted_owner != null and persisted_owner.is_ancestor_of(child): child.owner = persisted_owner
	node.free()
	frees += 1
func dispose(remove_nodes: bool, rescue: Node = null) -> void:
	if disposed: return
	disposed = true
	suspend()
	if remove_nodes and mounted != null: _free_managed(mounted,rescue)
	mounted = null
