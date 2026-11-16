extends SceneTree
const Core = preload("res://addons/estragon/runtime/node/internal/layout_core.gd")
var failed := false
func check(ok: bool, label: String):
	print("UX01_A ",label,": ",ok)
	failed = failed or not ok
func _initialize():
	for axis in range(2):
		for alignment in ["start","center","end","stretch"]:
			var parent := Core.new()
			var extent := Vector3(160,100,0) if axis==0 else Vector3(100,160,0)
			parent.configure(extent,0,false,1-axis)
			var policy := ["start","start","start"]
			policy[axis] = alignment
			parent.set_policy(policy)
			var wrap := Core.new()
			wrap.configure(Vector3(-1,-1,0),10,false,axis)
			wrap.set_strategy("wrap")
			wrap.physical_gaps = Vector2(10,12) if axis==0 else Vector2(12,10)
			var children: Array = []
			for i in range(3):
				var child := Core.new()
				child.configure(Vector3(70,20,0) if axis==0 else Vector3(20,70,0),0,false)
				children.append(child)
			wrap.set_children(children)
			parent.set_children([wrap])
			for width in [160,230,160]:
				extent[axis] = width
				parent.configure(extent,0,false,1-axis)
				parent.arrange(parent.measure())
				check(wrap.size[axis]<=width and wrap.size[1-axis]==(52 if width==160 else 20),"bounded auto geometry %d %s %d" % [axis,alignment,width])
				check(children[2].offset[axis]==(0 if width==160 else 160) and children[2].offset[1-axis]==(32 if width==160 else 0),"line geometry")
				check(wrap.content_reference[axis]==(-1 if alignment!="stretch" else width),"capacity is not percent authority")
			wrap.set_children([children[0]])
			parent.arrange(parent.measure())
			check(wrap.size[axis]==(160 if alignment=="stretch" else 70),"short natural width preserved")
			check(wrap.offset[axis]==(90 if alignment=="end" else (45 if alignment=="center" else 0)),"short parent physical alignment")
	var natural := Core.new()
	natural.configure(Vector3(-1,-1,0),0,false,1)
	var wrap := Core.new()
	wrap.configure(Vector3(-1,-1,0),0,false)
	wrap.set_strategy("wrap")
	var children: Array = []
	for i in range(3):
		var child := Core.new()
		child.configure(Vector3(70,20,0),0,false)
		children.append(child)
	wrap.set_children(children)
	natural.set_children([wrap])
	natural.arrange(natural.measure())
	check(wrap.size==Vector3(210,20,0),"truly indefinite remains natural")
	if not failed: print("UX01_A_MATH_OK")
	quit(1 if failed else 0)
