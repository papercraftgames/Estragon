extends RefCounted
## One transparent managed-root bridge owned by an existing Computation.
## No user fields, metadata, helper Node, authored-child adoption or layout math.
const Coordinator = preload("../node/internal/coordinator.gd")
const Hosts = preload("../node/internal/composition_hosts.tres")
var host: WeakRef
var root: WeakRef
var layout
var target
func _init(owner: Node) -> void:
	host = weakref(owner)
	# Native participants/entries already own a coordinator. Never duplicate it.
	if owner.has_method("_get_layout_coordinator"): return
	var dimension := 2 if owner is Node2D else (3 if owner is Node3D else 0)
	if dimension == 0: return
	layout = Coordinator.new(owner,dimension,Coordinator.Mode.COMPOSITION)
	start()
func start() -> void:
	if layout == null or layout.active: return
	var owner = host.get_ref()
	Hosts.add(owner,layout)
	layout.start()
	update(root.get_ref() if root != null else null)
func stop() -> void:
	if layout == null or not layout.active: return
	var owner = host.get_ref()
	_disconnect()
	# Keep registry identity until stop detaches the model from its parent;
	# active=false already prevents other coordinators from adopting it.
	layout.stop()
	Hosts.remove(owner,layout)
func _disconnect() -> void:
	if target != null and target.model.invalidated.is_connected(_configure): target.model.invalidated.disconnect(_configure)
	target = null
func update(view: Node) -> void:
	root = weakref(view) if view != null else null
	if layout == null or not layout.active: return
	_disconnect()
	layout.managed_root = root
	target = layout.participant(view)
	if target != null and target._mode == Coordinator.Mode.ENTRY: target = null
	if target != null: target.model.invalidated.connect(_configure)
	layout._sync()
	_configure()
func _configure() -> void:
	if layout == null or not layout.active: return
	var requested := Vector3(-1,-1,0) if layout._dimension==2 else Vector3(-1,-1,-1)
	var fills := Vector3.ZERO
	if target != null:
		requested = target.model.requested
		fills = target.model.fill
	# One child, at zero local offset. Parent places the native host once;
	# root constraints determine both proxy allocation and root allocation.
	layout.model.configure(requested,0,false,0,fills)
