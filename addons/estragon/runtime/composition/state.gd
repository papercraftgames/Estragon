@tool
extends Resource
## Framework-owned shared scope stack; never stored on application objects.
var scopes: Array = []
var records: Dictionary = {}
var dirty: Array = []
var pending := false
var flushing := false
func enqueue(record) -> void:
	if not dirty.has(record): dirty.append(record)
	if not pending and not flushing:
		pending = true
		drain.call_deferred()
func _parent_first(a, b) -> bool:
	return a.depth() < b.depth()
func drain() -> void:
	pending = false
	flushing = true
	var passes := 0
	while not dirty.is_empty():
		dirty.sort_custom(_parent_first)
		var record = dirty.pop_front()
		record.queued = false
		record._flush()
		passes += 1
		if passes > 1024:
			push_error("Composition scheduler exceeded bounded work; remove render-side mutations")
			for queued in dirty: queued.suspend()
			dirty.clear()
			break
	flushing = false
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
func unmount(host: Node, rescue: Node = null) -> void:
	var id := host.get_instance_id()
	if records.has(id):
		records[id].dispose(true,rescue)
		records.erase(id)
