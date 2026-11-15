extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
var native_clicks: int = 0
var ui_clicks: int = 0
func native_pressed() -> void:
	native_clicks += 1
func ui_pressed() -> void:
	ui_clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((self.native_pressed), (self.ui_pressed))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Callable, _gogo_value_1: Callable) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new("Button", {"name": "Native", "text": "Native Button"}, {"pressed": _gogo_value_0}, [], "examples/styling/StyledSettings.gogo:14:3", null, false)
		var _gogo_element_2 := _GogoElement_0.new(UiButton, {"name": "Ui", "text": "Estragon Button"}, {"pressed": _gogo_value_1}, [], "examples/styling/StyledSettings.gogo:15:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "Controls", "width": "100%", "padding": "8px", "gap": "12px", "background_color": "#30394d", "border_color": "#8295bc", "border_width": "1px"}, {}, [_gogo_element_1, _gogo_element_2], "examples/styling/StyledSettings.gogo:12:9", null, false)
		return _gogo_element_0
