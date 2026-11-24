extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("../../../addons/estragon/runtime/node/box.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/input.gd")
const _GogoImport_1 = preload("ScrollPanel.gd")
signal thickness_changed(previous: Variant, value: Variant)
var thickness: Variant = 12:
    set(_gogo_incoming_thickness):
        if is_same(thickness, _gogo_incoming_thickness): return
        var _gogo_previous_thickness: Variant = thickness
        thickness = _gogo_incoming_thickness
        thickness_changed.emit(_gogo_previous_thickness, _gogo_incoming_thickness)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"thickness_changed")
        return thickness

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

signal draft_changed(previous: String, value: String)
var draft: String = "Retained native input":
    set(_gogo_incoming_draft):
        if is_same(draft, _gogo_incoming_draft): return
        var _gogo_previous_draft: String = draft
        draft = _gogo_incoming_draft
        draft_changed.emit(_gogo_previous_draft, _gogo_incoming_draft)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"draft_changed")
        return draft

signal chrome_changed(previous: Dictionary, value: Dictionary)
var chrome: Dictionary = {"scrollbar_style":{"track_color":"#292929","thumb_color":"#727272","thumb_hover_color":"#919191","thumb_pressed_color":"#aaaaaa"}}:
    set(_gogo_incoming_chrome):
        if is_same(chrome, _gogo_incoming_chrome): return
        var _gogo_previous_chrome: Dictionary = chrome
        chrome = _gogo_incoming_chrome
        chrome_changed.emit(_gogo_previous_chrome, _gogo_incoming_chrome)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"chrome_changed")
        return chrome

func build_view() -> Element:
    return _GogoFactories_0._gogo_build_0(
        ("U03 / inside-only scrollbars / revision "+str(self.revision)),
        (self.thickness),
        (preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.chrome)),
        (preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "draft", func(_gogo_source, _gogo_edit: String): _gogo_source.draft = _gogo_edit, "self.draft", (self.draft) if self != null else null, TYPE_STRING))
    )

const _GOGO_RENDER_FUNCTIONS_caa4e942d97250c3 = {
"ordinary": [],
"reactive": ["build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_caa4e942d97250c3 = {
"chrome": "Dictionary",
"draft": "String",
"revision": "int",
"thickness": "Variant"
}

const _GogoProject_0 = preload("ScrollPanel.gd")

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(
        _gogo_value_0: String,
        _gogo_value_1: Variant,
        _gogo_value_2: Variant,
        _gogo_value_3: Variant
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_0}, {}, [], "examples/scrollbars/Scrollbars.gogo:14:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(_GogoProject_0, {"name": "Wrapped"}, {}, [], "examples/scrollbars/Scrollbars.gogo:16:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(_GogoImport_0, {"name": "Editor", "width": "100%", "value": _gogo_value_3}, {}, [], "examples/scrollbars/Scrollbars.gogo:17:13", null, false)
        _gogo_element_4.origins["value"] = "examples/scrollbars/Scrollbars.gogo:17:47"
        _gogo_element_4.resolve_bindings()
        var _gogo_element_7 := _GogoElement_0.new(Text, {"text": "Nested independent gutter"}, {}, [], "examples/scrollbars/Scrollbars.gogo:19:50", null, false)
        _gogo_element_7.resolve_bindings()
        var _gogo_element_6 := _GogoElement_0.new(Box, {"width": "100%", "height": "300px"}, {}, [_gogo_element_7], "examples/scrollbars/Scrollbars.gogo:19:17", null, false)
        _gogo_element_6.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(Box, {"name": "Nested", "width": "100%", "height": "100px", "vertical_scroll": true, "background_color": "#484848"}, {}, [_gogo_element_6], "examples/scrollbars/Scrollbars.gogo:18:13", null, false)
        _gogo_element_5.resolve_bindings()
        var _gogo_element_9 := _GogoElement_0.new(Text, {"text": "Wheel, Shift-wheel, track click and native thumb drag"}, {}, [], "examples/scrollbars/Scrollbars.gogo:21:74", null, false)
        _gogo_element_9.resolve_bindings()
        var _gogo_element_8 := _GogoElement_0.new(Box, {"width": "600px", "height": "500px", "background_color": "#537666"}, {}, [_gogo_element_9], "examples/scrollbars/Scrollbars.gogo:21:13", null, false)
        _gogo_element_8.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(Box, {}, {}, [_gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_8], "examples/scrollbars/Scrollbars.gogo:15:9", null, false)
        _gogo_element_2.expand([["name", "Body", "examples/scrollbars/Scrollbars.gogo:15:14"], ["direction", "column", "examples/scrollbars/Scrollbars.gogo:15:26"], ["width", "400px", "examples/scrollbars/Scrollbars.gogo:15:45"], ["height", "300px", "examples/scrollbars/Scrollbars.gogo:15:59"], ["vertical_scroll", true, "examples/scrollbars/Scrollbars.gogo:15:74"], ["horizontal_scroll", true, "examples/scrollbars/Scrollbars.gogo:15:90"], ["scrollbar_size", _gogo_value_1, "examples/scrollbars/Scrollbars.gogo:15:108"], [null, _gogo_value_2, "examples/scrollbars/Scrollbars.gogo:15:140"], ["background_color", "#383838", "examples/scrollbars/Scrollbars.gogo:15:157"]])
        _gogo_element_2.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "padding": "20px", "direction": "column", "gap": "12px", "background_color": "#202020"}, {}, [_gogo_element_1, _gogo_element_2], "examples/scrollbars/Scrollbars.gogo:13:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
