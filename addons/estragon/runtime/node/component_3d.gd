@tool
class_name EstragonComponent3D
extends Node3D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector3)
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
@export var depth: float = -1.0:
	set(value):
		if not valid_length(value) or depth == value: return
		depth = value
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
var layout_size: Vector3:
	get: return _layout_size
var _layout_size := Vector3.ZERO
# Internal bridge, deliberately not the public authoring API.
var layout = Coordinator.new(self, 3, Coordinator.Mode.ENTRY if _is_layout_entry() else Coordinator.Mode.PARTICIPANT)

static func valid_length(value: float) -> bool:
	return is_finite(value) and (value >= 0 or value == -1)

func set_extent(value: Vector3) -> Error:
	for axis in range(3):
		if not valid_length(value[axis]): return ERR_INVALID_PARAMETER
	width = value[0]
	height = value[1]
	depth = value[2]
	return OK

func requested_extent() -> Vector3:
	return Vector3(width, height, depth)

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
	position = offset

func apply_layout_size(size: Vector3) -> void:
	_layout_size = size
	# Explicit invalidation also restores a native position edited externally.
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)
