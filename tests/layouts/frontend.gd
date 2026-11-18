extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const Completion = preload("res://addons/estragon/editor/completion.gd")
const Context = preload("res://addons/estragon/editor/lexical_context.gd")
var failures := 0
var assertions := 0
var sequence := 0
func check(value: bool, label: String) -> void:
	assertions += 1
	print("EL02_FRONTEND ",label,": ",value)
	if not value: failures += 1
func compile(text: String):
	sequence += 1
	return Compiler.compile("extends Node2D\n"+text,"res://app/Probe.gogo","res://app/generated/Probe%d.gd" % sequence)
func instance(text: String):
	var result = compile(text)
	for diagnostic in result.diagnostics: print(diagnostic.format())
	check(result.ok,"compile source "+str(sequence))
	if not result.ok: return null
	var script := GDScript.new()
	script.resource_path = "res://app/generated/Probe%d.gd" % sequence
	script.source_code = result.code
	var loaded := script.reload()==OK
	check(loaded,"native reload "+str(sequence))
	return script.new() if loaded else null
func reject(text: String, message: String):
	var result = compile(text)
	check(not result.ok and result.diagnostics.size()==1 and message in result.diagnostics[0].message and result.diagnostics[0].span.start.line>=2,"reject "+message)
func _initialize():
	var matrix := 'layout const <App gap="8px">\n <Header /> <Header />\n <Side /> <Body />\n <Side /> <Footer />\n</App>\n'
	var host = instance(matrix+'func view():\n\treturn <App width="640px" height="480px"><Header /><Side /><Body /><Footer /></App>\n')
	if host!=null:
		var view = host.view()
		check(view.properties.areas==["Header Header","Side Body","Side Footer"],"exact case and spans matrix")
		check(view.children[0].placement.area=="Header" and view.children[1].placement.area=="Side","external logical area placement")
		check(view.children[0].type!=view.type,"area is Box, root is Grid")
		check(view!=host.view() and view.children[0]!=host.view().children[0],"descriptions are fresh values; declaration mounts nothing")
		host.free()
	host = instance('layout const <Side gap="8px"><Top /> <Top /></Side>\nfunc before(): return <Side />\nlayout const <App><Side width="25%" /> <Body /></App>\nfunc after(): return <Side />\nfunc local():\n\tlayout const <Local><Side gap="12px" /> <lower /></Local>\n\treturn <Local><Side /><lower /></Local>\nfunc again(): return <Side />\n')
	if host!=null:
		check(host.before().properties.gap=="8px" and host.before().placement.is_empty(),"prior references retain original binding")
		check(host.after().properties.width=="25%" and host.after().placement.area=="Side" and host.after().properties.areas==["Top Top"],"recomposed area retains base internal Grid")
		check(host.local().children[0].properties.gap=="12px" and host.again().properties.gap=="8px","local shadowing does not mutate enclosing binding")
		check(host.local().children[1].placement.area=="lower","lowercase identifiers preserved")
		host.free()
	host = instance('layout const <App><Part width="20px" /> <Part height="30px" /></App>\nfunc view(): return <Part width="40px" />\n')
	if host!=null:
		check(host.view().properties.width=="40px" and host.view().properties.height=="30px","repeated complementary defaults merge; instance wins")
		host.free()
	host = instance('var amount: int = 20\nvar options: Dictionary = {"height":"30px"}\nlayout var <App><Part width={str(self.amount)+"px"} {...self.options} /> <Part width={str(self.amount)+"px"} /></App>\nfunc view(): return <Part />\nfunc change(): Part = App\n')
	if host!=null:
		check(host.view().properties.width=="20px" and host.view().properties.height=="30px","dynamic defaults and spreads evaluate inside use")
		host.amount = 35
		check(host.view().properties.width=="35px","defaults read current host values")
		host.options = {"width":"wrong"}
		check(not host.view().attribute_error.is_empty(),"runtime repeated dynamic conflict rejects transaction")
		host.change()
		check(host.view().properties.areas==["Part Part"],"var assignment selects another preset")
		host.free()
	host = instance('export layout const <App><Part /></App>\nfunc view(): return <App />\n')
	if host!=null:
		check(host.App!=null and host.Part!=null,"exported definitions are public instance bindings")
		host.free()
	host = instance('export layout var <App><Part /></App>\nfunc view(): return <Part />\n')
	if host!=null:
		host.Part = host.App
		check(host.view().properties.areas==["Part"],"export var exposes assignable native property")
		host.free()
	host = instance('layout const <App columns={["100px","1fr"]} rows={["40px","1fr"]}><One /> <Two />\n<Three /> <Four /></App>\nfunc view(): return <App direction="row" width="25%" />\n')
	if host!=null:
		var view = host.view()
		check(view.properties.direction=="row" and view.properties.columns==["100px","1fr"] and view.properties.areas.size()==2 and view.properties.width=="25%","mode override retains grid configuration and ordinary width semantics")
		host.free()
	for pair in [
		['layout let <App><Part /></App>',"const or var"],
		['layout const <App><Part /> <Part />\n<Part /> <Other /></App>',"rectangle"],
		['layout const <App><Part /> <Other />\n<Third /></App>',"uneven"],
		['layout const <App><Part width="1px" /> <Part width="2px" /></App>',"Conflicting repeated"],
		['layout const <App><Part /></App>\nfunc bad(): App = null',"Cannot assign"],
		['layout const <App><Part fake="1" /></App>',"Unknown, read-only"],
		['layout const <App><Part key="x" /></App>',"cannot preset key"],
		['layout const <App><Part><Other /></Part></App>',"area matrix"],
		['func local():\n\texport layout const <App><Part /></App>',"module scope"],
		['var App=1\nlayout const <App><Part /></App>',"collides"],
		['const App=preload("res://addons/estragon/runtime/node/box.gd")\nlayout const <App><Part /></App>',"support native Grid"],
		['layout const <App.Part><Part /></App.Part>',"unqualified"],
		['layout const <App><App /></App>',"distinct"],
	]: reject(pair[0],pair[1])
	for pair in [
		['layout const <App><Part width={1} /> <Part width={2} /></App>',"Conflicting repeated"],
		['layout const <App><Part /></App>\nfunc local(Part: Script): return <Part />',"hidden by a native parameter"],
		['layout const <App><Part /></App>\nfunc local(Part: Script):\n\treturn <Part />',"hidden by a native parameter"],
		['layout const <return><Part /></return>',"unqualified"],
		['export layout const <App><Button /></App>',"Cannot export"],
	]: reject(pair[0],pair[1])
	host = instance('const Action=preload("res://addons/estragon/runtime/node/button.gd")\nexport layout const <App><Action text="Default" /></App>\nfunc view(): return <Action />\n')
	if host!=null:
		check(host.Action!=null and host.view().properties.text=="Default","export composes and hygienically preserves an existing Script import")
		host.free()
	host = instance('layout const <App><Part gap="7px" /></App>\nfunc local():\n\tlayout const <Other><Part gap="12px" /></Other>\n\treturn self.Part\nfunc view():return <Part />\n')
	if host!=null:
		check(host.local().generated.area=="Part" and host.view().properties.gap=="7px","explicit self retains module binding inside a shadowing scope")
		host.free()
	var self_named = Compiler.compile('extends Node2D\nlayout const <Layouts><Region /></Layouts>\nfunc view():return <Layouts />\n',"res://app/Layouts.gogo","res://app/generated/SelfNamed.gd")
	check(self_named.ok,"root binding may share its own source basename without implicit self-inheritance")
	var model_source := 'extends RefCounted\nvar amount: int = 12\nexport layout const <App gap={self.amount}><Part /></App>\n'
	var model_result = Compiler.compile(model_source,"res://Value.gogo","res://app/generated/Value.gd")
	check(model_result.ok,"code-only model presets compile")
	if model_result.ok:
		var model_script := GDScript.new()
		model_script.resource_path = "res://app/generated/Value.gd"
		model_script.source_code = model_result.code
		check(model_script.reload()==OK,"native code-only model defaults load")
		var proof: Array = released_model(model_script)
		check(proof[0].get_ref()==null and not proof[1].defaults.is_valid(),"default evaluator never forms a RefCounted owner/preset closure cycle")
	var library_source := 'extends Node2D\nexport layout const <Side gap="7px"><Top /> <Top /></Side>\n'
	var library = Compiler.compile(library_source,"res://fixture_library/Library.gogo","res://fixture_library/generated/Library.gd")
	check(library.ok,"export library compiles")
	DirAccess.make_dir_recursive_absolute("res://fixture_library/generated")
	var handle := FileAccess.open("res://fixture_library/Library.gogo",FileAccess.WRITE)
	handle.store_string(library_source)
	handle.close()
	handle = FileAccess.open("res://fixture_library/generated/Library.gd",FileAccess.WRITE)
	handle.store_string(library.code)
	handle.close()
	host = instance('const Library=preload("res://fixture_library/generated/Library.gd")\nvar library: Library = Library.new()\nvar Side = library.Side\nfunc original(): return <library.Side />\nlayout const <App><Side gap="12px" /> <Body /></App>\nfunc derived(): return <Side />\n')
	if host!=null:
		check(host.original().properties.gap=="7px" and host.derived().properties.gap=="12px" and host.library.Side.generated.direction=="grid","typed exported reuse preserves original across files")
		host.library.free()
		host.free()
	reject('layout const <App template="Part Part, 40px"><Part /> <Part /></App>',"Grid template")
	host = instance('var recipe: String = "Part Part, 40px\\n\\\\ 1fr 1fr"\nlayout const <App><Part /> <Part /></App>\nfunc view(): return <App template={self.recipe} />\n')
	if host!=null:
		var view = host.view()
		check(view.properties.columns==null and view.properties.areas==[] and view.properties.template==host.recipe,"caller template replaces generated track defaults using native configuration")
		host.free()
	var complete := matrix+'func view():\n\treturn <Header wid'
	var completion := Completion.new()
	var offered := completion.candidates(complete,"res://app/Editor.gogo",Context.new(),complete.split("\n").size()-1,complete.split("\n")[-1].length())
	check(offered.any(func(item):return item.insert=="width"),"layout area native property completion")
	complete = matrix+'func view():\n\treturn <He'
	offered = completion.candidates(complete,"res://app/Editor.gogo",Context.new(),complete.split("\n").size()-1,complete.split("\n")[-1].length())
	check(offered.any(func(item):return item.insert=="Header"),"layout binding tag completion")
	var lexical := Context.new()
	lexical.update(matrix)
	check(lexical.line(0).tokens.any(func(token): return token.kind=="keyword" and token.text=="layout") and lexical.line(0).tokens.any(func(token):return token.kind=="tag" and token.text=="App"),"editor recognizes layout keyword and GGX root")
	print("EL02_FRONTEND_ASSERTIONS ",assertions," failures=",failures)
	if failures==0: print("EL02_FRONTEND_OK")
	quit(0 if failures==0 else 1)

func released_model(script: Script) -> Array:
	# 4.0 retains a native getter receiver temporary until its caller returns.
	# Test the actual ownership graph after that native evaluation stack unwinds.
	var model = script.new()
	return [weakref(model),model.App]
