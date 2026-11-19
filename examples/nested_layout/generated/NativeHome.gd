extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Spacer = preload("../../../addons/estragon/runtime/node/spacer.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((1))

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


const _GogoProject_0 = preload("NativeSettings.gd")

const _GogoProject_1 = preload("Rose.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: float) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Spacer, {"grow": _gogo_value_0}, {}, [], "examples/nested_layout/NativeHome.gogo:10:4", null, false)
		var _gogo_element_3 := _GogoElement_0.new(Text, {"text": "Hello World!"}, {}, [], "examples/nested_layout/NativeHome.gogo:11:4", null, false)
		var _gogo_element_4 := _GogoElement_0.new(Text, {"text": "This is fun!"}, {}, [], "examples/nested_layout/NativeHome.gogo:12:4", null, false)
		var _gogo_element_5 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/nested_layout/NativeHome.gogo:13:4", null, false)
		var _gogo_element_6 := _GogoElement_0.new(_GogoProject_1, {}, {}, [], "examples/nested_layout/NativeHome.gogo:14:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"width": "100%", "height": "100%", "horizontal_align": "stretch", "gap": "8px"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/nested_layout/NativeHome.gogo:9:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"width": "100%", "height": "100%"}, {}, [_gogo_element_1], "examples/nested_layout/NativeHome.gogo:8:9", null, false)
		return _gogo_element_0
