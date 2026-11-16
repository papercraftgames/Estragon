@tool
extends RefCounted
## Pure line grouping and slot composition over the existing StackPolicy.
const Stack = preload("stack_policy.gd")
const CONTENT := ["start","center","end","space-between","space-around","space-evenly","stretch"]
static func layout(items: Array, content: Vector3, axis: int, gaps: Vector2, alignment: Array, align_content: String, definite: Vector2) -> Dictionary:
	var cross := 1-axis
	var lines: Array = []
	var current: Array = []
	var used := 0.0
	for index in range(items.size()):
		var item: Dictionary = items[index]
		var main: float = maxf(item.preferred[axis],item.minimum[axis])+item.outer[axis]
		if definite[axis]>0 and not current.is_empty() and used+gaps[axis]+main>content[axis]:
			lines.append(current)
			current = []
			used = 0
		if not current.is_empty(): used += gaps[axis]
		current.append(index)
		used += main
	if not current.is_empty(): lines.append(current)
	var heights: Array = []
	var natural := Vector3.ZERO
	for line in lines:
		var width := gaps[axis]*maxi(0,line.size()-1)
		var height := 0.0
		for index in line:
			var item: Dictionary = items[index]
			width += maxf(item.preferred[axis],item.minimum[axis])+item.outer[axis]
			height = maxf(height,maxf(item.preferred[cross],item.minimum[cross])+item.outer[cross])
		natural[axis] = maxf(natural[axis],width)
		natural[cross] += height
		heights.append(height)
	natural[cross] += gaps[cross]*maxi(0,lines.size()-1)
	var free: float = maxf(0,content[cross]-natural[cross]) if definite[cross]>0 else 0.0
	var offset := free*Stack.factor(align_content)
	var added := 0.0
	if align_content=="space-between" and lines.size()>1: added = free/(lines.size()-1)
	elif align_content=="space-around" and not lines.is_empty():
		added = free/lines.size()
		offset = added/2
	elif align_content=="space-evenly" and not lines.is_empty():
		added = free/(lines.size()+1)
		offset = added
	var slots: Array = []
	slots.resize(items.size())
	for line_index in range(lines.size()):
		var line: Array = lines[line_index]
		var line_items: Array = []
		for index in line: line_items.append(items[index])
		var extent := content
		extent[axis] = content[axis] if definite[axis]>0 else natural[axis]
		extent[cross] = heights[line_index]+(free/lines.size() if align_content=="stretch" else 0.0)
		var placed := Stack.slots(line_items,extent,axis,gaps[axis],alignment)
		for i in range(line.size()):
			placed[i].position[cross] += offset
			slots[line[i]] = placed[i]
		offset += extent[cross]+gaps[cross]+added
	return {"extent":natural,"slots":slots,"lines":lines}
