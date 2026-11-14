@tool
extends RefCounted
const Length = preload("length.gd")
const Profile = preload("../../composition/profile.tres")
## Shared B2/C1 mathematical row layout. No Nodes, rendering or SceneTree dependencies.
signal invalidated
signal placed(offset)
signal arranged(size)
var length_specs: Dictionary = {}
var flex: float = 0.0
var stretch: int = 0
var pixels_per_unit: float = 1.0
var length_offset := Vector3.ZERO
var viewport_size := Vector2.ZERO
var parent_reference := Vector3(-1,-1,-1)
var resolution_count := 0
var _length_context: Array = []
var _reported_unanchored := false
var requested := Vector3(-1, -1, -1)
var gap: float = 0.0
var center: bool = false
var axis: int = 0
var fill := Vector3.ZERO
var intrinsic := Vector3.ZERO
# Native Control minimums constrain assigned slots, never read back from size.
var allocation_minimum := Vector3.ZERO
var padding := Vector4.ZERO # left, top, right, bottom; border-box insets
var margin := Vector4.ZERO # outside own geometry; consumed by the parent
var transparent: bool = false # composition proxy forwards one root slot
var children: Array = []
var measured := Vector3.ZERO
# -1 is an unavailable/cyclic reference axis, distinct from an arranged zero.
var content_reference := Vector3(-1,-1,-1)
var _external_axes := Vector3.ZERO
var size := Vector3.ZERO
var offset := Vector3.ZERO
var measure_count: int = 0
var arrange_count: int = 0
var _measure_dirty: bool = true
var _arrange_dirty: bool = true
var _parent: WeakRef

func set_lengths(specs: Dictionary, growth: float, cross: int, scale: float) -> void:
	if length_specs==specs and flex==growth and stretch==cross and pixels_per_unit==scale: return
	length_specs = specs.duplicate(true)
	flex = growth
	stretch = cross
	pixels_per_unit = scale
	_length_context = []
	invalidate()

func _length(name: String, axis_index: int, fallback: float) -> float:
	if not length_specs.has(name): return fallback
	var spec: Dictionary = length_specs[name]
	if spec.unit=="%" and parent_reference[axis_index]<0 and not _reported_unanchored:
		_reported_unanchored = true
		push_warning("Estragon unanchored/cyclic percentage resolves to zero; give the containing layout axis an independent extent")
	return Length.resolve(spec,parent_reference[axis_index],viewport_size,pixels_per_unit)

func _edges(prefix: String) -> Vector4:
	var result := Vector4.ZERO
	var names := ["left","top","right","bottom"]
	for edge in range(4):
		var index: int = edge%2
		var value := _length(prefix+"_"+names[edge],index,-1)
		result[edge] = _length(prefix,index,0) if value<0 else value
	return result

# Resolve specs only on a changed parent/viewport/spec context. No property
# writeback, parsing in arrange, subscriptions per length, or frame polling.
func prepare(reference: Vector3, viewport: Vector2) -> void:
	if _length_context==[reference,viewport]: return
	_length_context = [reference,viewport]
	if transparent or viewport_size!=viewport and not children.is_empty():
		_measure_dirty = true
		_arrange_dirty = true
	parent_reference = reference
	viewport_size = viewport
	resolution_count += 1
	var before := [requested,gap,padding,margin,length_offset]
	if not length_specs.is_empty():
		for index in range(3):
			requested[index] = _length(["width","height","depth"][index],index,requested[index])
			length_offset[index] = _length(["x","y","z"][index],index,0)
		gap = _length("gap",axis,0)
		padding = _edges("padding")
		margin = _edges("margin")
	if before!=[requested,gap,padding,margin,length_offset]:
		_measure_dirty = true
		_arrange_dirty = true

func _content_basis() -> Vector3:
	var basis := Vector3(-1,-1,-1)
	for index in range(3):
		if requested[index]>=0: basis[index] = maxf(0,requested[index]-leading(padding)[index]-trailing(padding)[index])
	return basis

static func valid_extent(value: Vector3) -> bool:
	for axis in range(3):
		if not is_finite(value[axis]) or value[axis] < 0 and value[axis] != -1: return false
	return true

func configure(extent: Vector3, spacing: float, centered: bool, stack_axis: int = 0, fills: Vector3 = Vector3.ZERO, content: Vector3 = Vector3.ZERO, inner: Vector4 = Vector4.ZERO, outer: Vector4 = Vector4.ZERO, passthrough: bool = false) -> Error:
	if not valid_extent(extent) or not is_finite(spacing) or spacing < 0 or stack_axis < 0 or stack_axis > 2: return ERR_INVALID_PARAMETER
	for index in range(3):
		if fills[index] not in [0.0,1.0] or not is_finite(content[index]) or content[index] < 0: return ERR_INVALID_PARAMETER
	for edge in range(4):
		if not is_finite(inner[edge]) or inner[edge] < 0 or not is_finite(outer[edge]) or outer[edge] < 0: return ERR_INVALID_PARAMETER
	if requested == extent and gap == spacing and center == centered and axis == stack_axis and fill == fills and intrinsic == content and padding == inner and margin == outer and transparent == passthrough: return OK
	padding = inner
	margin = outer
	transparent = passthrough
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
		if not values.has(child):
			child._parent = null
	children = values.duplicate()
	for child in children:
		child._parent = weakref(self)
	invalidate()
	return OK

func invalidate() -> void:
	_measure_dirty = true
	_arrange_dirty = true
	var parent = _parent.get_ref() if _parent != null else null
	if parent != null: parent.invalidate()
	invalidated.emit()

static func leading(edges: Vector4) -> Vector3:
	return Vector3(edges.x,edges.y,0)
static func trailing(edges: Vector4) -> Vector3:
	return Vector3(edges.z,edges.w,0)
func outer_extent() -> Vector3:
	return leading(margin)+trailing(margin)

func measure() -> Vector3:
	if transparent and children.size()==1:
		var child = children[0]
		child.prepare(parent_reference,viewport_size)
		if child.requested!=requested or child.flex!=flex or child.stretch!=stretch or child.margin!=margin or child.fill!=fill or child.length_offset!=length_offset:
			requested = child.requested
			flex = child.flex
			stretch = child.stretch
			fill = child.fill
			margin = child.margin
			length_offset = child.length_offset
			_measure_dirty = true
	if not _measure_dirty: return measured
	measure_count += 1
	if Profile.is_enabled(): Profile.add("layout_measures")
	var natural := Vector3.ZERO
	for child in children:
		if not transparent: child.prepare(_content_basis(),viewport_size)
		var child_size: Vector3 = child.measure()
		if not transparent: child_size += child.outer_extent()
		for index in range(3):
			if index == axis: natural[index] += child_size[index]
			else: natural[index] = maxf(natural[index],child_size[index])
	if children.size() > 1: natural[axis] += gap * (children.size() - 1)
	for index in range(3): natural[index] = maxf(natural[index],intrinsic[index])
	if not transparent: natural += leading(padding)+trailing(padding)
	measured = natural
	for axis in range(3):
		if requested[axis] >= 0: measured[axis] = requested[axis]
	_measure_dirty = false
	return measured

# An auto axis cannot be a reference to its own descendants. Fill allocations
# ignore this model's intrinsic extent and can inherit an independent basis.
func independent_axis(index: int) -> bool:
	if not transparent and (requested[index] >= 0 or _external_axes[index] > 0): return true
	var parent = _parent.get_ref() if _parent != null else null
	if parent == null: return false
	return parent.independent_axis(index) if transparent or requested[index] < 0 and (fill[index] > 0 or (flex>0 if index==parent.axis else stretch>0)) else false

func arrange(available: Vector3, external_axes: Vector3 = Vector3.ZERO) -> void:
	_external_axes = external_axes
	var content := available-leading(padding)-trailing(padding)
	var reference := Vector3(-1,-1,-1)
	for index in range(3):
		content[index] = maxf(0,content[index])
		if independent_axis(index): reference[index] = content[index]
	var changed: bool = reference != content_reference
	if not _arrange_dirty and size == available and not changed: return
	content_reference = reference
	measure()
	arrange_count += 1
	if Profile.is_enabled(): Profile.add("layout_arranges")
	size = available
	# Clear before callbacks so a signal-triggered change queues a genuine
	# follow-up instead of being overwritten when this pass finishes.
	_arrange_dirty = false
	if transparent:
		for child in children:
			if child.offset != Vector3.ZERO or child.arrange_count == 0:
				child.offset = Vector3.ZERO
				child.placed.emit(Vector3.ZERO)
			child.viewport_size = viewport_size
			child.arrange(available)
		arranged.emit(size)
		return
	# Assigned content is authoritative, including flex allocations. Resolve the
	# immediate children against this box before measuring their slots.
	for child in children:
		child.prepare(reference,viewport_size)
		child.measure()
	var fixed: float = gap * maxi(0, children.size() - 1)
	var flexible: Array = []
	for child in children:
		fixed += child.outer_extent()[axis]
		if (child.flex>0 or child.fill[axis]>0) and child.requested[axis] < 0: flexible.append(child)
		else: fixed += child.measured[axis]
	var remaining: float = maxf(0,content[axis] - fixed)
	var shares: Dictionary = {}
	# Reserve constrained native minimums, then share the remaining space.
	# Zero floors preserve the existing equal-share Box behavior.
	while not flexible.is_empty():
		var weight := 0.0
		for child in flexible: weight += child.flex if child.flex>0 else 1.0
		var share: float = remaining / weight
		var constrained := false
		for child in flexible.duplicate():
			if child.allocation_minimum[axis] > share*(child.flex if child.flex>0 else 1.0):
				shares[child] = child.allocation_minimum[axis]
				remaining = maxf(0,remaining-child.allocation_minimum[axis])
				flexible.erase(child)
				constrained = true
		if not constrained:
			for child in flexible: shares[child] = share*(child.flex if child.flex>0 else 1.0)
			break
	var row_extent: float = fixed
	for share in shares.values(): row_extent += share
	var cursor: float = (content[axis] - row_extent) * 0.5 if center else 0.0
	for child in children:
		var allocation: Vector3 = child.measured
		for index in range(3):
			if (child.fill[index]>0 or (child.flex>0 if index==axis else child.stretch>0)) and child.requested[index] < 0:
				allocation[index] = shares[child] if index == axis else maxf(0,content[index]-child.outer_extent()[index])
			allocation[index] = maxf(allocation[index],child.allocation_minimum[index])
		var next: Vector3 = leading(padding)+leading(child.margin)+child.length_offset
		next[axis] += cursor
		if child.offset != next or child.arrange_count == 0:
			child.offset = next
			child.placed.emit(next)
		child.arrange(allocation)
		cursor += allocation[axis] + child.outer_extent()[axis] + gap
	arranged.emit(size)
