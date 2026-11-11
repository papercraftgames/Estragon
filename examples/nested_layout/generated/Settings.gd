extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
func exit() -> void:
	get_tree().quit()
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((self.exit))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Callable) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(UiButton, {"text": "Exit"}, {"pressed": _gogo_value_0}, [], "examples/nested_layout/Settings.gogo:8:15", null, false)
		var _gogo_element_0 := _GogoElement_0.new(HBox, {}, {}, [_gogo_element_1], "examples/nested_layout/Settings.gogo:8:9", null, false)
		return _gogo_element_0
