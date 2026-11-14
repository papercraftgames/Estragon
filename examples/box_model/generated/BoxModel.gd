extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Rect = preload("../../../addons/estragon/runtime/node/rect.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
signal inset_changed(previous: float, value: float)
var inset: float = 12.0:
    set(_gogo_incoming_inset):
        if is_same(inset, _gogo_incoming_inset): return
        var _gogo_previous_inset: float = inset
        inset = _gogo_incoming_inset
        inset_changed.emit(_gogo_previous_inset, _gogo_incoming_inset)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"inset_changed")
        return inset

func change_padding() -> void:
    inset = 24.0 if inset == 12.0 else 12.0
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (Vector2(24,24)),
        (440),
        (8),
        (self.inset),
        (24),
        (12),
        (24),
        (8),
        (10),
        (12),
        (80),
        (40),
        (Color(0.9,0.3,0.3)),
        (6),
        (80),
        (40),
        (Color(0.3,0.6,1.0)),
        (8),
        (44),
        (4),
        (change_padding)
    )


func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Vector2,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: Variant,
        _gogo_value_5: Variant,
        _gogo_value_6: int,
        _gogo_value_7: Variant,
        _gogo_value_8: Variant,
        _gogo_value_9: Variant,
        _gogo_value_10: Variant,
        _gogo_value_11: Variant,
        _gogo_value_12: Color,
        _gogo_value_13: Variant,
        _gogo_value_14: Variant,
        _gogo_value_15: Variant,
        _gogo_value_16: Color,
        _gogo_value_17: Variant,
        _gogo_value_18: Variant,
        _gogo_value_19: Variant,
        _gogo_value_20: Callable
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(Text, {"text": "Pixel padding and margins", "font_size": _gogo_value_6}, {}, [], "examples/box_model/BoxModel.gogo:15:13", null, false)
        var _gogo_element_4 := _GogoElement_0.new(Rect, {"width": _gogo_value_10, "height": _gogo_value_11, "fill": _gogo_value_12, "margin_right": _gogo_value_13}, {}, [], "examples/box_model/BoxModel.gogo:17:17", null, false)
        var _gogo_element_5 := _GogoElement_0.new(Rect, {"width": _gogo_value_14, "height": _gogo_value_15, "fill": _gogo_value_16, "margin_top": _gogo_value_17}, {}, [], "examples/box_model/BoxModel.gogo:18:17", null, false)
        var _gogo_element_3 := _GogoElement_0.new(HBox, {"padding": _gogo_value_7, "gap": _gogo_value_8, "margin_left": _gogo_value_9}, {}, [_gogo_element_4, _gogo_element_5], "examples/box_model/BoxModel.gogo:16:13", null, false)
        var _gogo_element_6 := _GogoElement_0.new(UiButton, {"name": "Action", "text": "Change padding", "height": _gogo_value_18, "width": "100%", "margin": _gogo_value_19}, {"pressed": _gogo_value_20}, [], "examples/box_model/BoxModel.gogo:20:13", null, false)
        var _gogo_element_1 := _GogoElement_0.new(VBox, {"name": "Panel", "padding": _gogo_value_3, "padding_left": _gogo_value_4, "gap": _gogo_value_5, "width": "100%"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_6], "examples/box_model/BoxModel.gogo:14:9", null, false)
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "position": _gogo_value_0, "width": _gogo_value_1, "padding": _gogo_value_2}, {}, [_gogo_element_1], "examples/box_model/BoxModel.gogo:13:12", null, false)
        return _gogo_element_0
