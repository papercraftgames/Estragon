@tool
extends RefCounted
const Profile = preload("profile.tres")
## Desired typed linkage, owned only by external description/mount records.
var root: WeakRef
var source: WeakRef
var field: StringName
var route: String
var read: Callable
var write: Callable
var value: Variant
var valid := false
var node: WeakRef
var computation: WeakRef
var connected := false
var writing := false
func _init(owner: Object, reader: Callable, property: StringName, writer: Callable, identity: String) -> void:
	route = identity
	root = weakref(owner)
	read = reader
	write = writer
	field = property
	var endpoint = current()
	if endpoint == null: return
	source = weakref(endpoint)
	value = endpoint.get(field)
	valid = typeof(value)==TYPE_BOOL and endpoint.has_signal(str(field)+"_changed")
func current():
	var owner = root.get_ref()
	var endpoint = read.call(owner) if is_instance_valid(owner) else null
	return endpoint if is_instance_valid(endpoint) else null
func same(other) -> bool:
	return other!=null and valid and other.valid and source.get_ref()==other.source.get_ref() and root.get_ref()==other.root.get_ref() and field==other.field and route==other.route
func attach(target: Node, scope) -> void:
	node = weakref(target)
	computation = weakref(scope)
	if not connected:
		connected = target.connect("value_changed",edit)==OK
		if connected and Profile.is_enabled(): Profile.add("binding_connects")
		if connected and not target.tree_exiting.is_connected(_target_exit): target.tree_exiting.connect(_target_exit)
func disconnect_edit() -> void:
	var target = node.get_ref() if node!=null else null
	if target!=null and target.is_connected("value_changed",edit): target.disconnect("value_changed",edit)
	if connected and Profile.is_enabled(): Profile.add("binding_disconnects")
	if target!=null and target.tree_exiting.is_connected(_target_exit): target.tree_exiting.disconnect(_target_exit)
	connected = false
func _target_exit() -> void:
	disconnect_edit()
	var scope = computation.get_ref() if computation!=null else null
	if scope!=null and scope.active and not scope.disposed: scope.schedule()
func edit(next: bool) -> void:
	var scope = computation.get_ref() if computation!=null else null
	var target = node.get_ref() if node!=null else null
	var endpoint = source.get_ref() if source!=null else null
	if not connected or writing or scope==null or scope.disposed or not scope.active or target==null or not target.is_inside_tree() or target.is_queued_for_deletion() or endpoint==null or current()!=endpoint: return
	if is_same(endpoint.get(field),next): return
	writing = true
	write.call(endpoint,next)
	writing = false
	# Reentrant model callbacks can restore the old value; commit must still
	# restore a control whose local user value diverged from its snapshot.
	scope.schedule()
