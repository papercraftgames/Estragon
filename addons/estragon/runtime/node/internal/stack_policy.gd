@tool
extends RefCounted
## Pure parent-owned sequential slot strategy. Input is measured placement data;
## output is border-box slots, before child-authored additive transforms.
## Wrap/Grid will assign the same slots without using this cursor algorithm.
static func slots(items: Array, content: Vector3, axis: int, gap: float, alignment: Array) -> Array:
	var extents: Array = []
	var occupied := gap * maxi(0,items.size()-1)
	var weight := 0.0
	var flexible: Array = []
	for item in items:
		var extent: Vector3 = item.preferred
		for index in range(3): extent[index] = maxf(extent[index],item.minimum[index])
		for index in range(3):
			if index != axis and item.requested[index]<0 and cross_alignment(item,alignment[index],index)=="stretch":
				extent[index] = maxf(item.minimum[index],content[index]-item.outer[index])
		extent = limit_extent(extent,item)
		# Native fill remains a zero-basis allocation with a native minimum floor.
		if item.fill[axis]>0 and item.requested[axis]<0: extent[axis] = 0.0
		extents.append(extent)
		occupied += extent[axis]+item.outer[axis]
		if item.requested[axis]<0 and (item.grow>0 or item.fill[axis]>0):
			weight += item.grow if item.grow>0 else 1.0
			flexible.append(extents.size()-1)
	var remaining := maxf(0,content[axis]-occupied)
	var shares := {}
	# Preserve native expand minimum water-filling (70/20 minima in 100 ->70/30).
	while not flexible.is_empty():
		var constrained := false
		for index in flexible.duplicate():
			var item: Dictionary = items[index]
			var part: float = remaining*(item.grow if item.grow>0 else 1.0)/weight
			var cap: Vector3 = item.get("maximum",Vector3(-1,-1,-1))
			if cap[axis]>=0 and part>maxf(0,maxf(item.minimum[axis],cap[axis])-extents[index][axis]):
				shares[index] = maxf(0,maxf(item.minimum[axis],cap[axis])-extents[index][axis])
				remaining = maxf(0,remaining-shares[index])
				weight -= item.grow if item.grow>0 else 1.0
				flexible.erase(index)
				constrained = true
				continue
			var floor_extra: float = maxf(0,item.minimum[axis]-extents[index][axis])
			if floor_extra>part:
				shares[index] = floor_extra
				remaining = maxf(0,remaining-floor_extra)
				weight -= item.grow if item.grow>0 else 1.0
				flexible.erase(index)
				constrained = true
		if not constrained:
			for index in flexible:
				var item: Dictionary = items[index]
				shares[index] = remaining*(item.grow if item.grow>0 else 1.0)/weight
			break
	# Growth/native minimum water-filling is complete before distribution. Count
	# final extents and margins afresh: none of the allocated shares is free twice.
	occupied = gap * maxi(0,items.size()-1)
	for index in range(items.size()):
		var extent: Vector3 = extents[index]
		if shares.has(index): extent[axis] += shares[index]
		extents[index] = extent
		occupied += extent[axis]+items[index].outer[axis]
	var free := maxf(0,content[axis]-occupied)
	var cursor := free * factor(alignment[axis])
	var extra_gap := 0.0
	var count := items.size()
	if alignment[axis]=="space-between" and count>1: extra_gap = free/(count-1)
	elif alignment[axis]=="space-around" and count>0:
		extra_gap = free/count
		cursor = extra_gap/2
	elif alignment[axis]=="space-evenly" and count>0:
		extra_gap = free/(count+1)
		cursor = extra_gap
	var result: Array = []
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var extent: Vector3 = extents[index]
		var position: Vector3 = item.leading
		position[axis] += cursor
		for cross in range(3):
			if cross != axis: position[cross] += maxf(0,content[cross]-extent[cross]-item.outer[cross])*factor(cross_alignment(item,alignment[cross],cross))
		result.append({"position":position,"extent":extent})
		cursor += extent[axis]+item.outer[axis]+gap+extra_gap
	return result
static func cross_alignment(item: Dictionary, parent: String, index: int) -> String:
	var own: String = item.get("align_self","auto")
	if own!="auto": return own
	return "stretch" if item.stretch>0 or item.fill[index]>0 else parent
static func factor(value: String) -> float:
	return 0.5 if value=="center" else (1.0 if value=="end" else 0.0)

static func limit_extent(extent: Vector3, item: Dictionary) -> Vector3:
	var cap: Vector3 = item.get("maximum",Vector3(-1,-1,-1))
	for index in range(3):
		if cap[index]>=0: extent[index] = minf(extent[index],cap[index])
		extent[index] = maxf(extent[index],item.minimum[index])
	return extent
