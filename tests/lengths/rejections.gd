extends SceneTree
const Rect = preload("res://addons/estragon/runtime/node/rect.gd")
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var entry := Entry.new()
	entry.width = 320
	entry.height = 240
	var node := Rect.new()
	node.width = "50%"
	node.min_width = "160px"
	node.min_height = 24
	entry.add_child(node)
	root.add_child(entry)
	for frame in range(4): await process_frame
	var before := node.get_layout_stats()
	print("L06_EXPECTED_REJECTION_BEGIN")
	await process_frame
	var failed := false
	for invalid in ["no-unit",-1.0,NAN,INF,true]:
		node.width = invalid
		if node.width!="50%" or node.lengths.specs.width.unit!="%": failed = true
	for name in ["min_width","min_height"]:
		var value = node.get(name)
		var spec: Dictionary = node.lengths.specs[name].duplicate()
		for invalid in ["bad","-1px",-1,NAN,INF,true,[],1e13,"1e13px"]:
			node.set(name,invalid)
			if not is_same(node.get(name),value) or node.lengths.specs[name]!=spec: failed = true
	# Execute a real bindable invalid description through the production manager.
	var host = load("res://app/generated/MinimumGallery.gd").new()
	root.add_child(host)
	for frame in range(6): await process_frame
	var panel = host.get_node("UI/Panel")
	var identity: int = panel.get_instance_id()
	var geometry: Vector2 = panel.layout_size
	host.floor_width = "broken"
	for frame in range(6): await process_frame
	if panel!=host.get_node("UI/Panel") or panel.get_instance_id()!=identity or panel.min_width!="280px" or panel.layout_size!=geometry: failed = true
	host.floor_width = "320px"
	for frame in range(6): await process_frame
	if panel!=host.get_node("UI/Panel") or panel.min_width!="320px": failed = true
	host.free()
	await process_frame
	await process_frame
	print("L06_EXPECTED_REJECTION_END")
	if before!=node.get_layout_stats() or node.layout_size!=Vector2(160,24): failed = true
	entry.free()
	if not failed: print("L06_REJECTIONS_OK")
	quit(1 if failed else 0)
