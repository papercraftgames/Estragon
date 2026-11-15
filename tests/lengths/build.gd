extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Imports = preload("res://addons/estragon/editor/imports.gd")
const Catalog = preload("res://addons/estragon/editor/components.gd")
static func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
static func header(path: String, names: Array, base := "Node2D") -> String:
	var source := "extends "+base+"\n"
	for name in names: source += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	return source
func _initialize() -> void:
	var path := "res://app/Home.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Rect","Text","UiButton"])+'''@bindable var flipped: bool = false
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func _ready() -> void:
	if OS.get_environment("L06_EDITOR")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(15): await get_tree().process_frame
	var panel = $UI/Column/Inline
	var identity: int = panel.get_instance_id()
	var samples: Array = []
	for extent in [Vector2i(1152,648),Vector2i(1440,900),Vector2i(800,500)]:
		get_tree().root.size = extent
		for frame in range(15): await get_tree().process_frame
		var column = $UI/Column
		samples.append({"width":panel.layout_size.x,"height":panel.layout_size.y,"content_x":column.layout.model.content_reference.x,"content_y":column.layout.model.content_reference.y,"identity":panel.get_instance_id()==identity,"spec":panel.width})
	var button = $UI/Column/Settings/Row/Action
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
	var file := FileAccess.open("res://.godot/l06-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples":samples,"clicks":button.get_parent().get_parent().clicks}))
	file.close()
	DirAccess.rename_absolute("res://.godot/l06-game.tmp","res://.godot/l06-game.json")
func build_view() -> Element:
	var items = [<Rect key="a" name="A" width="10%" height="12px" fill={Color.RED} />, <Rect key="b" name="B" width={200} height="12px" fill={Color.GREEN} />]
	if self.flipped: items.reverse()
	return <Entry2D name="UI" width="100vw" height="100vh" padding="16px">
		<VBox name="Column" width="100%" height="100%" padding="8px" gap="4px">
			<VBox name="Inline" width="50%" height="75%"><Rect width="100%" height="100%" fill={Color(0.2,0.35,0.65)} /></VBox>
			<Text text="Hello World!" />
			<Text text="This is fun!" />
			<Settings name="Settings" />
			<Rose name="Rose" />
			{items}
			{get_children()}
		</VBox>
	</Entry2D>
''')
	path = "res://app/Settings.gogo"
	write(path,header(path,["Element","HBox","UiButton"])+'''var clicks: int = 0
func pressed() -> void:
	clicks += 1
func build_view() -> Element:
	return <HBox name="Row" width="50%" height="32px"><UiButton name="Action" text="Actual input" width="100%" height="100%" pressed={self.pressed} /></HBox>
''')
	path = "res://app/Rose.gogo"
	write(path,header(path,["Element","Text"])+'''func build_view() -> Element:
	return <Text text="Rose" />
''')
	path = "res://app/FlexHome.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Text"])+'''func build_view() -> Element:
	return <Entry2D width="100vw" height="100vh"><VBox width="100%" height="100%"><VBox grow={1} stretch={1} /><Text text="Bottom aligned" /></VBox></Entry2D>
''')
	path = "res://app/FlexPanel.gogo"
	write(path,header(path,["Element","VBox","Rect"])+'''func build_view() -> Element:
	return <VBox name="Root" width={600} grow={1}><Rect name="Half" width="50%" height="50%" /></VBox>
''')
	path = "res://app/FlexWrapper.gogo"
	write(path,header(path,["Element"])+'''func build_view() -> Element:
	return <FlexPanel name="Panel" />
''')
	path = "res://app/DeepFlex.gogo"
	write(path,header(path,["Element","Entry2D","VBox"])+'''func build_view() -> Element:
	return <Entry2D name="UI" width={600} height={400}><VBox name="Column" width="100%" height="100%"><FlexWrapper name="Wrapper" /></VBox></Entry2D>
''')
	path = "res://app/Footer.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Spacer","Text"])+'''var clicks: int = 0
func pressed() -> void:
	clicks += 1
func _ready() -> void:
	if OS.get_environment("L06_EDITOR")=="1": editor_proof.call_deferred()
func editor_proof() -> void:
	var button = get_node("Borrowed")
	button.pressed.connect(self.pressed)
	var samples: Array = []
	for size in [Vector2i(640,480),Vector2i(1000,800)]:
		get_tree().root.size = size
		for frame in range(15): await get_tree().process_frame
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		get_viewport().push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		get_viewport().push_input(event,true)
		samples.append({"bottom":button.global_position.y+button.size.y,"viewport":size.y,"spacer":get_node("UI/Column/Space").layout_size.y})
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://l07-editor-game.png")
	var file := FileAccess.open("res://.godot/l07-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"samples":samples,"clicks":self.clicks}))
	file.close()
	DirAccess.rename_absolute("res://.godot/l07-game.tmp","res://.godot/l07-game.json")
func build_view() -> Element:
	return <Entry2D name="UI" width="100vw" height="100vh"><VBox name="Column" width="100%" height="100%" horizontal_align="stretch" gap="8px">
		<Spacer name="Space" grow={1} width="50%" />
		<Text name="Hello" text="Hello World!" />
		<Text name="Fun" text="This is fun!" />
		<Settings name="Settings" />
		<Rose name="Rose" />
		{get_children()}
	</VBox></Entry2D>
''')
	var footer_source := FileAccess.get_file_as_string(path)
	write("res://app/Before.gogo",footer_source.replace('width="100vw" height="100vh"','width="100%" height="100%"').replace('<Spacer name="Space" grow={1} width="50%"','<VBox name="Space" height="100%" width="50%"'))
	path = "res://app/Policy.gogo"
	write(path,header(path,["Element","Entry2D","Box","Rect"])+'''@bindable var flipped: bool = false
func build_view() -> Element:
	return <Entry2D width={500} height={400}><Box name="Policy" direction={"column" if self.flipped else "row"} horizontal_align={"stretch" if self.flipped else "end"} vertical_align={"center" if self.flipped else "stretch"} width={400} height={300} gap={12}>
		<Rect name="A" width={40} height={20} />
		<Rect name="B" width={70} height={30} />
	</Box></Entry2D>
''')
	var result := Build.run_build()
	print("L06_BUILD ",JSON.stringify(result))
	if result.ok:
		var home := Node2D.new()
		home.name = "Home"
		home.set_script(load("res://app/generated/Home.gd"))
		var borrowed := Button.new()
		borrowed.name = "Borrowed"
		borrowed.text = "Native scene Button"
		home.add_child(borrowed)
		borrowed.owner = home
		var packed := PackedScene.new()
		packed.pack(home)
		ResourceSaver.save(packed,"res://app/Home.tscn")
		home.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
		ProjectSettings.save()
		var footer = Node2D.new()
		footer.name = "Footer"
		footer.set_script(load("res://app/generated/Footer.gd"))
		var button := Button.new()
		button.name = "Borrowed"
		button.text = "Native footer button"
		footer.add_child(button)
		button.owner = footer
		var scene := PackedScene.new()
		scene.pack(footer)
		ResourceSaver.save(scene,"res://app/Footer.tscn")
		footer.free()
		print("L06_BUILD_OK")
	quit(0 if result.ok else 1)
