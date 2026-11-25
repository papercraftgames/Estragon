@tool
extends Resource
## Weak, external observation graph. No user-object metadata or second scheduler.
var records: Dictionary = {}
var _building: Dictionary = {}
var _emitting := false
var _visited: Dictionary = {}
var _hydrating: Dictionary = {}
func initializing(value: Object) -> bool:
	return _hydrating.has(value.get_instance_id())
class Edge extends RefCounted:
	var parent: WeakRef
	var manager: WeakRef
	func changed() -> void:
		var source = parent.get_ref()
		var state = manager.get_ref()
		if source!=null and state!=null: state.notify(source)

func fields(value: Object) -> Dictionary:
	var output := {}
	var script = value.get_script()
	while script is Script:
		for key in script.get_script_constant_map():
			if str(key).begins_with("_GOGO_BINDABLE_PROPERTIES_"):
				output.merge(script.get_script_constant_map()[key],false)
		script = script.get_base_script()
	return output
func is_collection(value) -> bool:
	return typeof(value)==TYPE_OBJECT and is_instance_valid(value) and value.get_script()==load(get_script().resource_path.get_base_dir().path_join("array_collection.gd"))
func event(value: Object) -> StringName:
	return &"changed" if is_collection(value) else &"_gogo_data_changed" if value.has_signal(&"_gogo_data_changed") else &""
func children(value: Object) -> Array:
	if is_collection(value): return value._values.duplicate()
	var output: Array = []
	for name in fields(value): output.append(value.get(name))
	return output
func refresh(value: Object) -> void:
	if event(value)==&"": return
	var id := value.get_instance_id()
	if _building.has(id): return
	_building[id] = true
	prune()
	var record: Dictionary = records.get(id,{"source":weakref(value),"edges":{}})
	var next := {}
	for child in children(value):
		if typeof(child)!=TYPE_OBJECT or not is_instance_valid(child) or event(child)==&"": continue
		var child_id: int = child.get_instance_id()
		if next.has(child_id): continue # Duplicate membership has one subscription.
		refresh(child)
		var child_event := event(child)
		if record.edges.has(child_id):
			next[child_id] = record.edges[child_id]
			continue
		var edge := Edge.new()
		edge.parent = weakref(value)
		edge.manager = weakref(self)
		var callback := Callable(edge,"changed")
		next[child_id] = [weakref(child),child_event,callback,edge]
		if not child.is_connected(child_event,callback): child.connect(child_event,callback)
	for child_id in record.edges:
		if not next.has(child_id): _disconnect(record.edges[child_id])
	record.edges = next
	records[id] = record
	_building.erase(id)
func prune() -> void:
	for id in records.keys():
		if records[id].source.get_ref()!=null: continue
		for edge in records[id].edges.values(): _disconnect(edge)
		records.erase(id)
func _disconnect(edge: Array) -> void:
	var source = edge[0].get_ref()
	if source!=null and source.is_connected(edge[1],edge[2]): source.disconnect(edge[1],edge[2])
func notify(value: Object) -> void:
	var outer := not _emitting
	if outer: _emitting = true; _visited.clear()
	var id := value.get_instance_id()
	if not _visited.has(id):
		_visited[id] = true
		value.emit_signal(event(value))
	if outer: _emitting = false; _visited.clear()
func can_attach(owner: Object, value, seen: Dictionary = {}) -> bool:
	if typeof(value)!=TYPE_OBJECT or not is_instance_valid(value): return true
	if value==owner: return false
	var id: int = value.get_instance_id()
	if seen.has(id): return true
	seen[id] = true
	if event(value)!=&"":
		for child in children(value):
			if not can_attach(owner,child,seen): return false
	return true
func hydrate(value, type, path: String = "data", ancestors: Array = []) -> Dictionary:
	if type==null: return _plain(value,path,ancestors)
	if type is Script:
		var shape := false
		for name in type.get_script_constant_map():
			if str(name).begins_with("_GOGO_DATA_SHAPE_"): shape = true
		if not shape or not ClassDB.is_parent_class(type.get_instance_base_type(),"RefCounted"): return _error(path,"type is not a Gogo plain-data shape")
		if value==null: return {"ok":true,"value":null}
		if typeof(value)==TYPE_OBJECT and is_instance_valid(value) and is_instance_of(value,type): return {"ok":true,"value":value}
		if not value is Dictionary: return _error(path,"expected typed data Dictionary or model")
		if _contains(ancestors,value): return _error(path,"cyclic data")
		var model = type.new()
		if event(model)==&"": return _error(path,"type is not a Gogo data shape")
		var properties := fields(model)
		var next := {}
		var branch := ancestors+[value]
		for key in value:
			if not key is String or not properties.has(key): return _error(path,"unknown field "+str(key))
			var target = _field_type(model,key,properties[key])
			var result := hydrate(value[key],target,path+"."+key,branch)
			if not result.ok: return result
			next[key] = result.value
		# Only publish the completely validated detached model.
		_hydrating[model.get_instance_id()] = true
		for key in next: model.set(key,next[key])
		_hydrating.erase(model.get_instance_id())
		refresh(model)
		return {"ok":true,"value":model}
	if type is Array and type.size()==1:
		if value==null: return {"ok":true,"value":null}
		if is_collection(value) and value.element_type==type[0]: return {"ok":true,"value":value}
		if not value is Array: return _error(path,"expected collection Array")
		if _contains(ancestors,value): return _error(path,"cyclic data")
		var next: Array = []
		for index in range(value.size()):
			var result := hydrate(value[index],type[0],path+"[%d]"%index,ancestors+[value])
			if not result.ok: return result
			next.append(result.value)
		return {"ok":true,"value":load(get_script().resource_path.get_base_dir().path_join("array_collection.gd")).new(type[0],next)}
	if type is Dictionary and type.has("array"):
		if not value is Array: return _error(path,"expected typed Array")
		if _contains(ancestors,value): return _error(path,"cyclic data")
		var next: Array = []
		for index in range(value.size()):
			var result := hydrate(value[index],type.array,path+"[%d]"%index,ancestors+[value])
			if not result.ok: return result
			next.append(result.value)
		return {"ok":true,"value":Array(next,TYPE_OBJECT if type.array is Script else int(type.array),&"",type.array if type.array is Script else null)}
	if int(type)==TYPE_FLOAT and typeof(value)==TYPE_INT: value = float(value)
	if int(type)==TYPE_INT and typeof(value)==TYPE_FLOAT and is_finite(value) and value==floor(value): value = int(value)
	if typeof(value)!=int(type): return _error(path,"incompatible value type "+str(typeof(value)))
	return _plain(value,path,ancestors)
func _declared_type(model: Object, name: String):
	var script = model.get_script()
	while script is Script:
		for key in script.get_script_constant_map():
			if str(key).begins_with("_GOGO_DATA_TYPES_") and script.get_script_constant_map()[key].has(name): return script.get_script_constant_map()[key][name]
		script = script.get_base_script()
	return null
func _field_type(model: Object, name: String, _declaration: String):
	var declared = _declared_type(model,name)
	if declared!=null: return declared
	for property in model.get_property_list():
		if property.name==name: return property.type
	return TYPE_NIL
func to_data(value):
	var result := _encode(value,"data",[])
	if not result.ok: push_error(result.error); return null
	return result.value
func _encode(value, path: String, ancestors: Array) -> Dictionary:
	if typeof(value)==TYPE_OBJECT:
		if not is_instance_valid(value): return {"ok":true,"value":null}
		if _contains(ancestors,value): return _error(path,"cyclic model")
		if is_collection(value): return _encode(value._values,path,ancestors+[value])
		if event(value)==&"": return _error(path,"unsupported native Object")
		var output := {}
		for name in fields(value):
			var result := _encode(value.get(name),path+"."+name,ancestors+[value])
			if not result.ok: return result
			output[name] = result.value
		return {"ok":true,"value":output}
	return _plain(value,path,ancestors,true)
func _plain(value, path: String, ancestors: Array, encode: bool = false) -> Dictionary:
	if value is Array or value is Dictionary:
		if _contains(ancestors,value): return _error(path,"cyclic plain data")
		var output = [] if value is Array else {}
		for key in range(value.size()) if value is Array else value.keys():
			if value is Dictionary and not key is String: return _error(path,"Dictionary keys must be Strings")
			var result := _encode(value[key],path+"."+str(key),ancestors+[value]) if encode else _plain(value[key],path+"."+str(key),ancestors+[value])
			if not result.ok: return result
			if output is Array: output.append(result.value)
			else: output[key] = result.value
		return {"ok":true,"value":output}
	if typeof(value) not in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]: return _error(path,"unsupported plain data value")
	if typeof(value)==TYPE_FLOAT and not is_finite(value): return _error(path,"non-finite plain data number")
	return {"ok":true,"value":value}
func _contains(values: Array, value) -> bool:
	for ancestor in values:
		if is_same(ancestor,value): return true
	return false
func _error(path: String, message: String) -> Dictionary:
	return {"ok":false,"error":path+": "+message}

func value(incoming, type, previous = null, path: String = "data"):
	var result := hydrate(incoming,type,path)
	if not result.ok:
		push_error(result.error)
		return previous
	return result.value
func iterate(value):
	return value
func assign(owner: Object, field: String, incoming, path: String = "data", _native_proof: Callable = Callable()) -> void:
	var shape := fields(owner)
	if not shape.has(field) and _declared_type(owner,field)==null:
		owner.set(field,incoming)
		return
	var result := hydrate(incoming,_field_type(owner,field,shape.get(field,"")),path+"."+field)
	if not result.ok: push_error(result.error); return
	if not can_attach(owner,result.value): push_error(path+": cyclic data assignment"); return
	owner.set(field,result.value)
