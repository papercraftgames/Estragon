extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(1.0),
		(1.0),
		(true),
		(true),
		(true)
	)


const _GogoProject_0 = preload("NativeSettings.gd")

const _GogoProject_1 = preload("Rose.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: float,
		_gogo_value_1: float,
		_gogo_value_2: bool,
		_gogo_value_3: bool,
		_gogo_value_4: bool
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(VBox, {"fill_height": _gogo_value_4}, {}, [], "examples/nested_layout/NativeHome.gogo:9:4", null, false)
		var _gogo_element_3 := _GogoElement_0.new(Text, {"text": "Hello World!"}, {}, [], "examples/nested_layout/NativeHome.gogo:10:4", null, false)
		var _gogo_element_4 := _GogoElement_0.new(Text, {"text": "This is fun!"}, {}, [], "examples/nested_layout/NativeHome.gogo:11:4", null, false)
		var _gogo_element_5 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/nested_layout/NativeHome.gogo:12:4", null, false)
		var _gogo_element_6 := _GogoElement_0.new(_GogoProject_1, {}, {}, [], "examples/nested_layout/NativeHome.gogo:13:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"fill_width": _gogo_value_2, "fill_height": _gogo_value_3}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/nested_layout/NativeHome.gogo:8:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"viewport_width_scale": _gogo_value_0, "viewport_height_scale": _gogo_value_1}, {}, [_gogo_element_1], "examples/nested_layout/NativeHome.gogo:7:9", null, false)
		return _gogo_element_0
