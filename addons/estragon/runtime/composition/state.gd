@tool
extends Resource
## Framework-owned shared scope stack; never stored on application objects.
var scopes: Array = []
var records: Dictionary = {}
func begin() -> void:
	scopes.append({})
func observe(source: Object, event: StringName) -> void:
	if scopes.is_empty(): return
	var key := str(source.get_instance_id())+":"+str(event)
	scopes.back()[key] = [weakref(source),event]
func finish() -> Dictionary:
	return scopes.pop_back()
func lifecycle(host: Node, what: int) -> void:
	if Engine.is_editor_hint(): return
	var id := host.get_instance_id()
	if what == Node.NOTIFICATION_READY:
		if not records.has(id):
			var record = preload("res://addons/estragon/runtime/composition/computation.gd").new(host,self)
			records[id] = record
			record.schedule()
	elif what == Node.NOTIFICATION_ENTER_TREE and records.has(id):
		records[id].resume()
	elif what == Node.NOTIFICATION_EXIT_TREE and records.has(id):
		records[id].suspend()
	elif what == NOTIFICATION_PREDELETE and records.has(id):
		records[id].dispose(false)
		records.erase(id)
func unmount(host: Node) -> void:
	var id := host.get_instance_id()
	if records.has(id):
		records[id].dispose(true)
		records.erase(id)
