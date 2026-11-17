extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
# Compatibility proof only: an old user's explicit alias remains an ordinary import.
var clicks: int = 0
func pressed(): clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((pressed))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Callable) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(UiButton, {"name": "OldUserAlias", "text": "Explicit old alias"}, {"pressed": _gogo_value_0}, [], "tests/button_imports/LegacyAlias.gogo:8:9", null, false)
		return _gogo_element_0
