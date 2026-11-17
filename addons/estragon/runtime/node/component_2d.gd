@icon("internal/component_2d_icon.tres")
@tool
class_name EstragonComponent2D
extends Node2D
## Native C1 participant. Needs a contiguous same-dimensional chain to an entry.
signal layout_applied(size: Vector2)
signal _layout_children_changed
const Coordinator = preload("internal/coordinator.gd")
const ESTRAGON_LENGTHS := true
const ESTRAGON_MINIMUMS_2D := true
const ESTRAGON_GAPS_2D := true
const ESTRAGON_SCROLL_2D := true
const Scroll = preload("internal/scroll_2d.gd")
var _scroll
@export var horizontal_scroll: bool = false:
	set(value):
		if horizontal_scroll==value: return
		horizontal_scroll = value
		_scroll_changed()
@export var vertical_scroll: bool = false:
	set(value):
		if vertical_scroll==value: return
		vertical_scroll = value
		_scroll_changed()
@export var scroll_offset := Vector2.ZERO:
	set(value):
		if not Scroll.valid_offset(value):
			push_error("Estragon scrolling scroll_offset requires a finite nonnegative Vector2")
			return
		scroll_offset = value
		if _scroll!=null: _scroll.offset_changed()
		elif not horizontal_scroll and not vertical_scroll: scroll_offset = Vector2.ZERO
var scroll_range: Vector2:
	get: return _scroll_range
	set(_value): push_error("Estragon scrolling scroll_range is read-only")
var content_extent: Vector2:
	get: return _content_extent
	set(_value): push_error("Estragon scrolling content_extent is read-only")
var _scroll_range := Vector2.ZERO
var _content_extent := Vector2.ZERO

var row_gap: Variant = "auto":
	set(value):
		if is_same(row_gap,value) or not lengths.assign("row_gap",value): return
		row_gap = value
		_changed()
var column_gap: Variant = "auto":
	set(value):
		if is_same(column_gap,value) or not lengths.assign("column_gap",value): return
		column_gap = value
		_changed()
const ESTRAGON_ALIGN_SELF_2D := true
const AlignmentContract = preload("internal/stack_contract.gd")
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
var padding: Variant = 0.0:
	set(value):
		if is_same(padding,value) or not lengths.assign("padding",value,Length.domain("padding",get_script())): return
		padding = value
		_changed()
var padding_top: Variant = "auto":
	set(value):
		if is_same(padding_top,value) or not lengths.assign("padding_top",value): return
		padding_top = value
		_changed()
var padding_right: Variant = "auto":
	set(value):
		if is_same(padding_right,value) or not lengths.assign("padding_right",value): return
		padding_right = value
		_changed()
var padding_bottom: Variant = "auto":
	set(value):
		if is_same(padding_bottom,value) or not lengths.assign("padding_bottom",value): return
		padding_bottom = value
		_changed()
var padding_left: Variant = "auto":
	set(value):
		if is_same(padding_left,value) or not lengths.assign("padding_left",value): return
		padding_left = value
		_changed()
var max_width: Variant = "auto":
	set(value):
		if is_same(max_width,value) or not lengths.assign("max_width",value): return
		max_width = value
		_changed()
var max_height: Variant = "auto":
	set(value):
		if is_same(max_height,value) or not lengths.assign("max_height",value): return
		max_height = value
		_changed()
var min_width: Variant = 0.0:
	set(value):
		if is_same(min_width,value) or not lengths.assign("min_width",value): return
		min_width = value
		_changed()
var min_height: Variant = 0.0:
	set(value):
		if is_same(min_height,value) or not lengths.assign("min_height",value): return
		min_height = value
		_changed()
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
@export_enum("auto", "start", "center", "end", "stretch") var align_self: String = "auto":
	set(value):
		if value==align_self: return
		var message := AlignmentContract.error("align_self",value,"")
		if not message.is_empty():
			push_error("Estragon alignment: "+message)
			return
		align_self = value
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
	var properties := Length.properties(["width","height","min_width","min_height","max_width","max_height","x","y","gap","padding","padding_top","padding_right","padding_bottom","padding_left","margin","margin_top","margin_right","margin_bottom","margin_left"])
	properties.append_array(Length.properties(["row_gap","column_gap"]))
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

func _default_padding() -> Vector4:
	return Vector4.ZERO

func _padding_insets() -> Vector4:
	layout.model.prepare(layout.model.parent_reference,layout.model.viewport_size)
	return layout.model.padding

func get_content_rect() -> Rect2:
	var insets: Vector4 = layout.model.padding+layout.model.border
	return Rect2(Vector2(insets.x,insets.y),Vector2(maxf(0,layout_size.x-insets.x-insets.z),maxf(0,layout_size.y-insets.y-insets.w)))

func _layout_options() -> Dictionary:
	var natural := _measure_native()
	return {"axis":_layout_axis(),"fill":Vector3.ZERO,"intrinsic":Vector3(natural.x,natural.y,0),"scroll_axes":Vector2(1 if horizontal_scroll else 0,1 if vertical_scroll else 0)}

func _is_layout_entry() -> bool:
	return false

func _scroll_changed() -> void:
	if _scroll==null and (horizontal_scroll or vertical_scroll): _scroll = Scroll.new(self)
	_changed()
	if _scroll!=null and is_inside_tree(): _scroll.start()
func _composition_child_parent() -> Node:
	return _scroll.child_parent() if _scroll!=null and is_instance_valid(_scroll.child_parent()) else self
func _composition_is_private(child: Node) -> bool:
	return _scroll!=null and _scroll.is_private(child)
func _layout_children() -> Array:
	return _scroll.children() if _scroll!=null else get_children()
func get_layout_children() -> Array:
	return _layout_children()
func get_layout_child(child_name: StringName) -> Node:
	for child in _layout_children():
		if child.name==child_name: return child
	return null
func _content_pointer_allowed(point: Vector2) -> bool:
	return _scroll==null or _scroll.pointer_allowed(point)
func _input(event: InputEvent) -> void:
	if _scroll!=null: _scroll.input(event)

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
	if _scroll==null and (horizontal_scroll or vertical_scroll or get_node_or_null("_EstragonViewport")!=null): _scroll = Scroll.new(self)
	if _scroll!=null: _scroll.start()
	layout.changed()
	layout.start()

func _exit_tree() -> void:
	if _scroll!=null: _scroll.stop()
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
	_content_extent = layout.model.content_extent()
	# Explicit invalidation also restores a native position edited externally.
	if layout.parent_coordinator() != null: layout._place(layout.model.offset)
	if _scroll!=null: _scroll.refresh()
	layout_applied.emit(_layout_size)

func _margin_insets() -> Vector4:
	layout.model.prepare(layout.model.parent_reference,layout.model.viewport_size)
	return layout.model.margin

func _queue_style_redraw() -> void:
	_visual_style.redraw_count += 1
	queue_redraw()
func _paint_visual_style() -> void:
	_visual_style.paint(self,layout_size,layout.model.border,get_background_color())
func get_background_color() -> Color:
	return _visual_style.colors.background_color
func get_visual_style_stats() -> Dictionary:
	return {"parse":_visual_style.parse_count,"draw":_visual_style.draw_count,"commands":_visual_style.command_count,"redraw":_visual_style.redraw_count}

func _style_supported() -> bool:
	if VisualStyle.supported(get_script()): return true
	push_error("Estragon style: shared visual styling is unsupported on this participant")
	return false
