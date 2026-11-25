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
var observable := false
var kind := TYPE_BOOL
var node: WeakRef
var computation: WeakRef
var connected := false
var writing := false
func _init(owner: Variant, reader: Callable, property: StringName, writer: Callable, identity: String, snapshot_value: Variant, value_type: int = TYPE_BOOL) -> void:
	kind = value_type
	value = snapshot_value
	valid = kind in [TYPE_BOOL,TYPE_STRING,TYPE_FLOAT,TYPE_INT] and typeof(value)==kind
	if not owner is Object or not is_instance_valid(owner): return
	route = identity
	root = weakref(owner)
	read = reader
	write = writer
	field = property
	var endpoint = current()
	if endpoint == null: return
	source = weakref(endpoint)
	if not valid: return
	observable = declared(endpoint.get_script(),str(field),kind)
	if observable:
		valid = endpoint.has_signal(str(field)+"_changed")
static func declared(script, property: String, value_type: int = TYPE_BOOL) -> bool:
	var type_name: String = {TYPE_BOOL:"bool",TYPE_STRING:"String",TYPE_FLOAT:"float",TYPE_INT:"int"}.get(value_type,"")
	if type_name.is_empty(): return false
	while script is Script:
		for name in script.get_script_constant_map():
			var contract = script.get_script_constant_map()[name]
			if str(name).begins_with("_GOGO_BINDABLE_PROPERTIES_") and contract is Dictionary and contract.get(property,"")==type_name: return true
		script = script.get_base_script()
	return false
func current():
	var owner = root.get_ref() if root!=null else null
	var endpoint = read.call(owner) if is_instance_valid(owner) else null
	return endpoint if endpoint is Object and is_instance_valid(endpoint) else null
func same(other) -> bool:
	return other!=null and valid and other.valid and kind==other.kind and source.get_ref()==other.source.get_ref() and root.get_ref()==other.root.get_ref() and field==other.field and route==other.route
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
func edit(_previous: Variant, next: Variant) -> void:
	if typeof(next)!=kind: return
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
func project(target: Node, next: Variant) -> void:
	writing = true
	target.set("value",next)
	writing = false

# A desired linkage is reusable data; each native mount owns its mutable edit
# connection. Copy without evaluating getters outside the render read scope.
func snapshot():
	var result = get_script().new(null,Callable(),&"",Callable(),"",null)
	result.root = root
	result.source = source
	result.field = field
	result.route = route
	result.read = read
	result.write = write
	result.value = value
	result.valid = valid
	result.observable = observable
	result.kind = kind
	return result
