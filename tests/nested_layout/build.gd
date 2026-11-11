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
var local_state: int = 7
func exit() -> void:
	print("L03_EXIT_QUIT")
	get_tree().quit()
func leaf():
	return <UiButton name="Exit" pressed={self.exit} text={self.caption} fill_width={self.wide} fill_height={self.wide} /> if self.visible_button else null
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
	if self.button: return <UiButton name="RoseButton" pressed={self.pressed} text="Rose is cute!" fill_width={self.wide} />
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
	install()
	var report := Build.run_build()
	print("L03_BUILD ",JSON.stringify(report))
	if report.ok: print("L03_BUILD_OK")
	quit(0 if report.ok else 1)
