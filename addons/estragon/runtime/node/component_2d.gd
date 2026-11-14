@tool
class_name EstragonComponent2D
extends Node2D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector2)
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
var gap: Variant = 0.0:
	set(value):
		if is_same(gap,value) or not lengths.assign("gap",value): return
		gap = value
		_changed()
var margin: Variant = 0.0:
	set(value):
		if is_same(margin,value) or not lengths.assign("margin",value): return
		margin = value
		_changed()
var margin_top: Variant = "auto":
	set(value):
		if is_same(margin_top,value) or not lengths.assign("margin_top",value): return
		margin_top = value
		_changed()
var margin_right: Variant = "auto":
	set(value):
		if is_same(margin_right,value) or not lengths.assign("margin_right",value): return
		margin_right = value
		_changed()
var margin_bottom: Variant = "auto":
	set(value):
		if is_same(margin_bottom,value) or not lengths.assign("margin_bottom",value): return
		margin_bottom = value
		_changed()
var margin_left: Variant = "auto":
	set(value):
		if is_same(margin_left,value) or not lengths.assign("margin_left",value): return
		margin_left = value
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
@export var center: bool = false:
	set(value):
		if center == value: return
		center = value
		_changed()
var layout_size: Vector2:
	get: return _layout_size
var _layout_size := Vector2.ZERO
var layout = Coordinator.new(self, 2, Coordinator.Mode.ENTRY if _is_layout_entry() else Coordinator.Mode.PARTICIPANT)
func _get_property_list() -> Array[Dictionary]:
	return Length.properties(["width","height","x","y","gap","margin","margin_top","margin_right","margin_bottom","margin_left"])
static func valid_length(value) -> bool:
	return Length.valid(value,"extent")

func set_extent(value: Vector2) -> Error:
	for axis in range(2):
		if not valid_length(value[axis]): return ERR_INVALID_PARAMETER
	width = value[0]
	height = value[1]
	return OK

func requested_extent() -> Vector3:
	return layout.model.requested

func _layout_axis() -> int:
	return 0

func _measure_native() -> Vector2:
	return Vector2.ZERO

func _layout_options() -> Dictionary:
	var natural := _measure_native()
	return {"axis":_layout_axis(),"fill":Vector3.ZERO,"intrinsic":Vector3(natural.x,natural.y,0)}

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
	position = Vector2(offset.x, offset.y)

func apply_layout_size(size: Vector3) -> void:
	_layout_size = Vector2(size.x, size.y)
	# Explicit invalidation also restores a native position edited externally.
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)

func _margin_insets() -> Vector4:
	layout.model.prepare(layout.model.parent_reference,layout.model.viewport_size)
	return layout.model.margin
