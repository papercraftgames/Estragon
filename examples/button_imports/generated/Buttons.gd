extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const NativeButton = preload("../../godot_button.gd")
const NativeOnly = preload("NativeOnly.gd")
const TypedButton = preload("TypedButton.gd")
const PANEL_TEXTURE = preload("../../surfaces/panel_gradient.tres")
const AnotherButton = _GogoImport_0
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

signal selected_changed(previous: _GogoImport_0, value: _GogoImport_0)
var selected: _GogoImport_0 = null:
	set(_gogo_incoming_selected):
		if is_same(selected, _gogo_incoming_selected): return
		var _gogo_previous_selected: _GogoImport_0 = selected
		selected = _gogo_incoming_selected
		selected_changed.emit(_gogo_previous_selected, _gogo_incoming_selected)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"selected_changed")
		return selected

var clicks: int = 0
var native_clicks: int = 0
func pressed(): clicks += 1
func native_pressed(): native_clicks += 1
func typed(value: _GogoImport_0) -> _GogoImport_0: return value
func constructors() -> Array:
	return [_GogoImport_0.new(),AnotherButton.new(),NativeButton.new(),ClassDB.instantiate("Button")]
func member_and_string() -> String:
	var object := {"Button":"Button member"}
	return object.Button # Button is data here, not the imported identifier.
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(pressed),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.props)),
		(native_pressed),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "checked", func(_gogo_source, _gogo_edit: bool): _gogo_source.checked = _gogo_edit, "checked")),
		(PANEL_TEXTURE),
		(pressed),
		(self.selected)
	)


const _GogoProject_0 = preload("NativeOnly.gd")

const _GogoProject_1 = preload("TypedButton.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Callable,
		_gogo_value_1: Variant,
		_gogo_value_2: Callable,
		_gogo_value_3: Variant,
		_gogo_value_4: Texture2D,
		_gogo_value_5: Callable,
		_gogo_value_6: _GogoProject_1._GogoImport_0
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {}, {}, [], "examples/button_imports/Buttons.gogo:30:4", null, false)
		_gogo_element_2.set_text_body([["Import-selected Button", "examples/button_imports/Buttons.gogo:30:10"]])
		var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {}, {}, [], "examples/button_imports/Buttons.gogo:32:5", null, false)
		_gogo_element_4.expand([["name", "Action", "examples/button_imports/Buttons.gogo:32:13"], ["text", "Estragon Button", "examples/button_imports/Buttons.gogo:32:27"], ["width", "180px", "examples/button_imports/Buttons.gogo:32:50"], ["height", "56px", "examples/button_imports/Buttons.gogo:32:64"], ["pressed", _gogo_value_0, "examples/button_imports/Buttons.gogo:32:78"], [null, _gogo_value_1, "examples/button_imports/Buttons.gogo:32:96"]])
		var _gogo_element_5 := _GogoElement_0.new(NativeButton, {"name": "Native", "text": "Native script alias"}, {"pressed": _gogo_value_2}, [], "examples/button_imports/Buttons.gogo:33:5", null, false)
		var _gogo_element_6 := _GogoElement_0.new(_GogoProject_0, {"name": "Unimported"}, {}, [], "examples/button_imports/Buttons.gogo:34:5", null, false)
		var _gogo_element_3 := _GogoElement_0.new(HBox, {"name": "Kinds", "wrap": true, "gap": "8px"}, {}, [_gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/button_imports/Buttons.gogo:31:4", null, false)
		var _gogo_element_7 := _GogoElement_0.new(_GogoImport_0, {"name": "Disabled", "disabled": true, "width": "180px", "height": "56px"}, {}, [], "examples/button_imports/Buttons.gogo:36:4", null, false)
		_gogo_element_7.set_text_body([["Disabled charcoal", "examples/button_imports/Buttons.gogo:36:65"]])
		var _gogo_element_8 := _GogoElement_0.new(Toggle, {"name": "Toggle", "width": "180px", "height": "56px"}, {}, [], "examples/button_imports/Buttons.gogo:37:4", null, false)
		_gogo_element_8.set_text_body([["Teal when checked", "examples/button_imports/Buttons.gogo:37:80"]])
		_gogo_element_8.bindings = {"value": _gogo_value_3}
		var _gogo_element_9 := _GogoElement_0.new(_GogoImport_0, {"name": "Surface", "width": "240px", "height": "72px", "corner_radius": "18px", "background_color": "#283842", "background_texture": _gogo_value_4}, {"pressed": _gogo_value_5}, [], "examples/button_imports/Buttons.gogo:38:4", null, false)
		_gogo_element_9.set_text_body([["Explicit native surface", "examples/button_imports/Buttons.gogo:38:156"]])
		var _gogo_element_10 := _GogoElement_0.new(_GogoProject_1, {"name": "Typed", "supplied": _gogo_value_6}, {}, [], "examples/button_imports/Buttons.gogo:39:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Column", "width": "100%", "gap": "8px"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_10], "examples/button_imports/Buttons.gogo:29:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "12px", "background_color": "#171b24", "vertical_scroll": true}, {}, [_gogo_element_1], "examples/button_imports/Buttons.gogo:28:9", null, false)
		return _gogo_element_0
