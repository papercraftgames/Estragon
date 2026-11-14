extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
var picture: Texture2D
func _ready() -> void:
	var image := Image.create(64,24,false,Image.FORMAT_RGBA8)
	image.fill(Color.CORNFLOWER_BLUE)
	picture = ImageTexture.create_from_image(image)
func exit() -> void:
	get_tree().quit()
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(Vector2(24,24)),
		(520.0),
		(8.0),
		(8.0),
		(self.exit),
		(8.0),
		(self.picture),
		(get_children())
	)


const _GogoProject_0 = preload("NativeSettings.gd")

func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Vector2,
		_gogo_value_1: Variant,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Callable,
		_gogo_value_5: Variant,
		_gogo_value_6: Texture2D,
		_gogo_value_7: Variant
	) -> _GogoElement_0:
		var _gogo_element_3 := _GogoElement_0.new("Button", {"text": "Exit"}, {"pressed": _gogo_value_4}, [], "examples/nested_layout/NativeGallery.gogo:17:20", null, false)
		var _gogo_element_4 := _GogoElement_0.new("Label", {"text": "Ready"}, {}, [], "examples/nested_layout/NativeGallery.gogo:17:62", null, false)
		var _gogo_element_2 := _GogoElement_0.new(HBox, {"gap": _gogo_value_3}, {}, [_gogo_element_3, _gogo_element_4], "examples/nested_layout/NativeGallery.gogo:17:4", null, false)
		var _gogo_element_6 := _GogoElement_0.new("LineEdit", {"placeholder_text": "Native editing"}, {}, [], "examples/nested_layout/NativeGallery.gogo:18:20", null, false)
		var _gogo_element_7 := _GogoElement_0.new("TextureRect", {"texture": _gogo_value_6}, {}, [], "examples/nested_layout/NativeGallery.gogo:18:66", null, false)
		var _gogo_element_5 := _GogoElement_0.new(VBox, {"gap": _gogo_value_5}, {}, [_gogo_element_6, _gogo_element_7], "examples/nested_layout/NativeGallery.gogo:18:4", null, false)
		var _gogo_element_9 := _GogoElement_0.new("Label", {"text": "Godot owns "}, {}, [], "examples/nested_layout/NativeGallery.gogo:19:19", null, false)
		var _gogo_element_10 := _GogoElement_0.new("Label", {"text": "Container internals"}, {}, [], "examples/nested_layout/NativeGallery.gogo:19:47", null, false)
		var _gogo_element_8 := _GogoElement_0.new("HBoxContainer", {}, {}, [_gogo_element_9, _gogo_element_10], "examples/nested_layout/NativeGallery.gogo:19:4", null, false)
		var _gogo_element_11 := _GogoElement_0.new(Text, {"text": "The next Button is borrowed from the Scene dock:"}, {}, [], "examples/nested_layout/NativeGallery.gogo:20:4", null, false)
		var _gogo_element_12 := _GogoElement_0.new(_GogoProject_0, {}, {}, [], "examples/nested_layout/NativeGallery.gogo:22:4", null, false)
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"gap": _gogo_value_2, "width": "100%"}, {}, [_gogo_element_2, _gogo_element_5, _gogo_element_8, _gogo_element_11, _gogo_value_7, _gogo_element_12], "examples/nested_layout/NativeGallery.gogo:16:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"position": _gogo_value_0, "width": _gogo_value_1}, {}, [_gogo_element_1], "examples/nested_layout/NativeGallery.gogo:15:9", null, false)
		return _gogo_element_0
