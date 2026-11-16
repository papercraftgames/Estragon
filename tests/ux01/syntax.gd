extends SceneTree
const Compiler = preload("res://addons/estragon/compiler/compiler.gd")
const State = preload("res://addons/estragon/runtime/composition/state.tres")
var failed := false
func check(ok: bool, label: String):
	print("UX01_B ",label,": ",ok)
	failed = failed or not ok
func _initialize(): run.call_deferred()
func run():
	var head := 'extends Node2D\nconst Text=preload("res://addons/estragon/runtime/node/text.gd")\nconst HBox=preload("res://addons/estragon/runtime/node/hbox.gd")\nfunc view(): return '
	for body in ['<HBox width />','<HBox imaginary />','<Button pressed />','<Button key />','<Button bind:value />','<Button disabled disabled={false} />','<Text text="x">body</Text>','<HBox>bad text</HBox>','<Text>Mixed<Button>Child</Button></Text>','<Text>{42}</Text>','<Text>{true}</Text>','<Text>unclosed','<Text></Button>','<Text>{"unfinished"</Text>']:
		var result = Compiler.compile(head+body,"negative.gogo")
		check(not result.ok and not result.diagnostics.is_empty() and result.diagnostics[0].source_name=="negative.gogo" and result.diagnostics[0].span.start.index>=head.length(),"source-located strict negative "+body)
	check(Compiler.compile(head+'<Text>{"Line\\nTwo"}</Text>',"newline.gogo").ok,"explicit GDScript newline String interpolation compiles")
	var imported = Compiler.compile('extends Node2D\nconst Imported=preload("res://app/generated/Ergonomics.gd")\nfunc view(): return <Imported bad_text label="String property" />',"res://app/Owned.gogo","res://app/generated/Owned.gd")
	check(imported.ok,"source-owned typed Gogo Bool/String fields remain writable on native subtype")
	var host = load("res://app/generated/Ergonomics.gd").new()
	root.add_child(host)
	for frame in range(8): await process_frame
	var column = host.get_node("@Estragon2D@2") if false else host.get_child(0).get_child(0)
	check(column.get_node("Greeting").text=="Hello é 🌱!","String interpolation Unicode")
	check(column.get_node("Quote").text=="I'm \"native\", é 🌱.","literal quotes are markup, never GDScript")
	check(column.get_node("Multiline").text=="One word another line","multiline whitespace")
	check(column.get_node("Boundaries").text=="Hello é 🌱 world" and column.get_node("Expressions").text=="Click Me é 🌱","newline/interpolation boundaries fold once")
	check(column.get_node("Empty").text.is_empty(),"empty body")
	check(column.get_node("Wrapped").wrap and column.get_node("Wrapped/Disabled").disabled,"bare true and ordered spread")
	check(not column.get_node("Override").wrap,"later spread overrides bare true")
	var id = column.get_node("Greeting").get_instance_id()
	host.username = "Updated"
	for frame in range(8): await process_frame
	check(column.get_node("Greeting").text=="Hello Updated!" and column.get_node("Greeting").get_instance_id()==id,"retained observed text update")
	host.label = "Line\nTwo"
	for frame in range(8): await process_frame
	check(column.get_node("Wrapped/Native").text=="Line\nTwo","String expression preserves explicit newlines on native Button")
	var greeting = column.get_node("Greeting")
	var before: Vector2 = greeting.layout_size
	greeting.font_size = 40
	for frame in range(8): await process_frame
	check(greeting.layout_size.y>before.y and greeting.get_instance_id()==id,"body text uses existing native font measurement and retained node")
	print("UX01_EXPECTED_BEGIN")
	host.extra = {"text":"conflict"}
	for frame in range(8): await process_frame
	print("UX01_EXPECTED_END")
	check(column.get_node("Spread").text=="Body","spread/body complete-description conflict rollback")
	host.extra = {}
	for frame in range(8): await process_frame
	print("UX01_EXPECTED_BEGIN")
	host.bad_text = true
	for frame in range(8): await process_frame
	print("UX01_EXPECTED_END")
	check(column.get_node("Strict").text=="Strict","dynamic non-String rejects atomically without coercion")
	host.bad_text = false
	for frame in range(8): await process_frame
	check(host.evaluations==State.records[host.get_instance_id()].runs+2,"each String interpolation evaluates once per description")
	host.free()
	for frame in range(8): await process_frame
	if not failed: print("UX01_B_OK")
	quit(1 if failed else 0)
