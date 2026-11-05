extends Node
## One target-owned deferred binding. Sources/host are weak, never captured closures.
@export var host_path: NodePath
@export var read_method: StringName
@export var sources_method: StringName
@export var property: StringName
var _host: WeakRef
var _connections: Array = []
var _queued := false
var _active := false
var _has_value := false
var _value: Variant

static func attach(target: Node, host: Node, read: StringName, sources: StringName, member: StringName, initial: Array) -> Node:
	var binding = load("res://addons/estragon/runtime/node/internal/property_binding.gd").new()
	binding._host = weakref(host)
	binding.read_method = read
	binding.sources_method = sources
	binding.property = member
	if not initial.is_empty():
		binding._has_value = true
		binding._value = initial[0]
	target.add_child(binding)
	return binding

func _enter_tree() -> void:
	var host = _host.get_ref() if _host != null else get_node_or_null(host_path)
	if host == null: return
	_host = weakref(host)
	host_path = get_path_to(host)
	if not host.tree_exiting.is_connected(_suspend): host.tree_exiting.connect(_suspend)
	if not host.tree_entered.is_connected(_resume): host.tree_entered.connect(_resume)
	_resume()
func _exit_tree() -> void:
	_suspend()
	var host = _host.get_ref() if _host != null else null
	if host != null:
		if host.tree_exiting.is_connected(_suspend): host.tree_exiting.disconnect(_suspend)
		if host.tree_entered.is_connected(_resume): host.tree_entered.disconnect(_resume)
	_has_value = false
	_value = null
func _resume() -> void:
	var host = _host.get_ref() if _host != null else null
	if not is_inside_tree() or host == null or not host.is_inside_tree(): return
	_active = true
	_rewire()
	_update()
func _suspend() -> void:
	_active = false
	_disconnect()
func _disconnect() -> void:
	for connection in _connections:
		var source = connection[0].get_ref()
		if source != null and source.is_connected(connection[1],_changed): source.disconnect(connection[1],_changed)
	_connections.clear()
func _rewire() -> void:
	_disconnect()
	var host = _host.get_ref() if _host != null else null
	if host == null: return
	var seen := {}
	for event in host.call(sources_method):
		var source: Object = event.get_object()
		var name: StringName = event.get_name()
		var key := str(source.get_instance_id())+":"+str(name)
		if seen.has(key): continue
		seen[key] = true
		if source.connect(name,_changed) != OK:
			push_error("Gogo reactive subscription failed: "+str(name))
			continue
		_connections.append([weakref(source),name])
func _changed(_previous: Variant, _current: Variant) -> void:
	if not _active: return
	_rewire()
	if not _queued:
		_queued = true
		_flush.call_deferred()
func _flush() -> void:
	_queued = false
	if _active: _update()
func _update() -> void:
	var host = _host.get_ref() if _host != null else null
	if host == null: return
	var result: Array = host.call(read_method)
	if result.is_empty(): return # Null intermediate: hold native default/last value.
	if _has_value and is_same(_value,result[0]): return
	_has_value = true
	_value = result[0]
	get_parent().set(property,_value)
