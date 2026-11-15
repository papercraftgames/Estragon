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
			if index != axis and item.requested[index]<0 and (item.stretch>0 or item.fill[index]>0 or alignment[index]=="stretch"):
				extent[index] = maxf(item.minimum[index],content[index]-item.outer[index])
		# Native fill remains a zero-basis allocation with a native minimum floor.
		if item.fill[axis]>0 and item.requested[axis]<0: extent[axis] = 0.0
		extents.append(extent)
		occupied += extent[axis]+item.outer[axis]
		if item.requested[axis]<0 and (item.grow>0 or item.fill[axis]>0):
			weight += item.grow if item.grow>0 else 1.0
			flexible.append(extents.size()-1)
	var remaining := maxf(0,content[axis]-occupied)
	var shares := {}
	var total_weight := weight
	# Preserve native expand minimum water-filling (70/20 minima in 100 ->70/30).
	while not flexible.is_empty():
		var constrained := false
		for index in flexible.duplicate():
			var item: Dictionary = items[index]
			var part: float = remaining*(item.grow if item.grow>0 else 1.0)/weight
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
	var cursor := maxf(0,content[axis]-occupied) * factor(alignment[axis]) if total_weight==0 else 0.0
	var result: Array = []
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var extent: Vector3 = extents[index]
		if shares.has(index): extent[axis] += shares[index]
		var position: Vector3 = item.leading
		position[axis] += cursor
		for cross in range(3):
			if cross != axis: position[cross] += maxf(0,content[cross]-extent[cross]-item.outer[cross])*factor(alignment[cross])
		result.append({"position":position,"extent":extent})
		cursor += extent[axis]+item.outer[axis]+gap
	return result
static func factor(value: String) -> float:
	return 0.5 if value=="center" else (1.0 if value=="end" else 0.0)
