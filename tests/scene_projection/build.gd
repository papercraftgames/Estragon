extends SceneTree
const Build = preload("res://addons/estragon/editor/build_service.gd")
const Imports = preload("res://addons/estragon/editor/imports.gd")
const Catalog = preload("res://addons/estragon/editor/components.gd")
static func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
static func header(path: String, names: Array, spatial := false) -> String:
	var text := "extends Node3D\n" if spatial else "extends Node2D\n"
	for name in names: text += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	return text
static func install() -> void:
	var path := "res://app/Home.gogo"
	write(path,header(path,["Element","Entry2D","VBox","Text"])+'''@bindable var tick: int = 0
@bindable var show_children: bool = true
@bindable var alternate: bool = false
@bindable var single: bool = false
@bindable var repeat_children: bool = false
@bindable var replace_root: bool = false
func _ready() -> void:
	if OS.get_environment("E08_EDITOR_PROOF")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var settings = get_node_or_null("Settings")
	var button = settings.get_node("View/Action") if settings != null else null
	var hello = get_node("UI/Column/Hello")
	var middle = get_node("UI/Column/Middle")
	if button != null:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_transform_with_canvas()*(button.layout_size/2)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		get_tree().root.push_input(event,true)
		event = event.duplicate()
		event.pressed = false
		get_tree().root.push_input(event,true)
	get_viewport().get_texture().get_image().save_png("res://editor-game.png")
	var file := FileAccess.open("res://.godot/e08-game.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"settings":settings != null,"caption":button.text if button != null else "","button_y":button.global_position.y if button != null else 0,"button_height":button.layout_size.y if button != null else 0,"hello_end":hello.global_position.y+hello.layout_size.y,"middle_y":middle.global_position.y,"clicks":settings.clicks if settings != null else 0,"persisted":settings.persisted if settings != null else 0,"native_parent":settings.get_parent()==self if settings != null else false,"owner":settings.owner==self if settings != null else false,"children":get_child_count(),"sprite":get_node("Sprite2D").position==Vector2(400,220)}))
	file.close()
func references():
	if self.single: return get_node("Settings")
	return get_children() if self.show_children else []
func build_view() -> Element:
	if self.replace_root: return <Entry2D name="Other"><VBox name="OtherBox">{self.references()}</VBox></Entry2D>
	return <Entry2D name="UI" position={Vector2(30,20)} width={480.0}>
		<VBox name="Column" gap={8.0}>
			<Text name="Hello" text={"Hello World! "+str(self.tick)} />
			{self.references() if not self.alternate else null}
			<Text name="Middle" text="After settings" />
			{self.references() if self.alternate or self.repeat_children else null}
		</VBox>
	</Entry2D>
''')
	path = "res://app/Settings.gogo"
	write(path,header(path,["Element","VBox","UiButton"])+'''@export var persisted: int = 17
@bindable var caption: String = "Settings"
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func build_view() -> Element:
	return <VBox name="View"><UiButton name="Action" text={self.caption} pressed={self.pressed} /></VBox>
''')
	path = "res://app/Nested.gogo"
	write(path,header(path,["Element","VBox"])+'''func build_view() -> Element:
		return <VBox name="View">{get_children()}</VBox>
	''')
	path = "res://app/Spatial.gogo"
	var header3d := header(path,["Element","Entry3D"],true)
	header3d += Imports.declaration("Part3D",(preload("res://addons/estragon/runtime/node/component_3d.gd") as Script).resource_path,path)
	write(path,header3d+'''@bindable var tick: int = 0
func build_view() -> Element:
	return <Entry3D name="UI" position={Vector3(3,4,5)}><Part3D name="Row" gap={2.0}><Part3D width={2.0} height={3.0} depth={4.0} />{get_children()}</Part3D></Entry3D>
''')
static func scene() -> Node2D:
	var home: Node2D = load("res://app/generated/Home.gd").new()
	home.name = "Home"
	var settings: Node2D = load("res://app/generated/Settings.gd").new()
	settings.name = "Settings"
	settings.position = Vector2(90,100)
	home.add_child(settings)
	settings.owner = home
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.position = Vector2(400,220)
	var image := GradientTexture2D.new()
	image.width = 24
	image.height = 24
	sprite.texture = image
	home.add_child(sprite)
	sprite.owner = home
	return home
func _initialize() -> void:
	install()
	var report := Build.run_build()
	print("E08_BUILD ",JSON.stringify(report))
	if report.ok:
		var home := Node2D.new()
		home.name = "Home"
		home.set_script(load("res://app/generated/Home.gd"))
		var packed := PackedScene.new()
		packed.pack(home)
		ResourceSaver.save(packed,"res://app/Home.tscn")
		home.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
		ProjectSettings.save()
		print("E08_BUILD_OK")
	quit(0 if report.ok else 1)
