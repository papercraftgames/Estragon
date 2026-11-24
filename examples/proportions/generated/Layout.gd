extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Grid = preload("../../../addons/estragon/runtime/node/grid.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("Panel.gd")
@export var borrowed: Node
signal target_changed(previous: String, value: String)
var target: String = "75%":
    set(_gogo_incoming_target):
        if is_same(target, _gogo_incoming_target): return
        var _gogo_previous_target: String = target
        target = _gogo_incoming_target
        target_changed.emit(_gogo_previous_target, _gogo_incoming_target)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"target_changed")
        return target

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

var _GogoLayout_24 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, Callable(self, "_GogoLayout_24_defaults"), {
"areas": ["Header Header", "Side Body"],
"columns": 2,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/proportions/Layout.gogo:11:15")
var _GogoLayout_26 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoProject_1, Callable(self, "_GogoLayout_26_defaults"), {
"area": "Header"
}, "examples/proportions/Layout.gogo:12:6")
var _GogoLayout_28 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_28_defaults"), {
"area": "Side"
}, "examples/proportions/Layout.gogo:13:6")
var _GogoLayout_30 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_30_defaults"), {
"area": "Body"
}, "examples/proportions/Layout.gogo:13:15")
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        (_GogoLayout_24),
        (_GogoLayout_26),
        (_GogoLayout_28),
        (self.target),
        (self.revision),
        (self.borrowed)
    )

const _GOGO_RENDER_FUNCTIONS_97b2aa55f76156fb = {
"ordinary": [],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_97b2aa55f76156fb = {
"revision": "int",
"target": "String"
}

const _GogoLayout_0 = preload("../../../addons/estragon/runtime/node/grid.gd")

const _GogoProject_1 = preload("../../layouts/generated/Header.gd")

const _GogoLayout_0_ = preload("../../../addons/estragon/runtime/node/box.gd")

const _GogoProject_3 = preload("Panel.gd")

func _GogoLayout_24_defaults(): return [[["columns", 2, "examples/proportions/Layout.gogo:11:32"], ["column_gap", "20px", "examples/proportions/Layout.gogo:11:44"], ["row_gap", "12px", "examples/proportions/Layout.gogo:11:62"]]]

func _GogoLayout_26_defaults(): return [[], []]

func _GogoLayout_28_defaults(): return [[]]

func _GogoLayout_30_defaults(): return [[]]

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: Variant,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: String,
        _gogo_value_4: int,
        _gogo_value_5: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": "L12 / parent-owned percentage budgets"}, {}, [], "examples/proportions/Layout.gogo:17:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(Text, {"text": "Auto header spans both tracks"}, {}, [], "examples/proportions/Layout.gogo:19:21", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_1), {}, {}, [_gogo_element_4], "examples/proportions/Layout.gogo:19:13", null, false)
        _gogo_element_3.resolve_bindings()
        _gogo_element_3 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_1, _gogo_element_3)
        var _gogo_element_6 := _GogoElement_0.new(Text, {"text": "25%"}, {}, [], "examples/proportions/Layout.gogo:20:70", null, false)
        _gogo_element_6.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_2), {"name": "Side", "width": "25%", "background_color": "#453747"}, {}, [_gogo_element_6], "examples/proportions/Layout.gogo:20:13", null, false)
        _gogo_element_5.resolve_bindings()
        _gogo_element_5 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_2, _gogo_element_5)
        var _gogo_element_7 := _GogoElement_0.new(_GogoProject_3, {"area": "Body", "name": "Panel", "width_target": _gogo_value_3, "revision": _gogo_value_4}, {}, [], "examples/proportions/Layout.gogo:21:13", null, false)
        _gogo_element_7.origins["area"] = "examples/proportions/Layout.gogo:21:20"
        _gogo_element_7.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_0), {"name": "Grid", "width": "100%", "height": "280px"}, {}, [_gogo_element_3, _gogo_element_5, _gogo_element_7], "examples/proportions/Layout.gogo:18:9", null, false)
        _gogo_element_2.resolve_bindings()
        _gogo_element_2 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_0, _gogo_element_2)
        var _gogo_element_9 := _GogoElement_0.new(Box, {"width": "25%", "height": "40px", "background_color": "#5995b5"}, {}, [], "examples/proportions/Layout.gogo:24:13", null, false)
        _gogo_element_9.resolve_bindings()
        var _gogo_element_10 := _GogoElement_0.new(Box, {"width": "75%", "height": "40px", "background_color": "#70ab82"}, {}, [], "examples/proportions/Layout.gogo:25:13", null, false)
        _gogo_element_10.resolve_bindings()
        var _gogo_element_8 := _GogoElement_0.new(Box, {"name": "PlainRow", "width": "300px", "column_gap": "20px"}, {}, [_gogo_element_9, _gogo_element_10], "examples/proportions/Layout.gogo:23:9", null, false)
        _gogo_element_8.resolve_bindings()
        var _gogo_element_11 := _GogoElement_0.new(Text, {"text": "Row: 70 + gap20 + 210 = 300 / Wrap keeps 25% + 75% of full content"}, {}, [], "examples/proportions/Layout.gogo:28:9", null, false)
        _gogo_element_11.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "padding": "20px", "direction": "column", "gap": "12px", "background_color": "#172332"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_8, _gogo_value_5, _gogo_element_11], "examples/proportions/Layout.gogo:16:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
