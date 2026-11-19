extends RefCounted
## One invocation record under the existing owner Computation; never a Node.
var parent: WeakRef
var children: Dictionary = {}
var reads: Dictionary = {}
var arguments: Array = []
var target: Variant
var result: Variant
var dirty := true
var keyed := false
var initialized := false
func invalidate() -> void:
	if dirty: return
	dirty = true
	var ancestor = parent.get_ref() if parent!=null else null
	if ancestor!=null: ancestor.invalidate()
static func argument(value):
	if typeof(value)==TYPE_OBJECT: return weakref(value) if is_instance_valid(value) else null
	return value
static func equivalent(previous, value) -> bool:
	if previous is WeakRef: return is_instance_valid(value) and previous.get_ref()==value
	if typeof(previous)!=typeof(value): return false
	if value is Array or value is Dictionary: return is_same(previous,value)
	return previous==value
func matches(values: Array) -> bool:
	if arguments.size()!=values.size(): return false
	for index in range(values.size()):
		if not equivalent(arguments[index],values[index]): return false
	return true
func collect(output: Dictionary, index: Dictionary) -> void:
	for key in reads:
		output[key] = reads[key]
		if not index.has(key): index[key] = []
		index[key].append(self)
	for bucket in children.values():
		for child in bucket: child.collect(output,index)
