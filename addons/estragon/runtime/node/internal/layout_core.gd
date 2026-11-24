@tool
extends RefCounted
const StackPolicy = preload("stack_policy.gd")
const WrapPolicy = preload("wrap_policy.gd")
const GridDefinition = preload("grid_definition.gd")
const GridPolicy = preload("grid_policy.gd")
const Length = preload("length.gd")
const ScrollbarGeometry = preload("scrollbar_geometry.gd")
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
# Width/height percentages alone use this parent-policy budget. Other Length
# domains retain parent_reference; spatial coordinators keep their old contract.
var dimension_reference := Vector3(-1,-1,-1)
var dimension_budget_enabled := true
var _dimension_axes := Vector3.ZERO
var _budget_context: Array = []
var _budget := Vector3(-1,-1,-1)
var dimension_budget_count := 0
var resolution_count := 0
var _length_context: Array = []
var _parent_axes := Vector3.ZERO
var _viewport_axes := Vector2.ZERO
var _forward_context: Array = []
var _reported_unanchored := false
var _reported_full_percent := false
var _reported_fixed_growth := false
var available_capacity := Vector3(-1,-1,-1)
var measurement_allocation := Vector3(-1,-1,-1)
var requested := Vector3(-1, -1, -1)
var placement: Dictionary = {}
var grid_config: Dictionary = {}
var grid_definition: Dictionary = {}
var policy_result: Dictionary = {}
var strategy := "stack"
# Viewport decoration; never replaces Stack/Wrap/Grid.
var scroll_axes := Vector2.ZERO
var scroll_geometry: Dictionary = {}
var clips_content := false
var align_content := "start"
var physical_gaps := Vector2.ZERO
var gap: float = 0.0
var center: bool = false
var axis: int = 0
var fill := Vector3.ZERO
var intrinsic := Vector3.ZERO
# Native Control minimums constrain assigned slots, never read back from size.
var allocation_minimum := Vector3.ZERO
# Authored border-box floors are independent of native adapter minimums.
var authored_maximum := Vector3(-1,-1,-1)
var _reported_max_conflict := false
var authored_minimum := Vector3.ZERO
var padding := Vector4.ZERO # left, top, right, bottom; border-box insets
var border := Vector4.ZERO # inside the border-box, before padding
var margin := Vector4.ZERO # outside own geometry; consumed by the parent
var transparent: bool = false # composition proxy forwards one root slot
var alignment: Array = ["start","start","start"]
# Parent-owned border-box placements; no Node references or additive offsets.
var slots: Array = []
var children: Array = []
var natural_extent := Vector3.ZERO
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

func is_layout_dirty() -> bool:
	return _measure_dirty or _arrange_dirty

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
	_dimension_axes = Vector3.ZERO
	for index in range(2):
		if length_specs.get(["width","height"][index],{}).get("unit","")=="%": _dimension_axes[index] = 1
	_length_context = []
	invalidate()

func set_placement(value: Dictionary) -> void:
	if placement==value: return
	placement = value.duplicate(true)
	invalidate()

func set_strategy(value: String, content_alignment: String = "start", config: Dictionary = {}) -> void:
	if strategy==value and align_content==content_alignment and grid_config==config: return
	grid_config = config.duplicate(true)
	grid_definition = {}
	strategy = value
	align_content = content_alignment
	invalidate()

func set_scroll_axes(value: Vector2) -> void:
	if scroll_axes==value: return
	scroll_axes = value
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
	var reference: float = dimension_reference[axis_index] if name in ["width","height"] and spec.unit=="%" else parent_reference[axis_index]
	return Length.resolve(spec,reference,viewport_size,pixels_per_unit)

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
func prepare(reference: Vector3, viewport: Vector2, dimensions: Variant = null) -> void:
	var budget: Vector3 = reference if dimensions==null else dimensions
	if transparent and _forward_context!=[reference,viewport,budget] or viewport_size!=viewport and not children.is_empty():
		_measure_dirty = true
		_arrange_dirty = true
	_forward_context = [reference,viewport,budget] if transparent else []
	for index in range(3):
		if parent_reference[index]!=reference[index] and measurement_allocation[index]>=0:
			measurement_allocation[index] = -1
			_measure_dirty = true
	parent_reference = reference
	dimension_reference = budget
	viewport_size = viewport
	var context := [reference*_parent_axes,viewport*_viewport_axes,budget*_dimension_axes]
	if _length_context==context: return
	_length_context = context
	if dimension_budget_enabled: measurement_allocation = Vector3(-1,-1,-1)
	resolution_count += 1
	var before := [requested,gap,physical_gaps,padding,border,margin,length_offset,authored_minimum,authored_maximum]
	if not length_specs.is_empty():
		for index in range(3):
			requested[index] = _length(["width","height","depth"][index],index,requested[index])
			length_offset[index] = _length(["x","y","z"][index],index,0)
		authored_minimum = Vector3(maxf(0,_length("min_width",0,0)),maxf(0,_length("min_height",1,0)),0)
		authored_maximum = Vector3(_length("max_width",0,-1),_length("max_height",1,-1),-1)
		gap = _length("gap",axis,0)
		physical_gaps = Vector2(_length("column_gap",0,-1),_length("row_gap",1,-1))
		for index in range(2):
			if physical_gaps[index]<0: physical_gaps[index] = _length("gap",index,0)
		padding = _edges("padding")
		border = _edges("border")
		margin = _edges("margin")
	if before!=[requested,gap,physical_gaps,padding,border,margin,length_offset,authored_minimum,authored_maximum]:
		_measure_dirty = true
		_arrange_dirty = true

func minimum() -> Vector3:
	var result := authored_minimum
	var inherited: Vector3 = children[0].minimum() if transparent and children.size()==1 else Vector3.ZERO
	for index in range(3): result[index] = maxf(result[index],maxf(allocation_minimum[index],inherited[index]))
	return result

func maximum() -> Vector3:
	if transparent and children.size()==1: return children[0].maximum()
	return authored_maximum

func constrain(extent: Vector3) -> Vector3:
	var floor := minimum()
	var cap := maximum()
	for index in range(3):
		if cap[index]>=0:
			if floor[index]>cap[index] and not _reported_max_conflict and not transparent:
				_reported_max_conflict = true
				push_warning("Estragon minimum exceeds maximum; minimum/native floor wins")
			extent[index] = minf(extent[index],cap[index])
		extent[index] = maxf(extent[index],floor[index])
	return extent

func _inner_basis() -> Vector3:
	var basis := Vector3(-1,-1,-1)
	for index in range(3):
		var allocated: float = constrain(requested)[index] if requested[index]>=0 else measurement_allocation[index]
		if allocated>=0: basis[index] = maxf(0,maxf(allocated,minimum()[index])-leading(padding+border)[index]-trailing(padding+border)[index])
	return basis

func _content_basis() -> Vector3:
	var basis := _inner_basis()
	var strips := ScrollbarGeometry.thickness(Vector2(basis.x,basis.y),scroll_axes,length_specs,viewport_size)
	for index in range(2):
		if basis[index]>=0: basis[index] = maxf(0,basis[index]-strips[index])
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
	if length_specs.is_empty(): physical_gaps = Vector2(spacing,spacing)
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
	grid_definition = {}
	for child in children:
		child._parent = weakref(self)
	invalidate()
	return OK

func invalidate() -> void:
	if dimension_budget_enabled: measurement_allocation = Vector3(-1,-1,-1)
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

# A wrapping item's intrinsic main floor is its largest unbreakable child,
# while ordinary stack preferred sizes stay unchanged. This lets a fractional
# Grid cell assign a narrower width before the bounded cross remeasurement.
func track_contribution() -> Vector3:
	if transparent and children.size()==1: return children[0].track_contribution()
	var result := measured
	if strategy=="wrap" and scroll_axes[axis]==0 and requested[axis]<0:
		result[axis] = intrinsic[axis]
		for child in children: result[axis] = maxf(result[axis],maxf(child.measured[axis],child.minimum()[axis])+child.outer_extent()[axis])
		result[axis] += leading(padding+border)[axis]+trailing(padding+border)[axis]
	return constrain(result)

func _items() -> Array:
	var items: Array = []
	for child in children:
		items.append({"preferred":child.measured,"contribution":child.track_contribution(),"scroll_floor":child.scroll_track_floor(),"minimum":child.minimum(),"maximum":child.maximum(),"requested":child.requested,"grow":child.grow,"stretch":child.stretch,"align_self":child.align_self,"fill":child.fill,"outer":child.outer_extent(),"leading":leading(child.margin),"placement":child.placement})
	return items

func scroll_track_floor() -> Vector3:
	if transparent and children.size()==1: return children[0].scroll_track_floor()
	var result := Vector3(-1,-1,-1)
	for index in range(2):
		if scroll_axes[index]>0 and requested[index]<0:
			result[index] = maxf(minimum()[index],intrinsic[index]+leading(padding+border)[index]+trailing(padding+border)[index])
	return result

func _prepare_grid() -> void:
	var placements: Array = []
	for child in children: placements.append(child.placement)
	if grid_definition.get("source_placements",[])!=placements or grid_definition.is_empty():
		grid_definition = GridDefinition.configuration(grid_config,placements)
		grid_definition.source_placements = placements.duplicate(true)
		if grid_definition.has("error"): push_error("Estragon Grid: "+grid_definition.error+"; previous native slots retained")

func dimension_budget(reference: Vector3) -> Vector3:
	if not dimension_budget_enabled or transparent or strategy=="wrap": return reference
	var result := reference
	var counts := Vector2i.ONE
	if strategy=="grid":
		_prepare_grid()
		if grid_definition.has("error"): return reference
		counts = Vector2i(grid_definition.columns.size(),grid_definition.rows.size())
	elif axis<2: counts[axis] = children.size()
	var context := [reference,physical_gaps,counts]
	if _budget_context==context: return _budget
	_budget_context = context
	dimension_budget_count += 1
	for index in range(2):
		if reference[index]>=0: result[index] = maxf(0,reference[index]-physical_gaps[index]*maxi(0,counts[index]-1))
	_budget = result
	return result

func _main_gap() -> float:
	return physical_gaps[axis] if axis<2 else gap

func _grid(items: Array, content: Vector3) -> Dictionary:
	_prepare_grid()
	if grid_definition.has("error"):
		# Native children may exceed an explicitly bounded grid after direct edits.
		# Reject the layout as a whole, preserving the previous allocated slots.
		return {"error":grid_definition.error,"extent":measured,"slots":slots}
	if not _reported_unanchored:
		for index in range(2):
			for track in grid_definition.columns if index==0 else grid_definition.rows:
				if track.unit=="%" and content[index]<0:
					_reported_unanchored = true
					push_warning("Estragon Grid percentage track has no definite content reference and resolves to zero")
	return GridPolicy.layout(items,grid_definition,content,physical_gaps,alignment,viewport_size)

# Allocation-dependent measurement is a bounded second pass in this same core.
# Only independently assigned axes may supply a basis; auto cycles stay absent.
func set_capacity(value: Vector3) -> void:
	if not transparent:
		if strategy!="wrap" or requested[axis]>=0: return
		var main: float = value[axis]
		value = Vector3(-1,-1,-1)
		value[axis] = main
	if available_capacity==value: return
	available_capacity = value
	_measure_dirty = true
	_arrange_dirty = true
	if transparent and children.size()==1: children[0].set_capacity(value)

func _wrap_basis() -> Vector3:
	var basis := _content_basis()
	if axis<2 and scroll_axes[axis]>0: basis[axis] = -1
	if strategy=="wrap" and scroll_axes[axis]==0 and requested[axis]<0 and basis[axis]<0 and available_capacity[axis]>=0:
		basis[axis] = maxf(0,available_capacity[axis]-leading(padding+border)[axis]-trailing(padding+border)[axis])
	var cap := maximum()
	if strategy=="wrap" and scroll_axes[axis]==0 and cap[axis]>=0:
		var available := maxf(0,maxf(cap[axis],minimum()[axis])-leading(padding+border)[axis]-trailing(padding+border)[axis])
		basis[axis] = minf(basis[axis],available) if basis[axis]>=0 else available
	return basis

func measure_allocated(extent: Vector3, authority: Vector3) -> void:
	if transparent and children.size()==1:
		children[0].measure_allocated(extent,authority)
		_measure_dirty = true
	elif strategy in ["wrap","grid"] or scroll_axes!=Vector2.ZERO or dimension_budget_enabled and not children.is_empty():
		var next := measurement_allocation
		for index in range(2):
			if requested[index]<0 and authority[index]>0: next[index] = extent[index]
		if next==measurement_allocation: return
		measurement_allocation = next
		_measure_dirty = true
	else: return
	var preferred := measured
	measure()
	# Allocated axes are not a new intrinsic growth basis. Only the dependent
	# unallocated (e.g. wrapped cross) axes feed back into this bounded pass.
	if dimension_budget_enabled:
		for index in range(2):
			if requested[index]<0 and authority[index]>0: measured[index] = preferred[index]

func overflow_extent() -> Vector3:
	# Ancestors see the clipped participant's viewport, not its hidden content.
	if clips_content or scroll_axes!=Vector2.ZERO: return size
	var result := size
	for index in range(3): result[index] = maxf(result[index],natural_extent[index])
	for child in children:
		var extent: Vector3 = child.offset+child.overflow_extent()+trailing(child.margin)
		for index in range(3): result[index] = maxf(result[index],extent[index])
	return result

func _slots(items: Array, content: Vector3, definite: Vector3) -> Array:
	if strategy=="grid": return _grid(items,content).slots
	if strategy=="wrap": return WrapPolicy.layout(items,content,axis,physical_gaps,alignment,align_content,Vector2(definite.x,definite.y)).slots
	return StackPolicy.slots(items,content,axis,_main_gap(),alignment)

func _authority(child, item: Dictionary, basis: Vector3) -> Vector3:
	var authority := Vector3.ZERO
	for index in range(3):
		if basis[index]<0 or child.requested[index]>=0 or index<2 and scroll_axes[index]>0: continue
		if strategy=="grid":
			if index<2 and alignment[index]=="stretch": authority[index] = 1
		elif index==axis:
			if child.grow>0 or child.fill[index]>0: authority[index] = 1
		elif StackPolicy.cross_alignment(item,alignment[index],index)=="stretch": authority[index] = 1
	return authority

func measure() -> Vector3:
	if transparent and children.size()==1:
		var child = children[0]
		child.prepare(parent_reference,viewport_size,dimension_reference)
		child.set_capacity(available_capacity)
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
	if not transparent:
		var basis := _content_basis()
		var budget := dimension_budget(basis)
		for child in children:
			child.prepare(basis,viewport_size,budget)
			var capacity := basis
			for index in range(3):
				if capacity[index]>=0: capacity[index] = maxf(0,capacity[index]-child.outer_extent()[index])
			child.set_capacity(capacity)
			child.measure()
		if basis.x>=0 or basis.y>=0:
			var items := _items()
			var definite := Vector3(1 if basis.x>=0 else 0,1 if basis.y>=0 else 0,1 if basis.z>=0 else 0)
			var allocations := _slots(items,basis,definite)
			if allocations.size()==children.size():
				for index in range(children.size()): children[index].measure_allocated(allocations[index].extent,_authority(children[index],items[index],basis))
	var natural := Vector3.ZERO
	for child in children:
		var child_size: Vector3 = child.measure()
		if not transparent: child_size += child.outer_extent()
		for index in range(3):
			if index == axis: natural[index] += child_size[index]
			else: natural[index] = maxf(natural[index],child_size[index])
	if children.size() > 1: natural[axis] += _main_gap() * (children.size() - 1)
	if strategy=="wrap" and not transparent:
		var basis := _wrap_basis()
		natural = WrapPolicy.layout(_items(),basis,axis,physical_gaps,alignment,align_content,Vector2(1 if basis.x>=0 else 0,1 if basis.y>=0 else 0)).extent
		if basis[axis]>=0 and requested[axis]<0: natural[axis] = minf(basis[axis],natural[axis])
	if strategy=="grid" and not transparent:
		natural = _grid(_items(),_content_basis()).extent
	for index in range(3): natural[index] = maxf(natural[index],intrinsic[index])
	if not transparent: natural += leading(padding+border)+trailing(padding+border)
	natural_extent = natural
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
	if index<2 and scroll_axes[index]>0 and maximum()[index]>=0: return true
	var parent = _parent.get_ref() if _parent != null else null
	if parent == null: return false
	var allocated := grow>0 or fill[index]>0
	if index!=parent.axis: allocated = StackPolicy.cross_alignment({"align_self":align_self,"stretch":stretch,"fill":fill},parent.alignment[index],index)=="stretch"
	if index<2 and parent.scroll_axes[index]>0: return false
	if parent.strategy=="grid" and index<2: allocated = parent.alignment[index]=="stretch"
	return parent.independent_axis(index) if requested[index] < 0 and allocated else false

func arrange(available: Vector3, external_axes: Vector3 = Vector3.ZERO) -> void:
	available = constrain(available)
	_external_axes = external_axes
	_warn_unanchored()
	var content := available-leading(padding+border)-trailing(padding+border)
	for index in range(3): content[index] = maxf(0,content[index])
	var origin := leading(padding+border)
	scroll_geometry = ScrollbarGeometry.snapshot(Rect2(Vector2(origin.x,origin.y),Vector2(content.x,content.y)),scroll_axes,length_specs,viewport_size)
	content.x = scroll_geometry.viewport.size.x
	content.y = scroll_geometry.viewport.size.y
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
	var budget := dimension_budget(reference)
	for child in children:
		child.prepare(reference,viewport_size,budget)
		child.measure()
	if not _reported_full_percent and children.size()>1:
		var main_name: String = ["width","height","depth"][axis]
		for child in children:
			var spec: Dictionary = child.length_specs.get(main_name,{})
			if spec.get("unit","")=="%" and spec.get("value",0)>=100:
				_reported_full_percent = true
				push_warning("Estragon "+main_name+"=100% consumes the full definite parent "+("dimension budget" if dimension_budget_enabled and strategy!="wrap" and axis<2 else "content axis")+", not remaining space; siblings may overflow. Use an auto-sized Spacer with grow=1 for remaining space")
				break
	var layout_content := content
	for index in range(2):
		if scroll_axes[index]>0: layout_content[index] = maxf(content[index],natural_extent[index]-leading(padding+border)[index]-trailing(padding+border)[index])
	var items := _items()
	var policy := alignment.duplicate()
	if center: policy[axis] = "center"
	if strategy=="wrap":
		var wrap_basis := _wrap_basis()
		slots = WrapPolicy.layout(items,layout_content,axis,physical_gaps,policy,align_content,Vector2(1 if reference.x>=0 or axis==0 and wrap_basis.x>=0 else 0,1 if reference.y>=0 or axis==1 and wrap_basis.y>=0 else 0)).slots
	else:
		slots = StackPolicy.slots(items,layout_content,axis,_main_gap(),policy)
	if strategy=="grid":
		policy_result = _grid(items,reference)
		if policy_result.has("error"): return
		slots = policy_result.slots
	for index in range(children.size()):
		var child = children[index]
		var slot: Dictionary = slots[index]
		var next: Vector3 = leading(padding+border)+slot.position+child.length_offset
		if child.offset != next or child.arrange_count == 0:
			child.offset = next
			child.placed.emit(next)
		var authority := Vector3.ZERO
		for cross in range(3):
			if strategy=="grid" and cross<2 and policy[cross]=="stretch" and child.requested[cross]<0 and independent_axis(cross): authority[cross] = 1
			elif strategy!="grid" and cross!=axis and StackPolicy.cross_alignment(items[index],policy[cross],cross)=="stretch" and child.requested[cross]<0 and independent_axis(cross): authority[cross] = 1
		for scrolling_axis in range(2):
			if scroll_axes[scrolling_axis]>0:
				authority[scrolling_axis] = 1 if independent_axis(scrolling_axis) and child.requested[scrolling_axis]<0 and (child.grow>0 or child.fill[scrolling_axis]>0) else 0
		child.arrange(slot.extent,authority)
	arranged.emit(size)

func content_extent() -> Vector2:
	var extent := Vector3.ZERO
	for child in children:
		var end: Vector3 = child.offset+child.overflow_extent()+trailing(child.margin)-leading(padding+border)
		for index in range(2): extent[index] = maxf(extent[index],end[index])
	return Vector2(extent.x,extent.y)
