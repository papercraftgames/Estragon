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
	var text := "extends Node2D\n"
	for name in names: text += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	return text
static func install() -> void:
	var path := "res://app/Home.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Text"])+'''@bindable var extent: Vector2 = Vector2(640,360)
@bindable var tick: int = 0
@bindable var reverse: bool = false
@bindable var show_settings: bool = true
@bindable var deep: bool = false
func _ready() -> void:
	extent = get_viewport_rect().size
	get_viewport().size_changed.connect(resized)
	if OS.get_environment("L04_EDITOR_PROOF")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var button = get_node("UI/Column/Settings/Row/Exit")
	var rose = get_node("UI/Column/Rose/Row/RoseText")
	get_viewport().get_texture().get_image().save_png("res://editor-game.png")
	var file := FileAccess.open("res://.godot/l04-game.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"caption":button.text,"button_y":button.global_position.y,"button_height":button.size.y if button is Control else button.layout_size.y,"rose_y":rose.global_position.y,"rose_size":rose.layout_size.y,"children":get_node("UI/Column").get_child_count()}))
	file.close()
func resized() -> void:
	extent = get_viewport_rect().size
func views():
	if self.deep: return [<Multi name="Multi" />]
	var settings = <Settings name="Settings" key="settings" /> if self.show_settings else null
	var rose = <Rose name="Rose" key="rose" />
	return [rose,settings] if self.reverse else [settings,rose]
func build_view() -> Element:
	return <Entry2D name="UI" width={self.extent.x} height={self.extent.y}>
		<VBox name="Column" fill_width={true} fill_height={true}>
			<VBox name="Spacer" fill_height={true} />
			<Text name="Hello" text={"Hello World!" if self.tick==0 else "Hello World! "+str(self.tick)} />
			<Text name="Fun" text="This is fun!" />
			{self.views()}
		</VBox>
	</Entry2D>
''')
	path = "res://app/Settings.gogo"
	write(path,header(path,["Element","HBox","UiButton","Text","Entry2D"])+'''@bindable var caption: String = "Exit"
@bindable var wide: bool = false
@bindable var view_width: float = -1
@bindable var view_height: float = -1
@bindable var visible_button: bool = true
@bindable var direct: bool = false
@bindable var independent: bool = false
@bindable var framework: bool = false
var local_state: int = 7
func exit() -> void:
	print("L04_EXIT_QUIT")
	get_tree().quit()
func leaf():
	if self.framework: return <UiButton name="Exit" pressed={self.exit} text={self.caption} />
	return <Button name="Exit" pressed={self.exit} text={self.caption} size_flags_horizontal={Control.SIZE_EXPAND_FILL if self.wide else Control.SIZE_FILL} size_flags_vertical={Control.SIZE_EXPAND_FILL if self.wide else Control.SIZE_FILL} /> if self.visible_button else null
func build_view() -> Element:
	if self.independent: return <Entry2D name="Independent" width={180.0} height={60.0} position={Vector2(250,40)}><Text name="IndependentText" text="Independent" /></Entry2D>
	if self.direct: return <Text name="Direct" text={self.caption} />
	return <HBox name="Row" width={self.view_width} height={self.view_height} fill_width={self.wide} gap={5.0}>{self.leaf()}</HBox>
''')
	path = "res://app/Rose.gogo"
	write(path,header(path,["Element","HBox","Text","UiButton"])+'''@bindable var button: bool = false
@bindable var wide: bool = false
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func leaf():
	if self.button: return <Button name="RoseButton" pressed={self.pressed} text="Rose is cute!" size_flags_horizontal={Control.SIZE_EXPAND_FILL if self.wide else Control.SIZE_FILL} />
	return <Text name="RoseText" text="Rose is cute!" />
func build_view() -> Element:
	return <HBox name="Row" fill_width={self.wide}>{self.leaf()}</HBox>
''')
	path = "res://app/Multi.gogo"
	write(path,header(path,["Element","VBox"])+'''func build_view() -> Element:
	return <VBox name="Stack" gap={3.0}><Settings name="Settings" /><Rose name="Rose" /></VBox>
''')
	path = "res://app/Relay.gogo"
	write(path,header(path,["Element"])+'''func build_view() -> Element:
	return <Settings name="Settings" />
''')
	path = "res://app/Spatial.gogo"
	var spatial := "extends Node3D\n"
	for name in ["Element","Entry3D"]: spatial += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	spatial += Imports.declaration("Part3D",(preload("res://addons/estragon/runtime/node/component_3d.gd") as Script).resource_path,path)
	write(path,spatial+'''@bindable var room: float = -1
func build_view() -> Element:
	return <Part3D name="Row" width={self.room}><Part3D name="A" width={2.0} height={3.0} depth={4.0} /><Part3D name="B" width={5.0} height={2.0} depth={1.0} /></Part3D>
''')
func _initialize() -> void:
	if OS.get_environment("L04_EXAMPLES")!="1":
		install()
		extra_sources()
	var report := Build.run_build()
	print("L04_BUILD ",JSON.stringify(report))
	if report.ok:
		for name in ["Home","Borrow"]:
			var node := Node2D.new()
			node.name = name
			node.set_script(load("res://app/generated/"+name+".gd"))
			var packed := PackedScene.new()
			packed.pack(node)
			ResourceSaver.save(packed,"res://app/"+name+".tscn")
			node.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
		ProjectSettings.save()
		print("L04_BUILD_OK")
	quit(0 if report.ok else 1)

static func extra_sources() -> void:
	var path := "res://app/Widgets.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Text"])+'''var clicks: int = 0
var picture: Texture2D
func _ready() -> void:
	var image := Image.create(40,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.CORNFLOWER_BLUE)
	picture = ImageTexture.create_from_image(image)
func pressed() -> void:
	clicks += 1
func build_view() -> Element:
	return <Entry2D name="UI" position={Vector2(20,20)} width={400.0}>
		<VBox name="Column" gap={8.0} fill_width={true}>
			<Button name="A" text="Native A" pressed={self.pressed} />
			<Button name="B" text="Native B" pressed={self.pressed} />
			<Text name="FrameworkText" text="Framework Text" />
			<Label name="Label" text="Ready" />
			<LineEdit name="Edit" text="Native editing" />
			<TextureRect name="Image" texture={self.picture} />
			<HBoxContainer name="Container"><Label name="Left" text="Left" /><Label name="Right" text="Right" /></HBoxContainer>
		</VBox>
	</Entry2D>
''')
	path = "res://app/NativeRoot.gogo"
	write(path,header(path,["Element"])+'''func build_view() -> Element:
	return <Button name="NativeRoot" text="Direct native root" />
''')
	path = "res://app/Borrow.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Text"])+'''@bindable var show_children: bool = true
@bindable var tick: int = 0
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func _ready() -> void:
	if has_node("SceneButton") and not $SceneButton.pressed.is_connected(pressed): $SceneButton.pressed.connect(pressed)
	if OS.get_environment("L04_EDITOR_PROOF")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var button: Button = $SceneButton
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	get_viewport().get_texture().get_image().save_png("res://editor-borrowed.png")
	var file := FileAccess.open("res://.godot/l04-borrow-game.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"children":get_child_count(),"parent":button.get_parent()==self,"owner":button.owner==self,"clicks":clicks,"height":button.size.y,"y":button.global_position.y,"after":$UI/Column/After.global_position.y}))
	file.close()
func build_view() -> Element:
	return <Entry2D name="UI" position={Vector2(30,20)}><VBox name="Column" gap={8.0}><Text name="Before" text={"Before "+str(self.tick)} />{get_children() if self.show_children else []}<Text name="After" text="After" /></VBox></Entry2D>
''')
