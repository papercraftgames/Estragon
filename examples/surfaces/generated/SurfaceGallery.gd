extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const PANEL_TEXTURE = preload("../panel_gradient.tres")
signal props_changed(previous: Dictionary, value: Dictionary)
var props: Dictionary = {}:
	set(_gogo_incoming_props):
		if is_same(props, _gogo_incoming_props): return
		var _gogo_previous_props: Dictionary = props
		props = _gogo_incoming_props
		props_changed.emit(_gogo_previous_props, _gogo_incoming_props)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"props_changed")
		return props

signal radius_changed(previous: Variant, value: Variant)
var radius: Variant = "24px":
	set(_gogo_incoming_radius):
		if is_same(radius, _gogo_incoming_radius): return
		var _gogo_previous_radius: Variant = radius
		radius = _gogo_incoming_radius
		radius_changed.emit(_gogo_previous_radius, _gogo_incoming_radius)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"radius_changed")
		return radius

signal clipped_changed(previous: bool, value: bool)
var clipped: bool = true:
	set(_gogo_incoming_clipped):
		if is_same(clipped, _gogo_incoming_clipped): return
		var _gogo_previous_clipped: bool = clipped
		clipped = _gogo_incoming_clipped
		clipped_changed.emit(_gogo_previous_clipped, _gogo_incoming_clipped)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"clipped_changed")
		return clipped

signal enabled_changed(previous: bool, value: bool)
var enabled: bool = true:
	set(_gogo_incoming_enabled):
		if is_same(enabled, _gogo_incoming_enabled): return
		var _gogo_previous_enabled: bool = enabled
		enabled = _gogo_incoming_enabled
		enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
		return enabled

signal checked_changed(previous: bool, value: bool)
var checked: bool = false:
	set(_gogo_incoming_checked):
		if is_same(checked, _gogo_incoming_checked): return
		var _gogo_previous_checked: bool = checked
		checked = _gogo_incoming_checked
		checked_changed.emit(_gogo_previous_checked, _gogo_incoming_checked)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"checked_changed")
		return checked

var clicks: int = 0
func pressed(): clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(Color.WHITE),
		(1.5),
		(2.5),
		(self.radius),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
		(PANEL_TEXTURE),
		(8.5),
		(2.5),
		(PANEL_TEXTURE),
		(PANEL_TEXTURE),
		(2),
		(self.clipped),
		(not self.enabled),
		(pressed),
		(Vector2(200,100)),
		(pressed),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "checked", func(_gogo_source, _gogo_edit: bool): _gogo_source.checked = _gogo_edit, "checked")),
		(PANEL_TEXTURE)
	)

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Color,
		_gogo_value_1: Variant,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Variant,
		_gogo_value_5: Texture2D,
		_gogo_value_6: Variant,
		_gogo_value_7: Variant,
		_gogo_value_8: Texture2D,
		_gogo_value_9: Texture2D,
		_gogo_value_10: Variant,
		_gogo_value_11: bool,
		_gogo_value_12: bool,
		_gogo_value_13: Callable,
		_gogo_value_14: Vector2,
		_gogo_value_15: Callable,
		_gogo_value_16: Variant,
		_gogo_value_17: Texture2D
	) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {"name": "Title", "color": _gogo_value_0}, {}, [], "examples/surfaces/SurfaceGallery.gogo:22:3", null, false)
		_gogo_element_1.set_text_body([["Native visual surfaces", "examples/surfaces/SurfaceGallery.gogo:22:42"]])
		var _gogo_element_3 := _GogoElement_0.new(Rect, {"name": "Square", "width": "140px", "height": "100px", "background_color": "#328abe", "border_color": "#eaffff", "border_width": _gogo_value_1}, {}, [], "examples/surfaces/SurfaceGallery.gogo:24:4", null, false)
		var _gogo_element_4 := _GogoElement_0.new(Rect, {}, {}, [], "examples/surfaces/SurfaceGallery.gogo:25:4", null, false)
		_gogo_element_4.expand([["name", "Round", "examples/surfaces/SurfaceGallery.gogo:25:10"], ["width", "140px", "examples/surfaces/SurfaceGallery.gogo:25:23"], ["height", "100px", "examples/surfaces/SurfaceGallery.gogo:25:37"], ["background_color", "#347f68", "examples/surfaces/SurfaceGallery.gogo:25:52"], ["border_color", "#eaffff", "examples/surfaces/SurfaceGallery.gogo:25:79"], ["border_width", _gogo_value_2, "examples/surfaces/SurfaceGallery.gogo:25:102"], ["corner_radius", _gogo_value_3, "examples/surfaces/SurfaceGallery.gogo:25:121"], [null, _gogo_value_4, "examples/surfaces/SurfaceGallery.gogo:25:149"]])
		var _gogo_element_5 := _GogoElement_0.new(Rect, {"name": "Asymmetric", "width": "140px", "height": "100px", "background_texture": _gogo_value_5, "corner_radius": "30px", "corner_radius_top_left": "0px", "corner_radius_bottom_right": "70px", "border_color": "#ffcc88", "border_left_width": _gogo_value_6, "border_width": _gogo_value_7}, {}, [], "examples/surfaces/SurfaceGallery.gogo:26:4", null, false)
		var _gogo_element_6 := _GogoElement_0.new(Rect, {"name": "Huge", "width": "140px", "height": "100px", "background_color": "#514174", "corner_radius": "1000000px", "border_color": "#c5b0ec", "border_width": "3px"}, {}, [], "examples/surfaces/SurfaceGallery.gogo:27:4", null, false)
		var _gogo_element_8 := _GogoElement_0.new(Text, {}, {}, [], "examples/surfaces/SurfaceGallery.gogo:28:154", null, false)
		_gogo_element_8.set_text_body([["Gradient", "examples/surfaces/SurfaceGallery.gogo:28:160"]])
		var _gogo_element_7 := _GogoElement_0.new(VBox, {"name": "Gradient", "width": "140px", "height": "100px", "background_color": "#30304080", "background_texture": _gogo_value_8, "corner_radius": "20%", "padding": "10px"}, {}, [_gogo_element_8], "examples/surfaces/SurfaceGallery.gogo:28:4", null, false)
		var _gogo_element_9 := _GogoElement_0.new(Rect, {"name": "Tiled", "width": "140px", "height": "100px", "background_color": "#50305080", "background_texture": _gogo_value_9, "background_texture_mode": "tile", "corner_radius": "18px"}, {}, [], "examples/surfaces/SurfaceGallery.gogo:29:4", null, false)
		var _gogo_element_2 := _GogoElement_0.new(HBox, {"name": "Panels", "wrap": true, "width": "100%", "gap": "8px"}, {}, [_gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_element_9], "examples/surfaces/SurfaceGallery.gogo:23:3", null, false)
		var _gogo_element_11 := _GogoElement_0.new(_GogoImport_0, {"name": "Custom", "width": "500px", "height": "100px", "corner_radius": "14px", "disabled": _gogo_value_12}, {"pressed": _gogo_value_13}, [], "examples/surfaces/SurfaceGallery.gogo:32:4", null, false)
		_gogo_element_11.set_text_body([["Native rounded button", "examples/surfaces/SurfaceGallery.gogo:32:122"]])
		var _gogo_element_12 := _GogoElement_0.new(NativeButton, {"name": "Native", "custom_minimum_size": _gogo_value_14}, {"pressed": _gogo_value_15}, [], "examples/surfaces/SurfaceGallery.gogo:33:4", null, false)
		_gogo_element_12.set_text_body([["Godot Button", "examples/surfaces/SurfaceGallery.gogo:33:89"]])
		var _gogo_element_10 := _GogoElement_0.new(Grid, {"name": "Clipped", "columns": _gogo_value_10, "width": "100%", "height": "120px", "clip_content": _gogo_value_11, "padding": "8px", "border_width": "2px", "border_color": "#8295bc", "corner_radius": "20px", "background_color": "#252b38"}, {}, [_gogo_element_11, _gogo_element_12], "examples/surfaces/SurfaceGallery.gogo:31:3", null, false)
		var _gogo_element_13 := _GogoElement_0.new(Toggle, {"name": "Toggle", "width": "200px", "corner_radius": "12px"}, {}, [], "examples/surfaces/SurfaceGallery.gogo:35:3", null, false)
		_gogo_element_13.set_text_body([["Native Toggle", "examples/surfaces/SurfaceGallery.gogo:35:86"]])
		_gogo_element_13.bindings = {"value": _gogo_value_16}
		var _gogo_element_14 := _GogoElement_0.new(Text, {"name": "Footer", "height": "80px", "background_texture": _gogo_value_17, "corner_radius": "8px", "padding": "8px"}, {}, [], "examples/surfaces/SurfaceGallery.gogo:36:3", null, false)
		_gogo_element_14.set_text_body([["Text foreground stays native", "examples/surfaces/SurfaceGallery.gogo:36:106"]])
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "background_color": "#142536", "padding": "8px", "direction": "column", "gap": "8px", "vertical_scroll": true}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_10, _gogo_element_13, _gogo_element_14], "examples/surfaces/SurfaceGallery.gogo:21:9", null, false)
		return _gogo_element_0
