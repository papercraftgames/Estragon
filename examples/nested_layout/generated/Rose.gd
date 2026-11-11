extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0()


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0() -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "Rose is cute!"}, {}, [], "examples/nested_layout/Rose.gogo:6:15", null, false)
		var _gogo_element_0 := _GogoElement_0.new(HBox, {}, {}, [_gogo_element_1], "examples/nested_layout/Rose.gogo:6:9", null, false)
		return _gogo_element_0
