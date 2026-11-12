@tool
class_name EstragonNative2D
extends "component_2d.gd"
## C1 bounded native visual participant; allocation never stretches geometry.
const Bounds = preload("internal/native_bounds.gd")
@export var observe_native: bool = false:
	set(value):
		observe_native = value
		if bounds != null: bounds.invalidate()
var bounds = Bounds.new(self, 2)

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
	return Vector3(width if width >= 0 else natural.x, height if height >= 0 else natural.y, 0.0)

func apply_layout_position(offset: Vector3) -> void:
	var value: Vector3 = offset - bounds.origin
	position = Vector2(value.x, value.y)

func apply_layout_size(size: Vector3) -> void:
	_layout_size = Vector2(size.x, size.y)
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)

func get_native_bounds() -> Rect2:
	return Rect2(Vector2(bounds.origin.x, bounds.origin.y), Vector2(bounds.extent.x, bounds.extent.y))

func get_native_bounds_status() -> Error:
	return bounds.status
