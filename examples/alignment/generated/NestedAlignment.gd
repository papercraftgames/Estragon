extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
signal own_changed(previous: String, value: String)
var own: String = "end":
	set(_gogo_incoming_own):
		if is_same(own, _gogo_incoming_own): return
		var _gogo_previous_own: String = own
		own = _gogo_incoming_own
		own_changed.emit(_gogo_previous_own, _gogo_incoming_own)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"own_changed")
		return own

func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0((self.own))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
		var _gogo_element_1 := _GogoElement_0.new(Rect, {"width": "20px", "height": "20px", "background_color": "#ffc65c"}, {}, [], "examples/alignment/NestedAlignment.gogo:8:3", null, false)
		var _gogo_element_2 := _GogoElement_0.new(Rect, {"width": "20px", "height": "20px", "background_color": "#477dbb"}, {}, [], "examples/alignment/NestedAlignment.gogo:9:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(HBox, {"name": "Body", "align_self": _gogo_value_0, "width": "50%", "height": "40px", "horizontal_align": "space-around", "vertical_align": "center", "background_color": "#252b38"}, {}, [_gogo_element_1, _gogo_element_2], "examples/alignment/NestedAlignment.gogo:7:9", null, false)
		return _gogo_element_0
