extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
signal width_target_changed(previous: String, value: String)
var width_target: String = "75%":
    set(_gogo_incoming_width_target):
        if is_same(width_target, _gogo_incoming_width_target): return
        var _gogo_previous_width_target: String = width_target
        width_target = _gogo_incoming_width_target
        width_target_changed.emit(_gogo_previous_width_target, _gogo_incoming_width_target)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"width_target_changed")
        return width_target

signal revision_changed(previous: int, value: int)
var revision: int = 0:
    set(_gogo_incoming_revision):
        if is_same(revision, _gogo_incoming_revision): return
        var _gogo_previous_revision: int = revision
        revision = _gogo_incoming_revision
        revision_changed.emit(_gogo_previous_revision, _gogo_incoming_revision)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"revision_changed")
        return revision

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (self.width_target),
        ("Body / revision "+str(self.revision)),
        (Color("#5995b5")),
        (Color("#70ab82"))
    )

const _GOGO_RENDER_FUNCTIONS_9a6fb41067b89d61 = {
"ordinary": [],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_9a6fb41067b89d61 = {
"revision": "int",
"width_target": "String"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Variant,
        _gogo_value_1: String,
        _gogo_value_2: Color,
        _gogo_value_3: Color
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_1}, {}, [], "examples/proportions/Panel.gogo:10:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(Rect, {"name": "Quarter", "width": "25%", "height": "30px", "fill": _gogo_value_2}, {}, [], "examples/proportions/Panel.gogo:12:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(Rect, {"name": "ThreeQuarters", "width": "75%", "height": "30px", "fill": _gogo_value_3}, {}, [], "examples/proportions/Panel.gogo:13:13", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Box, {"name": "Nested", "wrap": true, "width": "100%", "gap": "20px", "background_color": "#18232e"}, {}, [_gogo_element_3, _gogo_element_4], "examples/proportions/Panel.gogo:11:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Box, {"name": "Body", "direction": "column", "width": _gogo_value_0, "padding": "20px", "border_width": "5px", "border_color": "#9ab4cf", "background_color": "#28323e", "gap": "10px"}, {}, [_gogo_element_1, _gogo_element_2], "examples/proportions/Panel.gogo:9:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
