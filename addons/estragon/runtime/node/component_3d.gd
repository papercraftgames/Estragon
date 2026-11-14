@tool
class_name EstragonComponent3D
extends Node3D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector3)
const Coordinator = preload("internal/coordinator.gd")
const ESTRAGON_LENGTHS := true
const Length = preload("internal/length.gd")
var lengths = Length.new()
var width: Variant = "auto":
	set(value):
		if is_same(width,value) or not lengths.assign("width",value): return
		width = value
		_changed()
var height: Variant = "auto":
	set(value):
		if is_same(height,value) or not lengths.assign("height",value): return
		height = value
		_changed()
var depth: Variant = "auto":
	set(value):
		if is_same(depth,value) or not lengths.assign("depth",value): return
		depth = value
		_changed()
var x: Variant = 0.0:
	set(value):
		if is_same(x,value) or not lengths.assign("x",value): return
		x = value
		_changed()
var y: Variant = 0.0:
	set(value):
		if is_same(y,value) or not lengths.assign("y",value): return
		y = value
		_changed()
var z: Variant = 0.0:
	set(value):
		if is_same(z,value) or not lengths.assign("z",value): return
		z = value
		_changed()
var gap: Variant = 0.0:
	set(value):
		if is_same(gap,value) or not lengths.assign("gap",value): return
		gap = value
		_changed()
@export var flex: float = 0.0:
	set(value):
		if not is_finite(value) or value<0 or value==flex: return
		flex = value
		_changed()
@export_enum("Natural", "Stretch") var stretch: int = 0:
	set(value):
		if value not in [0,1] or value==stretch: return
		stretch = value
		_changed()
@export var pixels_per_unit: float = 100.0:
	set(value):
		if not is_finite(value) or value<=0 or pixels_per_unit==value: return
		pixels_per_unit = value
		_changed()
@export var center: bool = false:
	set(value):
		if center == value: return
		center = value
		_changed()
var layout_size: Vector3:
	get: return _layout_size
var _layout_size := Vector3.ZERO
var layout = Coordinator.new(self, 3, Coordinator.Mode.ENTRY if _is_layout_entry() else Coordinator.Mode.PARTICIPANT)
func _get_property_list() -> Array[Dictionary]:
	return Length.properties(["width","height","depth","x","y","z","gap"])
static func valid_length(value) -> bool:
	return Length.valid(value,"extent")

func set_extent(value: Vector3) -> Error:
	for axis in range(3):
		if not valid_length(value[axis]): return ERR_INVALID_PARAMETER
	width = value[0]
	height = value[1]
	depth = value[2]
	return OK

func requested_extent() -> Vector3:
	return layout.model.requested

func _measure_native() -> Vector3:
	return Vector3.ZERO

func _layout_options() -> Dictionary:
	return {"axis":0,"fill":Vector3.ZERO,"intrinsic":_measure_native()}

func _is_layout_entry() -> bool:
	return false

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
