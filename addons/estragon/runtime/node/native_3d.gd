@tool
class_name EstragonNative3D
extends "component_3d.gd"
## C1 bounded native visual participant; allocation never stretches geometry.
const Bounds = preload("internal/native_bounds.gd")
@export var observe_native: bool = false:
	set(value):
		observe_native = value
		if bounds != null: bounds.invalidate()
var bounds = Bounds.new(self, 3)

func _enter_tree() -> void:
	bounds.start()
	super._enter_tree()

func _exit_tree() -> void:
	bounds.stop()
	super._exit_tree()

func invalidate_native() -> void:
	bounds.invalidate()

func requested_extent() -> Vector3:
	var natural: Vector3 = bounds.extent if bounds != null else Vector3.ZERO
	return Vector3(width if width >= 0 else natural.x, height if height >= 0 else natural.y, depth if depth >= 0 else natural.z)

func apply_layout_position(offset: Vector3) -> void:
	var value: Vector3 = offset - bounds.origin
	position = value

func apply_layout_size(size: Vector3) -> void:
	_layout_size = size
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)

func get_native_bounds() -> AABB:
	return AABB(bounds.origin, bounds.extent)

func get_native_bounds_status() -> Error:
	return bounds.status
