extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const ScrollView = preload("../../../addons/estragon/runtime/node/scroll_view.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
signal username_changed(previous: String, value: String)
var username: String = "Gogo":
	set(_gogo_incoming_username):
		if is_same(username, _gogo_incoming_username): return
		var _gogo_previous_username: String = username
		username = _gogo_incoming_username
		username_changed.emit(_gogo_previous_username, _gogo_incoming_username)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"username_changed")
		return username

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

signal order_changed(previous: Array, value: Array)
var order: Array = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]:
	set(_gogo_incoming_order):
		if is_same(order, _gogo_incoming_order): return
		var _gogo_previous_order: Array = order
		order = _gogo_incoming_order
		order_changed.emit(_gogo_previous_order, _gogo_incoming_order)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"order_changed")
		return order

signal extra_changed(previous: Dictionary, value: Dictionary)
var extra: Dictionary = {}:
	set(_gogo_incoming_extra):
		if is_same(extra, _gogo_incoming_extra): return
		var _gogo_previous_extra: Dictionary = extra
		extra = _gogo_incoming_extra
		extra_changed.emit(_gogo_previous_extra, _gogo_incoming_extra)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"extra_changed")
		return extra

signal show_overflow_changed(previous: bool, value: bool)
var show_overflow: bool = true:
	set(_gogo_incoming_show_overflow):
		if is_same(show_overflow, _gogo_incoming_show_overflow): return
		var _gogo_previous_show_overflow: bool = show_overflow
		show_overflow = _gogo_incoming_show_overflow
		show_overflow_changed.emit(_gogo_previous_show_overflow, _gogo_incoming_show_overflow)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_overflow_changed")
		return show_overflow

var clicks: int = 0
func pressed(): clicks += 1
func row(index: int) -> Element:
	if index==0: return _GogoFactories_0._gogo_build_0((index), (Vector2(0,60)), (pressed))
	if index==1: return _GogoFactories_0._gogo_build_1((index), (pressed))
	if index==2: return _GogoFactories_0._gogo_build_2((index), (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "enabled")))
	if index==3: return _GogoFactories_0._gogo_build_3((index), (2))
	if index==4: return _GogoFactories_0._gogo_build_4((index))
	return _GogoFactories_0._gogo_build_5(
		(index),
		("Row"+str(index)),
		(pressed),
		(str(index))
	)
func build_view() -> Element:
	var panel := {"background_color":"#252b38","padding":"8px"}
	return _GogoFactories_0._gogo_build_6(
		(self.username),
		(pressed),
		(pressed),
		(_GogoFactories_0._gogo_build_7() if self.show_overflow else null),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(panel)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.extra)),
		(self.order.map(row))
	)


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: Vector2, _gogo_value_2: Callable) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new("Button", {"name": "NativeRow", "custom_minimum_size": _gogo_value_1}, {"pressed": _gogo_value_2}, [], "examples/ux01/UXGallery.gogo:20:22", _gogo_value_0, true)
		_gogo_element_0.set_text_body([["Native scroll button", "examples/ux01/UXGallery.gogo:20:113"]])
		return _gogo_element_0


	static func _gogo_build_1(_gogo_value_0: Variant, _gogo_value_1: Callable) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(UiButton, {"name": "CustomRow", "height": "60px"}, {"pressed": _gogo_value_1}, [], "examples/ux01/UXGallery.gogo:21:22", _gogo_value_0, true)
		_gogo_element_0.set_text_body([["Estragon scroll button", "examples/ux01/UXGallery.gogo:21:93"]])
		return _gogo_element_0


	static func _gogo_build_2(_gogo_value_0: Variant, _gogo_value_1: Variant) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Toggle, {"name": "ToggleRow", "height": "60px"}, {}, [], "examples/ux01/UXGallery.gogo:22:22", _gogo_value_0, true)
		_gogo_element_0.set_text_body([["Enabled", "examples/ux01/UXGallery.gogo:22:99"]])
		_gogo_element_0.bindings = {"value": _gogo_value_1}
		return _gogo_element_0


	static func _gogo_build_3(_gogo_value_0: Variant, _gogo_value_1: Variant) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:23:104", null, false)
		_gogo_element_1.set_text_body([["Native Grid", "examples/ux01/UXGallery.gogo:23:110"]])
		var _gogo_element_2 := _GogoElement_0.new(Rect, {"height": "60px", "background_color": "#477dbb"}, {}, [], "examples/ux01/UXGallery.gogo:23:128", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Grid, {"name": "GridRow", "columns": _gogo_value_1, "width": "100%", "height": "60px", "gap": "8px"}, {}, [_gogo_element_1, _gogo_element_2], "examples/ux01/UXGallery.gogo:23:22", _gogo_value_0, true)
		return _gogo_element_0


	static func _gogo_build_4(_gogo_value_0: Variant) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:24:84", null, false)
		_gogo_element_1.set_text_body([["Wrap", "examples/ux01/UXGallery.gogo:24:90"]])
		var _gogo_element_2 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:24:101", null, false)
		_gogo_element_2.set_text_body([["inside", "examples/ux01/UXGallery.gogo:24:107"]])
		var _gogo_element_3 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:24:120", null, false)
		_gogo_element_3.set_text_body([["viewport", "examples/ux01/UXGallery.gogo:24:126"]])
		var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "WrapRow", "wrap": true, "height": "60px", "gap": "8px"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3], "examples/ux01/UXGallery.gogo:24:22", _gogo_value_0, true)
		return _gogo_element_0


	static func _gogo_build_5(
		_gogo_value_0: Variant,
		_gogo_value_1: StringName,
		_gogo_value_2: Callable,
		_gogo_value_3: Variant
	) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(UiButton, {"name": _gogo_value_1, "height": "60px"}, {"pressed": _gogo_value_2}, [], "examples/ux01/UXGallery.gogo:25:9", _gogo_value_0, true)
		_gogo_element_0.set_text_body([["Item ", "examples/ux01/UXGallery.gogo:25:87"], [_gogo_value_3, "examples/ux01/UXGallery.gogo:25:92"]])
		return _gogo_element_0


	static func _gogo_build_6(
		_gogo_value_0: Variant,
		_gogo_value_1: Callable,
		_gogo_value_2: Callable,
		_gogo_value_3: Variant,
		_gogo_value_4: Variant,
		_gogo_value_5: Variant,
		_gogo_value_6: Variant
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Greeting"}, {}, [], "examples/ux01/UXGallery.gogo:30:4", null, false)
		_gogo_element_2.set_text_body([["Hello ", "examples/ux01/UXGallery.gogo:30:26"], [_gogo_value_0, "examples/ux01/UXGallery.gogo:30:32"], ["!", "examples/ux01/UXGallery.gogo:30:47"]])
		var _gogo_element_4 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:32:5", null, false)
		_gogo_element_4.set_text_body([["One", "examples/ux01/UXGallery.gogo:32:11"]])
		var _gogo_element_5 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:32:21", null, false)
		_gogo_element_5.set_text_body([["Two", "examples/ux01/UXGallery.gogo:32:27"]])
		var _gogo_element_6 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/UXGallery.gogo:32:37", null, false)
		_gogo_element_6.set_text_body([["Three", "examples/ux01/UXGallery.gogo:32:43"]])
		var _gogo_element_7 := _GogoElement_0.new("Button", {"name": "Native"}, {"pressed": _gogo_value_1}, [], "examples/ux01/UXGallery.gogo:33:5", null, false)
		_gogo_element_7.set_text_body([["Native", "examples/ux01/UXGallery.gogo:33:45"]])
		var _gogo_element_8 := _GogoElement_0.new(UiButton, {"name": "Custom"}, {"pressed": _gogo_value_2}, [], "examples/ux01/UXGallery.gogo:34:5", null, false)
		_gogo_element_8.set_text_body([["Estragon", "examples/ux01/UXGallery.gogo:34:47"]])
		var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Wrap", "wrap": true, "gap": "8px", "row_gap": "6px"}, {}, [_gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/ux01/UXGallery.gogo:31:4", null, false)
		var _gogo_element_10 := _GogoElement_0.new(VBox, {"name": "List", "width": "100%", "horizontal_align": "stretch"}, {}, [_gogo_value_6], "examples/ux01/UXGallery.gogo:38:5", null, false)
		var _gogo_element_9 := _GogoElement_0.new(ScrollView, {}, {}, [_gogo_element_10], "examples/ux01/UXGallery.gogo:37:4", null, false)
		_gogo_element_9.expand([["name", "Scroll", "examples/ux01/UXGallery.gogo:37:16"], ["width", "100%", "examples/ux01/UXGallery.gogo:37:30"], ["height", "30vh", "examples/ux01/UXGallery.gogo:37:43"], ["max_height", "380px", "examples/ux01/UXGallery.gogo:37:57"], ["vertical_scroll", true, "examples/ux01/UXGallery.gogo:37:76"], [null, _gogo_value_4, "examples/ux01/UXGallery.gogo:37:92"], [null, _gogo_value_5, "examples/ux01/UXGallery.gogo:37:103"]])
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Content", "width": "100%", "height": "100%", "gap": "6px", "horizontal_align": "end"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_value_3, _gogo_element_9], "examples/ux01/UXGallery.gogo:29:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/ux01/UXGallery.gogo:28:9", null, false)
		return _gogo_element_0


	static func _gogo_build_7() -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {"width": "240px", "height": "26px", "background_color": "#477dbb"}, {}, [], "examples/ux01/UXGallery.gogo:36:107", null, false)
		_gogo_element_1.set_text_body([["Visible overflow", "examples/ux01/UXGallery.gogo:36:168"]])
		var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "Overflow", "width": "500px", "max_width": "180px", "height": "26px", "align_self": "start"}, {}, [_gogo_element_1], "examples/ux01/UXGallery.gogo:36:5", "overflow", true)
		return _gogo_element_0
