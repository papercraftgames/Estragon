extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((Vector2(24,24)), (8.0), (get_children()))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Vector2, _gogo_value_1: Variant, _gogo_value_2: Variant) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {"text": "Hello World!"}, {}, [], "examples/nested_layout/SceneHome.gogo:9:4", null, false)
		var _gogo_element_3 := _GogoElement_0.new(Text, {"text": "After the scene-authored Settings"}, {}, [], "examples/nested_layout/SceneHome.gogo:11:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"gap": _gogo_value_1}, {}, [_gogo_element_2, _gogo_value_2, _gogo_element_3], "examples/nested_layout/SceneHome.gogo:8:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"position": _gogo_value_0}, {}, [_gogo_element_1], "examples/nested_layout/SceneHome.gogo:7:9", null, false)
		return _gogo_element_0
