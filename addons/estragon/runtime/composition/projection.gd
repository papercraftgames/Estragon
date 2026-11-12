extends RefCounted
## Tree observation is scoped to computations that actually read native children.
var computation: WeakRef
var host: WeakRef
var watching := false
func _init(record: RefCounted, owner: Node) -> void:
	computation = weakref(record)
	host = weakref(owner)
func start() -> void:
	if watching: return
	var node = host.get_ref()
	if node == null: return
	watching = true
	node.child_entered_tree.connect(changed)
	node.child_exiting_tree.connect(changed)
	if node.has_signal("child_order_changed"): node.connect("child_order_changed",ordered)
func stop() -> void:
	if not watching: return
	watching = false
	var node = host.get_ref()
	if node == null: return
	if node.child_entered_tree.is_connected(changed): node.child_entered_tree.disconnect(changed)
	if node.child_exiting_tree.is_connected(changed): node.child_exiting_tree.disconnect(changed)
	if node.has_signal("child_order_changed") and node.is_connected("child_order_changed",ordered): node.disconnect("child_order_changed",ordered)
func changed(child: Node) -> void:
	var record = computation.get_ref()
	if record == null: return
	var manager = record.state.get_ref()
	if manager != null and not manager.is_managed(child): record.schedule()
func ordered() -> void:
	var record = computation.get_ref()
	if watching and record != null and not record._rendering: record.schedule()
