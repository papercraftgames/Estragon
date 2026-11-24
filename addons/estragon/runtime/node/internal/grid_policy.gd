@tool
extends RefCounted
## Pure track floors, fractional allocation and native border-box slots.
const Length = preload("length.gd")
const Stack = preload("stack_policy.gd")
static func tracks(specs: Array, items: Array, placements: Array, axis: int, reference: float, viewport: Vector2, gap: float) -> Array:
	var sizes: Array = []
	var flexible: Array = []
	var weight := 0.0
	for index in range(specs.size()):
		var spec: Dictionary = specs[index]
		sizes.append(0.0 if spec.unit in ["auto","fr"] else maxf(0,Length.resolve(spec,reference,viewport)))
		if spec.unit=="fr":
			flexible.append(index)
			weight += spec.value
	for i in range(items.size()):
		var rect: Dictionary = placements[i]
		var start: int = rect.column if axis==0 else rect.row
		var span: int = rect.column_span if axis==0 else rect.row_span
		var occupied := gap*(span-1)
		var eligible: Array = []
		var fractions_only := true
		for index in range(start,start+span):
			occupied += sizes[index]
			if specs[index].unit in ["auto","fr"]: eligible.append(index)
			if specs[index].unit!="fr": fractions_only = false
		var contribution: float = items[i].get("contribution",items[i].preferred)[axis]
		var viewport_floor: float = items[i].get("scroll_floor",Vector3(-1,-1,-1))[axis]
		# A definite fraction cell assigns a scrolling viewport. Its hidden
		# content is not a minimum viewport size; auto rows remain intrinsic.
		if reference>=0 and fractions_only and viewport_floor>=0: contribution = viewport_floor
		var deficit: float = maxf(0,maxf(contribution,items[i].minimum[axis])+items[i].outer[axis]-occupied)
		for index in eligible: sizes[index] += deficit/eligible.size()
	if reference>=0:
		var budget := reference-gap*maxi(0,sizes.size()-1)
		for index in range(sizes.size()):
			if not flexible.has(index): budget -= sizes[index]
		# Fractional tracks water-fill above intrinsic floors, never shrink them.
		while not flexible.is_empty():
			var constrained := false
			for index in flexible.duplicate():
				if sizes[index]>maxf(0,budget)*specs[index].value/weight:
					budget -= sizes[index]
					weight -= specs[index].value
					flexible.erase(index)
					constrained = true
			if not constrained:
				for index in flexible: sizes[index] = maxf(0,budget)*specs[index].value/weight
				break
	return sizes
static func layout(items: Array, definition: Dictionary, content: Vector3, gaps: Vector2, alignment: Array, viewport: Vector2) -> Dictionary:
	var columns := tracks(definition.columns,items,definition.placements,0,content.x,viewport,gaps.x)
	var rows := tracks(definition.rows,items,definition.placements,1,content.y,viewport,gaps.y)
	var natural := Vector3(gaps.x*maxi(0,columns.size()-1),gaps.y*maxi(0,rows.size()-1),0)
	for value in columns: natural.x += value
	for value in rows: natural.y += value
	var slots: Array = []
	for index in range(items.size()):
		var rect: Dictionary = definition.placements[index]
		var origin := Vector3.ZERO
		var cell := Vector3.ZERO
		for col in range(rect.column): origin.x += columns[col]+gaps.x
		for row in range(rect.row): origin.y += rows[row]+gaps.y
		for col in range(rect.column,rect.column+rect.column_span): cell.x += columns[col]
		for row in range(rect.row,rect.row+rect.row_span): cell.y += rows[row]
		cell += Vector3(gaps.x*(rect.column_span-1),gaps.y*(rect.row_span-1),0)
		var item: Dictionary = items[index]
		var extent: Vector3 = item.preferred
		var position: Vector3 = origin+item.leading
		for axis in range(2):
			extent[axis] = maxf(extent[axis],item.minimum[axis])
			if item.requested[axis]<0 and alignment[axis]=="stretch": extent[axis] = maxf(item.minimum[axis],cell[axis]-item.outer[axis])
			extent = Stack.limit_extent(extent,item)
			position[axis] += maxf(0,cell[axis]-extent[axis]-item.outer[axis])*Stack.factor(alignment[axis])
		slots.append({"position":position,"extent":extent})
	return {"extent":natural,"slots":slots,"columns":columns,"rows":rows,"placements":definition.placements}
