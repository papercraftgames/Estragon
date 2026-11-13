extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
signal extent_changed(previous: Vector2, value: Vector2)
var extent: Vector2 = Vector2(640,360):
	set(_gogo_incoming_extent):
		if is_same(extent, _gogo_incoming_extent): return
		var _gogo_previous_extent: Vector2 = extent
		extent = _gogo_incoming_extent
		extent_changed.emit(_gogo_previous_extent, _gogo_incoming_extent)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"extent_changed")
		return extent

func _ready() -> void:
	resized()
	get_viewport().size_changed.connect(resized)
func resized() -> void:
	extent = get_viewport_rect().size
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(self.extent.x),
		(self.extent.y),
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
		var _gogo_element_2 := _GogoElement_0.new(VBox, {"fill_height": _gogo_value_4}, {}, [], "examples/nested_layout/NativeHome.gogo:15:4", null, false)
		var _gogo_element_3 := _GogoElement_0.new(Text, {"text": "Hello World!"}, {}, [], "examples/nested_layout/NativeHome.gogo:16:4", null, false)
		var _gogo_element_4 := _GogoElement_0.new(Text, {"text": "This is fun!"}, {}, [], "examples/nested_layout/NativeHome.gogo:17:4", null, false)
		var _gogo_element_5 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/nested_layout/NativeHome.gogo:18:4", null, false)
		var _gogo_element_6 := _GogoElement_0.new(_GogoProject_1, {}, {}, [], "examples/nested_layout/NativeHome.gogo:19:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"fill_width": _gogo_value_2, "fill_height": _gogo_value_3}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6], "examples/nested_layout/NativeHome.gogo:14:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"width": _gogo_value_0, "height": _gogo_value_1}, {}, [_gogo_element_1], "examples/nested_layout/NativeHome.gogo:13:9", null, false)
		return _gogo_element_0
