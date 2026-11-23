extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
signal order_changed(previous: Array, value: Array)
var order: Array = ["a","b","c","d","e","f"]:
	set(_gogo_incoming_order):
		if is_same(order, _gogo_incoming_order): return
		var _gogo_previous_order: Array = order
		order = _gogo_incoming_order
		order_changed.emit(_gogo_previous_order, _gogo_incoming_order)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"order_changed")
		return order

signal show_extra_changed(previous: bool, value: bool)
var show_extra: bool = true:
	set(_gogo_incoming_show_extra):
		if is_same(show_extra, _gogo_incoming_show_extra): return
		var _gogo_previous_show_extra: bool = show_extra
		show_extra = _gogo_incoming_show_extra
		show_extra_changed.emit(_gogo_previous_show_extra, _gogo_incoming_show_extra)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_extra_changed")
		return show_extra

signal enabled_changed(previous: bool, value: bool)
var enabled: bool = false:
	set(_gogo_incoming_enabled):
		if is_same(enabled, _gogo_incoming_enabled): return
		var _gogo_previous_enabled: bool = enabled
		enabled = _gogo_incoming_enabled
		enabled_changed.emit(_gogo_previous_enabled, _gogo_incoming_enabled)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"enabled_changed")
		return enabled

signal grid_props_changed(previous: Dictionary, value: Dictionary)
var grid_props: Dictionary = {"columns":["140px","1fr"],"rows":["48px","auto"],"areas":["header header","sidebar main"]}:
	set(_gogo_incoming_grid_props):
		if is_same(grid_props, _gogo_incoming_grid_props): return
		var _gogo_previous_grid_props: Dictionary = grid_props
		grid_props = _gogo_incoming_grid_props
		grid_props_changed.emit(_gogo_previous_grid_props, _gogo_incoming_grid_props)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"grid_props_changed")
		return grid_props

signal header_props_changed(previous: Dictionary, value: Dictionary)
var header_props: Dictionary = {}:
	set(_gogo_incoming_header_props):
		if is_same(header_props, _gogo_incoming_header_props): return
		var _gogo_previous_header_props: Dictionary = header_props
		header_props = _gogo_incoming_header_props
		header_props_changed.emit(_gogo_previous_header_props, _gogo_incoming_header_props)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"header_props_changed")
		return header_props

signal placement_changed(previous: Dictionary, value: Dictionary)
var placement: Dictionary = {"area":"main"}:
	set(_gogo_incoming_placement):
		if is_same(placement, _gogo_incoming_placement): return
		var _gogo_previous_placement: Dictionary = placement
		placement = _gogo_incoming_placement
		placement_changed.emit(_gogo_previous_placement, _gogo_incoming_placement)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"placement_changed")
		return placement

var clicks: int = 0
var native_clicks: int = 0
var edits: Array = []
func pressed() -> void: clicks += 1
func native_pressed() -> void: native_clicks += 1
func edited(value: bool) -> void: edits.append(value)
func card(value: String) -> Element:
	return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/responsive/ResponsiveGallery.gogo:1342", value, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0(
		(_gogo_mount_key),
		(value),
		("Card "+value),
		(pressed)
	))
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_1(
		(Color("#ffc65c")),
		(true),
		(self.order.map(card)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.grid_props)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.header_props)),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "self.enabled", (self.enabled) if self != null else null)),
		(native_pressed),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.placement)),
		(3),
		(native_pressed),
		(preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/responsive/ResponsiveGallery.gogo:2780", "extra", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_2()) if self.show_extra else null),
		(get_children())
	)

const _GOGO_RENDER_FUNCTIONS_c0ecc4494879e4a2 = {
"ordinary": ["pressed", "native_pressed", "edited"],
"reactive": ["card", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_c0ecc4494879e4a2 = {
"enabled": "bool",
"grid_props": "Dictionary",
"header_props": "Dictionary",
"order": "Array",
"placement": "Dictionary",
"show_extra": "bool"
}

const _GogoProject_0 = preload("NestedResponsive.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Variant,
		_gogo_value_1: StringName,
		_gogo_value_2: String,
		_gogo_value_3: Callable
	) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": _gogo_value_1, "text": _gogo_value_2, "width": "120px", "height": "36px"}, {"pressed": _gogo_value_3}, [], "examples/responsive/ResponsiveGallery.gogo:25:9", _gogo_value_0, true)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0


	static func _gogo_build_1(
		_gogo_value_0: Color,
		_gogo_value_1: bool,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Variant,
		_gogo_value_5: Variant,
		_gogo_value_6: Callable,
		_gogo_value_7: Variant,
		_gogo_value_8: Variant,
		_gogo_value_9: Callable,
		_gogo_value_10: Variant,
		_gogo_value_11: Variant
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {"text": "Responsive Wrap + Grid", "color": _gogo_value_0}, {}, [], "examples/responsive/ResponsiveGallery.gogo:29:4", null, false)
		_gogo_element_2.resolve_bindings()
		var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Cards", "width": "100%", "wrap": _gogo_value_1, "gap": "10px", "row_gap": "12px", "horizontal_align": "space-between", "vertical_align": "center"}, {}, [_gogo_value_2], "examples/responsive/ResponsiveGallery.gogo:30:4", null, false)
		_gogo_element_3.resolve_bindings()
		var _gogo_element_5 := _GogoElement_0.new(NativeButton, {}, {}, [], "examples/responsive/ResponsiveGallery.gogo:34:5", null, false)
		_gogo_element_5.expand([["name", "Header", "examples/responsive/ResponsiveGallery.gogo:34:19"], ["area", "header", "examples/responsive/ResponsiveGallery.gogo:34:33"], ["text", "Native tracks", "examples/responsive/ResponsiveGallery.gogo:34:47"], [null, _gogo_value_4, "examples/responsive/ResponsiveGallery.gogo:34:68"]])
		_gogo_element_5.resolve_bindings()
		var _gogo_element_7 := _GogoElement_0.new(Toggle, {"name": "Enabled", "text": "Enabled", "value": _gogo_value_5}, {}, [], "examples/responsive/ResponsiveGallery.gogo:36:6", null, false)
		_gogo_element_7.origins["value"] = "examples/responsive/ResponsiveGallery.gogo:36:44"
		_gogo_element_7.resolve_bindings()
		var _gogo_element_8 := _GogoElement_0.new(NativeButton, {"name": "Native", "text": "Native Control"}, {"pressed": _gogo_value_6}, [], "examples/responsive/ResponsiveGallery.gogo:37:6", null, false)
		_gogo_element_8.resolve_bindings()
		var _gogo_element_6 := _GogoElement_0.new(VBox, {"name": "Sidebar", "area": "sidebar", "gap": "8px"}, {}, [_gogo_element_7, _gogo_element_8], "examples/responsive/ResponsiveGallery.gogo:35:5", null, false)
		_gogo_element_6.origins["area"] = "examples/responsive/ResponsiveGallery.gogo:35:26"
		_gogo_element_6.resolve_bindings()
		var _gogo_element_9 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/responsive/ResponsiveGallery.gogo:39:5", null, false)
		_gogo_element_9.expand([["name", "Main", "examples/responsive/ResponsiveGallery.gogo:39:23"], [null, _gogo_value_7, "examples/responsive/ResponsiveGallery.gogo:39:35"]])
		_gogo_element_9.resolve_bindings()
		var _gogo_element_4 := _GogoElement_0.new(Grid, {}, {}, [_gogo_element_5, _gogo_element_6, _gogo_element_9], "examples/responsive/ResponsiveGallery.gogo:33:4", null, false)
		_gogo_element_4.expand([["name", "Named", "examples/responsive/ResponsiveGallery.gogo:33:10"], ["width", "100%", "examples/responsive/ResponsiveGallery.gogo:33:23"], ["gap", "10px", "examples/responsive/ResponsiveGallery.gogo:33:36"], ["padding", "10px", "examples/responsive/ResponsiveGallery.gogo:33:47"], ["border_width", "2px", "examples/responsive/ResponsiveGallery.gogo:33:62"], ["border_color", "#8295bc", "examples/responsive/ResponsiveGallery.gogo:33:81"], ["background_color", "#252b38", "examples/responsive/ResponsiveGallery.gogo:33:104"], [null, _gogo_value_3, "examples/responsive/ResponsiveGallery.gogo:33:131"]])
		_gogo_element_4.resolve_bindings()
		var _gogo_element_11 := _GogoElement_0.new(Rect, {"name": "One", "height": "20px", "background_color": "#477dbb"}, {}, [], "examples/responsive/ResponsiveGallery.gogo:42:5", null, false)
		_gogo_element_11.resolve_bindings()
		var _gogo_element_12 := _GogoElement_0.new(Rect, {"name": "Two", "height": "28px", "background_color": "#ffc65c"}, {}, [], "examples/responsive/ResponsiveGallery.gogo:43:5", null, false)
		_gogo_element_12.resolve_bindings()
		var _gogo_element_13 := _GogoElement_0.new(Rect, {"name": "Three", "height": "20px", "background_color": "#477dbb"}, {}, [], "examples/responsive/ResponsiveGallery.gogo:44:5", null, false)
		_gogo_element_13.resolve_bindings()
		var _gogo_element_14 := _GogoElement_0.new(NativeButton, {"name": "Fourth", "text": "Native cell"}, {"pressed": _gogo_value_9}, [], "examples/responsive/ResponsiveGallery.gogo:45:5", null, false)
		_gogo_element_14.resolve_bindings()
		var _gogo_element_10 := _GogoElement_0.new(Grid, {"name": "Automatic", "columns": _gogo_value_8, "width": "100%", "gap": "10px", "background_color": "#30394d"}, {}, [_gogo_element_11, _gogo_element_12, _gogo_element_13, _gogo_element_14, _gogo_value_10, _gogo_value_11], "examples/responsive/ResponsiveGallery.gogo:41:4", null, false)
		_gogo_element_10.resolve_bindings()
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Content", "width": "100%", "gap": "12px", "horizontal_align": "stretch"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_10], "examples/responsive/ResponsiveGallery.gogo:28:3", null, false)
		_gogo_element_1.resolve_bindings()
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/responsive/ResponsiveGallery.gogo:27:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0


	static func _gogo_build_2() -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Extra", "text": "Row 2"}, {}, [], "examples/responsive/ResponsiveGallery.gogo:46:6", "extra", true)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
