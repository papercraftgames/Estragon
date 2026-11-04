@tool
extends RefCounted
## Shared B3/C1 snapshot/subscription bridge. Geometry stays native-owned; no polling.
var origin := Vector3.ZERO
var extent := Vector3.ZERO
var snapshots: int = 0
var notifications: int = 0
var status: Error = ERR_UNCONFIGURED
var _host: WeakRef
var _dimension: int
var _active: bool = false
var _queued: bool = false
var _source: Object
var _signal: StringName

func _init(host: Node, dimension: int) -> void:
	_host = weakref(host)
	_dimension = dimension

func start() -> void:
	_active = true
	var host: Node = _host.get_ref()
	host.child_entered_tree.connect(_child_changed)
	host.child_exiting_tree.connect(_child_changed)
	invalidate()

func stop() -> void:
	_active = false
	_disconnect()
	var host: Node = _host.get_ref()
	if host.child_entered_tree.is_connected(_child_changed): host.child_entered_tree.disconnect(_child_changed)
	if host.child_exiting_tree.is_connected(_child_changed): host.child_exiting_tree.disconnect(_child_changed)

func _child_changed(_child: Node) -> void:
	invalidate()

func _disconnect() -> void:
	if is_instance_valid(_source) and _source.is_connected(_signal, _native_changed):
		_source.disconnect(_signal, _native_changed)
	_source = null

func _native_changed() -> void:
	notifications += 1
	invalidate()

func invalidate() -> void:
	if not _active or _queued: return
	_queued = true
	call_deferred("_refresh")

func _refresh() -> void:
	_queued = false
	if not _active: return
	_disconnect()
	snapshots += 1
	origin = Vector3.ZERO
	extent = Vector3.ZERO
	var host = _host.get_ref()
	status = ERR_INVALID_PARAMETER
	if host == null or host.get_child_count() != 1:
		_publish(host)
		return
	var child: Node = host.get_child(0)
	var points: Array[Vector3] = []
	if _dimension == 2 and child is Polygon2D:
		var basis: Transform2D = host.transform
		basis.origin = Vector2.ZERO
		var transform: Transform2D = basis * child.transform
		for point in child.polygon:
			var transformed: Vector2 = transform * (point + child.offset)
			points.append(Vector3(transformed.x, transformed.y, 0))
		if host.observe_native:
			_source = child
			_signal = &"item_rect_changed"
	elif _dimension == 3 and child is MeshInstance3D and child.mesh != null:
		var box: AABB = child.mesh.get_aabb()
		var transform: Transform3D = Transform3D(host.basis, Vector3.ZERO) * child.transform
		for index in range(8): points.append(transform * box.get_endpoint(index))
		if host.observe_native:
			_source = child.mesh
			_signal = &"changed"
	if points.is_empty():
		_publish(host)
		return
	var minimum: Vector3 = points[0]
	var maximum: Vector3 = minimum
	for point in points:
		if not is_finite(point.x) or not is_finite(point.y) or not is_finite(point.z):
			_publish(host)
			return
		minimum = Vector3(minf(minimum.x,point.x),minf(minimum.y,point.y),minf(minimum.z,point.z))
		maximum = Vector3(maxf(maximum.x,point.x),maxf(maximum.y,point.y),maxf(maximum.z,point.z))
	origin = minimum
	extent = maximum - minimum
	status = OK
	if _source != null: _source.connect(_signal, _native_changed)
	_publish(host)

func _publish(host: Node) -> void:
	if host != null:
		host.layout.changed()
		# A changed minimum with identical size still requires placement.
		host.layout.model.invalidate()
