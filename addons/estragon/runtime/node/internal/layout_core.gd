@tool
extends RefCounted
## Shared B2/C1 mathematical row layout. No Nodes, rendering or SceneTree dependencies.
signal invalidated
signal placed(offset)
signal arranged(size)
var requested := Vector3(-1, -1, -1)
var gap: float = 0.0
var center: bool = false
var axis: int = 0
var fill := Vector3.ZERO
var intrinsic := Vector3.ZERO
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

func configure(extent: Vector3, spacing: float, centered: bool, stack_axis: int = 0, fills: Vector3 = Vector3.ZERO, content: Vector3 = Vector3.ZERO) -> Error:
	if not valid_extent(extent) or not is_finite(spacing) or spacing < 0 or stack_axis < 0 or stack_axis > 2: return ERR_INVALID_PARAMETER
	for index in range(3):
		if fills[index] not in [0.0,1.0] or not is_finite(content[index]) or content[index] < 0: return ERR_INVALID_PARAMETER
	if requested == extent and gap == spacing and center == centered and axis == stack_axis and fill == fills and intrinsic == content: return OK
	axis = stack_axis
	fill = fills
	intrinsic = content
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
		for index in range(3):
			if index == axis: natural[index] += child_size[index]
			else: natural[index] = maxf(natural[index],child_size[index])
	if children.size() > 1: natural[axis] += gap * (children.size() - 1)
	for index in range(3): natural[index] = maxf(natural[index],intrinsic[index])
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
	var fixed: float = gap * maxi(0, children.size() - 1)
	var flexible: int = 0
	for child in children:
		if child.fill[axis] > 0 and child.requested[axis] < 0: flexible += 1
		else: fixed += child.measured[axis]
	var share: float = maxf(0,available[axis] - fixed) / maxi(1,flexible)
	var row_extent: float = fixed + share * flexible
	var cursor: float = (available[axis] - row_extent) * 0.5 if center else 0.0
	for child in children:
		var allocation: Vector3 = child.measured
		for index in range(3):
			if child.fill[index] > 0 and child.requested[index] < 0:
				allocation[index] = share if index == axis else available[index]
		var next := Vector3.ZERO
		next[axis] = cursor
		if child.offset != next or child.arrange_count == 0:
			child.offset = next
			child.placed.emit(next)
		child.arrange(allocation)
		cursor += allocation[axis] + gap
	arranged.emit(size)
