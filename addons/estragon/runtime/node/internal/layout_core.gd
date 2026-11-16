@tool
extends RefCounted
const StackPolicy = preload("stack_policy.gd")
const Length = preload("length.gd")
const Profile = preload("../../composition/profile.tres")
## Shared B2/C1 mathematical row layout. No Nodes, rendering or SceneTree dependencies.
signal invalidated
signal placed(offset)
signal arranged(size)
var length_specs: Dictionary = {}
var grow: float = 0.0
var stretch: int = 0
var align_self := "auto"
var pixels_per_unit: float = 1.0
var length_offset := Vector3.ZERO
var viewport_size := Vector2.ZERO
var parent_reference := Vector3(-1,-1,-1)
var resolution_count := 0
var _length_context: Array = []
var _parent_axes := Vector3.ZERO
var _viewport_axes := Vector2.ZERO
var _forward_context: Array = []
var _reported_unanchored := false
var _reported_full_percent := false
var _reported_fixed_growth := false
var requested := Vector3(-1, -1, -1)
var gap: float = 0.0
var center: bool = false
var axis: int = 0
var fill := Vector3.ZERO
var intrinsic := Vector3.ZERO
# Native Control minimums constrain assigned slots, never read back from size.
var allocation_minimum := Vector3.ZERO
# Authored border-box floors are independent of native adapter minimums.
var authored_minimum := Vector3.ZERO
var padding := Vector4.ZERO # left, top, right, bottom; border-box insets
var border := Vector4.ZERO # inside the border-box, before padding
var margin := Vector4.ZERO # outside own geometry; consumed by the parent
var transparent: bool = false # composition proxy forwards one root slot
var alignment: Array = ["start","start","start"]
# Parent-owned border-box placements; no Node references or additive offsets.
var slots: Array = []
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

var default_padding := Vector4.ZERO

func set_lengths(specs: Dictionary, growth: float, cross: int, scale: float, stack_axis: int, padding_fallback: Vector4 = Vector4.ZERO) -> void:
	if default_padding==padding_fallback and length_specs==specs and grow==growth and stretch==cross and pixels_per_unit==scale and axis==stack_axis: return
	default_padding = padding_fallback
	length_specs = specs.duplicate(true)
	grow = growth
	stretch = cross
	pixels_per_unit = scale
	var dependencies := Length.dependencies(length_specs,stack_axis)
	_parent_axes = dependencies[0]
	_viewport_axes = dependencies[1]
	_length_context = []
	invalidate()

func set_policy(values: Array) -> void:
	if alignment==values: return
	alignment = values.duplicate()
	invalidate()

func set_align_self(value: String) -> void:
	if align_self==value: return
	align_self = value
	invalidate()

func _length(name: String, axis_index: int, fallback: float) -> float:
	if not length_specs.has(name): return fallback
	var spec: Dictionary = length_specs[name]
	return Length.resolve(spec,parent_reference[axis_index],viewport_size,pixels_per_unit)

func _warn_unanchored() -> void:
	if _reported_unanchored: return
	for index in range(3):
		if _parent_axes[index]>0 and parent_reference[index]<0:
			_reported_unanchored = true
			push_warning("Estragon percentage has no definite containing content axis and resolves to zero; give the containing auto layout axis an independent extent or grow allocation; independent 2D Entries use their visible viewport")
			return

func _edges(prefix: String) -> Vector4:
	var result := Vector4.ZERO
	var names := ["left","top","right","bottom"]
	for edge in range(4):
		var index: int = edge%2
		var key: String = prefix+"_"+names[edge]+("_width" if prefix=="border" else "")
		var value := _length(key,index,-1)
		var uniform := _length("border_width" if prefix=="border" else prefix,index,0)
		if prefix=="padding" and uniform<0: uniform = default_padding[edge]
		result[edge] = uniform if value<0 else value
	return result

# Resolve specs only on a changed parent/viewport/spec context. No property
# writeback, parsing in arrange, subscriptions per length, or frame polling.
func prepare(reference: Vector3, viewport: Vector2) -> void:
	if transparent and _forward_context!=[reference,viewport] or viewport_size!=viewport and not children.is_empty():
		_measure_dirty = true
		_arrange_dirty = true
	_forward_context = [reference,viewport] if transparent else []
	parent_reference = reference
	viewport_size = viewport
	var context := [reference*_parent_axes,viewport*_viewport_axes]
	if _length_context==context: return
	_length_context = context
	resolution_count += 1
	var before := [requested,gap,padding,border,margin,length_offset,authored_minimum]
	if not length_specs.is_empty():
		for index in range(3):
			requested[index] = _length(["width","height","depth"][index],index,requested[index])
			length_offset[index] = _length(["x","y","z"][index],index,0)
		authored_minimum = Vector3(maxf(0,_length("min_width",0,0)),maxf(0,_length("min_height",1,0)),0)
		gap = _length("gap",axis,0)
		padding = _edges("padding")
		border = _edges("border")
		margin = _edges("margin")
	if before!=[requested,gap,padding,border,margin,length_offset,authored_minimum]:
		_measure_dirty = true
		_arrange_dirty = true

func minimum() -> Vector3:
	var result := authored_minimum
	var inherited: Vector3 = children[0].minimum() if transparent and children.size()==1 else Vector3.ZERO
	for index in range(3): result[index] = maxf(result[index],maxf(allocation_minimum[index],inherited[index]))
	return result

func constrain(extent: Vector3) -> Vector3:
	var floor := minimum()
	for index in range(3): extent[index] = maxf(extent[index],floor[index])
	return extent

func _content_basis() -> Vector3:
	var basis := Vector3(-1,-1,-1)
	for index in range(3):
		if requested[index]>=0: basis[index] = maxf(0,maxf(requested[index],minimum()[index])-leading(padding+border)[index]-trailing(padding+border)[index])
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
		child.measure()
		if child.requested!=requested or child.grow!=grow or child.stretch!=stretch or child.align_self!=align_self or child.margin!=margin or child.fill!=fill or child.length_offset!=length_offset:
			requested = child.requested
			grow = child.grow
			stretch = child.stretch
			align_self = child.align_self
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
	if not transparent: natural += leading(padding+border)+trailing(padding+border)
	measured = natural
	for axis in range(3):
		if requested[axis] >= 0: measured[axis] = requested[axis]
	measured = constrain(measured)
	_measure_dirty = false
	return measured

# An auto axis cannot be a reference to its own descendants. Fill allocations
# ignore this model's intrinsic extent and can inherit an independent basis.
func independent_axis(index: int) -> bool:
	if requested[index] >= 0 or _external_axes[index] > 0: return true
	var parent = _parent.get_ref() if _parent != null else null
	if parent == null: return false
	var allocated: bool = grow>0 or fill[index]>0 if index==parent.axis else StackPolicy.cross_alignment({"align_self":align_self,"stretch":stretch,"fill":fill},parent.alignment[index],index)=="stretch"
	return parent.independent_axis(index) if requested[index] < 0 and allocated else false

func arrange(available: Vector3, external_axes: Vector3 = Vector3.ZERO) -> void:
	available = constrain(available)
	_external_axes = external_axes
	_warn_unanchored()
	var content := available-leading(padding+border)-trailing(padding+border)
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
			# Forward actual allocation authority through transparent hosts. Their
			# internal X axis must not reinterpret the outer Box's grow axis.
			var authority := Vector3.ZERO
			for index in range(3):
				if independent_axis(index): authority[index] = 1
			child.arrange(available,authority)
		arranged.emit(size)
		return
	if not _reported_fixed_growth and grow>0 and _parent!=null and _parent.get_ref()!=null:
		var containing = _parent.get_ref()
		while containing.transparent and containing._parent!=null and containing._parent.get_ref()!=null: containing = containing._parent.get_ref()
		var main: int = containing.axis
		if requested[main]>=0:
			_reported_fixed_growth = true
			push_warning("Estragon explicit main-axis dimension overrides grow; use auto height/width on a remaining-space Spacer")
	# Assigned content is authoritative, including grow allocations. Resolve the
	# immediate children against this box before measuring their slots.
	for child in children:
		child.prepare(reference,viewport_size)
		child.measure()
	if not _reported_full_percent and children.size()>1:
		var main_name: String = ["width","height","depth"][axis]
		for child in children:
			var spec: Dictionary = child.length_specs.get(main_name,{})
			if spec.get("unit","")=="%" and spec.get("value",0)>=100:
				_reported_full_percent = true
				push_warning("Estragon "+main_name+"=100% consumes the full definite parent content axis, not remaining space; siblings may overflow. Use an auto-sized Spacer with grow=1 for remaining space")
				break
	var items: Array = []
	for child in children:
		items.append({"preferred":child.measured,"minimum":child.minimum(),"requested":child.requested,"grow":child.grow,"stretch":child.stretch,"align_self":child.align_self,"fill":child.fill,"outer":child.outer_extent(),"leading":leading(child.margin)})
	var policy := alignment.duplicate()
	if center: policy[axis] = "center"
	slots = StackPolicy.slots(items,content,axis,gap,policy)
	for index in range(children.size()):
		var child = children[index]
		var slot: Dictionary = slots[index]
		var next: Vector3 = leading(padding+border)+slot.position+child.length_offset
		if child.offset != next or child.arrange_count == 0:
			child.offset = next
			child.placed.emit(next)
		var authority := Vector3.ZERO
		for cross in range(3):
			if cross!=axis and StackPolicy.cross_alignment(items[index],policy[cross],cross)=="stretch" and child.requested[cross]<0 and independent_axis(cross): authority[cross] = 1
		child.arrange(slot.extent,authority)
	arranged.emit(size)
