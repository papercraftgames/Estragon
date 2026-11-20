extends SceneTree
const State = preload("res://addons/estragon/runtime/composition/state.tres")
const Profile = preload("res://addons/estragon/runtime/composition/profile.tres")
const Model = preload("res://app/generated/Model.gd")
var checks := 0
var errors := 0
var measurements: Array = []
func check(value: bool,label: String):
	checks += 1
	print("CORE01_INTEGRATION ",label,": ",value)
	if not value: errors += 1
func frames(count: int = 8):
	for index in range(count): await process_frame
func ids(parent: Node) -> Dictionary:
	var result := {}
	for child in parent.get_children(): result[str(child.name)] = child.get_instance_id()
	return result
func entries(entry) -> int:
	var count := 1
	for bucket in entry.children.values():
		for child in bucket: count += entries(child)
	return count
func click(node: Node):
	var event := InputEventMouseButton.new()
	event.position = node.get_global_transform_with_canvas()*Vector2(12,12)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,480)
	var host = load("res://app/generated/Core.gd").new()
	root.add_child(host)
	await frames()
	var column = host.get_node("UI/Column")
	var badges = column.get_node("Badges")
	var first = column.get_node("First")
	var second = column.get_node("Second")
	var record = State.records[host.get_instance_id()]
	check(host.counts.badge==4 and host.counts.wrapper==1 and host.counts.manual==1,"distinct helper occurrences and opaque ordinary wrapper")
	check(host.counts.lambda==1 and host.counts.lambda_body==2,"anonymous GGX bodies own independent reactive call occurrences")
	check(column.get_node("StaticImport").text=="STATIC IMPORT","ordinary imported static function uses native Script Callable on both engines")
	check(host.edits==0,"handler references never invoke during render")
	check(first.views==1 and second.views==1,"two independent components observe shared model")
	var controls = column.get_node("SharedControls")
	var control_one = controls.get_child(0)
	var control_two = controls.get_child(1)
	check(control_one!=control_two and control_one.value_changed.get_connections().size()==1 and control_two.value_changed.get_connections().size()==1,"one cached controlled description owns independent native edit connections")
	click(control_one)
	await frames()
	check(host.model.alternate and control_one.value and control_two.value,"first cached controlled mount edits and projects both native controls")
	click(control_two)
	await frames()
	check(not host.model.alternate and not control_one.value and not control_two.value,"second cached controlled mount edits independently")
	host.show_pair=false
	await frames()
	check(controls.get_child_count()==1 and control_one.value_changed.get_connections().size()==1,"removing a peer disconnects only that mount's binding")
	click(control_one)
	await frames()
	check(host.model.alternate and control_one.value,"remaining cached controlled mount still accepts native input")
	var original := ids(badges)
	var manual_one = column.get_node("Ordinary").get_child(2)
	var manual_two = column.get_node("Ordinary").get_child(3)
	check(manual_one!=manual_two and manual_one.text==manual_two.text,"cached description mounted twice has distinct native nodes")
	var hidden: String = column.get_node("Ordinary/Static").text
	var badge_count: int = host.counts.badge
	var imported_calls: int = host.ordinary.calls
	var first_views: int = first.views
	var second_views: int = second.views
	host.tick += 1
	await frames()
	check(host.counts.badge==badge_count and host.ordinary.calls==imported_calls,"unchanged arguments skip reactive and imported ordinary bodies")
	check(first.views==first_views and second.views==second_views,"sibling component isolation under unrelated parent update")
	var before_change: int = record.runs
	for value in range(1,101): host.model.value = value
	await frames()
	check(host.model.value==100 and record.runs==before_change+1,"rapid chained writes coalesce without losing final value")
	check(first.views==first_views and second.views==second_views,"unread shared property does not rerun sibling leaf views")
	host.model.label="other"
	await frames()
	check(host.counts.badge==badge_count+3 and host.counts.wrapper==1,"dirty nested GGX invocation propagates but ordinary wrapper stays static")
	check(badges.get_child(0).has_node("Alternate") and badges.get_child(1).has_node("Alternate") and not column.get_node("Ordinary").get_child(1).has_node("Alternate"),"GGX local branch replaces child type; opaque wrapper retains original structure")
	check(ids(badges)==original and manual_one==column.get_node("Ordinary").get_child(2),"retained native state and shared description independence")
	check(host.counts.lambda==2 and host.counts.lambda_body==4 and column.get_node("Lambda").get_child(0).text=="other","anonymous GGX local read invalidates cached enclosing function")
	check(first.views==first_views+1 and second.views==second_views+1,"two components independently rerun on shared read")
	check(column.get_node("Ordinary/Static").text==hidden and manual_one.text==hidden,"zero-argument ordinary and manual Element helpers remain static")
	check(host.counts.callable==1 and column.get_node("Callable").text=="FIXED","ordinary Callable.call uses the same explicit-argument cache across parent updates")
	var stats: Dictionary = host.get_node("UI").get_layout_stats()
	var runs: int = record.runs
	host.model.label="other"
	await frames()
	check(record.runs==runs and stats==host.get_node("UI").get_layout_stats(),"same values produce no notification/layout storms")
	var collection_calls: int = host.counts.collection
	host.collection.change(7)
	await frames()
	check(host.counts.collection==collection_calls+1 and column.get_node("Ordinary/Collection").text=="7","same-identity observable argument invalidates on real change signal")
	host.collection.change(7)
	await frames()
	check(host.counts.collection==collection_calls+1,"same observable argument value is quiet")
	var arrays: int = host.counts.array
	host.plain_values[0]=2
	host.tick += 1
	await frames()
	check(host.counts.array==arrays and column.get_node("Plain").text=="1","raw collection identity stays memoized after in-place mutation and unrelated render")
	host.plain_values=[2]
	await frames()
	check(host.counts.array==arrays+1 and column.get_node("Plain").text=="2","new Array reference invalidates explicit argument cache")
	# Transition to a new invalid branch, then repair solely through its newly read source.
	var previous_branch: String = column.get_node("Branch").text
	print("CORE01_EXPECTED_REJECTION_BEGIN")
	host.choose=true
	host.invalid=true
	await frames()
	check(column.get_node("Branch").text==previous_branch,"failed desired preflight retains previous native values")
	var rejected_source = host.replacement
	for attempt in range(3):
		host.replacement=Model.new()
		host.replacement.label="Rejected "+str(attempt)
		await frames()
		check(rejected_source.label_changed.get_connections().is_empty(),"repeated rejected descriptions release obsolete repair subscriptions "+str(attempt))
		rejected_source=host.replacement
	host.replacement.label="Repair source"
	await frames()
	print("CORE01_EXPECTED_REJECTION_END")
	check(column.get_node("Branch").text=="Repair source","new conditional subscriptions recover after rejected desired output")
	host.invalid=false
	await frames()
	runs=record.runs
	host.model.label="Original branch removed"
	await frames()
	check(column.get_node("Branch").text=="Repair source","changed conditional dependencies detach from old source")
	var weak_old = weakref(host.model)
	host.model=null
	await frames()
	check(first.get_child(0).get_child(0).text=="null" and column.get_node("Badges").get_child(0).get_child(0).text=="NULL","null model propagates to independent scopes")
	host.model=Model.new()
	await frames()
	check(weak_old.get_ref()==null,"model replacement releases old source and weak argument subscriptions")
	# Parent removes a child in the same tick that its source dirties the child.
	var removed_id: int = second.get_instance_id()
	host.show=false
	host.model.label="parent first"
	await frames()
	check(not is_instance_valid(second) and not State.records.has(removed_id),"parent-first removal cancels dirty descendant safely")
	host.show=true
	await frames()
	check(column.has_node("Second") and column.get_node("Second")!=first,"conditional remount creates independent scope")
	host.mutate_once=true
	host.model.value=101
	await frames()
	check(host.model.value==102 and column.get_node("Mutation").text=="102","reentrant same-drain write is observed and final value committed")
	var disposable := Node.new()
	disposable.name="source alive"
	root.add_child(disposable)
	host.disposable=disposable
	await frames()
	check(column.get_node("Disposable").text=="source alive","native observable argument source mounts")
	disposable.queue_free()
	await frames()
	check(column.get_node("Disposable").text=="gone","native source disposal invalidates its weak dependent cache")
	host.disposable=null
	await frames()
	click(column.get_node("Action"))
	await frames()
	check(host.edits==1 and host.model.value==103,"actual native event executes normally with synchronous model writes")
	await RenderingServer.frame_post_draw
	var capture: Image = root.get_texture().get_image()
	check(capture.save_png("res://core01-640.png")==OK,"actual native geometry/rendered capture")
	for size in [128,256]:
		var values: Array = []
		for index in range(size):
			var model=Model.new()
			model.id=index
			model.label="row "+str(index)
			values.append(model)
		host.items=values
		await frames()
		var rows=column.get_node("Rows")
		var keyed_zero=column.get_node("KeyedZero")
		check(rows.get_child_count()==size and keyed_zero.get_child_count()==size,"real keyed helper and keyed zero-argument occurrences "+str(size))
		var before_ids := ids(rows)
		var before_keys := ids(keyed_zero)
		var row_calls: int = host.counts.row
		var zeros: int = host.counts.badge
		var first_calls: int = first.views
		var group_calls: int = host.counts.group
		Profile.set_enabled(true)
		Profile.reset()
		var started := Time.get_ticks_usec()
		values[size/2].value += 1
		await frames()
		var elapsed := Time.get_ticks_usec()-started
		var snapshot: Dictionary = Profile.snapshot()
		Profile.set_enabled(false)
		check(host.counts.row==row_calls+1 and host.counts.badge==zeros and first.views==first_calls and host.counts.group==group_calls,"one row invalidates one render invocation and leaves other branches quiet "+str(size))
		check(ids(rows)==before_ids and ids(keyed_zero)==before_keys,"row update retains every native node identity "+str(size))
		measurements.append({"rows":size,"elapsed_with_settle_us":elapsed,"profile":snapshot,"cache_entries":entries(record.render_cache)})
		# Keyed reorder reuses each row's call record even when invocation order changes.
		var reversed: Array=values.duplicate()
		if size==128: reversed.reverse()
		host.items=reversed
		await frames()
		check(host.counts.row==row_calls+1 and host.counts.badge==zeros and ids(rows)==before_ids and ids(keyed_zero)==before_keys,("keyed reorder" if size==128 else "same-order replacement")+" preserves call caches and native instances "+str(size))
		var same_calls: Dictionary = host.counts.duplicate()
		host.tick += 1
		await frames()
		check(host.counts.row==same_calls.row and host.counts.badge==same_calls.badge,"unrelated parent update retains all keyed helper caches "+str(size))
		if size==128:
			var nested_before: int = host.counts.badge
			var groups_before: int = host.counts.group
			host.model.label="keyed dependency"
			await frames()
			check(host.counts.badge==nested_before+size+3 and host.counts.group==groups_before+1 and keyed_zero.get_child(0).get_child(0).get_child(0).text=="KEYED DEPENDENCY","keyed nested dependency links propagate through cached enclosing GGX function")
		if size==128:
			host.items=[]
			values.clear()
			reversed.clear()
			await frames()
			check(rows.get_child_count()==0 and entries(record.render_cache)<40,"removed branches release bounded cache entries "+str(size))
	Profile.set_enabled(true)
	Profile.reset()
	await frames(12)
	var idle: Dictionary = Profile.snapshot()
	Profile.set_enabled(false)
	check(idle.counts.is_empty() and idle.timings_us.is_empty(),"idle zero descriptions/computations/layout counters")
	root.remove_child(host)
	await frames()
	check(record.subscriptions.is_empty() and record.cache_observers.is_empty() and entries(record.render_cache)==1,"host exit disconnects observations and releases caches")
	root.add_child(host)
	await frames()
	check(column==host.get_node("UI/Column") and record.active,"host reentry retains native nodes and rebuilds scopes")
	host.queue_free()
	await frames()
	check(State.records.is_empty() and State.dirty.is_empty() and State.scopes.is_empty() and State.invocations.is_empty(),"all native lifetimes and manager stacks clean")
	var derived = load("res://app/generated/Derived.gd").new()
	root.add_child(derived)
	await frames()
	var inherited = derived.get_node("Inherited")
	var inherited_ids := ids(inherited)
	check(derived.ordinary_calls==3 and derived.base_calls==1 and derived.hidden_calls==1 and derived.override_calls==1,"inherited and explicit super functions mount independent call caches")
	derived.tick += 1
	await frames()
	check(derived.ordinary_calls==3 and derived.base_calls==1 and derived.hidden_calls==1 and derived.override_calls==1,"unchanged super arguments and reactive base body reuse cached results")
	derived.title="Changed"
	await frames()
	check(derived.ordinary_calls==5 and inherited.get_node("Explicit").text=="CHANGED" and inherited.get_node("Normal").text=="CHANGED","changed inherited typed arguments invalidate both explicit call sites")
	check(derived.base_calls==2 and inherited.get_node("BaseBadge").text=="Changed","super GGX body observes bindable locals in its own base scope")
	check(derived.override_calls==1 and derived.hidden_calls==1 and inherited.get_node("Override").text=="Base" and inherited.get_node("Hidden").text=="Base","ordinary override and zero-argument super body stay opaque despite inherited GGX metadata")
	check(ids(inherited)==inherited_ids,"inherited function invalidation retains native node identities")
	derived.free()
	await frames()
	check(State.records.is_empty() and State.dirty.is_empty(),"inherited invocation caches dispose with their native owner")
	var file := FileAccess.open("res://core01-profile.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"errors":errors,"measurements":measurements,"idle":idle}))
	file.close()
	print("CORE01_INTEGRATION_ASSERTIONS ",checks," errors=",errors)
	if errors==0: print("CORE01_INTEGRATION_OK")
	quit(0 if errors==0 else 1)
