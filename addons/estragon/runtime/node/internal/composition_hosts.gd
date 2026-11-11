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
