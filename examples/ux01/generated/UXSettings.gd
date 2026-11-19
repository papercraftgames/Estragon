extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element: return _GogoFactories_0._gogo_build_0()

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0() -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Text, {"text": "Settings"}, {}, [], "examples/ux01/UXSettings.gogo:4:38", null, false)
		return _gogo_element_0
