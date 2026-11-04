@tool
extends RefCounted
## Shared B2/C1 mathematical row layout. No Nodes, rendering or SceneTree dependencies.
signal invalidated
signal placed(offset)
signal arranged(size)
var requested := Vector3(-1, -1, -1)
var gap: float = 0.0
var center: bool = false
var children: Array = []
var measured := Vector3.ZERO
var size := Vector3.ZERO
var offset := Vector3.ZERO
var measure_count: int = 0
var arrange_count: int = 0
var _measure_dirty: bool = true
var _arrange_dirty: bool = true
var _parent: WeakRef

static func valid_extent(value: Vector3) -> bool:
	for axis in range(3):
		if not is_finite(value[axis]) or value[axis] < 0 and value[axis] != -1: return false
	return true

func configure(extent: Vector3, spacing: float, centered: bool) -> Error:
	if not valid_extent(extent) or not is_finite(spacing) or spacing < 0: return ERR_INVALID_PARAMETER
	if requested == extent and gap == spacing and center == centered: return OK
	requested = extent
	gap = spacing
	center = centered
	invalidate()
	return OK

func set_children(values: Array) -> Error:
	var seen: Array = []
	for child in values:
		if child == null or child == self or seen.has(child): return ERR_INVALID_PARAMETER
		var ancestor = self
		while ancestor != null:
			if child == ancestor: return ERR_INVALID_PARAMETER
			ancestor = ancestor._parent.get_ref() if ancestor._parent != null else null
		if child._parent != null and child._parent.get_ref() != null and child._parent.get_ref() != self: return ERR_ALREADY_IN_USE
		seen.append(child)
	if children == values: return OK
	for child in children:
		if not values.has(child): child._parent = null
	children = values.duplicate()
	for child in children: child._parent = weakref(self)
	invalidate()
	return OK

func invalidate() -> void:
	_measure_dirty = true
	_arrange_dirty = true
	var parent = _parent.get_ref() if _parent != null else null
	if parent != null: parent.invalidate()
	invalidated.emit()

func measure() -> Vector3:
	if not _measure_dirty: return measured
	measure_count += 1
	var natural := Vector3.ZERO
	for child in children:
		var child_size: Vector3 = child.measure()
		natural.x += child_size.x
		natural.y = maxf(natural.y, child_size.y)
		natural.z = maxf(natural.z, child_size.z)
	if children.size() > 1: natural.x += gap * (children.size() - 1)
	measured = natural
	for axis in range(3):
		if requested[axis] >= 0: measured[axis] = requested[axis]
	_measure_dirty = false
	return measured

func arrange(available: Vector3) -> void:
	if not _arrange_dirty and size == available: return
	measure()
	arrange_count += 1
	size = available
	# Clear before callbacks so a signal-triggered change queues a genuine
	# follow-up instead of being overwritten when this pass finishes.
	_arrange_dirty = false
	var natural_width: float = gap * maxi(0, children.size() - 1)
	for child in children: natural_width += child.measured.x
	var cursor: float = (available.x - natural_width) * 0.5 if center else 0.0
	for child in children:
		var next := Vector3(cursor, 0, 0)
		if child.offset != next or child.arrange_count == 0:
			child.offset = next
			child.placed.emit(next)
		child.arrange(child.measured)
		cursor += child.measured.x + gap
	arranged.emit(size)
