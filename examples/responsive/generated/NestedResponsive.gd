extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
var clicks: int = 0
func pressed() -> void: clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((true), (pressed), (pressed))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: bool, _gogo_value_1: Callable, _gogo_value_2: Callable) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "Nested", "width": "130px", "height": "26px"}, {}, [], "examples/responsive/NestedResponsive.gogo:10:3", null, false)
		var _gogo_element_2 := _GogoElement_0.new(UiButton, {"name": "NestedAction", "text": "Action", "width": "96px", "height": "32px"}, {"pressed": _gogo_value_1}, [], "examples/responsive/NestedResponsive.gogo:11:3", null, false)
		var _gogo_element_3 := _GogoElement_0.new(UiButton, {"name": "More", "text": "More", "width": "96px", "height": "32px"}, {"pressed": _gogo_value_2}, [], "examples/responsive/NestedResponsive.gogo:12:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "Body", "wrap": _gogo_value_0, "width": "auto", "gap": "8px", "row_gap": "10px", "padding": "8px", "background_color": "#30394d"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_3], "examples/responsive/NestedResponsive.gogo:9:9", null, false)
		return _gogo_element_0
