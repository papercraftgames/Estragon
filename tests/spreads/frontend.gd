extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Frontend = preload("res://addons/estragon/compiler/frontend.gd")
const Model = preload("res://addons/estragon/compiler/model.gd")
const Element = preload("res://addons/estragon/runtime/composition/element.gd")
var checks := 0
var failed := false
func check(ok: bool, label: String) -> void:
	checks += 1
	print("S03_CHECK ",label,": ",ok)
	if not ok: failed = true
func _initialize() -> void: run.call_deferred()
func compile_view(body: String, declarations: String = ""):
	var source := 'extends Node\n'+declarations+'\nfunc view(): return '+body+'\n'
	var built := Compiler.compile(source,"spread.gogo")
	check(built.ok,"spread compile "+body+" "+str(built.diagnostics.map(func(d): return d.format())))
	if not built.ok: return null
	var script := GDScript.new()
	script.resource_path = "res://_SpreadProbe_%d.gd" % script.get_instance_id()
	script.source_code = built.code
	check(script.reload()==OK,"actual native semantics "+body)
	return script
func run() -> void:
	for body in [
		'<Node2D {...{"name":"A", "visible":false}} />',
		'<Node2D { ... {"name":"A"}} />',
		'<Node2D {... # GDScript comment\n {"name":"A"}} />',
		'<Node2D {...{&"name":"A"}} />',
		'<Node><Node name="same" {...{"name":"A"}} /><Node name="same" {...{"name":"B"}} /></Node>',
		'<Node2D {...props} name="after" {...values()} />',
		'<Node2D {...{"name":"A"}}><Node {...{"name":"child"}} /></Node2D>',
		'<Node>{<Node2D {...props} /> if true else null}</Node>',
		'<Node>{items.map(func(n: int): return <Node {...{"name":str(n)}} key={n} />)}</Node>'
	]:
		var script = compile_view(body,'var items: Array = [1,2]\nvar props := {"name":"before"}\nfunc values() -> Dictionary: return {"visible":false}')
		if script!=null:
			var host = script.new()
			check(host.view() is Element and host.get_child_count()==0,"description only, no candidate Nodes")
			host.free()
	var order = compile_view('<Node2D {...first()} name={named()} {...second()} />','var effects: Array = []\nvar props := {"visible":true}\nfunc first():\n\teffects.append(1)\n\treturn props\nfunc named():\n\teffects.append(2)\n\treturn "final"\nfunc second():\n\teffects.append(3)\n\tprops.visible=false\n\treturn {"position":Vector2(2,3)}')
	if order!=null:
		var host = order.new()
		var desired = host.view()
		print("S03_ORDER ",desired.properties," ",host.effects)
		check(desired.properties.size()==3 and desired.properties.visible==true and str(desired.properties.name)=="final" and desired.properties.position==Vector2(2,3) and host.effects==[1,2,3],"snapshot at authored evaluation, exactly once left to right including named expression")
		host.free()
	var precedence = compile_view('<Node name="before" {...{"name":"spread"}} {...{"name":"last"}} />')
	if precedence!=null:
		var host = precedence.new()
		check(host.view().properties.name=="last","later spread overrides explicit and earlier spread")
		host.free()
	precedence = compile_view('<Node {...{"name":"spread"}} name="explicit" />')
	if precedence!=null:
		var host = precedence.new()
		check(host.view().properties.name=="explicit" and not host.view().spread_properties.has("name"),"later explicit wins and has ordinary omission ownership")
		host.free()
	for body in ['<Node {...} />','<Node {... # empty\n} />','<Node {props} />','<Node {...{"name":"x"} />','<Node {...[1)} />','<Node name="a" name="b" {...{}} />','<Node {...{}} name="a" name="b" />','<Node>{...props}</Node>','<Node {...props}/Timer>']:
		var result := Compiler.compile('extends Node\nfunc view(): return '+body+'\n',"negative.gogo")
		check(not result.ok and result.diagnostics[0].source_name=="negative.gogo" and result.diagnostics[0].span.start.line==2,"authored parser/duplicate rejection "+body)
	for expression in ['var x = ...props','var x = [...props]','func x(): return call(...props)']:
		check(not Compiler.compile('extends Node\n'+expression+'\n',"negative.gogo").ok,"no spread outside attribute list "+expression)
	for body in ['<Node multiplayer={null} />','<Timer time_left={0.0} />','<AnimationPlayer current_animation_length={0.0} />','<AnimationPlayer current_animation_position={0.0} />','<ShapeCast2D collision_result={[]} />','<ShapeCast3D collision_result={[]} />']:
		check(not Compiler.compile('extends Node\nfunc view(): return '+body+'\n',"readonly.gogo").ok,"shared native getter-only metadata bridge "+body)
	var policy = compile_view('<Layout horizontal_align="stretch" {...{"direction":"column"}} />','const Layout = preload("res://addons/estragon/runtime/node/box.gd")')
	if policy!=null:
		var host = policy.new()
		check(host.view().properties.direction=="column","spread cross-axis policy defers to final effective values")
		host.free()
	var text := 'extends Node\nfunc view(): return <Node {...{ "name": "😀" }} />\n'
	var front := Frontend.analyze(text,"map.gogo")
	var node = front.module.parts.filter(func(part): return part is Model.Component)[0]
	var attribute = node.attributes[0]
	check(attribute.kind=="spread" and text.substr(attribute.span.start.index,attribute.span.end.index-attribute.span.start.index)=='{...{ "name": "😀" }}',"distinct ordered AST spread with complete authored span")
	check(front.tokens.any(func(token): return token.kind=="attribute-spread" and token.text=='{...'),"spread marker has a lexical token/span")
	var built := Compiler.compile(text,"map.gogo")
	var copied = built.source_map.segments.filter(func(segment): return segment.kind=="copied" and segment.original.start.line==2 and text.substr(segment.original.start.index,1)=="{")
	check(not copied.is_empty() and built.source_map.original_position(copied[0].generated.start.line,copied[0].generated.start.column).offset==copied[0].original.start.offset,"spread expression maps precisely independent of marker and UTF16")
	check(built.code==Compiler.compile(text,"map.gogo").code and built.source_map.serialize()==Compiler.compile(text,"map.gogo").source_map.serialize(),"deterministic spread output/maps")
	print("S03_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("S03_FRONTEND_OK")
	quit(1 if failed else 0)
