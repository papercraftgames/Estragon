extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const Action = preload("../../godot_button.gd")
const Header = preload("Header.gd")
const Library = preload("Library.gd")
var library: Library = Library.new()
var Shared = library.Shared
signal caption_changed(previous: String, value: String)
var caption: String = "First-class layout declarations":
    set(_gogo_incoming_caption):
        if is_same(caption, _gogo_incoming_caption): return
        var _gogo_previous_caption: String = caption
        caption = _gogo_incoming_caption
        caption_changed.emit(_gogo_previous_caption, _gogo_incoming_caption)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"caption_changed")
        return caption

signal tint_changed(previous: String, value: String)
var tint: String = "#30455c":
    set(_gogo_incoming_tint):
        if is_same(tint, _gogo_incoming_tint): return
        var _gogo_previous_tint: String = tint
        tint = _gogo_incoming_tint
        tint_changed.emit(_gogo_previous_tint, _gogo_incoming_tint)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"tint_changed")
        return tint

signal mode_changed(previous: String, value: String)
var mode: String = "grid":
    set(_gogo_incoming_mode):
        if is_same(mode, _gogo_incoming_mode): return
        var _gogo_previous_mode: String = mode
        mode = _gogo_incoming_mode
        mode_changed.emit(_gogo_previous_mode, _gogo_incoming_mode)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"mode_changed")
        return mode

signal side_mode_changed(previous: String, value: String)
var side_mode: String = "grid":
    set(_gogo_incoming_side_mode):
        if is_same(side_mode, _gogo_incoming_side_mode): return
        var _gogo_previous_side_mode: String = side_mode
        side_mode = _gogo_incoming_side_mode
        side_mode_changed.emit(_gogo_previous_side_mode, _gogo_incoming_side_mode)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"side_mode_changed")
        return side_mode

signal selected_changed(previous: bool, value: bool)
var selected: bool = false:
    set(_gogo_incoming_selected):
        if is_same(selected, _gogo_incoming_selected): return
        var _gogo_previous_selected: bool = selected
        selected = _gogo_incoming_selected
        selected_changed.emit(_gogo_previous_selected, _gogo_incoming_selected)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"selected_changed")
        return selected

signal borrowed_changed(previous: Node, value: Node)
var borrowed: Node = null:
    set(_gogo_incoming_borrowed):
        if is_same(borrowed, _gogo_incoming_borrowed): return
        var _gogo_previous_borrowed: Node = borrowed
        borrowed = _gogo_incoming_borrowed
        borrowed_changed.emit(_gogo_previous_borrowed, _gogo_incoming_borrowed)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"borrowed_changed")
        return borrowed

signal options_changed(previous: Dictionary, value: Dictionary)
var options: Dictionary = {}:
    set(_gogo_incoming_options):
        if is_same(options, _gogo_incoming_options): return
        var _gogo_previous_options: Dictionary = options
        options = _gogo_incoming_options
        options_changed.emit(_gogo_previous_options, _gogo_incoming_options)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"options_changed")
        return options

signal show_extra_changed(previous: bool, value: bool)
var show_extra: bool = true:
    set(_gogo_incoming_show_extra):
        if is_same(show_extra, _gogo_incoming_show_extra): return
        var _gogo_previous_show_extra: bool = show_extra
        show_extra = _gogo_incoming_show_extra
        show_extra_changed.emit(_gogo_previous_show_extra, _gogo_incoming_show_extra)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_extra_changed")
        return show_extra

var clicks: int = 0
func clicked(): clicks += 1

var _GogoLayout_43 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, Callable(self, "_GogoLayout_43_defaults"), {
"areas": ["Top Top Top", "BottomLeft BottomMiddle BottomRight"],
"columns": 3,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/layouts/Layouts.gogo:23:15")
var _GogoLayout_45 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_45_defaults"), {
"area": "Top"
}, "examples/layouts/Layouts.gogo:24:6")
var _GogoLayout_47 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_47_defaults"), {
"area": "BottomLeft"
}, "examples/layouts/Layouts.gogo:25:6")
var _GogoLayout_48 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_48_defaults"), {
"area": "BottomMiddle"
}, "examples/layouts/Layouts.gogo:25:48")
var _GogoLayout_49 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_49_defaults"), {
"area": "BottomRight"
}, "examples/layouts/Layouts.gogo:25:92")

# This earlier use keeps the original Side with no parent-area placement.
func original_side(): return _GogoFactories_0._gogo_build_0((_GogoLayout_43))

var _GogoLayout_50 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, Callable(self, "_GogoLayout_50_defaults"), {
"areas": ["Header Header", "Side Body", "Side Footer"],
"columns": 2,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/layouts/Layouts.gogo:31:15")
var _GogoLayout_51 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoProject_2, Callable(self, "_GogoLayout_51_defaults"), {
"area": "Header"
}, "examples/layouts/Layouts.gogo:32:6")
var _GogoLayout_53 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_43, Callable(self, "_GogoLayout_53_defaults"), {
"area": "Side"
}, "examples/layouts/Layouts.gogo:33:6")
var _GogoLayout_54 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_54_defaults"), {
"area": "Body"
}, "examples/layouts/Layouts.gogo:33:27")
var _GogoLayout_55 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0_, Callable(self, "_GogoLayout_55_defaults"), {
"area": "Footer"
}, "examples/layouts/Layouts.gogo:34:15")

var _GogoLayout_56 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, Callable(self, "_GogoLayout_56_defaults"), {
"areas": ["Shared"],
"columns": 1,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/layouts/Layouts.gogo:37:15")
var _GogoLayout_57 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(Shared, Callable(self, "_GogoLayout_57_defaults"), {
"area": "Shared"
}, "examples/layouts/Layouts.gogo:38:6")

func scoped_side():
    var _GogoLayout_58 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_0, func(): return [[]], {
"areas": ["Side"],
"columns": 1,
"direction": "grid",
"rows": null,
"template": ""
}, "examples/layouts/Layouts.gogo:42:19")
    var _GogoLayout_59 = preload("../../../addons/estragon/runtime/composition/preset.gd").new(_GogoLayout_53, func(): return [[["gap", "2px", "examples/layouts/Layouts.gogo:43:15"]]], {
"area": "Side"
}, "examples/layouts/Layouts.gogo:43:10")
    return _GogoFactories_0._gogo_build_1((_GogoLayout_59))

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_2(
        (_GogoLayout_50),
        (self.mode),
        (_GogoLayout_51),
        (_GogoLayout_53),
        (self.side_mode),
        (_GogoLayout_45),
        (_GogoLayout_47),
        (_GogoLayout_48),
        (_GogoLayout_49),
        (_GogoLayout_54),
        (clicked),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "selected", func(_gogo_source, _gogo_edit: bool): _gogo_source.selected = _gogo_edit, "selected")),
        (_GogoLayout_56),
        (_GogoLayout_57),
        (library.upper),
        (library.lowerLeft),
        (library.lowerRight),
        (_GogoFactories_0._gogo_build_3((preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.options))) if self.show_extra else null),
        (self.borrowed),
        (_GogoLayout_55)
    )


const _GogoLayout_0 = preload("../../../addons/estragon/runtime/node/grid.gd")

const _GogoLayout_0_ = preload("../../../addons/estragon/runtime/node/box.gd")

const _GogoProject_2 = preload("Header.gd")

func _GogoLayout_43_defaults(): return [[["gap", "8px", "examples/layouts/Layouts.gogo:23:20"], ["padding", "8px", "examples/layouts/Layouts.gogo:23:30"], ["rows", ["1fr","1fr"], "examples/layouts/Layouts.gogo:23:44"], ["background_color", "#25374c", "examples/layouts/Layouts.gogo:23:65"]]]

func _GogoLayout_45_defaults(): return [[["background_color", "#3e6483", "examples/layouts/Layouts.gogo:24:10"]], [], []]

func _GogoLayout_47_defaults(): return [[["background_color", "#567953", "examples/layouts/Layouts.gogo:25:17"]]]

func _GogoLayout_48_defaults(): return [[["background_color", "#827044", "examples/layouts/Layouts.gogo:25:61"]]]

func _GogoLayout_49_defaults(): return [[["background_color", "#875d61", "examples/layouts/Layouts.gogo:25:104"]]]

func _GogoLayout_50_defaults(): return [[["gap", "8px", "examples/layouts/Layouts.gogo:31:19"], ["padding", "12px", "examples/layouts/Layouts.gogo:31:29"], ["columns", ["160px","1fr"], "examples/layouts/Layouts.gogo:31:44"], ["rows", ["64px","1fr","48px"], "examples/layouts/Layouts.gogo:31:70"], ["background_color", "#172332", "examples/layouts/Layouts.gogo:31:99"]]]

func _GogoLayout_51_defaults(): return [[["padding", "12px", "examples/layouts/Layouts.gogo:32:13"], ["background_color", self.tint, "examples/layouts/Layouts.gogo:32:28"], ["title", self.caption, "examples/layouts/Layouts.gogo:32:57"]], []]

func _GogoLayout_53_defaults(): return [[["width", "25%", "examples/layouts/Layouts.gogo:33:11"]], []]

func _GogoLayout_54_defaults(): return [[["padding", "8px", "examples/layouts/Layouts.gogo:33:32"], ["gap", "8px", "examples/layouts/Layouts.gogo:33:46"], ["direction", "column", "examples/layouts/Layouts.gogo:33:56"], ["background_color", "#263544", "examples/layouts/Layouts.gogo:33:75"]]]

func _GogoLayout_55_defaults(): return [[["padding", "8px", "examples/layouts/Layouts.gogo:34:22"], ["background_color", "#30445b", "examples/layouts/Layouts.gogo:34:36"], [null, preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.options), "examples/layouts/Layouts.gogo:34:63"]]]

func _GogoLayout_56_defaults(): return [[["gap", "4px", "examples/layouts/Layouts.gogo:37:24"], ["columns", 1, "examples/layouts/Layouts.gogo:37:34"], ["rows", ["1fr"], "examples/layouts/Layouts.gogo:37:46"]]]

func _GogoLayout_57_defaults(): return [[]]

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_0), {}, {}, [], "examples/layouts/Layouts.gogo:29:30", null, false)
        _gogo_element_0 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_0, _gogo_element_0)
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_0), {}, {}, [], "examples/layouts/Layouts.gogo:45:12", null, false)
        _gogo_element_0 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_0, _gogo_element_0)
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: Variant,
        _gogo_value_1: String,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant,
        _gogo_value_4: String,
        _gogo_value_5: Variant,
        _gogo_value_6: Variant,
        _gogo_value_7: Variant,
        _gogo_value_8: Variant,
        _gogo_value_9: Variant,
        _gogo_value_10: Callable,
        _gogo_value_11: Variant,
        _gogo_value_12: Variant,
        _gogo_value_13: Variant,
        _gogo_value_14: Variant,
        _gogo_value_15: Variant,
        _gogo_value_16: Variant,
        _gogo_value_17: Variant,
        _gogo_value_18: Variant,
        _gogo_value_19: Variant
    ) -> _GogoElement_0:
        var _gogo_element_2 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_2), {"name": "Header"}, {}, [], "examples/layouts/Layouts.gogo:50:13", null, false)
        _gogo_element_2 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_2, _gogo_element_2)
        var _gogo_element_5 := _GogoElement_0.new(Text, {"text": "Side"}, {}, [], "examples/layouts/Layouts.gogo:52:33", null, false)
        var _gogo_element_4 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_5), {"name": "Top"}, {}, [_gogo_element_5], "examples/layouts/Layouts.gogo:52:17", null, false)
        _gogo_element_4 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_5, _gogo_element_4)
        var _gogo_element_6 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_6), {"name": "Left"}, {}, [], "examples/layouts/Layouts.gogo:53:17", null, false)
        _gogo_element_6 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_6, _gogo_element_6)
        var _gogo_element_7 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_7), {"name": "Middle"}, {}, [], "examples/layouts/Layouts.gogo:54:17", null, false)
        _gogo_element_7 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_7, _gogo_element_7)
        var _gogo_element_8 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_8), {"name": "Right"}, {}, [], "examples/layouts/Layouts.gogo:55:17", null, false)
        _gogo_element_8 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_8, _gogo_element_8)
        var _gogo_element_3 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_3), {"name": "Side", "width": "auto", "direction": _gogo_value_4}, {}, [_gogo_element_4, _gogo_element_6, _gogo_element_7, _gogo_element_8], "examples/layouts/Layouts.gogo:51:13", null, false)
        _gogo_element_3 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_3, _gogo_element_3)
        var _gogo_element_10 := _GogoElement_0.new(Text, {"text": "Native Grid tracks and Nodes"}, {}, [], "examples/layouts/Layouts.gogo:58:17", null, false)
        var _gogo_element_11 := _GogoElement_0.new(Action, {"name": "Action", "text": "Native button"}, {"pressed": _gogo_value_10}, [], "examples/layouts/Layouts.gogo:59:17", null, false)
        var _gogo_element_12 := _GogoElement_0.new(Toggle, {"name": "Toggle", "width": "300px"}, {}, [], "examples/layouts/Layouts.gogo:60:17", null, false)
        _gogo_element_12.set_text_body([["Controlled native toggle", "examples/layouts/Layouts.gogo:60:80"]])
        _gogo_element_12.bindings = {"value": _gogo_value_11}
        var _gogo_element_15 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_14), {"name": "Upper"}, {}, [], "examples/layouts/Layouts.gogo:63:25", null, false)
        _gogo_element_15 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_14, _gogo_element_15)
        var _gogo_element_16 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_15), {"name": "LowerLeft"}, {}, [], "examples/layouts/Layouts.gogo:64:25", null, false)
        _gogo_element_16 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_15, _gogo_element_16)
        var _gogo_element_17 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_16), {"name": "LowerRight"}, {}, [], "examples/layouts/Layouts.gogo:65:25", null, false)
        _gogo_element_17 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_16, _gogo_element_17)
        var _gogo_element_14 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_13), {"name": "Shared"}, {}, [_gogo_element_15, _gogo_element_16, _gogo_element_17], "examples/layouts/Layouts.gogo:62:21", null, false)
        _gogo_element_14 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_13, _gogo_element_14)
        var _gogo_element_13 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_12), {"name": "Imported", "width": "100%", "height": "120px"}, {}, [_gogo_element_14], "examples/layouts/Layouts.gogo:61:17", null, false)
        _gogo_element_13 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_12, _gogo_element_13)
        var _gogo_element_9 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_9), {"name": "Body"}, {}, [_gogo_element_10, _gogo_element_11, _gogo_element_12, _gogo_element_13, _gogo_value_17, _gogo_value_18], "examples/layouts/Layouts.gogo:57:13", null, false)
        _gogo_element_9 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_9, _gogo_element_9)
        var _gogo_element_19 := _GogoElement_0.new(Text, {"text": "Reusable native definitions"}, {}, [], "examples/layouts/Layouts.gogo:71:35", null, false)
        var _gogo_element_18 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_19), {"name": "Footer"}, {}, [_gogo_element_19], "examples/layouts/Layouts.gogo:71:13", null, false)
        _gogo_element_18 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_19, _gogo_element_18)
        var _gogo_element_1 := _GogoElement_0.new(preload("../../../addons/estragon/runtime/composition/preset.gd").type_of(_gogo_value_0), {"name": "App", "width": "100%", "height": "100%", "direction": _gogo_value_1}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_9, _gogo_element_18], "examples/layouts/Layouts.gogo:49:9", null, false)
        _gogo_element_1 = preload("../../../addons/estragon/runtime/composition/preset.gd").apply(_gogo_value_0, _gogo_element_1)
        var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"name": "UI", "width": "100%", "height": "100%"}, {}, [_gogo_element_1], "examples/layouts/Layouts.gogo:48:12", null, false)
        return _gogo_element_0


    static func _gogo_build_3(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Box, {}, {}, [], "examples/layouts/Layouts.gogo:68:18", "extra", true)
        _gogo_element_0.expand([["name", "Extra", "examples/layouts/Layouts.gogo:68:23"], ["width", "100%", "examples/layouts/Layouts.gogo:68:48"], ["height", "20px", "examples/layouts/Layouts.gogo:68:61"], ["background_color", "#52677c", "examples/layouts/Layouts.gogo:68:75"], [null, _gogo_value_0, "examples/layouts/Layouts.gogo:68:102"]])
        return _gogo_element_0
