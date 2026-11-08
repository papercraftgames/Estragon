@tool
extends RefCounted
const Catalog = preload("res://addons/estragon/editor/components.gd")
const Imports = preload("res://addons/estragon/editor/imports.gd")
const HOME := "res://app/Screens/Home.gogo"
const SETTINGS := "res://app/Screens/Settings.gogo"
const LEAF := "res://app/Screens/Nested/Leaf.gogo"
static func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
static func header(path: String, base: String, names: Array) -> String:
	var result := "extends "+base+"\n"
	for name in names: result += Imports.declaration(name,Catalog.path(Catalog.named(name)),path)
	return result
static func settings(path: String = SETTINGS) -> String:
	return header(path,"Node2D",["Element","Entry2D","Text"])+'''@bindable var title: String = "Settings child"
signal changed(value: bool)
func build_view() -> Element:
	return <Entry2D name="SettingsView" position={Vector2(0,60)} viewport_width_scale={0.8}>
		<Text name="Caption" text={self.title} />
		<Leaf name="Leaf" />
	</Entry2D>
'''
static func leaf() -> String:
	return header(LEAF,"Node2D",["Element"])+'''func build_view() -> Element:
	return <Node2D name="LeafView" />
'''
static func home() -> String:
	return header(HOME,"Node2D",["Element","Entry2D","VBox","Text"])+'''@bindable var tick: int = 0
var received: bool = false
func on_changed(value: bool) -> void:
	received = value
func build_view() -> Element:
	return <Entry2D name="UI">
		<VBox name="Column" fill_width={true} fill_height={true}>
			<Text name="Greeting" text={"Hello World! " + str(self.tick)} />
			<Settings name="SettingsChild" title={"Settings child"} changed={self.on_changed} />
			<Boundary name="BoundaryChild" />
		</VBox>
	</Entry2D>
func _ready() -> void:
	if not Engine.is_editor_hint() and OS.get_environment("ESTRAGON_E07_GAME") == "1": _proof.call_deferred()
func _proof() -> void:
	for frame in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://e02-project-game.png")
	var child := get_node("UI/Column/SettingsChild/SettingsView/Caption")
	var output := FileAccess.open("res://.godot/e07-game.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"text":child.text,"leaf":get_node_or_null("UI/Column/SettingsChild/SettingsView/Leaf/LeafView")!=null}))
	output.close()
'''
static func install() -> void:
	write(SETTINGS,settings())
	write(LEAF,leaf())
	var boundary := "res://app/Screens/Boundary.gogo"
	write(boundary,header(boundary,"Node2D",["Element","Text"])+'''func build_view() -> Element:
	return <Text name="Unscoped" text="No inherited layout" />
''')
	write(HOME,home())
	var spatial := "res://app/Screens/Spatial.gogo"
	write(spatial,header(spatial,"Node3D",["Element"])+'''func build_view() -> Element:
	return <SpatialChild name="SpatialChild" />
''')
	var child := "res://app/Screens/Nested/SpatialChild.gogo"
	write(child,header(child,"Node3D",["Element"])+'''func build_view() -> Element:
	return <Node3D name="SpatialView" />
''')
