@tool
extends Resource
const Cache = preload("render_cache.gd")
const Element = preload("element.gd")
const Profile = preload("profile.tres")
## Framework-owned shared scope stack; never stored on application objects.
var scopes: Array = []
var invocations: Array = []
var owners: Array = []
var opaque := 0
var records: Dictionary = {}
var managed: Dictionary = {}
var dirty: Array = []
var pending := false
var flushing := false
func is_managed(node: Node) -> bool:
	var reference = managed.get(node.get_instance_id())
	return reference != null and reference.get_ref() == node

func enqueue(record) -> void:
	if not dirty.has(record): dirty.append(record)
	if not pending and not flushing:
		pending = true
		drain.call_deferred()
func _parent_first(a, b) -> bool:
	return a.depth() < b.depth()
func drain() -> void:
	var started: int = Time.get_ticks_usec() if Profile.is_enabled() else 0
	if Profile.is_enabled() and not dirty.is_empty(): Profile.add("drains")
	pending = false
	flushing = true
	var passes := 0
	while not dirty.is_empty():
		dirty.sort_custom(_parent_first)
		var record = dirty.pop_front()
		record.queued = false
		if Profile.is_enabled(): Profile.add("jobs")
		record._flush()
		passes += 1
		if passes > 1024:
			push_error("Composition scheduler exceeded bounded work; remove render-side mutations")
			for queued in dirty: queued.suspend()
			dirty.clear()
			break
	flushing = false
	if Profile.is_enabled() and passes>0: Profile.elapsed("drain",started)
func begin() -> void:
	scopes.append({})
func observe(source: Object, event: StringName) -> void:
	if scopes.is_empty() or opaque>0: return
	if Profile.is_enabled(): Profile.add("getter_reads")
	var key := str(source.get_instance_id())+":"+str(event)
	scopes.back()[key] = [weakref(source),event]
	if not owners.is_empty() and not invocations.is_empty(): owners.back().watch(source,event,invocations.back().entry)
func finish() -> Dictionary:
	return scopes.pop_back()
func lifecycle(host: Node, what: int) -> void:
	if Engine.is_editor_hint(): return
	var id := host.get_instance_id()
	if what == Node.NOTIFICATION_READY:
		if not records.has(id):
			var record = preload("computation.gd").new(host,self)
			records[id] = record
			record.schedule()
	elif what == Node.NOTIFICATION_ENTER_TREE and records.has(id):
		records[id].resume()
	elif what == Node.NOTIFICATION_EXIT_TREE and records.has(id):
		records[id].suspend()
	elif what == 24 and records.has(id): # Public CHILD_ORDER_CHANGED, including 4.0
		records[id].projection.ordered()
	elif what == 12 and records.has(id): # 4.0 NOTIFICATION_MOVED_IN_PARENT
		records[id].layout_host.order_moved()
		var parent = host.get_parent()
		if parent != null and records.has(parent.get_instance_id()): records[parent.get_instance_id()].projection.ordered()
	elif what == NOTIFICATION_PREDELETE and records.has(id):
		records[id].dispose(false)
		records.erase(id)
func unmount(host: Node, rescue: Node = null) -> void:
	var id := host.get_instance_id()
	if records.has(id):
		records[id].dispose(true,rescue)
		records.erase(id)

# A function is the reactive unit. Ordinary bodies run behind an observation
# boundary, while their arguments were already evaluated by native GDScript.
func call_at(site: String, callable: Callable, arguments: Array, _native_proof: Callable = Callable(), reactive_lambda: bool = false):
	if owners.is_empty() or opaque>0: return callable.callv(arguments)
	# Variant built-ins (Array/Dictionary/String) have no Object receiver.
	# They remain native operations; application Script methods have stable IDs.
	if callable.get_object_id()==0: return callable.callv(arguments)
	var owner = owners.back()
	var parent: Dictionary = invocations.back()
	var ordinal: int = parent.ordinals.get(site,0)
	parent.ordinals[site] = ordinal+1
	var bucket: Array = parent.entry.children.get(site,[])
	var entry = null
	# Keyed results follow their argument identity on reorders. Explicit keyed
	# GGX scopes below handle repeated zero-argument calls inside keyed lambdas.
	for candidate in bucket:
		if candidate.keyed and not parent.used.has(candidate) and candidate.matches(arguments):
			entry = candidate
			break
	if entry==null and ordinal<bucket.size() and not parent.used.has(bucket[ordinal]): entry = bucket[ordinal]
	if entry==null:
		entry = Cache.new()
		entry.parent = weakref(parent.entry)
		bucket.append(entry)
	parent.entry.children[site] = bucket
	parent.used[entry] = true
	var object: Object = instance_from_id(callable.get_object_id())
	var method: StringName = &"" if callable.is_custom() else callable.get_method()
	var target := callable
	var hit: bool = entry.initialized and not entry.dirty and entry.target==target and entry.matches(arguments)
	if hit:
		if Profile.is_enabled(): Profile.add("render_cache_hits")
		return entry.result
	if Profile.is_enabled(): Profile.add("render_cache_misses")
	entry.target = target
	entry.arguments.clear()
	for value in arguments: entry.arguments.append(Cache.argument(value))
	var reactive := reactive_lambda or _reactive(object,method)
	entry.dirty = false
	entry.initialized = true
	var argument_reads := {}
	# Observable arguments invalidate independently of the body observation
	# boundary. CORE02 can supply real upward change signals without revisions.
	for value in arguments:
		if typeof(value)!=TYPE_OBJECT or not is_instance_valid(value): continue
		for signal_info in value.get_signal_list():
			var event: StringName = signal_info.name
			if event in [&"changed",&"tree_exiting"] or str(event).ends_with("_changed"):
				argument_reads[str(value.get_instance_id())+":"+str(event)] = [weakref(value),event]
				owner.watch(value,event,entry)
	var frame := {"entry":entry,"ordinals":{},"used":{}}
	invocations.append(frame)
	begin()
	if not reactive: opaque += 1
	var result = callable.callv(arguments)
	if not reactive: opaque -= 1
	entry.reads = finish()
	entry.reads.merge(argument_reads,true)
	invocations.pop_back()
	_prune(frame)
	entry.result = result
	entry.keyed = result is Element and result.keyed
	return result
func _reactive(object, method: StringName) -> bool:
	if method==&"build_view": return true
	if not is_instance_valid(object): return false
	var script = object if object is Script else object.get_script()
	while script is Script:
		if method in script.get_script_constant_map().get("_GOGO_RENDER_FUNCTIONS",[]): return true
		script = script.get_base_script()
	return false
func _prune(frame: Dictionary) -> void:
	for site in frame.entry.children.keys():
		var retained: Array = []
		for entry in frame.entry.children[site]:
			if frame.used.has(entry): retained.append(entry)
		if retained.is_empty(): frame.entry.children.erase(site)
		else: frame.entry.children[site] = retained
func enter_render(owner) -> void:
	owners.append(owner)
	invocations.append({"entry":owner.render_cache,"ordinals":{},"used":{}})
func leave_render() -> Dictionary:
	var frame: Dictionary = invocations.pop_back()
	_prune(frame)
	var owner = owners.pop_back()
	var reads := {}
	owner.cache_observers.clear()
	owner.render_cache.collect(reads,owner.cache_observers)
	return reads
func in_slot(site: String, key, body: Callable):
	if owners.is_empty() or opaque>0: return body.call(key)
	var parent: Dictionary = invocations.back()
	var identity := site+":"+str(typeof(key))+":"+str(key)
	if key==null:
		var ordinal: int = parent.ordinals.get(identity,0)
		parent.ordinals[identity] = ordinal+1
		identity += ":"+str(ordinal)
	var bucket: Array = parent.entry.children.get(identity,[])
	var group = bucket[0] if not bucket.is_empty() else Cache.new()
	group.parent = weakref(parent.entry)
	group.dirty = false
	parent.entry.children[identity] = [group]
	parent.used[group] = true
	var frame := {"entry":group,"ordinals":{},"used":{}}
	invocations.append(frame)
	var result = body.call(key)
	invocations.pop_back()
	_prune(frame)
	return result

func method_at(site: String, receiver, method: StringName, arguments: Array, native_call: Callable, _native_proof: Callable = Callable(), reactive_lambda: bool = false):
	if typeof(receiver)==TYPE_OBJECT:
		if not is_instance_valid(receiver): return null
		if receiver.has_method(method): return call_at(site,Callable(receiver,method),arguments)
		var value = receiver.get(method)
		if value is Callable: return call_at(site,value,arguments,Callable(),reactive_lambda)
		return null
	# Native Variant methods have no script body/dependency boundary. This also
	# preserves normal Array callback traversal without a second evaluator.
	return native_call.call(receiver,arguments)
