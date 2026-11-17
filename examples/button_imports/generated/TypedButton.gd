extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
signal supplied_changed(previous: _GogoImport_0, value: _GogoImport_0)
var supplied: _GogoImport_0 = null:
	set(_gogo_incoming_supplied):
		if is_same(supplied, _gogo_incoming_supplied): return
		var _gogo_previous_supplied: _GogoImport_0 = supplied
		supplied = _gogo_incoming_supplied
		supplied_changed.emit(_gogo_previous_supplied, _gogo_incoming_supplied)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"supplied_changed")
		return supplied

func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(("Typed import: "+("none" if self.supplied==null else self.supplied.text)))


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(_gogo_value_0: String) -> _GogoElement_0:
		var _gogo_element_0 := _GogoElement_0.new(Text, {"text": _gogo_value_0}, {}, [], "examples/button_imports/TypedButton.gogo:7:9", null, false)
		return _gogo_element_0
