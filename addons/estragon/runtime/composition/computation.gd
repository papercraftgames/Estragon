extends RefCounted
const GridDefinition = preload("../node/internal/grid_definition.gd")
const GRID_CONFIG := ["columns","rows","areas","template","horizontal_align","vertical_align"]
const StackContract = preload("../node/internal/stack_contract.gd")
const VisualStyle = preload("../node/internal/visual_style_2d.gd")
const Length = preload("../node/internal/length.gd")
const NativeAttributes = preload("native_attributes.gd")
const Profile = preload("profile.tres")
## F01 computation and retained static-shape records external to native objects.
const Binding = preload("binding.gd")
const Element = preload("element.gd")
const Hosts = preload("../node/internal/composition_hosts.tres")
class Mounted extends RefCounted:
	var node: WeakRef
	var id: int
	var borrowed: WeakRef
	var type: Variant
	var key: Variant
	var keyed := false
	var slot: Array = []
	var properties: Dictionary = {}
	var defaults: Dictionary = {}
	var spread_owned: Dictionary = {}
	var spread_applied: Dictionary = {}
	var handlers: Dictionary = {}
	var bindings: Dictionary = {}
	var children: Array = []
var render_cache = preload("render_cache.gd").new()
var cache_observers: Dictionary = {}
var notification_callbacks: Dictionary = {}
var host: WeakRef
var projection
var _borrow_seen: Dictionary = {}
var _observes_children := false
var layout_host
var state: WeakRef
var parent_computation: WeakRef
var mounted: Mounted
var subscriptions: Dictionary = {}
var committed_reads: Dictionary = {}
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
var validation_error := ""
func _init(owner: Node, manager: Resource) -> void:
	host = weakref(owner)
	state = weakref(manager)
	projection = preload("projection.gd").new(self,owner)
	layout_host = preload("layout_host.gd").new(owner)
	var ancestor := owner.get_parent()
	while ancestor != null:
		if manager.records.has(ancestor.get_instance_id()):
			parent_computation = weakref(manager.records[ancestor.get_instance_id()])
			break
		ancestor = ancestor.get_parent()
func schedule(_previous: Variant = null, _value: Variant = null) -> void:
	if not active or disposed: return
	for entry in render_cache.children.get("$root",[]): entry.invalidate()
	if Profile.is_enabled():
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
	render_cache = preload("render_cache.gd").new()
	cache_observers.clear()
	committed_reads.clear()
	projection.stop()
	Hosts.replace_projection(self,{}, {})
	layout_host.stop()
	_disconnect_bindings(mounted)
	_disconnect()
func resume() -> void:
	active = true
	layout_host.start()
	schedule()
func _disconnect() -> void:
	for key in subscriptions:
		var pair: Array = subscriptions[key]
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],notification_callbacks.get(key,Callable())):
			source.disconnect(pair[1],notification_callbacks[key])
			if Profile.is_enabled(): Profile.add("subscription_disconnects")
	subscriptions.clear()
	notification_callbacks.clear()
func _subscribe(next: Dictionary) -> void:
	for key in subscriptions.keys():
		if next.has(key): continue
		var pair: Array = subscriptions[key]
		var source = pair[0].get_ref()
		if source != null and source.is_connected(pair[1],notification_callbacks.get(key,Callable())):
			source.disconnect(pair[1],notification_callbacks[key])
			if Profile.is_enabled(): Profile.add("subscription_disconnects")
	for key in notification_callbacks.keys():
		if not next.has(key): notification_callbacks.erase(key)
	for key in next:
		if not subscriptions.has(key): _connect_observer(key,next[key])
	subscriptions = next
func _flush() -> void:
	queued = false
	var owner = host.get_ref()
	var manager = state.get_ref()
	if disposed or not active or owner == null or not owner.is_inside_tree() or manager == null:
		if Profile.is_enabled(): Profile.add("cancelled_jobs")
		return
	var started: int = Time.get_ticks_usec() if Profile.is_enabled() else 0
	if Profile.is_enabled(): Profile.add("views")
	_rendering = true
	_again = false
	manager.enter_render(self)
	manager.begin()
	var desired = manager.call_at("$root",Callable(owner,"build_view"),[])
	var reads: Dictionary = manager.finish()
	reads.merge(manager.leave_render(),true)
	# New reads are connected eagerly by watch(). Retain previous native-tree
	# subscriptions on failed preflight; prune them only after successful validation.
	if Profile.is_enabled(): Profile.elapsed("view",started)
	_borrow_seen.clear()
	_observes_children = false
	validation_error = ""
	desired = _normalize(desired)
	_rendering = false
	if not desired is Element or not _valid(desired,mounted) or not _preflight(desired,mounted,owner) or not _rescue_clear(desired,mounted,owner):
		var repair_reads := committed_reads.duplicate()
		repair_reads.merge(reads,true)
		_subscribe(repair_reads)
		push_error(validation_error if not validation_error.is_empty() else "Invalid composition output or foreign boundary conflict; previous tree retained")
		return
	committed_reads = reads.duplicate()
	_subscribe(reads)
	# A nested array may be an empty get_children() result. Observe native
	# changes without inspecting the expression source or polling the tree.
	if _observes_children: projection.start()
	else: projection.stop()
	# Catch mutation after a read during first composition/commit as a later
	# pass. Source-side effects are unsupported, but never recurse into SceneTree.
	_rendering = true
	mounted = _reconcile(desired,mounted,owner,owner)
	var projected := {}
	var ordering := {}
	_projection_tree(mounted,projected,ordering)
	Hosts.replace_projection(self,projected,ordering)
	layout_host.update(mounted.node.get_ref() if mounted != null else null)
	_rendering = false
	runs += 1
	if Profile.is_enabled(): Profile.elapsed("computation",started)
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
	if not value.attribute_error.is_empty():
		validation_error = value.attribute_error
		return null
	if value.keyed and not _key_valid(value.key): return null
	var next := ancestors.duplicate()
	next.append(value)
	if Profile.is_enabled(): Profile.add("normalized_elements")
	var result := Element.new(value.type,value.properties.duplicate(),value.handlers,[],value.source,value.key,value.keyed)
	result.placement = value.placement.duplicate(true)
	result.origins = value.origins.duplicate()
	result.spread_properties = value.spread_properties.duplicate()
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
			_observes_children = true
			if not _flatten(value,slot,output,ancestors,level+1): return false
		elif value==null: output.append(null)
		elif value is Node:
			_observes_children = true
			var manager = state.get_ref()
			if manager.is_managed(value): continue
			if value.get_parent() != host.get_ref():
				var label: String = str(value.get_path()) if value.is_inside_tree() else str(value.name)
				push_error(ancestors.back().source+": GGX borrowed children must be persistent direct children of the rendering host: "+label)
				return false
			if value.owner == null: continue # Foreign runtime actors remain native.
			if _borrow_seen.has(value.get_instance_id()):
				push_error(ancestors.back().source+": GGX scene child referenced more than once: "+str(value.get_path()))
				return false
			_borrow_seen[value.get_instance_id()] = true
			var child := Element.new()
			child.borrowed = weakref(value)
			child.slot = slot
			output.append(child)
		else:
			var child = _normalize(value,ancestors,level+1)
			if child==null: return false
			child.slot = slot
			output.append(child)
	return true
# Exact key type participates in identity (bool/float never alias int).
func _identity(value, index: int) -> String:
	if value.borrowed != null: return "n:"+str(value.borrowed.get_ref().get_instance_id()) if value.borrowed.get_ref() != null else "expired"
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
	if Profile.is_enabled(): Profile.add("validations")
	if desired.borrowed != null: return desired.borrowed.get_ref() != null
	if desired.type == null: return false
	if desired.type is String:
		if not ClassDB.class_exists(desired.type) or not ClassDB.is_parent_class(desired.type,"Node") or not ClassDB.can_instantiate(desired.type): return false
	elif desired.type is Script:
		if not desired.type.can_instantiate() or not ClassDB.is_parent_class(desired.type.get_instance_base_type(),"Node"): return false
	else: return false
	for binding in desired.bindings.values():
		if not binding is Binding or not binding.valid: return false
	for event in desired.handlers:
		var handler = desired.handlers[event]
		if not handler is Callable or not handler.is_valid(): return _invalid_attribute(desired,event,"signal requires a valid native Callable")
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
			if names.has(name): return _invalid_attribute(child,"name","duplicate declared sibling name "+name)
			names[name] = true
	return true
func _collect_foreign(record, result: Array) -> void:
	if record==null or record.borrowed != null: return
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
	for child in (node._layout_children() if node.has_method("_layout_children") else node.get_children()):
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
	for existing in (owner._layout_children() if owner.has_method("_layout_children") else owner.get_children()):
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
	for child in (parent._layout_children() if parent.has_method("_layout_children") else parent.get_children()):
		if str(child.name)==name: return false
	return true
func _mount(desired: Element, parent: Node, owner: Node) -> Mounted:
	if parent.has_method("_composition_child_parent"): parent = parent._composition_child_parent()
	var record := Mounted.new()
	if desired.borrowed != null:
		record.borrowed = desired.borrowed
		record.node = desired.borrowed
		return record
	var node: Node = ClassDB.instantiate(desired.type) if desired.type is String else desired.type.new()
	state.get_ref().managed[node.get_instance_id()] = weakref(node)
	allocations += 1
	if Profile.is_enabled(): Profile.add("nodes_created")
	record.node = weakref(node)
	record.id = node.get_instance_id()
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
	# Capture the real class/_init defaults before its first authored write, with
	# no probe instances. Later first ownership preserves preexisting native state.
	for key in desired.properties:
		if not record.defaults.has(key):
			record.defaults[key] = node.get(key)
			# An unattached native Node starts unnamed, but set_name rejects empty
			# names after attachment. Restore its native class label instead;
			# Godot retains authority over sibling-name uniqueness.
			if key=="name" and str(record.defaults[key]).is_empty(): record.defaults[key] = node.get_class()
	var resets := _spread_resets(desired,record)
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
			if Profile.is_enabled(): Profile.add("property_writes")
		binding.attach(node,self)
	Hosts.set_placement(node,desired.placement)
	var grid := GridDefinition.marked(desired.type)
	if grid:
		node._apply_grid(_grid_config(desired))
	var stack := StackContract.registered(desired.type)
	var scroll := VisualStyle.marked(desired.type,"ESTRAGON_SCROLL_2D")
	if stack:
		var policy := resets.duplicate()
		policy.merge(desired.properties,true)
		node._apply_stack_policy(policy)
	for key in resets:
		if scroll and key=="scroll_offset": continue
		if (not stack or key not in ["direction","horizontal_align","vertical_align"]) and (not grid or key not in GRID_CONFIG): node.set(key,resets[key])
		writes += 1
		if Profile.is_enabled(): Profile.add("property_writes")
	# An omitted previously declared border side removes that local override;
	# do not turn omission into permanent native state or change other props.
	if VisualStyle.supported(desired.type):
		for key in record.properties:
			if (key in Length.BORDER_EDGES or key in VisualStyle.RADII.slice(1)) and not desired.properties.has(key):
				node.set(key,"auto")
				writes += 1
				if Profile.is_enabled(): Profile.add("property_writes")
	if Length.registered(desired.type,"min_width"):
		for key in Length.MINIMUMS:
			if record.properties.has(key) and not desired.properties.has(key):
				node.set(key,0.0)
				writes += 1
				if Profile.is_enabled(): Profile.add("property_writes")
	if Length.registered(desired.type,"max_width"):
		for key in Length.MAXIMUMS:
			if record.properties.has(key) and not desired.properties.has(key): node.set(key,"auto")
	if StackContract.self_registered(desired.type) and record.properties.has("align_self") and not desired.properties.has("align_self"):
		node.set("align_self","auto")
		writes += 1
		if Profile.is_enabled(): Profile.add("property_writes")
	for key in desired.properties:
		if scroll and key=="scroll_offset": continue
		if not record.properties.has(key) or not is_same(record.properties[key],desired.properties[key]):
			if not stack or key not in ["direction","horizontal_align","vertical_align"]: node.set(key,desired.properties[key])
			writes += 1
			if Profile.is_enabled(): Profile.add("property_writes")
	# Apply the effective authored offset after geometry/axis flags. A dirty
	# component retains it until the same core's next arrangement, so attribute
	# order cannot clamp restoration against the previous viewport range.
	if scroll:
		var offset = desired.properties if desired.properties.has("scroll_offset") else resets
		if offset.has("scroll_offset") and (not desired.properties.has("scroll_offset") or not record.properties.has("scroll_offset") or not is_same(record.properties.scroll_offset,offset.scroll_offset)):
			node.set("scroll_offset",offset.scroll_offset)
			writes += 1
			if Profile.is_enabled(): Profile.add("property_writes")
	for event in record.handlers:
		if not desired.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if node.is_connected(event,record.handlers[event]):
				node.disconnect(event,record.handlers[event])
				if Profile.is_enabled(): Profile.add("handler_disconnects")
	for event in desired.handlers:
		if not record.handlers.has(event) or record.handlers[event]!=desired.handlers[event]:
			if Profile.is_enabled(): Profile.add("handler_connects")
			if node.connect(event,desired.handlers[event],Object.CONNECT_PERSIST)!=OK: push_error("F01 native handler connection failed: "+desired.source)
	record.properties = desired.properties.duplicate()
	record.handlers = desired.handlers.duplicate()
	record.spread_owned = desired.spread_properties.duplicate()
	record.spread_applied.clear()
	for key in desired.properties:
		if record.spread_owned.has(key): record.spread_applied[key] = node.get(key)

func _spread_resets(desired: Element, record) -> Dictionary:
	var result := {}
	if record==null or not _compatible(desired,record): return result
	var node = record.node.get_ref()
	for key in record.spread_applied:
		if desired.properties.has(key) or (key=="align_self" and StackContract.self_registered(desired.type)) or key in Length.BORDER_EDGES or key in Length.MINIMUMS or key in Length.MAXIMUMS: continue
		# Do not overwrite imperative native changes made since our last commit.
		if is_same(node.get(key),record.spread_applied[key]) and not is_same(node.get(key),record.defaults[key]): result[key] = record.defaults[key]
	return result

func _effective_name(desired: Element, record) -> String:
	if desired.properties.has("name"): return str(desired.properties.name)
	var resets := _spread_resets(desired,record)
	if resets.has("name"): return str(resets.name)
	return str(record.node.get_ref().name) if _compatible(desired,record) else ""

func _invalid_attribute(desired: Element, key: String, message: String) -> bool:
	validation_error = desired.location(key)+": attribute '"+key+"': "+message+"; previous tree retained"
	return false

func _handler_error(handler: Callable, emitted: int) -> String:
	# Named methods expose public metadata on both supported engines. Custom
	# Callables without method metadata retain native invocation semantics.
	if handler.is_custom(): return ""
	var target = handler.get_object()
	if target==null: return ""
	for method in target.get_method_list():
		if method.name!=handler.get_method(): continue
		if int(method.flags)&METHOD_FLAG_VARARG: return ""
		var supplied := emitted
		var maximum: int = method.args.size()
		if supplied<maximum-method.default_args.size() or supplied>maximum: return "Callable arity does not match native signal"
		return ""
	return ""
func _compatible(desired: Element, record: Mounted) -> bool:
	if record == null: return false
	if desired.borrowed != null or record.borrowed != null:
		return desired.borrowed != null and record.borrowed != null and desired.borrowed.get_ref() != null and desired.borrowed.get_ref() == record.node.get_ref()
	return record != null and is_same(record.type,desired.type) and record.keyed==desired.keyed and (not desired.keyed or typeof(record.key)==typeof(desired.key) and record.key==desired.key) and record.node.get_ref()!=null
func _reconcile(desired, record, parent: Node, owner: Node):
	if parent.has_method("_composition_child_parent"): parent = parent._composition_child_parent()
	if Profile.is_enabled(): Profile.add("reconciles")
	if desired == null:
		if record != null: _free_managed(record,owner)
		return null
	if not _compatible(desired,record):
		if record != null: _free_managed(record,owner)
		return _mount(desired,parent,owner)
	if record.borrowed != null: return record
	_apply(desired,record)
	var node: Node = record.node.get_ref()
	if node.get_parent()!=parent:
		if node.get_parent()!=null: node.get_parent().remove_child(node)
		parent.add_child(node)
		if Profile.is_enabled(): Profile.add("reparents")
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
	if parent.has_method("_composition_child_parent"): parent = parent._composition_child_parent()
	var pending: Array = []
	var targets := {}
	for index in range(desired.size()):
		var next = desired[index]
		var old = matches[index]
		if next==null or old==null: continue
		if not next.properties.has("name") and not _spread_resets(next,old).has("name"): continue
		var final_name := _effective_name(next,old)
		var node: Node = old.node.get_ref()
		if node==null or node.get_parent()!=parent or str(node.name)==final_name: continue
		pending.append([node,old])
		targets[final_name] = true
	for pair in pending:
		var node: Node = pair[0]
		if not targets.has(str(node.name)): continue
		var temporary := "_EstragonRename_"+str(node.get_instance_id())
		while parent.has_node(NodePath(temporary)): temporary += "_"
		node.name = temporary
		if pair[1].spread_applied.has("name"): pair[1].spread_applied.name = node.name
		writes += 1
		if Profile.is_enabled(): Profile.add("property_writes")
# Keep a longest increasing subsequence of actual native indices. Everything
# else moves once, right to left beside its final successor; no-op moves zero.
func _order(children: Array, parent: Node) -> void:
	if parent.has_method("_composition_child_parent"): parent = parent._composition_child_parent()
	var nodes: Array = []
	for child in children:
		if child!=null and child.borrowed == null: nodes.append(child.node.get_ref())
	# Native child indices are unique. Binary-search minimal tails to recover
	# one longest increasing subsequence without quadratic comparisons.
	var tails: Array = []
	var tail_indices: Array = []
	var predecessors: Array = []
	for index in range(nodes.size()):
		var position: int = nodes[index].get_index()
		var low := 0
		var high := tails.size()
		while low<high:
			if Profile.is_enabled(): Profile.add("order_comparisons")
			var middle: int = (low+high)/2
			if tails[middle]<position: low = middle+1
			else: high = middle
		predecessors.append(tail_indices[low-1] if low>0 else -1)
		if low==tails.size():
			tails.append(position)
			tail_indices.append(index)
		else:
			tails[low] = position
			tail_indices[low] = index
	var best: int = tail_indices.back() if not tail_indices.is_empty() else -1
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
				if Profile.is_enabled(): Profile.add("moves")
		anchor = actual

func _grid_config(desired: Element) -> Dictionary:
	var result := {"columns":null,"rows":null,"areas":[],"template":"","horizontal_align":"stretch","vertical_align":"stretch"}
	for key in GRID_CONFIG:
		if desired.properties.has(key): result[key] = desired.properties[key]
	return result

func _preflight(desired, previous, parent: Node, contracts: Variant = null) -> bool:
	if Profile.is_enabled(): Profile.add("preflights")
	if desired == null: return true
	if desired.borrowed != null: return desired.borrowed.get_ref() != null
	# Cache only within this synchronous desired-tree validation. No Script
	# contracts survive a commit or hide editor reload/metadata changes.
	if contracts==null: contracts = {}
	if not contracts.has(desired.type):
		if Profile.is_enabled(): Profile.add("metadata_builds")
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
		contracts[desired.type] = {"properties":properties,"signals":signals}
	var properties: Dictionary = contracts[desired.type].properties
	var signals: Dictionary = contracts[desired.type].signals
	if StackContract.registered(desired.type):
		var policy: Dictionary = previous.properties.duplicate() if previous!=null and _compatible(desired,previous) else {}
		policy.merge(_spread_resets(desired,previous),true)
		policy.merge(desired.properties,true)
		var fixed := StackContract.preset(desired.type)
		var direction = policy.get("direction",StackContract.initial(desired.type))
		for key in ["direction","horizontal_align","vertical_align","align_content"]:
			var value = policy.get(key,direction if key=="direction" else ("stretch" if direction=="grid" and key in ["horizontal_align","vertical_align"] else "start"))
			var message := StackContract.error(key,value,str(direction),fixed,StackContract.grid_capable(desired.type))
			if not message.is_empty():
				validation_error = desired.location(key)+": "+message+"; previous tree retained"
				return false
	if VisualStyle.marked(desired.type,"ESTRAGON_SCROLL_2D"):
		if desired.properties.has("scroll_offset") and not preload("../node/internal/scroll_2d.gd").valid_offset(desired.properties.scroll_offset): return _invalid_attribute(desired,"scroll_offset","requires a finite nonnegative Vector2")
		for key in ["scroll_range","content_extent"]:
			if desired.properties.has(key): return _invalid_attribute(desired,key,"read-only scrolling measurement")
	if GridDefinition.marked(desired.type):
		var config := _grid_config(desired)
		var grid_active: bool = desired.properties.get("direction","grid")=="grid"
		if not grid_active:
			config.horizontal_align = "stretch"
			config.vertical_align = "stretch"
		var grid_matches := _matches(desired.children,previous.children if previous!=null and _compatible(desired,previous) else [])
		var placements: Array = []
		var grid_children: Array = []
		for child in desired.children:
			if child==null: continue
			if child.borrowed==null:
				for key in GridDefinition.PLACEMENT:
					if child.properties.has(key):
						child.placement[key] = child.properties[key]
						child.properties.erase(key)
						child.spread_properties.erase(key)
				var native: String = child.type if child.type is String else child.type.get_instance_base_type()
				if not ClassDB.is_parent_class(native,"Control") and not (ClassDB.is_parent_class(native,"Node2D") and (Length.registered(child.type,"width") or GridDefinition.component(child.type))):
					return _invalid_attribute(child,"area","Grid child requires a native 2D layout participant, Control or Gogo component")
			if child.borrowed!=null:
				var borrowed: Node = child.borrowed.get_ref()
				if not borrowed is Control and not (borrowed is Node2D and (Length.registered(borrowed.get_script(),"width") or GridDefinition.component(borrowed.get_script()))): return _invalid_attribute(child,"area","Grid borrowed child has no bounded 2D layout participant")
			var native: String = child.type if child.type is String else (child.borrowed.get_ref().get_class() if child.borrowed!=null else child.type.get_instance_base_type())
			if grid_active and ClassDB.is_parent_class(native,"Control"):
				var values := {}
				var old = grid_matches[desired.children.find(child)]
				var existing = child.borrowed.get_ref() if child.borrowed!=null else (old.node.get_ref() if old!=null else null)
				if existing!=null:
					for key in ["anchor_left","anchor_right","anchor_top","anchor_bottom","rotation","scale","pivot_offset","top_level"]: values[key] = existing.get(key) if key!="top_level" else existing.is_set_as_top_level()
				values.merge(child.properties,true)
				var message := GridDefinition.control_error(values)
				if not message.is_empty():
					var field := "area"
					for key in ["anchor_left","anchor_right","anchor_top","anchor_bottom","rotation","scale","pivot_offset","top_level"]:
						if child.properties.has(key): field = key
					return _invalid_attribute(child,field,message)
			placements.append(child.placement)
			grid_children.append(child)
		var parsed := GridDefinition.configuration(config,placements if grid_active else [])
		if parsed.has("error"):
			var origin = grid_children[parsed.item] if parsed.has("item") else desired
			var key: String = str(origin.placement.keys()[0]) if parsed.has("item") and not origin.placement.is_empty() else parsed.get("field","columns")
			return _invalid_attribute(origin,key,parsed.error)
	if VisualStyle.rect_conflict(desired.type,desired.properties.keys()):
		validation_error = desired.location("fill")+": Rect fill and background_color conflict; previous tree retained"
		return false
	for key in desired.properties:
		var native: String = desired.type if desired.type is String else desired.type.get_instance_base_type()
		if not properties.has(key) or not NativeAttributes.writable(native,desired.type,str(key),properties[key]): return _invalid_attribute(desired,str(key),"unknown, read-only or reserved native property")
		var value = desired.properties[key]
		if VisualStyle.supported(desired.type) and key in VisualStyle.SURFACE:
			var message := VisualStyle.surface_error(key,value)
			if not message.is_empty(): return _invalid_attribute(desired,str(key),message)
		if key=="align_self" and StackContract.self_registered(desired.type):
			var message := StackContract.error(key,value,"")
			if not message.is_empty(): return _invalid_attribute(desired,str(key),message)
		if VisualStyle.property(str(key)) and VisualStyle.has_api(desired.type) and not VisualStyle.supported(desired.type):
			validation_error = desired.location(str(key))+": shared visual styling is unsupported on this participant; previous tree retained"
			return false
		if key=="grow" and Length.registered(desired.type,"width") and (not typeof(value) in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or value<0):
			validation_error = desired.location(str(key))+": grow requires a finite nonnegative weight; previous tree retained"
			return false
		if key=="fill" and VisualStyle.marked(desired.type,"ESTRAGON_RECT_STYLE"):
			if not value is Color or VisualStyle.parse_color(value).has("error"):
				validation_error = desired.location(str(key))+": Rect fill requires a finite native Color; previous tree retained"
				return false
		if VisualStyle.registered(desired.type,key):
			var parsed := VisualStyle.parse_color(value)
			if parsed.has("error"):
				validation_error = desired.location(str(key))+": invalid style '"+str(key)+"': "+parsed.error+"; previous tree retained"
				return false
		if Length.registered(desired.type,key):
			var parsed := Length.parse(value,Length.domain(key,desired.type))
			if parsed.has("error"):
				validation_error = desired.location(str(key))+": invalid length '"+str(key)+"': "+parsed.error+"; previous tree retained"
				return false
		var kind: int = properties[key].type
		if kind!=TYPE_NIL and typeof(value)!=kind and not (kind==TYPE_FLOAT and typeof(value)==TYPE_INT) and not (kind==TYPE_OBJECT and value==null) and not (kind in [TYPE_STRING,TYPE_STRING_NAME] and typeof(value) in [TYPE_STRING,TYPE_STRING_NAME]): return _invalid_attribute(desired,str(key),"incompatible native value type")
		if kind==TYPE_OBJECT and value!=null:
			var expected: String = str(properties[key].get("class_name",""))
			if ClassDB.class_exists(expected) and not value.is_class(expected): return _invalid_attribute(desired,str(key),"incompatible native Object class "+expected)
	for key in desired.bindings:
		if key!="value" or desired.properties.has(key) or desired.handlers.has("value_changed") or not properties.has(key) or properties[key].type!=TYPE_BOOL or int(properties[key].usage)&PROPERTY_USAGE_READ_ONLY: return _invalid_attribute(desired,"value_changed" if desired.handlers.has("value_changed") else str(key),"invalid or conflicting controlled binding")
		var args: Array = signals.get("value_changed",{}).get("args",[])

		# 4.0 lacks signal argument type metadata. Compiler source proof and
		# native typed callback still apply; optional introspection cannot
		# reject a valid input on that engine.
		if args.size()!=1 or args[0].type not in [TYPE_NIL,TYPE_BOOL]: return false
	for key in desired.handlers:
		if not signals.has(key): return _invalid_attribute(desired,str(key),"unknown native signal")
		var message := _handler_error(desired.handlers[key],signals[key].get("args",[]).size())
		if not message.is_empty(): return _invalid_attribute(desired,str(key),message)
	var node: Node = previous.node.get_ref() if _compatible(desired,previous) else null
	if parent != null:
		var name := _effective_name(desired,previous)
		for existing in (parent._layout_children() if parent.has_method("_layout_children") else parent.get_children()):
			if str(existing.name)==name and (previous==null or existing!=previous.node.get_ref()): return _invalid_attribute(desired,"name","native sibling name conflict "+name)
	var known: Array = []
	if node != null:
		for child in previous.children:
			if child != null and child.node.get_ref()!=null: known.append(child.node.get_ref())
	var names := {}
	var matches := _matches(desired.children,previous.children if node!=null else [])
	for index in range(desired.children.size()):
		var child = desired.children[index]
		if child == null or child.borrowed != null: continue
		var old = matches[index]
		if not _preflight(child,old,null,contracts): return false
		var name := _effective_name(child,old)
		if not name.is_empty():
			if names.has(name): return _invalid_attribute(child,"name","duplicate effective sibling name "+name)
			names[name] = true
			if node != null:
				for existing in (node._layout_children() if node.has_method("_layout_children") else node.get_children()):
					if str(existing.name)==name and not known.has(existing): return false
	return true
func _free_managed(record: Mounted, rescue: Node = null) -> void:
	if record.borrowed != null: return
	for child in record.children:
		if child != null: _free_managed(child,rescue)
	var node = record.node.get_ref()
	if node == null:
		Hosts.clear_placement(record.id)
		state.get_ref().managed.erase(record.id)
		return
	for binding in record.bindings.values(): binding.disconnect_edit()
	record.bindings.clear()
	# Foreign descendants have no record. Move them outside the managed region
	# before removing its Nodes; never recursively free application-owned actors.
	var owner: Node = rescue if rescue != null else host.get_ref()
	var manager = state.get_ref()
	if manager != null and manager.records.has(node.get_instance_id()): manager.unmount(node,owner)
	for child in (node._layout_children() if node.has_method("_layout_children") else node.get_children()):
		if node.has_method("_composition_is_private") and node._composition_is_private(child): continue
		var persisted_owner: Node = child.owner
		child.get_parent().remove_child(child)
		if owner != null:
			owner.add_child(child)
			if persisted_owner != null and persisted_owner.is_ancestor_of(child): child.owner = persisted_owner
	var id: int = node.get_instance_id()
	Hosts.set_placement(node,{})
	node.free()
	if manager != null: manager.managed.erase(id)
	frees += 1
	if Profile.is_enabled(): Profile.add("nodes_freed")
func dispose(remove_nodes: bool, rescue: Node = null) -> void:
	if disposed: return
	disposed = true
	suspend()
	if remove_nodes and mounted != null: _free_managed(mounted,rescue)
	_unindex(mounted)
	mounted = null

func _disconnect_bindings(record) -> void:
	if record==null: return
	for binding in record.bindings.values(): binding.disconnect_edit()
	for child in record.children: _disconnect_bindings(child)

func _projection_tree(record, projected: Dictionary, ordering: Dictionary) -> void:
	if record == null or record.borrowed != null: return
	var parent = record.node.get_ref()
	if parent == null: return
	var nodes: Array = []
	var has_borrowed := false
	for child in record.children:
		if child == null: continue
		var node = child.node.get_ref()
		if node == null: continue
		nodes.append(weakref(node))
		if child.borrowed != null:
			projected[node.get_instance_id()] = [node,parent]
			has_borrowed = true
		else: _projection_tree(child,projected,ordering)
	if has_borrowed: ordering[parent.get_instance_id()] = nodes

func _unindex(record) -> void:
	if record == null or record.borrowed != null: return
	state.get_ref().managed.erase(record.id)
	Hosts.clear_placement(record.id)
	for child in record.children: _unindex(child)

func _notified(key: String) -> void:
	for entry in cache_observers.get(key,[]): entry.invalidate()
	schedule()

func watch(source: Object, event: StringName, entry) -> void:
	var key := str(source.get_instance_id())+":"+str(event)
	if not cache_observers.has(key): cache_observers[key] = []
	if not cache_observers[key].has(entry): cache_observers[key].append(entry)
	if subscriptions.has(key): return
	var pair := [weakref(source),event]
	subscriptions[key] = pair
	_connect_observer(key,pair)

func _connect_observer(key: String, pair: Array) -> void:
	var source = pair[0].get_ref()
	if source==null: return
	var arity := 0
	for event in source.get_signal_list():
		if event.name==pair[1]: arity = event.args.size()
	var callback := Callable(self,"_notified").bind(key)
	if arity>0: callback = callback.unbind(arity)
	notification_callbacks[key] = callback
	if Profile.is_enabled(): Profile.add("subscription_connects")
	if source.connect(pair[1],callback)!=OK: push_error("Composition observation connection failed")
