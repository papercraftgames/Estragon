extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const _GogoImport_0 = preload("../../../addons/estragon/runtime/node/button.gd")
const Toggle = preload("../../../addons/estragon/runtime/node/toggle.gd")
const NativeButton = preload("../../godot_button.gd")
const TextDelegate = preload("../TextDelegate.gd")
signal caption_changed(previous: String, value: String)
var caption: String = "Tab / Shift-Tab, Space / Enter, Escape":
    set(_gogo_incoming_caption):
        if is_same(caption, _gogo_incoming_caption): return
        var _gogo_previous_caption: String = caption
        caption = _gogo_incoming_caption
        caption_changed.emit(_gogo_previous_caption, _gogo_incoming_caption)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"caption_changed")
        return caption

signal show_first_changed(previous: bool, value: bool)
var show_first: bool = true:
    set(_gogo_incoming_show_first):
        if is_same(show_first, _gogo_incoming_show_first): return
        var _gogo_previous_show_first: bool = show_first
        show_first = _gogo_incoming_show_first
        show_first_changed.emit(_gogo_previous_show_first, _gogo_incoming_show_first)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"show_first_changed")
        return show_first

signal reversed_changed(previous: bool, value: bool)
var reversed: bool = false:
    set(_gogo_incoming_reversed):
        if is_same(reversed, _gogo_incoming_reversed): return
        var _gogo_previous_reversed: bool = reversed
        reversed = _gogo_incoming_reversed
        reversed_changed.emit(_gogo_previous_reversed, _gogo_incoming_reversed)
    get:
        preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"reversed_changed")
        return reversed

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

var clicks: int = 0
var native_clicks: int = 0
func clicked(): clicks += 1
func native_clicked(): native_clicks += 1
func first() -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/focus/Focus.gogo:907", "first", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_0((self.clicked)))
func toggle() -> Element:
    return preload("../../../addons/estragon/runtime/composition/state.tres").in_slot("examples/focus/Focus.gogo:1040", "toggle", func(_gogo_mount_key): return _GogoFactories_0._gogo_build_1((preload("../../../addons/estragon/runtime/composition/binding.gd").new(self, func(_gogo_root): return _gogo_root if _gogo_root != null else null, "selected", func(_gogo_source, _gogo_edit: bool): _gogo_source.selected = _gogo_edit, "self.selected"))))
func build_view() -> Element:
    return _GogoFactories_0._gogo_build_2(
        (self.caption),
        (22),
        (([(preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/focus/Focus.gogo:1402", toggle, [], func(): toggle()) as Element),(preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/focus/Focus.gogo:1411", first, [], func(): first()) as Element)] if self.reversed else [(preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/focus/Focus.gogo:1443", first, [], func(): first()) as Element),(preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/focus/Focus.gogo:1451", toggle, [], func(): toggle()) as Element)]) if self.show_first else [(preload("../../../addons/estragon/runtime/composition/state.tres").call_at("examples/focus/Focus.gogo:1487", toggle, [], func(): toggle()) as Element)]),
        (Vector2(300,44)),
        (native_clicked),
        (18)
    )

const _GOGO_RENDER_FUNCTIONS_42c469322dc6e198 = {
"ordinary": ["clicked", "native_clicked"],
"reactive": ["first", "toggle", "build_view"]
}
const _GOGO_BINDABLE_PROPERTIES_42c469322dc6e198 = {
"caption": "String",
"reversed": "bool",
"selected": "bool",
"show_first": "bool"
}

func _notification(_gogo_what: int) -> void:
    preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
    const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


    static func _gogo_build_0(_gogo_value_0: Callable) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(_GogoImport_0, {"name": "First", "text": "Estragon Button", "width": "300px"}, {"pressed": _gogo_value_0}, [], "examples/focus/Focus.gogo:19:12", "first", true)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_1(_gogo_value_0: Variant) -> _GogoElement_0:
        var _gogo_element_0 := _GogoElement_0.new(Toggle, {"name": "Toggle", "text": "Estragon Toggle", "width": "300px", "value": _gogo_value_0}, {}, [], "examples/focus/Focus.gogo:21:12", "toggle", true)
        _gogo_element_0.origins["value"] = "examples/focus/Focus.gogo:21:84"
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0


    static func _gogo_build_2(
        _gogo_value_0: String,
        _gogo_value_1: int,
        _gogo_value_2: Variant,
        _gogo_value_3: Vector2,
        _gogo_value_4: Callable,
        _gogo_value_5: int
    ) -> _GogoElement_0:
        var _gogo_element_1 := _GogoElement_0.new(Text, {"text": _gogo_value_0, "font_size": _gogo_value_1}, {}, [], "examples/focus/Focus.gogo:24:9", null, false)
        _gogo_element_1.resolve_bindings()
        var _gogo_element_3 := _GogoElement_0.new(_GogoImport_0, {"name": "Disabled", "text": "Disabled — skipped by Tab", "disabled": true, "width": "300px"}, {}, [], "examples/focus/Focus.gogo:27:13", null, false)
        _gogo_element_3.resolve_bindings()
        var _gogo_element_4 := _GogoElement_0.new(NativeButton, {"name": "Native", "text": "Godot native Button", "custom_minimum_size": _gogo_value_3}, {"pressed": _gogo_value_4}, [], "examples/focus/Focus.gogo:28:13", null, false)
        _gogo_element_4.resolve_bindings()
        var _gogo_element_5 := _GogoElement_0.new(TextDelegate, {"name": "Prototype", "width": "360px", "height": "44px"}, {}, [], "examples/focus/Focus.gogo:29:13", null, false)
        _gogo_element_5.resolve_bindings()
        var _gogo_element_2 := _GogoElement_0.new(VBox, {"name": "Actions", "gap": "8px"}, {}, [_gogo_value_2, _gogo_element_3, _gogo_element_4, _gogo_element_5], "examples/focus/Focus.gogo:25:9", null, false)
        _gogo_element_2.resolve_bindings()
        var _gogo_element_6 := _GogoElement_0.new(Text, {"text": "The text delegate is a bounded prototype, not Input.", "font_size": _gogo_value_5}, {}, [], "examples/focus/Focus.gogo:31:9", null, false)
        _gogo_element_6.resolve_bindings()
        var _gogo_element_0 := _GogoElement_0.new(Entry, {"name": "UI", "width": "100%", "height": "100%", "direction": "column", "gap": "12px", "padding": "20px", "background_color": "#172332"}, {}, [_gogo_element_1, _gogo_element_2, _gogo_element_6], "examples/focus/Focus.gogo:23:12", null, false)
        _gogo_element_0.resolve_bindings()
        return _gogo_element_0
