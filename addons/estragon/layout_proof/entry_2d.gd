@tool
extends Node2D
## Experimental B2 entry/participant; pixel row layout, not B3 adapters.
signal layout_applied
const Coordinator = preload("res://addons/estragon/layout_proof/coordinator.gd")
@export var width: float = -1.0:
	set(value):
		if not valid_length(value): return
		width = value
		_changed()
@export var height: float = -1.0:
	set(value):
		if not valid_length(value): return
		height = value
		_changed()
@export var gap: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0: return
		gap = value
		_changed()
@export var center: bool = false:
	set(value):
		center = value
		_changed()
@export var viewport_width_scale: float = 0.0:
	set(value):
		if not is_finite(value) or value < 0: return
		viewport_width_scale = value
		_changed()
@export var tint := Color(0.2, 0.8, 0.6):
	set(value):
		tint = value
		queue_redraw()
var layout_size := Vector2.ZERO
var layout = Coordinator.new(self, 2)

static func valid_length(value: float) -> bool:
	return is_finite(value) and (value >= 0 or value == -1)

func requested_extent() -> Vector3:
	return Vector3(width, height, 0.0)

func _changed() -> void:
	if layout != null:
		layout.changed()
		layout._invalidated()

func _notification(what: int) -> void:
	# Godot 4.0 emits MOVED_IN_PARENT (12); later engines expose
	# child_order_changed. Keep the old constant out of newer parsers.
	if what == 12 and layout != null: layout.order_moved()

func _enter_tree() -> void:
	layout.changed()
	layout.start()

func _exit_tree() -> void:
	layout.stop()

func invalidate_layout() -> void:
	layout.model.invalidate()

func apply_layout_size(size: Vector3) -> void:
	layout_size = Vector2(size.x, size.y)
	queue_redraw()
	layout_applied.emit()

func _draw() -> void:
	if layout_size.x > 0 and layout_size.y > 0:
		draw_rect(Rect2(Vector2.ZERO, layout_size), tint)
