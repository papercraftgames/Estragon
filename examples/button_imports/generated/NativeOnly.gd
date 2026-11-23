extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
var clicks: int = 0
func pressed(): clicks += 1
func construct() -> Button: return Button.new()
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((pressed))

const _GOGO_RENDER_FUNCTIONS_e098fd201e9a2ee6 = {
"ordinary": ["pressed", "construct"],
"reactive": ["build_view"]
}

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Callable) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new("Button", {"name": "Godot", "text": "Unimported native Button"}, {"pressed": _gogo_value_0}, [], "examples/button_imports/NativeOnly.gogo:7:9", null, false)
		_gogo_element_0.resolve_bindings()
		return _gogo_element_0
