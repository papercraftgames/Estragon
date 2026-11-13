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
	var source := header(path,["Element","Entry2D","VBox","Text"])+'''var clicks: int = 0
func pressed() -> void:
	clicks += 1
func _ready() -> void:
	if OS.get_environment("L05_EDITOR")=="1": proof.call_deferred()
func proof() -> void:
	for frame in range(10): await get_tree().process_frame
	get_window().size = Vector2i(1400,900)
	for frame in range(10): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var entry = $UI
	var button: Button = $UI/Column/Settings/Row/Exit
	var rose = $UI/Column/Rose/Row/RoseText
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas()*(button.size/2)
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event,true)
	get_viewport().get_texture().get_image().save_png("res://editor-game.png")
	var file := FileAccess.open("res://.godot/l05-game.tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify({"width":entry.layout_size.x,"height":entry.layout_size.y,"visible_width":get_viewport_rect().size.x,"visible_height":get_viewport_rect().size.y,"rose_bottom":rose.global_position.y+rose.layout_size.y,"button_bottom":button.global_position.y+button.size.y,"rose_y":rose.global_position.y,"clicks":$UI/Column/Settings.clicks}))
	file.close()
	DirAccess.rename_absolute("res://.godot/l05-game.tmp","res://.godot/l05-game.json")
func build_view() -> Element:
	return <Entry2D name="UI" viewport_width_scale={1.0} viewport_height_scale={1.0}>
		<VBox name="Column" fill_width={true} fill_height={true}>
			<VBox name="Spacer" fill_height={true} />
			<Text name="Hello" text="Hello World!" />
			<Text name="Fun" text="This is fun!" />
			<Settings name="Settings" />
			{get_children()}
			<Rose name="Rose" />
		</VBox>
	</Entry2D>
'''
	write(path,source)
	write("res://app/Snapshot.gogo",source.replace('viewport_width_scale={1.0} viewport_height_scale={1.0}','width={get_viewport_rect().size.x} height={get_viewport_rect().size.y}'))
	path = "res://app/Settings.gogo"
	write(path,header(path,["Element","HBox"])+'''var clicks: int = 0
func exit() -> void:
	clicks += 1
	if OS.get_environment("L05_EXIT")=="1":
		print("L05_EXIT_QUIT")
		get_tree().quit()
func build_view() -> Element:
	return <HBox name="Row"><Button name="Exit" text="Exit" pressed={self.exit} /></HBox>
''')
	path = "res://app/Rose.gogo"
	write(path,header(path,["Element","HBox","Text"])+'''func build_view() -> Element:
	return <HBox name="Row"><Text name="RoseText" text="Rose is cute!" /></HBox>
''')
	var result := Build.run_build()
	print("L05_BUILD ",JSON.stringify(result))
	if result.ok:
		var home := Node2D.new()
		home.name = "Home"
		home.set_script(load("res://app/generated/Home.gd"))
		var borrowed := Button.new()
		borrowed.name = "Borrowed"
		borrowed.text = "Scene Button"
		home.add_child(borrowed)
		borrowed.owner = home
		var packed := PackedScene.new()
		packed.pack(home)
		ResourceSaver.save(packed,"res://app/Home.tscn")
		home.free()
		ProjectSettings.set_setting("application/run/main_scene","res://app/Home.tscn")
		ProjectSettings.save()
		print("L05_BUILD_OK")
	quit(0 if result.ok else 1)
