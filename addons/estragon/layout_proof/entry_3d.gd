@tool
extends Node3D
## Experimental B2 entry/participant; Godot world-unit row layout, not B3 adapters.
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
@export var depth: float = -1.0:
	set(value):
		if not valid_length(value): return
		depth = value
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
		_update_visual()
var layout_size := Vector3.ZERO
var layout = Coordinator.new(self, 3)
var _visual: MeshInstance3D

static func valid_length(value: float) -> bool:
	return is_finite(value) and (value >= 0 or value == -1)

func requested_extent() -> Vector3:
	return Vector3(width, height, depth)

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
	layout_size = size
	_update_visual()
	layout_applied.emit()

func _update_visual() -> void:
	if not is_inside_tree(): return
	if _visual == null:
		_visual = MeshInstance3D.new()
		_visual.name = "B2Visual"
		_visual.mesh = BoxMesh.new()
		add_child(_visual)
	_visual.visible = layout_size.x > 0 and layout_size.y > 0 and layout_size.z > 0 and tint.a > 0
	if not _visual.visible: return
	var box: BoxMesh = _visual.mesh
	box.size = layout_size
	_visual.position = layout_size * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	_visual.material_override = material
