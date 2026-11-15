extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((Color("#ffcc66")))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Color) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {"name": "Caption", "text": "Rose — local Text color", "color": _gogo_value_0}, {}, [], "examples/styling/StyledRose.gogo:8:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(VBox, {"name": "Rose", "width": "100%", "padding": "8px", "background_color": "#344139", "border_color": "#83b698", "border_width": "1px", "border_left_width": "4px"}, {}, [_gogo_element_1], "examples/styling/StyledRose.gogo:6:9", null, false)
		return _gogo_element_0
