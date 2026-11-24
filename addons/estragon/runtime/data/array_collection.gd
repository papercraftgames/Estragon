@tool
extends RefCounted
## Optional ordered observable data. Native Arrays remain ordinary values.
signal changed
signal structure_changed
const Data = preload("state.tres")
var _values: Array = []
var element_type: Variant
var _batch := 0
var _pending := false

func _init(type: Variant = null, values: Array = []) -> void:
	element_type = type
	reset(values)
func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE: Data.prune()

func size() -> int:
	_observe()
	return _values.size()
func is_empty() -> bool:
	return size()==0
func at(index: int):
	_observe()
	return _values[index]
func to_array() -> Array:
	_observe()
	return _values.duplicate()
func map(callback: Callable) -> Array:
	_observe()
	var output: Array = []
	var manager = preload("../composition/state.tres")
	for item in _values:
		# Inline callbacks retain compiler-owned lexical call sites; named Gogo
		# render functions need the same invocation boundary as an authored call.
		output.append(callback.call(item) if callback.is_custom() else manager.call_at("$collection-map:"+str(get_instance_id()),callback,[item]))
	return output
func _iter_init(iterator: Array) -> bool:
	_observe()
	iterator[0] = 0
	return not _values.is_empty()
func _iter_next(iterator: Array) -> bool:
	iterator[0] += 1
	return iterator[0]<_values.size()
func _iter_get(index):
	return _values[index[0] if index is Array else index]
func append(value) -> bool:
	return insert(_values.size(),value)
func insert(index: int, value) -> bool:
	if index<0 or index>_values.size(): return _reject("insert index out of range")
	var converted: Dictionary = Data.hydrate(value,element_type,"ArrayCollection[%d]" % index)
	if not converted.ok: return _reject(converted.error)
	if not Data.can_attach(self,converted.value): return _reject("cyclic collection membership")
	_values.insert(index,converted.value)
	_mutated()
	return true
func remove_at(index: int) -> bool:
	if index<0 or index>=_values.size(): return _reject("remove index out of range")
	_values.remove_at(index)
	_mutated()
	return true
func replace(index: int, value) -> bool:
	if index<0 or index>=_values.size(): return _reject("replace index out of range")
	var converted: Dictionary = Data.hydrate(value,element_type,"ArrayCollection[%d]" % index)
	if not converted.ok: return _reject(converted.error)
	if not Data.can_attach(self,converted.value): return _reject("cyclic collection membership")
	if is_same(_values[index],converted.value): return true
	_values[index] = converted.value
	_mutated()
	return true
func move(from: int, to: int) -> bool:
	if from<0 or from>=_values.size() or to<0 or to>=_values.size(): return _reject("move index out of range")
	if from==to: return true
	var value = _values.pop_at(from)
	_values.insert(to,value)
	_mutated()
	return true
func reset(values: Array) -> bool:
	var next: Array = []
	for index in range(values.size()):
		var converted: Dictionary = Data.hydrate(values[index],element_type,"ArrayCollection[%d]" % index)
		if not converted.ok: return _reject(converted.error)
		if not Data.can_attach(self,converted.value): return _reject("cyclic collection membership")
		next.append(converted.value)
	if next==_values: return true
	_values = next
	_mutated()
	return true
func begin_update() -> void:
	_batch += 1
func end_update() -> void:
	if _batch==0:
		_reject("end_update without begin_update")
		return
	_batch -= 1
	if _batch==0 and _pending: _publish()
func _mutated() -> void:
	Data.refresh(self)
	_pending = true
	if _batch==0: _publish()
func _publish() -> void:
	_pending = false
	structure_changed.emit()
	Data.notify(self)
func _observe() -> void:
	preload("../composition/state.tres").observe(self,&"structure_changed")
func _reject(message: String) -> bool:
	push_error("ArrayCollection: "+message)
	return false
func to_data():
	return Data.to_data(self)
