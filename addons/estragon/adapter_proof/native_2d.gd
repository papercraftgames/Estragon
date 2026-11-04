@tool
extends "res://addons/estragon/layout_proof/entry_2d.gd"
## B3 bounded native visual adapter; inherited extents allocate, never stretch.
const Bounds = preload("res://addons/estragon/adapter_proof/bounds.gd")
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
	layout_size = Vector2(size.x, size.y)
	if layout.parent_coordinator() != null: apply_layout_position(layout.model.offset)
	layout_applied.emit()

func _draw() -> void:
	# Rendering belongs exclusively to the authored native visual child.
	pass
