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

signal font_size_changed(previous: int, value: int)
var font_size: int = 24:
	set(_gogo_incoming_font_size):
		if is_same(font_size, _gogo_incoming_font_size): return
		var _gogo_previous_font_size: int = font_size
		font_size = _gogo_incoming_font_size
		font_size_changed.emit(_gogo_previous_font_size, _gogo_incoming_font_size)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"font_size_changed")
		return font_size

signal order_changed(previous: Array, value: Array)
var order: Array = [0,1,2,3,4,5,6,7,8]:
	set(_gogo_incoming_order):
		if is_same(order, _gogo_incoming_order): return
		var _gogo_previous_order: Array = order
		order = _gogo_incoming_order
		order_changed.emit(_gogo_previous_order, _gogo_incoming_order)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"order_changed")
		return order

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

var clicks: int = 0
func pressed(): clicks += 1
func card(index: int) -> Element:
	return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/ux01/InheritedScrolling.gogo:901", index, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0(
		(_gogo_mount_key),
		("Card"+str(index)),
		(2 if index==0 else 1),
		(pressed),
		(str(index))
	))
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_1(
		(Vector2(120,80)),
		(pressed),
		(pressed),
		(self.enabled),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
		(112.5),
		(self.font_size),
		(112.5),
		(112.5),
		(112.5),
		(112.5),
		(112.5),
		(112.5),
		(112.5),
		(3),
		(self.order.map(card)),
		(["80px","1fr"]),
		(["120px","240px"]),
		(["head head","left right"])
	)

const _GOGO_RENDER_FUNCTIONS_07d309160f1f0f63 = {
"ordinary": ["pressed"],
"reactive": ["card", "build_view"]
}

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Variant,
		_gogo_value_1: StringName,
		_gogo_value_2: Variant,
		_gogo_value_3: Callable,
		_gogo_value_4: Variant
	) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": _gogo_value_1, "column_span": _gogo_value_2, "height": "400px"}, {"pressed": _gogo_value_3}, [], "examples/ux01/InheritedScrolling.gogo:18:9", _gogo_value_0, true)
		_gogo_element_0.origins["column_span"] = "examples/ux01/InheritedScrolling.gogo:18:54"
		_gogo_element_0.set_text_body([["Card ", "examples/ux01/InheritedScrolling.gogo:18:122"], [_gogo_value_4, "examples/ux01/InheritedScrolling.gogo:18:127"]])
		return _gogo_element_0


	static func _gogo_build_1(
		_gogo_value_0: Vector2,
		_gogo_value_1: Callable,
		_gogo_value_2: Callable,
		_gogo_value_3: bool,
		_gogo_value_4: Variant,
		_gogo_value_5: Variant,
		_gogo_value_6: int,
		_gogo_value_7: Variant,
		_gogo_value_8: Variant,
		_gogo_value_9: Variant,
		_gogo_value_10: Variant,
		_gogo_value_11: Variant,
		_gogo_value_12: Variant,
		_gogo_value_13: Variant,
		_gogo_value_14: Variant,
		_gogo_value_15: Variant,
		_gogo_value_16: Variant,
		_gogo_value_17: Variant,
		_gogo_value_18: Array
	) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(NativeButton, {"name": "EntryNative", "custom_minimum_size": _gogo_value_0}, {"pressed": _gogo_value_1}, [], "examples/ux01/InheritedScrolling.gogo:21:3", null, false)
		_gogo_element_1.set_text_body([["Entry native input", "examples/ux01/InheritedScrolling.gogo:21:92"]])
		var _gogo_element_2 := _GogoElement_0.new(_GogoImport_0, {"name": "EntryCustom", "height": "80px"}, {"pressed": _gogo_value_2}, [], "examples/ux01/InheritedScrolling.gogo:22:3", null, false)
		_gogo_element_2.set_text_body([["Entry custom input", "examples/ux01/InheritedScrolling.gogo:22:62"]])
		var _gogo_element_4 := _GogoElement_0.new(Text, {"name": "T0", "height": _gogo_value_5, "font_size": _gogo_value_6}, {}, [], "examples/ux01/InheritedScrolling.gogo:24:4", null, false)
		_gogo_element_4.set_text_body([["First item", "examples/ux01/InheritedScrolling.gogo:24:62"]])
		var _gogo_element_5 := _GogoElement_0.new(Text, {"name": "T1", "height": _gogo_value_7}, {}, [], "examples/ux01/InheritedScrolling.gogo:25:4", null, false)
		_gogo_element_5.set_text_body([["Second item", "examples/ux01/InheritedScrolling.gogo:25:35"]])
		var _gogo_element_6 := _GogoElement_0.new(Text, {"name": "T2", "height": _gogo_value_8}, {}, [], "examples/ux01/InheritedScrolling.gogo:26:4", null, false)
		_gogo_element_6.set_text_body([["Third item", "examples/ux01/InheritedScrolling.gogo:26:35"]])
		var _gogo_element_7 := _GogoElement_0.new(Text, {"name": "T3", "height": _gogo_value_9}, {}, [], "examples/ux01/InheritedScrolling.gogo:27:4", null, false)
		_gogo_element_7.set_text_body([["Fourth item", "examples/ux01/InheritedScrolling.gogo:27:35"]])
		var _gogo_element_8 := _GogoElement_0.new(Text, {"name": "T4", "height": _gogo_value_10}, {}, [], "examples/ux01/InheritedScrolling.gogo:28:4", null, false)
		_gogo_element_8.set_text_body([["Fifth item", "examples/ux01/InheritedScrolling.gogo:28:35"]])
		var _gogo_element_9 := _GogoElement_0.new(Text, {"name": "T5", "height": _gogo_value_11}, {}, [], "examples/ux01/InheritedScrolling.gogo:29:4", null, false)
		_gogo_element_9.set_text_body([["Sixth item", "examples/ux01/InheritedScrolling.gogo:29:35"]])
		var _gogo_element_10 := _GogoElement_0.new(Text, {"name": "T6", "height": _gogo_value_12}, {}, [], "examples/ux01/InheritedScrolling.gogo:30:4", null, false)
		_gogo_element_10.set_text_body([["Seventh item", "examples/ux01/InheritedScrolling.gogo:30:35"]])
		var _gogo_element_11 := _GogoElement_0.new(Text, {"name": "T7", "height": _gogo_value_13}, {}, [], "examples/ux01/InheritedScrolling.gogo:31:4", null, false)
		_gogo_element_11.set_text_body([["Eighth item", "examples/ux01/InheritedScrolling.gogo:31:35"]])
		var _gogo_element_3 := _GogoElement_0.new(VBox, {}, {}, [_gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_10, _gogo_element_11], "examples/ux01/InheritedScrolling.gogo:23:3", null, false)
		_gogo_element_3.expand([["name", "Direct", "examples/ux01/InheritedScrolling.gogo:23:9"], ["width", "100%", "examples/ux01/InheritedScrolling.gogo:23:23"], ["height", "300px", "examples/ux01/InheritedScrolling.gogo:23:36"], ["vertical_scroll", _gogo_value_3, "examples/ux01/InheritedScrolling.gogo:23:51"], [null, _gogo_value_4, "examples/ux01/InheritedScrolling.gogo:23:82"], ["background_color", "#252b38", "examples/ux01/InheritedScrolling.gogo:23:98"]])
		var _gogo_element_13 := _GogoElement_0.new(Rect, {"width": "200px", "height": "100px", "background_color": "#477dbb"}, {}, [], "examples/ux01/InheritedScrolling.gogo:34:4", null, false)
		var _gogo_element_14 := _GogoElement_0.new(Rect, {"width": "200px", "height": "100px", "background_color": "#75599b"}, {}, [], "examples/ux01/InheritedScrolling.gogo:35:4", null, false)
		var _gogo_element_15 := _GogoElement_0.new(Rect, {"width": "200px", "height": "100px", "background_color": "#477dbb"}, {}, [], "examples/ux01/InheritedScrolling.gogo:36:4", null, false)
		var _gogo_element_12 := _GogoElement_0.new(HBox, {"name": "Horizontal", "width": "100%", "max_width": "320px", "height": "100px", "horizontal_scroll": true, "gap": "12px"}, {}, [_gogo_element_13, _gogo_element_14, _gogo_element_15], "examples/ux01/InheritedScrolling.gogo:33:3", null, false)
		var _gogo_element_16 := _GogoElement_0.new(Grid, {"name": "Cards", "width": "100%", "height": "260px", "columns": _gogo_value_14, "vertical_scroll": true, "row_gap": "10px"}, {}, [_gogo_value_15], "examples/ux01/InheritedScrolling.gogo:38:3", null, false)
		var _gogo_element_18 := _GogoElement_0.new(Rect, {"name": "Head", "area": "head", "height": "120px", "background_color": "#477dbb"}, {}, [], "examples/ux01/InheritedScrolling.gogo:40:4", null, false)
		_gogo_element_18.origins["area"] = "examples/ux01/InheritedScrolling.gogo:40:22"
		var _gogo_element_19 := _GogoElement_0.new(Rect, {"name": "Left", "area": "left", "height": "240px", "background_color": "#75599b"}, {}, [], "examples/ux01/InheritedScrolling.gogo:41:4", null, false)
		_gogo_element_19.origins["area"] = "examples/ux01/InheritedScrolling.gogo:41:22"
		var _gogo_element_20 := _GogoElement_0.new(Rect, {"name": "Right", "area": "right", "height": "240px", "background_color": "#477dbb"}, {}, [], "examples/ux01/InheritedScrolling.gogo:42:4", null, false)
		_gogo_element_20.origins["area"] = "examples/ux01/InheritedScrolling.gogo:42:23"
		var _gogo_element_17 := _GogoElement_0.new(Grid, {"name": "Areas", "width": "100%", "height": "160px", "vertical_scroll": true, "columns": _gogo_value_16, "rows": _gogo_value_17, "areas": _gogo_value_18, "row_gap": "10px"}, {}, [_gogo_element_18, _gogo_element_19, _gogo_element_20], "examples/ux01/InheritedScrolling.gogo:39:3", null, false)
		var _gogo_element_23 := _GogoElement_0.new(Text, {"width": "90px"}, {}, [], "examples/ux01/InheritedScrolling.gogo:45:38", null, false)
		_gogo_element_23.set_text_body([["One", "examples/ux01/InheritedScrolling.gogo:45:57"]])
		var _gogo_element_24 := _GogoElement_0.new(Text, {"width": "90px"}, {}, [], "examples/ux01/InheritedScrolling.gogo:45:67", null, false)
		_gogo_element_24.set_text_body([["Two", "examples/ux01/InheritedScrolling.gogo:45:86"]])
		var _gogo_element_25 := _GogoElement_0.new(Text, {"width": "90px"}, {}, [], "examples/ux01/InheritedScrolling.gogo:45:96", null, false)
		_gogo_element_25.set_text_body([["Three", "examples/ux01/InheritedScrolling.gogo:45:115"]])
		var _gogo_element_26 := _GogoElement_0.new(Text, {"width": "90px"}, {}, [], "examples/ux01/InheritedScrolling.gogo:45:127", null, false)
		_gogo_element_26.set_text_body([["Four", "examples/ux01/InheritedScrolling.gogo:45:146"]])
		var _gogo_element_22 := _GogoElement_0.new(HBox, {"name": "Tags", "wrap": true, "gap": "10px"}, {}, [_gogo_element_23, _gogo_element_24, _gogo_element_25, _gogo_element_26], "examples/ux01/InheritedScrolling.gogo:45:4", null, false)
		var _gogo_element_27 := _GogoElement_0.new(Rect, {"width": "100%", "height": "400px", "background_color": "#477dbb"}, {}, [], "examples/ux01/InheritedScrolling.gogo:46:4", null, false)
		var _gogo_element_28 := _GogoElement_0.new(Rect, {"width": "100%", "height": "400px", "background_color": "#75599b"}, {}, [], "examples/ux01/InheritedScrolling.gogo:47:4", null, false)
		var _gogo_element_21 := _GogoElement_0.new(VBox, {"name": "Wrapped", "width": "100%", "max_height": "380px", "vertical_scroll": true, "padding": "16px", "border_width": "4px", "gap": "12px", "background_color": "#252b38"}, {}, [_gogo_element_22, _gogo_element_27, _gogo_element_28], "examples/ux01/InheritedScrolling.gogo:44:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "direction": "column", "width": "100%", "height": "100%", "vertical_scroll": true, "padding": "8px", "gap": "12px", "background_color": "#171b24"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3, _gogo_element_12, _gogo_element_16, _gogo_element_17, _gogo_element_21], "examples/ux01/InheritedScrolling.gogo:20:9", null, false)
		return _gogo_element_0
