extends SceneTree
const Policy = preload("res://addons/estragon/runtime/node/internal/stack_policy.gd")
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
const Contract = preload("res://addons/estragon/runtime/node/internal/stack_contract.gd")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("L08_CHECK ",label,": ",ok)
	if not ok: failed = true
func item(size := Vector3(40,30,0)) -> Dictionary:
	return {"preferred":size,"minimum":Vector3.ZERO,"requested":size,"grow":0.0,"stretch":0,"fill":Vector3.ZERO,"outer":Vector3.ZERO,"leading":Vector3.ZERO,"align_self":"auto"}
func _initialize() -> void:
	var expected := {"start":[0,50,100],"center":[80,130,180],"end":[160,210,260],"space-between":[0,130,260],"space-around":[160.0/6,130,700.0/3],"space-evenly":[40,130,220]}
	for axis in [0,1]:
		for mode in expected:
			var size := Vector3(40,40,0)
			var content := Vector3(100,100,0)
			content[axis] = 300
			var alignment := ["center","center","start"]
			alignment[axis] = mode
			var slots := Policy.slots([item(size),item(size),item(size)],content,axis,10,alignment)
			for index in range(3):
				check(is_equal_approx(slots[index].position[axis],float(expected[mode][index])) and slots[index].position[1-axis]==30,"300/3x40/gap10 axis%d %s child%d" % [axis,mode,index])
			print("L08_NUMERIC ",axis," ",mode," ",slots)
			check(Policy.slots([],content,axis,10,alignment).is_empty(),"zero children "+mode)
			var single := Policy.slots([item(size)],content,axis,10,alignment)
			var offset := 130 if mode in ["center","space-around","space-evenly"] else (260 if mode=="end" else 0)
			check(single[0].position[axis]==offset,"one child "+mode)
			content[axis] = 100
			var overflow := Policy.slots([item(size),item(size),item(size)],content,axis,10,alignment)
			check(overflow[0].position[axis]==0 and overflow[2].position[axis]==100,"overflow is normal forward gap, never negative "+mode)
	for mode in expected:
		var growing := item()
		growing.requested.x = -1
		growing.grow = 1
		var slots := Policy.slots([growing,item()],Vector3(300,100,0),0,10,[mode,"start","start"])
		check(slots[0].extent.x==250 and slots[0].position.x==0 and slots[1].position.x==260,"grow consumes free space before "+mode)
	var first := item(Vector3(70,20,0))
	first.fill.x = 1
	first.requested.x = -1
	first.minimum.x = 70
	var second := item(Vector3(20,20,0))
	second.fill.x = 1
	second.requested.x = -1
	second.minimum.x = 20
	var slots := Policy.slots([first,second],Vector3(100,40,0),0,0,["space-between","start","start"])
	check(slots[0].extent.x==70 and slots[1].extent.x==30 and slots[1].position.x==70,"native fill water-filling floors precede distribution")
	for own in Contract.SELF:
		var child := item()
		child.requested.y = -1
		child.stretch = 1
		child.align_self = own
		slots = Policy.slots([child],Vector3(300,100,0),0,0,["space-evenly","center","start"])
		var stretch: bool = own in ["auto","stretch"]
		var y := 35 if own=="center" else (70 if own=="end" else 0)
		check(slots[0].extent.y==(100 if stretch else 30) and slots[0].position.y==y,"align_self beats old stretch; auto defers "+own)
		child.requested.y = 30
		slots = Policy.slots([child],Vector3(300,100,0),0,0,["space-between","stretch","start"])
		check(slots[0].extent.y==30,"explicit cross dimension wins over every stretch "+own)
	for axis in [0,1]:
		var child := item(Vector3(40,30,0))
		child.requested[1-axis] = -1
		child.minimum[1-axis] = 120
		child.align_self = "stretch"
		child.outer = Vector3(8,8,0)
		child.leading = Vector3(3,3,0)
		slots = Policy.slots([child],Vector3(100,100,0),axis,10,["start","start","start"])
		check(slots[0].extent[1-axis]==120 and slots[0].position[1-axis]==3,"cross minimum overflow preserves leading margin axis"+str(axis))
	for direction in ["row","column"]:
		var main := "horizontal_align" if direction=="row" else "vertical_align"
		var cross := "vertical_align" if direction=="row" else "horizontal_align"
		for mode in expected:
			check(Contract.error(main,mode,direction).is_empty(),"shared valid main matrix "+direction+mode)
		for mode in Contract.DISTRIBUTION:
			check(not Contract.error(cross,mode,direction).is_empty(),"shared invalid cross matrix "+direction+mode)
		check(not Contract.error(main,"stretch",direction).is_empty(),"main stretch still rejects "+direction)
	check(not Contract.error("align_self","space-evenly","").is_empty(),"self distribution rejects")
	print("L08_MATH_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("L08_MATH_OK")
	quit(1 if failed else 0)
