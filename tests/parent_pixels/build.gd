extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Imports = preload("res://addons/estragon/editor/imports.gd")
const Catalog = preload("res://addons/estragon/editor/components.gd")
static func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
static func header(path: String, names: Array) -> String:
	var source := "extends Node2D\n"
	for name in names: source += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	return source
func _initialize() -> void:
	var path := "res://app/Home.gogo"
	write(path,header(path,["Element","Entry2D","VBox","HBox","Rect"])+'''@bindable var flipped: bool = false
func _ready() -> void:
	if OS.get_environment("L02_EDITOR")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(15): await get_tree().process_frame
	var panel = $UI/Outer/Panel
	var identity: int = panel.get_instance_id()
	var samples: Array = []
	for extent in [Vector2(640,400),Vector2(800,600),Vector2(520,320)]:
		$UI.width = extent.x
		$UI.height = extent.y
		for frame in range(15): await get_tree().process_frame
		var outer = $UI/Outer
		samples.append({"width":panel.get_node("Panel").width,"height":panel.get_node("Panel").height,"content_x":outer.layout.model.content_reference.x,"content_y":outer.layout.model.content_reference.y,"identity":panel.get_instance_id()==identity})
	var button = panel.get_node("Panel/Action")
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://editor-game.png")
	var file := FileAccess.open("res://.godot/l02-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples":samples,"clicks":panel.clicks}))
	file.close()
	DirAccess.rename_absolute("res://.godot/l02-game.tmp","res://.godot/l02-game.json")
func build_view() -> Element:
	var children = [<PercentPanel name="Panel" key="panel" />, <Rect name="Fixed" key="fixed" width={40} height={20} fill={Color.RED} />, <VBox name="Flex" key="flex" fill_width={true} fill_height={true} />]
	if self.flipped: children.reverse()
	return <Entry2D name="UI" width={640} height={400}>
		<HBox name="Outer" fill_width={true} fill_height={true} padding={20} gap={10}>
			{children}
		</HBox>
	</Entry2D>
''')
	path = "res://app/PercentPanel.gogo"
	write(path,header(path,["Element","VBox","UiButton","Rect","Pixels"])+'''@bindable var percent_x: float = 50.0
@bindable var percent_y: float = 75.0
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func build_view() -> Element:
	return <VBox name="Panel" width={Pixels.parent_width(self,self.percent_x)} height={Pixels.parent_height(self,self.percent_y)} padding={8} margin={5} gap={4}>
		<UiButton name="Action" text="Parent pixels" height={40} fill_width={true} pressed={self.pressed} />
		<Rect name="Accent" height={8} fill_width={true} fill={Color(0.3,0.8,0.6)} />
		<Nested name="Nested" />
	</VBox>
''')
	path = "res://app/Nested.gogo"
	write(path,header(path,["Element","VBox","Rect","Pixels"])+'''func build_view() -> Element:
	return <VBox name="Nested" width={Pixels.parent_width(self,50.0)} height={Pixels.parent_height(self,50.0)} padding={2}>
		<Rect name="Color" fill_width={true} fill_height={true} fill={Color(0.3,0.6,1)} />
	</VBox>
''')
	path = "res://app/Wrapper.gogo"
	write(path,header(path,["Element"])+'''func build_view() -> Element:
	return <PercentPanel name="Wrapped" />
''')
	path = "res://app/Boundary.gogo"
	write(path,header(path,["Element","Entry2D"])+'''func build_view() -> Element:
	return <Entry2D name="Independent" width={300} height={200}><PercentPanel name="Panel" /></Entry2D>
''')
	var result := Build.run_build()
	print("L02_BUILD ",JSON.stringify(result))
	if result.ok:
		var home := Node2D.new()
		home.name = "Home"
		home.set_script(load("res://app/generated/Home.gd"))
		var packed := PackedScene.new()
		packed.pack(home)
		ResourceSaver.save(packed,"res://app/Home.tscn")
		home.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
		ProjectSettings.save()
		print("L02_BUILD_OK")
	quit(0 if result.ok else 1)
