@tool
class_name EstragonComponent2D
extends Node2D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector2)
const Coordinator = preload("internal/coordinator.gd")
@export var width: float = -1.0:
	set(value):
		if not valid_length(value) or width == value: return
		width = value
		_changed()
@export var height: float = -1.0:
	set(value):
		if not valid_length(value) or height == value: return
		height = value
		_changed()
@export var fill_width: bool = false:
	set(value):
		if fill_width == value: return
		fill_width = value
		_changed()
@export var fill_height: bool = false:
	set(value):
		if fill_height == value: return
		fill_height = value
		_changed()
@export var gap: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0 or value == gap: return
		gap = value
		_changed()
@export var center: bool = false:
	set(value):
		if center == value: return
		center = value
		_changed()
var layout_size: Vector2:
	get: return _layout_size
var _layout_size := Vector2.ZERO
# Internal bridge, deliberately not the public authoring API.
var layout = Coordinator.new(self, 2, Coordinator.Mode.ENTRY if _is_layout_entry() else Coordinator.Mode.PARTICIPANT)

static func valid_length(value: float) -> bool:
	return is_finite(value) and (value >= 0 or value == -1)

func set_extent(value: Vector2) -> Error:
	for axis in range(2):
		if not valid_length(value[axis]): return ERR_INVALID_PARAMETER
	width = value[0]
	height = value[1]
	return OK

func requested_extent() -> Vector3:
	return Vector3(width, height, 0.0)

func _layout_axis() -> int:
	return 0

func _measure_native() -> Vector2:
	return Vector2.ZERO

func _layout_options() -> Dictionary:
	var natural := _measure_native()
	return {"axis":_layout_axis(),"fill":Vector3(1 if fill_width else 0,1 if fill_height else 0,0),"intrinsic":Vector3(natural.x,natural.y,0)}

func _is_layout_entry() -> bool:
	return false

func _layout_viewport_scale() -> float:
	return 0.0

func _changed() -> void:
	if layout != null: layout.changed()

func _notification(what: int) -> void:
	# 4.0 MOVED_IN_PARENT; newer engines use child_order_changed.
	if what == 12 and layout != null: layout.order_moved()

func _enter_tree() -> void:
	layout.changed()
	layout.start()

func _exit_tree() -> void:
	layout.stop()

func invalidate_layout() -> void:
	layout.model.invalidate()

func _get_layout_coordinator():
	return layout

func get_layout_root() -> Node:
	return layout.root_host()

func get_layout_stats() -> Dictionary:
	return {"measure": layout.model.measure_count, "arrange": layout.model.arrange_count, "flush": layout.flush_count, "active": get_layout_root() != null}

func apply_layout_position(offset: Vector3) -> void:
	position = Vector2(offset.x, offset.y)

func apply_layout_size(size: Vector3) -> void:
	_layout_size = Vector2(size.x, size.y)
	# Explicit invalidation also restores a native position edited externally.
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)
