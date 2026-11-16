extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
func build_view() -> Element:
	var style := {"background_color":"#0000aa"}
	return _GogoFactories_0._gogo_build_0(
		(1),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(style)),
		(1),
		(true)
	)


const _GogoProject_0 = preload("Settings.gd")

const _GogoProject_1 = preload("Rose.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: float,
		_gogo_value_1: Variant,
		_gogo_value_2: float,
		_gogo_value_3: bool
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(VBox, {}, {}, [], "examples/ux01/WrapReproduction.gogo:11:4", null, false)
		_gogo_element_2.expand([["width", "75%", "examples/ux01/WrapReproduction.gogo:11:10"], ["grow", _gogo_value_0, "examples/ux01/WrapReproduction.gogo:11:22"], [null, _gogo_value_1, "examples/ux01/WrapReproduction.gogo:11:31"]])
		var _gogo_element_3 := _GogoElement_0.new(VBox, {"width": "75%", "grow": _gogo_value_2, "background_color": "#aaaa00"}, {}, [], "examples/ux01/WrapReproduction.gogo:12:4", null, false)
		var _gogo_element_4 := _GogoElement_0.new(Text, {"text": "Hello World!"}, {}, [], "examples/ux01/WrapReproduction.gogo:13:4", null, false)
		var _gogo_element_5 := _GogoElement_0.new(Text, {"text": "This is fun!"}, {}, [], "examples/ux01/WrapReproduction.gogo:14:4", null, false)
		var _gogo_element_7 := _GogoElement_0.new(Text, {"text": "This is the first Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:16:5", null, false)
		var _gogo_element_8 := _GogoElement_0.new(Text, {"text": "This is the second Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:17:5", null, false)
		var _gogo_element_9 := _GogoElement_0.new(Text, {"text": "This is the third Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:18:5", null, false)
		var _gogo_element_10 := _GogoElement_0.new(Text, {"text": "This is the fourth Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:19:5", null, false)
		var _gogo_element_11 := _GogoElement_0.new(Text, {"text": "This is the fifth Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:20:5", null, false)
		var _gogo_element_12 := _GogoElement_0.new(Text, {"text": "This is the sixth Text"}, {}, [], "examples/ux01/WrapReproduction.gogo:21:5", null, false)
		var _gogo_element_6 := _GogoElement_0.new(HBox, {"name": "Words", "wrap": _gogo_value_3}, {}, [_gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_10, _gogo_element_11, _gogo_element_12], "examples/ux01/WrapReproduction.gogo:15:4", null, false)
		var _gogo_element_13 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/ux01/WrapReproduction.gogo:23:4", null, false)
		var _gogo_element_14 := _GogoElement_0.new(_GogoProject_1, {}, {}, [], "examples/ux01/WrapReproduction.gogo:24:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Column", "width": "100%", "height": "100%", "padding": "20px", "gap": "20px", "horizontal_align": "end"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_13, _gogo_element_14], "examples/ux01/WrapReproduction.gogo:10:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%"}, {}, [_gogo_element_1], "examples/ux01/WrapReproduction.gogo:9:9", null, false)
		return _gogo_element_0
