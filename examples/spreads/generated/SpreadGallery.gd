extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
signal panel_changed(previous: Dictionary, value: Dictionary)
var panel: Dictionary = {"padding":"12px", "background_color":"#171b24", "border_width":"2px", "border_color":"#8295bc", "gap":"12px", "min_width":"280px"}:
	set(_gogo_incoming_panel):
		if is_same(panel, _gogo_incoming_panel): return
		var _gogo_previous_panel: Dictionary = panel
		panel = _gogo_incoming_panel
		panel_changed.emit(_gogo_previous_panel, _gogo_incoming_panel)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"panel_changed")
		return panel

signal action_changed(previous: Dictionary, value: Dictionary)
var action: Dictionary = {"text":"Continue", "min_width":"96px", "min_height":"36px", "background_color":"#70599b"}:
	set(_gogo_incoming_action):
		if is_same(action, _gogo_incoming_action): return
		var _gogo_previous_action: Dictionary = action
		action = _gogo_incoming_action
		action_changed.emit(_gogo_previous_action, _gogo_incoming_action)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"action_changed")
		return action

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

signal alternate_changed(previous: bool, value: bool)
var alternate: bool = false:
	set(_gogo_incoming_alternate):
		if is_same(alternate, _gogo_incoming_alternate): return
		var _gogo_previous_alternate: bool = alternate
		alternate = _gogo_incoming_alternate
		alternate_changed.emit(_gogo_previous_alternate, _gogo_incoming_alternate)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"alternate_changed")
		return alternate

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

var clicks: int = 0
var alternate_clicks: int = 0
var native_clicks: int = 0
func pressed() -> void: clicks += 1
func alternate_pressed() -> void: alternate_clicks += 1
func native_pressed() -> void: native_clicks += 1
func requires_argument(value: int) -> void: clicks += value
func emphasis() -> Dictionary: return {"background_color":"#252b38", "min_height":"200px"}
func button_values() -> Dictionary:
	var values := self.action.duplicate()
	values["pressed"] = alternate_pressed if self.alternate else pressed
	return values
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.panel)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/spreads/SpreadGallery.gogo:1720", emphasis, [], func(): emphasis()) as Dictionary))),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"text":"Ordinary dictionaries, native properties", "color":Color("#ffc65c")})),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot((preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/spreads/SpreadGallery.gogo:1945", button_values, [], func(): button_values()) as Dictionary))),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"text":"Enabled", "min_width":"120px", "min_height":"36px"})),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "self.enabled", (self.enabled) if self != null else null)),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"text":"Native Button", "pressed":native_pressed})),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"width":"100%", "height":"12px", "background_color":"#355e92"})),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"caption":"Nested spread, retained native nodes"})),
		(preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/spreads/SpreadGallery.gogo:2360", "extra", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_1((preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"text":"Explicit key + spread"})))) if self.show_extra else null)
	)

const _GOGO_RENDER_FUNCTIONS_41d4e9792a603555 = {
"ordinary": ["pressed", "alternate_pressed", "native_pressed", "requires_argument", "emphasis", "button_values"],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_41d4e9792a603555 = {
"action": "Dictionary",
"alternate": "bool",
"enabled": "bool",
"panel": "Dictionary",
"show_extra": "bool"
}

const _GogoProject_0 = preload("NestedSpread.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Variant,
		_gogo_value_1: Variant,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Variant,
		_gogo_value_5: Variant,
		_gogo_value_6: Variant,
		_gogo_value_7: Variant,
		_gogo_value_8: Variant,
		_gogo_value_9: Variant
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {}, {}, [], "examples/spreads/SpreadGallery.gogo:30:4", null, false)
		_gogo_element_2.expand([["name", "Caption", "examples/spreads/SpreadGallery.gogo:30:10"], [null, _gogo_value_2, "examples/spreads/SpreadGallery.gogo:30:25"], ["min_width", "120px", "examples/spreads/SpreadGallery.gogo:30:108"]])
		_gogo_element_2.resolve_bindings()
		var _gogo_element_3 := _GogoElement_0.new(_GogoImport_0, {}, {}, [], "examples/spreads/SpreadGallery.gogo:31:4", null, false)
		_gogo_element_3.expand([["name", "Continue", "examples/spreads/SpreadGallery.gogo:31:12"], ["width", "50%", "examples/spreads/SpreadGallery.gogo:31:28"], ["height", "20px", "examples/spreads/SpreadGallery.gogo:31:40"], ["background_color", "#477dbb", "examples/spreads/SpreadGallery.gogo:31:54"], [null, _gogo_value_3, "examples/spreads/SpreadGallery.gogo:31:81"]])
		_gogo_element_3.resolve_bindings()
		var _gogo_element_4 := _GogoElement_0.new(Toggle, {}, {}, [], "examples/spreads/SpreadGallery.gogo:32:4", null, false)
		_gogo_element_4.origins["value"] = "examples/spreads/SpreadGallery.gogo:32:93"
		_gogo_element_4.expand([["name", "Enabled", "examples/spreads/SpreadGallery.gogo:32:12"], [null, _gogo_value_4, "examples/spreads/SpreadGallery.gogo:32:27"], ["value", _gogo_value_5, "examples/spreads/SpreadGallery.gogo:32:93"]])
		_gogo_element_4.resolve_bindings()
		var _gogo_element_5 := _GogoElement_0.new(NativeButton, {}, {}, [], "examples/spreads/SpreadGallery.gogo:33:4", null, false)
		_gogo_element_5.expand([["name", "Native", "examples/spreads/SpreadGallery.gogo:33:18"], [null, _gogo_value_6, "examples/spreads/SpreadGallery.gogo:33:32"]])
		_gogo_element_5.resolve_bindings()
		var _gogo_element_6 := _GogoElement_0.new(Rect, {}, {}, [], "examples/spreads/SpreadGallery.gogo:34:4", null, false)
		_gogo_element_6.expand([["name", "Swatch", "examples/spreads/SpreadGallery.gogo:34:10"], [null, _gogo_value_7, "examples/spreads/SpreadGallery.gogo:34:24"]])
		_gogo_element_6.resolve_bindings()
		var _gogo_element_7 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/spreads/SpreadGallery.gogo:35:4", null, false)
		_gogo_element_7.expand([["name", "Nested", "examples/spreads/SpreadGallery.gogo:35:18"], [null, _gogo_value_8, "examples/spreads/SpreadGallery.gogo:35:32"]])
		_gogo_element_7.resolve_bindings()
		var _gogo_element_1 := _GogoElement_0.new(VBox, {}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_value_9], "examples/spreads/SpreadGallery.gogo:29:3", null, false)
		_gogo_element_1.expand([["name", "Panel", "examples/spreads/SpreadGallery.gogo:29:9"], ["width", "100%", "examples/spreads/SpreadGallery.gogo:29:22"], [null, _gogo_value_0, "examples/spreads/SpreadGallery.gogo:29:35"], ["padding", "16px", "examples/spreads/SpreadGallery.gogo:29:51"], [null, _gogo_value_1, "examples/spreads/SpreadGallery.gogo:29:66"]])
		_gogo_element_1.resolve_bindings()
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/spreads/SpreadGallery.gogo:28:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0


	static func _gogo_build_1(_gogo_value_0: Variant) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Text, {}, {}, [], "examples/spreads/SpreadGallery.gogo:36:5", "extra", true)
		_gogo_element_0.expand([["name", "Extra", "examples/spreads/SpreadGallery.gogo:36:23"], [null, _gogo_value_0, "examples/spreads/SpreadGallery.gogo:36:36"]])
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
