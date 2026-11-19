extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const NativeButton = preload("../../godot_button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
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
func pressed(): clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(pressed),
		(Vector2(0,300)),
		(pressed),
		(preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "enabled", func(_gogo_source, _gogo_edit: bool): _gogo_source.enabled = _gogo_edit, "enabled"))
	)

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Callable,
		_gogo_value_1: Vector2,
		_gogo_value_2: Callable,
		_gogo_value_3: Variant
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(_GogoImport_0, {"name": "First", "height": "300px"}, {"pressed": _gogo_value_0}, [], "examples/ux01/ScrollProof.gogo:14:5", null, false)
		_gogo_element_2.set_text_body([["First", "examples/ux01/ScrollProof.gogo:14:59"]])
		var _gogo_element_3 := _GogoElement_0.new(NativeButton, {"name": "Middle", "custom_minimum_size": _gogo_value_1}, {"pressed": _gogo_value_2}, [], "examples/ux01/ScrollProof.gogo:15:5", null, false)
		_gogo_element_3.set_text_body([["Native middle", "examples/ux01/ScrollProof.gogo:15:88"]])
		var _gogo_element_4 := _GogoElement_0.new(Toggle, {"name": "Last", "height": "300px"}, {}, [], "examples/ux01/ScrollProof.gogo:16:5", null, false)
		_gogo_element_4.set_text_body([["Last", "examples/ux01/ScrollProof.gogo:16:66"]])
		_gogo_element_4.bindings = {"value": _gogo_value_3}
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"horizontal_align": "stretch", "name": "Scroll", "width": "300px", "height": "300px", "vertical_scroll": true, "background_color": "#252b38"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4], "examples/ux01/ScrollProof.gogo:13:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%", "padding": "20px", "background_color": "#171b24"}, {}, [_gogo_element_1], "examples/ux01/ScrollProof.gogo:12:9", null, false)
		return _gogo_element_0
