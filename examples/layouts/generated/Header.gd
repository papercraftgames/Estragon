extends "../../../addons/estragon/runtime/node/box.gd"
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
signal title_changed(previous: String, value: String)
var title: String = "Native layout presets":
    set(_gogo_incoming_title):
        if is_same(title, _gogo_incoming_title): return
        var _gogo_previous_title: String = title
        title = _gogo_incoming_title
        title_changed.emit(_gogo_previous_title, _gogo_incoming_title)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"title_changed")
        return title

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0((Color("#ffffff")), (self.title))

const _GOGO_RENDER_FUNCTIONS = ["build_view"]


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Color, _gogo_value_1: String) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Text, {"color": _gogo_value_0, "text": _gogo_value_1}, {}, [], "examples/layouts/Header.gogo:6:12", null, false)
        return _gogo_element_0
