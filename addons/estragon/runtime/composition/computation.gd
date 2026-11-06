extends RefCounted
const Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
## F01 computation and retained static-shape records external to native objects.
const Binding = preload("res://addons/estragon/runtime/composition/binding.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
class Mounted extends RefCounted:
	var node: WeakRef
	var type: Variant
	var key: Variant
	var keyed := false
	var slot: Array = []
	var properties: Dictionary = {}
	var handlers: Dictionary = {}
	var bindings: Dictionary = {}
	var children: Array = []
var host: WeakRef
var state: WeakRef
var parent_computation: WeakRef
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
	var ancestor := owner.get_parent()
	while ancestor != null:
		if manager.records.has(ancestor.get_instance_id()):
			parent_computation = weakref(manager.records[ancestor.get_instance_id()])
			break
		ancestor = ancestor.get_parent()
func schedule(_previous: Variant = null, _value: Variant = null) -> void:
	if not active or disposed: return
	if Profile.enabled:
		Profile.add("schedule_requests")
		if queued: Profile.add("coalesced")
	if _rendering: _again = true
	if not queued:
		queued = true
		state.get_ref().enqueue(self)
func depth() -> int:
	var parent = parent_computation.get_ref() if parent_computation != null else null
	if parent != null and not parent.disposed: return parent.depth()+1
	var node = host.get_ref()
	var result := 0
	while node != null:
		result += 1
		node = node.get_parent()
	return result
func suspend() -> void:
	active = false
	_disconnect_bindings(mounted)
	_disconnect()
func resume() -> void:
	active = true
	schedule()
func _disconnect() -> void:
	for pair in subscriptions.values():
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],schedule):
			source.disconnect(pair[1],schedule)
			if Profile.enabled: Profile.add("subscription_disconnects")
	subscriptions.clear()
func _subscribe(next: Dictionary) -> void:
	for key in subscriptions.keys():
		if next.has(key): continue
		var pair: Array = subscriptions[key]
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],schedule):
			source.disconnect(pair[1],schedule)
			if Profile.enabled: Profile.add("subscription_disconnects")
	for key in next:
		if subscriptions.has(key): continue
		var pair: Array = next[key]
		var source = pair[0].get_ref()
		if Profile.enabled: Profile.add("subscription_connects")
		if source != null and source.connect(pair[1],schedule) != OK: push_error("F01 observation connection failed")
	subscriptions = next
func _flush() -> void:
	queued = false
	var owner = host.get_ref()
	var manager = state.get_ref()
	if disposed or not active or owner == null or not owner.is_inside_tree() or manager == null:
		if Profile.enabled: Profile.add("cancelled_jobs")
		return
	var started: int = Time.get_ticks_usec() if Profile.enabled else 0
	if Profile.enabled: Profile.add("views")
	_rendering = true
	_again = false
	manager.begin()
	var desired = owner.call("build_view")
	var reads: Dictionary = manager.finish()
	if Profile.enabled: Profile.elapsed("view",started)
	desired = _normalize(desired)
	_rendering = false
	if not desired is Element or not _valid(desired,mounted) or not _preflight(desired,mounted,owner) or not _rescue_clear(desired,mounted,owner):
		push_error("Invalid composition output or foreign boundary conflict; previous tree retained")
		return
	_subscribe(reads)
	# Catch mutation after a read during first composition/commit as a later
	# pass. Source-side effects are unsupported, but never recurse into SceneTree.
	_rendering = true
	mounted = _reconcile(desired,mounted,owner,owner)
	_rendering = false
	runs += 1
	if Profile.enabled: Profile.elapsed("computation",started)
	if _again:
		_consecutive += 1
		if _consecutive > 16:
			suspend()
			push_error("F01 composition invalidated itself repeatedly; move mutations out of build_view")
		else: schedule()
	else: _consecutive = 0
# Copy descriptions into a validated snapshot. Never rewrite an authored Array or
# descriptor: callers may reuse either, and cycles must fail before native edits.
func _normalize(value, ancestors: Array = [], level: int = 0):
	if not value is Element or level>128 or ancestors.has(value): return null
	if value.keyed and not _key_valid(value.key): return null
	var next := ancestors.duplicate()
	next.append(value)
	if Profile.enabled: Profile.add("normalized_elements")
	var result := Element.new(value.type,value.properties,value.handlers,[],value.source,value.key,value.keyed)
	result.bindings = value.bindings.duplicate()
	if not _flatten(value.children,[],result.children,next,level+1): return null
	return result
func _key_valid(key) -> bool:
	return typeof(key)==TYPE_INT or typeof(key)==TYPE_STRING and not key.is_empty()
func _flatten(values: Array, path: Array, output: Array, ancestors: Array, level: int) -> bool:
	if level>128: return false
	for index in range(values.size()):
		var slot := path.duplicate()
		slot.append(index)
		var value = values[index]
		if value is Array:
			if not _flatten(value,slot,output,ancestors,level+1): return false
		elif value==null: output.append(null)
		else:
			var child = _normalize(value,ancestors,level+1)
			if child==null: return false
			child.slot = slot
			output.append(child)
	return true
# Exact key type participates in identity (bool/float never alias int).
func _identity(value, index: int) -> String:
	if value.keyed: return "k:"+str(typeof(value.key))+":"+str(value.key)
	return "p:"+str(value.slot if not value.slot.is_empty() else [index])
func _matches(desired: Array, previous: Array) -> Array:
	var old := {}
	for index in range(previous.size()):
		if previous[index]!=null: old[_identity(previous[index],index)] = previous[index]
	var result: Array = []
	for index in range(desired.size()):
		result.append(old.get(_identity(desired[index],index)) if desired[index]!=null else null)
	return result
func _valid(desired: Element, previous: Mounted) -> bool:
	if Profile.enabled: Profile.add("validations")
	if desired.type == null: return false
	if desired.type is String:
		if not ClassDB.class_exists(desired.type) or not ClassDB.is_parent_class(desired.type,"Node") or not ClassDB.can_instantiate(desired.type): return false
	elif desired.type is Script:
		if not desired.type.can_instantiate() or not ClassDB.is_parent_class(desired.type.get_instance_base_type(),"Node"): return false
	else: return false
	for binding in desired.bindings.values():
		if not binding is Binding or not binding.valid: return false
	for handler in desired.handlers.values():
		if not handler is Callable or not handler.is_valid(): return false
	var names := {}
	var keys := {}
	if desired.keyed and not _key_valid(desired.key): return false
	for child in desired.children:
		if child == null: continue
		if not child is Element or not _valid(child,null): return false
		if child.keyed:
			var key := _identity(child,0)
			if keys.has(key): return false
			keys[key] = true
		var name: String = str(child.properties.get("name",""))
		if not name.is_empty():
			if names.has(name): return false
			names[name] = true
	return true
func _collect_foreign(record, result: Array) -> void:
	if record==null: return
	var node = record.node.get_ref()
	if node==null: return
	var known: Array = []
	for child in record.children:
		if child==null: continue
		_collect_foreign(child,result)
		if child.node.get_ref()!=null: known.append(child.node.get_ref())
	var manager = state.get_ref()
	if manager!=null and manager.records.has(node.get_instance_id()):
		var nested = manager.records[node.get_instance_id()].mounted
		_collect_foreign(nested,result)
		if nested!=null and nested.node.get_ref()!=null: known.append(nested.node.get_ref())
	for child in node.get_children():
		if not known.has(child) and not result.has(child): result.append(child)
func _planned_foreign(desired, previous, result: Array) -> void:
	if previous==null: return
	if desired==null or not _compatible(desired,previous):
		_collect_foreign(previous,result)
		return
	var matches := _matches(desired.children,previous.children)
	for index in range(previous.children.size()):
		var old = previous.children[index]
		var next = null
		var found := matches.find(old) if old!=null else -1
		if found>=0: next = desired.children[found]
		_planned_foreign(next,old,result)
func _rescue_clear(desired, previous, owner: Node) -> bool:
	var rescued: Array = []
	_planned_foreign(desired,previous,rescued)
	var names := {}
	for existing in owner.get_children():
		if previous!=null and existing==previous.node.get_ref(): continue
		names[str(existing.name)] = true
	var desired_name: String = str(desired.properties.get("name",str(previous.node.get_ref().name) if previous!=null and _compatible(desired,previous) else ""))
	if not desired_name.is_empty(): names[desired_name] = true
	for child in rescued:
		var name: String = str(child.name)
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
	if Profile.enabled: Profile.add("nodes_created")
	record.node = weakref(node)
	record.type = desired.type
	record.key = desired.key
	record.keyed = desired.keyed
	record.slot = desired.slot.duplicate()
	_apply(desired,record)
	parent.add_child(node)
	# F01 managed views are runtime output, intentionally not serialized into
	# PackedScene. Reload mounts descriptions once; authored host ownership is
	# untouched. Persisting adopted managed regions belongs to later cutover.
	for child in desired.children: record.children.append(_mount(child,node,owner) if child != null else null)
	return record
func _apply(desired: Element, record: Mounted) -> void:
	var node: Node = record.node.get_ref()
	for key in record.bindings.keys():
		if not desired.bindings.has(key) or not record.bindings[key].same(desired.bindings[key]):
			record.bindings[key].disconnect_edit()
			record.bindings.erase(key)
	for key in desired.bindings:
		var binding = record.bindings.get(key,desired.bindings[key])
		record.bindings[key] = binding
		if not is_same(node.get(key),desired.bindings[key].value):
			node.set(key,desired.bindings[key].value)
			writes += 1
			if Profile.enabled: Profile.add("property_writes")
		binding.attach(node,self)
	for key in desired.properties:
		if not record.properties.has(key) or not is_same(record.properties[key],desired.properties[key]):
			node.set(key,desired.properties[key])
			writes += 1
			if Profile.enabled: Profile.add("property_writes")
	for event in record.handlers:
		if not desired.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if node.is_connected(event,record.handlers[event]):
				node.disconnect(event,record.handlers[event])
				if Profile.enabled: Profile.add("handler_disconnects")
	for event in desired.handlers:
		if not record.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if Profile.enabled: Profile.add("handler_connects")
			if node.connect(event,desired.handlers[event],Object.CONNECT_PERSIST)!=OK: push_error("F01 native handler connection failed: "+desired.source)
	record.properties = desired.properties.duplicate()
	record.handlers = desired.handlers.duplicate()
func _compatible(desired: Element, record: Mounted) -> bool:
	return record != null and is_same(record.type,desired.type) and record.keyed==desired.keyed and (not desired.keyed or typeof(record.key)==typeof(desired.key) and record.key==desired.key) and record.node.get_ref()!=null
func _reconcile(desired, record, parent: Node, owner: Node):
	if Profile.enabled: Profile.add("reconciles")
	if desired == null:
		if record != null: _free_managed(record,owner)
		return null
	if not _compatible(desired,record):
		if record != null: _free_managed(record,owner)
		return _mount(desired,parent,owner)
	_apply(desired,record)
	var node: Node = record.node.get_ref()
	if node.get_parent()!=parent:
		if node.get_parent()!=null: node.get_parent().remove_child(node)
		parent.add_child(node)
		if Profile.enabled: Profile.add("reparents")
	var matches := _matches(desired.children,record.children)
	# Dispose unmatched/retyped branches before mounts, including queued scopes.
	for old in record.children:
		if old==null: continue
		var index := matches.find(old)
		if index<0 or not _compatible(desired.children[index],old):
			_free_managed(old,owner)
			if index>=0: matches[index] = null
	_prepare_names(desired.children,matches,node)
	var children: Array = []
	for index in range(desired.children.size()):
		children.append(_reconcile(desired.children[index],matches[index],node,owner))
	record.children = children
	_order(children,node)
	return record
# Release names that must change before applying final sibling names. Native
# Node otherwise silently renames a valid swap against the still-old sibling.
func _prepare_names(desired: Array, matches: Array, parent: Node) -> void:
	var pending: Array = []
	var targets := {}
	for index in range(desired.size()):
		var next = desired[index]
		var old = matches[index]
		if next==null or old==null or not next.properties.has("name"): continue
		if old.properties.has("name") and is_same(old.properties.name,next.properties.name): continue
		var node: Node = old.node.get_ref()
		if node==null or node.get_parent()!=parent or str(node.name)==str(next.properties.name): continue
		pending.append(node)
		targets[str(next.properties.name)] = true
	for node in pending:
		if not targets.has(str(node.name)): continue
		var temporary := "_EstragonRename_"+str(node.get_instance_id())
		while parent.has_node(NodePath(temporary)): temporary += "_"
		node.name = temporary
		writes += 1
		if Profile.enabled: Profile.add("property_writes")
# Keep a longest increasing subsequence of actual native indices. Everything
# else moves once, right to left beside its final successor; no-op moves zero.
func _order(children: Array, parent: Node) -> void:
	var nodes: Array = []
	for child in children:
		if child!=null: nodes.append(child.node.get_ref())
	var lengths: Array = []
	var predecessors: Array = []
	var best := -1
	for index in range(nodes.size()):
		lengths.append(1)
		predecessors.append(-1)
		for before in range(index):
			if Profile.enabled: Profile.add("order_comparisons")
			if nodes[before].get_index()<nodes[index].get_index() and lengths[before]+1>lengths[index]:
				lengths[index] = lengths[before]+1
				predecessors[index] = before
		if best<0 or lengths[index]>lengths[best]: best = index
	var keep := {}
	while best>=0:
		keep[best] = true
		best = predecessors[best]
	var anchor: Node = null
	for index in range(nodes.size()-1,-1,-1):
		var actual: Node = nodes[index]
		if not keep.has(index):
			var position := parent.get_child_count()-1 if anchor==null else anchor.get_index()-(1 if actual.get_index()<anchor.get_index() else 0)
			if actual.get_index()!=position:
				parent.move_child(actual,position)
				moves += 1
				if Profile.enabled: Profile.add("moves")
		anchor = actual

func _preflight(desired, previous, parent: Node) -> bool:
	if Profile.enabled: Profile.add("preflights")
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
		if kind==TYPE_OBJECT and value!=null:
			var expected: String = str(properties[key].get("class_name",""))
			if ClassDB.class_exists(expected) and not value.is_class(expected): return false
	for key in desired.bindings:
		if key!="value" or desired.properties.has(key) or desired.handlers.has("value_changed") or not properties.has(key) or properties[key].type!=TYPE_BOOL or int(properties[key].usage)&PROPERTY_USAGE_READ_ONLY: return false
		var args: Array = signals.get("value_changed",{}).get("args",[])

		# 4.0 lacks signal argument type metadata. Compiler source proof and
		# native typed callback still apply; optional introspection cannot
		# reject a valid input on that engine.
		if args.size()!=1 or args[0].type not in [TYPE_NIL,TYPE_BOOL]: return false
	for key in desired.handlers:
		if not signals.has(key): return false
	var node: Node = previous.node.get_ref() if _compatible(desired,previous) else null
	if parent != null:
		var name: String = str(desired.properties.get("name",str(node.name) if node != null else ""))
		for existing in parent.get_children():
			if str(existing.name)==name and (previous==null or existing!=previous.node.get_ref()): return false
	var known: Array = []
	if node != null:
		for child in previous.children:
			if child != null and child.node.get_ref()!=null: known.append(child.node.get_ref())
	var names := {}
	var matches := _matches(desired.children,previous.children if node!=null else [])
	for index in range(desired.children.size()):
		var child = desired.children[index]
		if child == null: continue
		var old = matches[index]
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
	for binding in record.bindings.values(): binding.disconnect_edit()
	record.bindings.clear()
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
	if Profile.enabled: Profile.add("nodes_freed")
func dispose(remove_nodes: bool, rescue: Node = null) -> void:
	if disposed: return
	disposed = true
	suspend()
	if remove_nodes and mounted != null: _free_managed(mounted,rescue)
	mounted = null

func _disconnect_bindings(record) -> void:
	if record==null: return
	for binding in record.bindings.values(): binding.disconnect_edit()
	for child in record.children: _disconnect_bindings(child)
