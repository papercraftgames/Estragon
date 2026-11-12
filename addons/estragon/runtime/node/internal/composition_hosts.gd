@tool
extends Resource
## External weak lookup only. Never serialized onto authored Nodes/Resources.
var hosts: Dictionary = {}
func find(node: Node):
	if node == null: return null
	var reference = hosts.get(node.get_instance_id())
	return reference.get_ref() if reference != null else null
func add(node: Node, coordinator: RefCounted) -> void:
	hosts[node.get_instance_id()] = weakref(coordinator)
func remove(node: Node, coordinator: RefCounted) -> void:
	if find(node) == coordinator: hosts.erase(node.get_instance_id())

# E08 borrowed scene references. All ownership/order bookkeeping lives here,
# never on authored objects. Native parents, owners and sibling order stay put.
var projections: Dictionary = {}
var orders: Dictionary = {}
var order_owners: Dictionary = {}
func projected_parent(node: Node) -> Node:
	var entry = projections.get(node.get_instance_id())
	return entry.parent.get_ref() if entry != null else null
func children(parent: Node, native_children: Array) -> Array:
	var result: Array = []
	for reference in orders.get(parent.get_instance_id(),[]):
		var node = reference.get_ref()
		if node != null:
			var logical = projected_parent(node)
			if logical == null or logical == parent: result.append(node)
	for node in native_children:
		var logical = projected_parent(node)
		if not result.has(node) and (logical == null or logical == parent): result.append(node)
	return result
func _coordinator(node: Node):
	if node == null: return null
	return node._get_layout_coordinator() if node.has_method("_get_layout_coordinator") else find(node)
func _placement(node: Node, parent: Node):
	var coordinator = _coordinator(node)
	if coordinator == null or coordinator._mode == coordinator.Mode.ENTRY or coordinator.participant(parent) == null: return null
	return coordinator
func _same_projection(owner: RefCounted, next: Dictionary, next_orders: Dictionary) -> bool:
	var count := 0
	for id in projections:
		var item: Dictionary = projections[id]
		if item.claim.get_ref() != owner: continue
		count += 1
		if not next.has(id) or item.node.get_ref() != next[id][0] or item.parent.get_ref() != next[id][1] or item.native_parent.get_ref() != next[id][0].get_parent(): return false
	if count != next.size(): return false
	count = 0
	for id in order_owners:
		if order_owners[id].get_ref() != owner: continue
		count += 1
		if not next_orders.has(id) or orders[id].size() != next_orders[id].size(): return false
		for index in range(orders[id].size()):
			if orders[id][index].get_ref() != next_orders[id][index].get_ref(): return false
	return count == next_orders.size()
func replace_projection(owner: RefCounted, next: Dictionary, next_orders: Dictionary) -> void:
	if _same_projection(owner,next,next_orders):
		for item in next.values():
			var coordinator = _placement(item[0],item[1])
			if coordinator != null and coordinator.scope_root() != null: coordinator._place(coordinator.model.offset)
		return
	var affected: Array = []
	var refresh: Array = []
	# Detach changed model edges before adopting into another model. Core remains
	# the sole authority for one-parent/cycle validation and layout arithmetic.
	for id in projections:
		var item: Dictionary = projections[id]
		if item.claim.get_ref() != owner: continue
		for reference in [item.parent,item.native_parent]:
			var node = reference.get_ref()
			if node != null and not affected.has(node): affected.append(node)
	for id in next:
		var prior = projections.get(id)
		if prior != null and prior.parent.get_ref() != null and not affected.has(prior.parent.get_ref()): affected.append(prior.parent.get_ref())
		var item: Array = next[id]
		for node in [item[0].get_parent(),item[1]]:
			if node != null and not affected.has(node): affected.append(node)
	for node in affected:
		var coordinator = _coordinator(node)
		if coordinator != null and coordinator.active: coordinator.model.set_children([])
	for id in projections.keys():
		var item: Dictionary = projections[id]
		if item.claim.get_ref() != owner: continue
		var node = item.node.get_ref()
		if not next.has(id):
			projections.erase(id)
			if node != null:
				if node.get_parent() == item.native_parent.get_ref() and item.position != null: node.position = item.position
				refresh.append(node)
	for id in next:
		var node: Node = next[id][0]
		var parent: Node = next[id][1]
		if not projections.has(id) or projections[id].claim.get_ref() != owner:
			var coordinator = _placement(node,parent)
			projections[id] = {"node":weakref(node),"native_parent":weakref(node.get_parent()),"position":node.position if coordinator != null and (node is Node2D or node is Node3D) else null,"claim":weakref(owner),"parent":weakref(parent)}
		else:
			var item: Dictionary = projections[id]
			if _placement(node,parent) == null and item.position != null:
				if node.get_parent() == item.native_parent.get_ref(): node.position = item.position
				item.position = null
			elif _placement(node,parent) != null and item.position == null: item.position = node.position
			item.parent = weakref(parent)
		refresh.append(node)
	for id in order_owners.keys():
		if order_owners[id].get_ref() == owner:
			orders.erase(id)
			order_owners.erase(id)
	for id in next_orders:
		orders[id] = next_orders[id]
		order_owners[id] = weakref(owner)
	for node in affected:
		var coordinator = _coordinator(node)
		if coordinator != null: coordinator._sync()
	for node in refresh: _refresh_scope(node)
func _refresh_scope(node: Node) -> void:
	if node.has_method("_layout_scope_changed"): node._layout_scope_changed()
	for child in node.get_children(): _refresh_scope(child)
func refresh_positions(root: RefCounted) -> void:
	# Called after event-driven arrange, never per frame. A logical ancestor may
	# move without changing this child's model offset, so refresh its translation.
	for item in projections.values():
		var node = item.node.get_ref()
		var coordinator = _coordinator(node)
		if coordinator != null and coordinator._mode != coordinator.Mode.ENTRY and coordinator.scope_root() == root: coordinator._place(coordinator.model.offset)
