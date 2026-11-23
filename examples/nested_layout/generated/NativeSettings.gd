extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
func exit() -> void:
	get_tree().quit()
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((self.exit))

const _GOGO_RENDER_FUNCTIONS_88ee654dea9a491a = {
"ordinary": ["exit"],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Callable) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new("Button", {"text": "Exit"}, {"pressed": _gogo_value_0}, [], "examples/nested_layout/NativeSettings.gogo:7:15", null, false)
		_gogo_element_1.resolve_bindings()
		var _gogo_element_0 := _GogoElement_0.new(HBox, {}, {}, [_gogo_element_1], "examples/nested_layout/NativeSettings.gogo:7:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
