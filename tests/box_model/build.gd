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
	write(path,header(path,["Element","Entry2D","VBox","HBox","Box","Rect","UiButton"])+'''@bindable var inset: float = 12.0
var clicks: int = 0
func pressed() -> void:
	clicks += 1
func _ready() -> void:
	if OS.get_environment("L01_EDITOR")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	inset = 20.0
	for frame in range(10): await get_tree().process_frame
	var button = $UI/Column/Action
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
	var file := FileAccess.open("res://.godot/l01-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"x":button.global_position.x,"y":button.global_position.y,"width":button.layout_size.x,"clicks":clicks,"padding":$UI/Column.padding}))
	file.close()
	DirAccess.rename_absolute("res://.godot/l01-game.tmp","res://.godot/l01-game.json")
func build_view() -> Element:
	return <Entry2D name="UI" width={500} height={400} padding={10}>
		<VBox name="Column" fill_width={true} fill_height={true} padding_left={24} padding={self.inset} gap={8}>
			<UiButton name="Action" text="Pixel Box" width="180" height={40} margin={5} pressed={self.pressed} />
			<Settings name="Settings" />
			<Box name="Ordinary" padding={3} margin={4}><Rect width={20} height={10} /></Box>
		</VBox>
	</Entry2D>
''')
	path = "res://app/Settings.gogo"
	write(path,header(path,["Element","HBox","Rect"])+'''func build_view() -> Element:
	return <HBox name="Row" margin={7} margin_left={11} padding={4} gap={6}>
		<Rect name="Red" width={40} height={20} fill={Color.RED} />
		<Rect name="Blue" width={30} height={20} fill={Color.BLUE} />
	</HBox>
''')
	var result := Build.run_build()
	print("L01_BUILD ",JSON.stringify(result))
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
		print("L01_BUILD_OK")
	quit(0 if result.ok else 1)
