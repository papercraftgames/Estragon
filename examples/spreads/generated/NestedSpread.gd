extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
signal caption_changed(previous: String, value: String)
var caption: String = "Nested":
	set(_gogo_incoming_caption):
		if is_same(caption, _gogo_incoming_caption): return
		var _gogo_previous_caption: String = caption
		caption = _gogo_incoming_caption
		caption_changed.emit(_gogo_previous_caption, _gogo_incoming_caption)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"caption_changed")
		return caption

func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"width":"100%", "padding":"6px", "background_color":"#30394d"})), (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"text":self.caption})))

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: Variant, _gogo_value_1: Variant) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Text, {}, {}, [], "examples/spreads/NestedSpread.gogo:8:3", null, false)
		_gogo_element_1.expand([[null, _gogo_value_1, "examples/spreads/NestedSpread.gogo:8:9"]])
		var _gogo_element_0 := _GogoElement_0.new(VBox, {}, {}, [_gogo_element_1], "examples/spreads/NestedSpread.gogo:7:9", null, false)
		_gogo_element_0.expand([["name", "Body", "examples/spreads/NestedSpread.gogo:7:15"], [null, _gogo_value_0, "examples/spreads/NestedSpread.gogo:7:27"]])
		return _gogo_element_0
