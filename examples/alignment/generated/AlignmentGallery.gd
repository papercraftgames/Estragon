extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
signal policy_changed(previous: Dictionary, value: Dictionary)
var policy: Dictionary = {"direction":"row", "horizontal_align":"space-between", "vertical_align":"center"}:
	set(_gogo_incoming_policy):
		if is_same(policy, _gogo_incoming_policy): return
		var _gogo_previous_policy: Dictionary = policy
		policy = _gogo_incoming_policy
		policy_changed.emit(_gogo_previous_policy, _gogo_incoming_policy)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"policy_changed")
		return policy

signal child_props_changed(previous: Dictionary, value: Dictionary)
var child_props: Dictionary = {"align_self":"end"}:
	set(_gogo_incoming_child_props):
		if is_same(child_props, _gogo_incoming_child_props): return
		var _gogo_previous_child_props: Dictionary = child_props
		child_props = _gogo_incoming_child_props
		child_props_changed.emit(_gogo_previous_child_props, _gogo_incoming_child_props)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"child_props_changed")
		return child_props

signal order_changed(previous: Array, value: Array)
var order: Array = ["a","b","c"]:
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

var clicks: int = 0
var native_clicks: int = 0
func pressed() -> void: clicks += 1
func native_pressed() -> void: native_clicks += 1
func tile(value: String) -> Element:
	return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/alignment/AlignmentGallery.gogo:1202", value, func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0((_gogo_mount_key), (value), (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot((self.child_props if value=="b" else {})))))
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_1(
		(Color("#ffc65c")),
		(pressed),
		(self.order.map(tile)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.policy)),
		(pressed),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "self.enabled")),
		(native_pressed),
		(preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/alignment/AlignmentGallery.gogo:2500", "extra", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_2()) if self.show_extra else null),
		(get_children())
	)

const _GOGO_RENDER_FUNCTIONS_b327ab6aa43a72f1 = {
"ordinary": ["pressed", "native_pressed"],
"reactive": ["tile", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_b327ab6aa43a72f1 = {
"child_props": "Dictionary",
"enabled": "bool",
"order": "Array",
"policy": "Dictionary",
"show_extra": "bool"
}

const _GogoProject_0 = preload("NestedAlignment.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: StringName, _gogo_value_2: Variant) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Rect, {}, {}, [], "examples/alignment/AlignmentGallery.gogo:22:9", _gogo_value_0, true)
		_gogo_element_0.expand([["name", _gogo_value_1, "examples/alignment/AlignmentGallery.gogo:22:27"], ["width", "40px", "examples/alignment/AlignmentGallery.gogo:22:40"], ["height", "30px", "examples/alignment/AlignmentGallery.gogo:22:53"], ["background_color", "#477dbb", "examples/alignment/AlignmentGallery.gogo:22:67"], [null, _gogo_value_2, "examples/alignment/AlignmentGallery.gogo:22:94"]])
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0


	static func _gogo_build_1(
		_gogo_value_0: Color,
		_gogo_value_1: Callable,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Callable,
		_gogo_value_5: Variant,
		_gogo_value_6: Callable,
		_gogo_value_7: Variant,
		_gogo_value_8: Variant
	) -> _GogoElement_0:
		var _gogo_element_3 := _GogoElement_0.new(Text, {"text": "Inventory", "color": _gogo_value_0}, {}, [], "examples/alignment/AlignmentGallery.gogo:27:5", null, false)
		_gogo_element_3.resolve_bindings()
		var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {"name": "Close", "text": "Close", "height": "32px", "min_width": "96px"}, {"pressed": _gogo_value_1}, [], "examples/alignment/AlignmentGallery.gogo:28:5", null, false)
		_gogo_element_4.resolve_bindings()
		var _gogo_element_2 := _GogoElement_0.new(HBox, {"name": "Header", "width": "100%", "height": "64px", "horizontal_align": "space-between", "vertical_align": "center", "padding": "12px", "background_color": "#252b38", "border_width": "2px", "border_color": "#8295bc"}, {}, [_gogo_element_3, _gogo_element_4], "examples/alignment/AlignmentGallery.gogo:26:4", null, false)
		_gogo_element_2.resolve_bindings()
		var _gogo_element_5 := _GogoElement_0.new(HBox, {"name": "Even", "width": "100%", "height": "96px", "horizontal_align": "space-evenly", "vertical_align": "center", "background_color": "#252b38"}, {}, [_gogo_value_2], "examples/alignment/AlignmentGallery.gogo:30:4", null, false)
		_gogo_element_5.resolve_bindings()
		var _gogo_element_7 := _GogoElement_0.new(_GogoImport_0, {"name": "Action", "text": "Aligned action", "min_height": "36px"}, {"pressed": _gogo_value_4}, [], "examples/alignment/AlignmentGallery.gogo:34:5", null, false)
		_gogo_element_7.resolve_bindings()
		var _gogo_element_8 := _GogoElement_0.new(Toggle, {"name": "Enabled", "text": "Enabled", "min_height": "36px", "value": _gogo_value_5}, {}, [], "examples/alignment/AlignmentGallery.gogo:35:5", null, false)
		_gogo_element_8.origins["value"] = "examples/alignment/AlignmentGallery.gogo:35:61"
		_gogo_element_8.resolve_bindings()
		var _gogo_element_9 := _GogoElement_0.new(NativeButton, {"name": "Native", "text": "Native Control"}, {"pressed": _gogo_value_6}, [], "examples/alignment/AlignmentGallery.gogo:36:5", null, false)
		_gogo_element_9.resolve_bindings()
		var _gogo_element_6 := _GogoElement_0.new(Box, {}, {}, [_gogo_element_7, _gogo_element_8, _gogo_element_9], "examples/alignment/AlignmentGallery.gogo:33:4", null, false)
		_gogo_element_6.expand([["name", "Configurable", "examples/alignment/AlignmentGallery.gogo:33:9"], ["width", "100%", "examples/alignment/AlignmentGallery.gogo:33:29"], ["height", "110px", "examples/alignment/AlignmentGallery.gogo:33:42"], ["gap", "10px", "examples/alignment/AlignmentGallery.gogo:33:57"], ["padding", "8px", "examples/alignment/AlignmentGallery.gogo:33:68"], [null, _gogo_value_3, "examples/alignment/AlignmentGallery.gogo:33:82"], ["background_color", "#30394d", "examples/alignment/AlignmentGallery.gogo:33:99"]])
		_gogo_element_6.resolve_bindings()
		var _gogo_element_10 := _GogoElement_0.new(_GogoProject_0, {"name": "Nested"}, {}, [], "examples/alignment/AlignmentGallery.gogo:38:4", null, false)
		_gogo_element_10.resolve_bindings()
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Content", "width": "100%", "height": "100%", "horizontal_align": "stretch", "gap": "12px"}, {}, [_gogo_element_2, _gogo_element_5, _gogo_element_6, _gogo_element_10, _gogo_value_7, _gogo_value_8], "examples/alignment/AlignmentGallery.gogo:25:3", null, false)
		_gogo_element_1.resolve_bindings()
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/alignment/AlignmentGallery.gogo:24:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0


	static func _gogo_build_2() -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Text, {"name": "Extra", "text": "Physical axes, retained native nodes"}, {}, [], "examples/alignment/AlignmentGallery.gogo:39:5", "extra", true)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
