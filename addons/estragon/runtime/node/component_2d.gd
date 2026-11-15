@tool
class_name EstragonComponent2D
extends Node2D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector2)
const Coordinator = preload("internal/coordinator.gd")
const ESTRAGON_LENGTHS := true
const VisualStyle = preload("internal/visual_style_2d.gd")
var _visual_style = VisualStyle.new()
const Length = preload("internal/length.gd")
var lengths = Length.new()
const ESTRAGON_VISUAL_STYLE := true
var background_color: Variant = "transparent":
	set(value):
		if is_same(background_color,value) or not _style_supported() or not _visual_style.assign("background_color",value): return
		background_color = value
		_queue_style_redraw()
var border_color: Variant = "transparent":
	set(value):
		if is_same(border_color,value) or not _style_supported() or not _visual_style.assign("border_color",value): return
		border_color = value
		_queue_style_redraw()
var border_width: Variant = 0.0:
	set(value):
		if is_same(border_width,value) or not _style_supported() or not lengths.assign("border_width",value): return
		border_width = value
		_changed()
		_queue_style_redraw()
var border_top_width: Variant = "auto":
	set(value):
		if is_same(border_top_width,value) or not _style_supported() or not lengths.assign("border_top_width",value): return
		border_top_width = value
		_changed()
		_queue_style_redraw()
var border_right_width: Variant = "auto":
	set(value):
		if is_same(border_right_width,value) or not _style_supported() or not lengths.assign("border_right_width",value): return
		border_right_width = value
		_changed()
		_queue_style_redraw()
var border_bottom_width: Variant = "auto":
	set(value):
		if is_same(border_bottom_width,value) or not _style_supported() or not lengths.assign("border_bottom_width",value): return
		border_bottom_width = value
		_changed()
		_queue_style_redraw()
var border_left_width: Variant = "auto":
	set(value):
		if is_same(border_left_width,value) or not _style_supported() or not lengths.assign("border_left_width",value): return
		border_left_width = value
		_changed()
		_queue_style_redraw()
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
@export var grow: float = 0.0:
	set(value):
		if not is_finite(value) or value<0 or value==grow: return
		grow = value
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
	var properties := Length.properties(["width","height","x","y","gap","margin","margin_top","margin_right","margin_bottom","margin_left"])
	if VisualStyle.supported(get_script()): properties.append_array(Length.properties(["border_width","border_top_width","border_right_width","border_bottom_width","border_left_width","background_color","border_color"]))
	return properties
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
	# Native draw signal precedes script _draw, so derived Box foreground hooks
	# cannot accidentally bypass the shared style. Legacy widget painters
	# explicitly opt out of S01 styles and remain untouched until S02.
	if VisualStyle.supported(get_script()) and not draw.is_connected(_paint_visual_style): draw.connect(_paint_visual_style)
	layout.changed()
	layout.start()

func _exit_tree() -> void:
	if draw.is_connected(_paint_visual_style): draw.disconnect(_paint_visual_style)
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
	var next := Vector2(size.x,size.y)
	if next!=_layout_size: _queue_style_redraw()
	_layout_size = next
	# Explicit invalidation also restores a native position edited externally.
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	layout_applied.emit(_layout_size)

func _margin_insets() -> Vector4:
	layout.model.prepare(layout.model.parent_reference,layout.model.viewport_size)
	return layout.model.margin

func _queue_style_redraw() -> void:
	_visual_style.redraw_count += 1
	queue_redraw()
func _paint_visual_style() -> void:
	_visual_style.paint(self,layout_size,layout.model.border)
func get_visual_style_stats() -> Dictionary:
	return {"parse":_visual_style.parse_count,"draw":_visual_style.draw_count,"commands":_visual_style.command_count,"redraw":_visual_style.redraw_count}

func _style_supported() -> bool:
	if VisualStyle.supported(get_script()): return true
	push_error("Estragon style: Text/Rect/Button painters retain their local API until S02")
	return false
