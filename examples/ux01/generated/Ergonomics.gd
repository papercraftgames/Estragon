extends Node2D
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Entry2D = preload("../../../addons/estragon/runtime/node/estragon_2d.gd")
const VBox = preload("../../../addons/estragon/runtime/node/vbox.gd")
const HBox = preload("../../../addons/estragon/runtime/node/hbox.gd")
const Text = preload("../../../addons/estragon/runtime/node/text.gd")
const UiButton = preload("../../../addons/estragon/runtime/node/button.gd")
signal username_changed(previous: String, value: String)
var username: String = "é 🌱":
	set(_gogo_incoming_username):
		if is_same(username, _gogo_incoming_username): return
		var _gogo_previous_username: String = username
		username = _gogo_incoming_username
		username_changed.emit(_gogo_previous_username, _gogo_incoming_username)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"username_changed")
		return username

signal label_changed(previous: String, value: String)
var label: String = "Click Me":
	set(_gogo_incoming_label):
		if is_same(label, _gogo_incoming_label): return
		var _gogo_previous_label: String = label
		label = _gogo_incoming_label
		label_changed.emit(_gogo_previous_label, _gogo_incoming_label)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"label_changed")
		return label

signal extra_changed(previous: Dictionary, value: Dictionary)
var extra: Dictionary = {}:
	set(_gogo_incoming_extra):
		if is_same(extra, _gogo_incoming_extra): return
		var _gogo_previous_extra: Dictionary = extra
		extra = _gogo_incoming_extra
		extra_changed.emit(_gogo_previous_extra, _gogo_incoming_extra)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"extra_changed")
		return extra

signal bad_text_changed(previous: bool, value: bool)
var bad_text: bool = false:
	set(_gogo_incoming_bad_text):
		if is_same(bad_text, _gogo_incoming_bad_text): return
		var _gogo_previous_bad_text: bool = bad_text
		bad_text = _gogo_incoming_bad_text
		bad_text_changed.emit(_gogo_previous_bad_text, _gogo_incoming_bad_text)
	get:
		preload("../../../addons/estragon/runtime/composition/state.tres").observe(self, &"bad_text_changed")
		return bad_text

var evaluations: int = 0
func body_value() -> Variant:
	evaluations += 1
	return 42 if self.bad_text else "Strict"
var clicks: int = 0
func pressed(): clicks += 1
func build_view() -> Element:
	return _GogoFactories_0._gogo_build_0(
		(self.username),
		(self.username),
		(self.label),
		(self.username),
		(body_value()),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"wrap":false})),
		(pressed),
		(self.label),
		(pressed),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot({"wrap":false})),
		(preload("../../../addons/estragon/runtime/composition/element.gd").snapshot(self.extra))
	)


func _notification(_gogo_what: int) -> void:
	preload("../../../addons/estragon/runtime/composition/state.tres").lifecycle(self, _gogo_what)


class _GogoFactories_0:
	const _GogoElement_0 = preload("../../../addons/estragon/runtime/composition/element.gd")


	static func _gogo_build_0(
		_gogo_value_0: Variant,
		_gogo_value_1: Variant,
		_gogo_value_2: Variant,
		_gogo_value_3: Variant,
		_gogo_value_4: Variant,
		_gogo_value_5: Variant,
		_gogo_value_6: Callable,
		_gogo_value_7: Variant,
		_gogo_value_8: Callable,
		_gogo_value_9: Variant,
		_gogo_value_10: Variant
	) -> _GogoElement_0:
		var _gogo_element_2 := _GogoElement_0.new(Text, {"name": "Greeting"}, {}, [], "examples/ux01/Ergonomics.gogo:21:4", null, false)
		_gogo_element_2.set_text_body([["Hello ", "examples/ux01/Ergonomics.gogo:21:26"], [_gogo_value_0, "examples/ux01/Ergonomics.gogo:21:32"], ["!", "examples/ux01/Ergonomics.gogo:21:47"]])
		var _gogo_element_3 := _GogoElement_0.new(Text, {"name": "Quote"}, {}, [], "examples/ux01/Ergonomics.gogo:22:4", null, false)
		_gogo_element_3.set_text_body([["I'm \"native\", é 🌱.", "examples/ux01/Ergonomics.gogo:22:23"]])
		var _gogo_element_4 := _GogoElement_0.new(Text, {"name": "Multiline"}, {}, [], "examples/ux01/Ergonomics.gogo:23:4", null, false)
		_gogo_element_4.set_text_body([["One word another line", "examples/ux01/Ergonomics.gogo:23:27"]])
		var _gogo_element_5 := _GogoElement_0.new(Text, {"name": "Boundaries"}, {}, [], "examples/ux01/Ergonomics.gogo:27:4", null, false)
		_gogo_element_5.set_text_body([["Hello ", "examples/ux01/Ergonomics.gogo:27:28"], [_gogo_value_1, "examples/ux01/Ergonomics.gogo:29:5"], [" world", "examples/ux01/Ergonomics.gogo:29:20"]])
		var _gogo_element_6 := _GogoElement_0.new(Text, {"name": "Expressions"}, {}, [], "examples/ux01/Ergonomics.gogo:32:4", null, false)
		_gogo_element_6.set_text_body([[_gogo_value_2, "examples/ux01/Ergonomics.gogo:32:29"], [" ", "examples/ux01/Ergonomics.gogo:32:41"], [_gogo_value_3, "examples/ux01/Ergonomics.gogo:33:5"]])
		var _gogo_element_7 := _GogoElement_0.new(Text, {"name": "Empty"}, {}, [], "examples/ux01/Ergonomics.gogo:34:4", null, false)
		var _gogo_element_8 := _GogoElement_0.new(Text, {"name": "Strict"}, {}, [], "examples/ux01/Ergonomics.gogo:35:4", null, false)
		_gogo_element_8.set_text_body([[_gogo_value_4, "examples/ux01/Ergonomics.gogo:35:24"]])
		var _gogo_element_10 := _GogoElement_0.new("Button", {"name": "Native"}, {"pressed": _gogo_value_6}, [], "examples/ux01/Ergonomics.gogo:37:5", null, false)
		_gogo_element_10.set_text_body([[_gogo_value_7, "examples/ux01/Ergonomics.gogo:37:45"]])
		var _gogo_element_11 := _GogoElement_0.new(UiButton, {"name": "Custom"}, {"pressed": _gogo_value_8}, [], "examples/ux01/Ergonomics.gogo:38:5", null, false)
		_gogo_element_11.set_text_body([["Also click me", "examples/ux01/Ergonomics.gogo:38:47"]])
		var _gogo_element_12 := _GogoElement_0.new(UiButton, {"name": "Disabled", "disabled": true}, {}, [], "examples/ux01/Ergonomics.gogo:39:5", null, false)
		_gogo_element_12.set_text_body([["Disabled", "examples/ux01/Ergonomics.gogo:39:40"]])
		var _gogo_element_9 := _GogoElement_0.new(HBox, {}, {}, [_gogo_element_10, _gogo_element_11, _gogo_element_12], "examples/ux01/Ergonomics.gogo:36:4", null, false)
		_gogo_element_9.expand([["name", "Wrapped", "examples/ux01/Ergonomics.gogo:36:10"], [null, _gogo_value_5, "examples/ux01/Ergonomics.gogo:36:25"], ["wrap", true, "examples/ux01/Ergonomics.gogo:36:45"]])
		var _gogo_element_13 := _GogoElement_0.new(HBox, {}, {}, [], "examples/ux01/Ergonomics.gogo:41:4", null, false)
		_gogo_element_13.expand([["name", "Override", "examples/ux01/Ergonomics.gogo:41:10"], ["wrap", true, "examples/ux01/Ergonomics.gogo:41:26"], [null, _gogo_value_9, "examples/ux01/Ergonomics.gogo:41:31"]])
		var _gogo_element_14 := _GogoElement_0.new(Text, {}, {}, [], "examples/ux01/Ergonomics.gogo:42:4", null, false)
		_gogo_element_14.expand([["name", "Spread", "examples/ux01/Ergonomics.gogo:42:10"], [null, _gogo_value_10, "examples/ux01/Ergonomics.gogo:42:24"]])
		_gogo_element_14.set_text_body([["Body", "examples/ux01/Ergonomics.gogo:42:40"]])
		var _gogo_element_1 := _GogoElement_0.new(VBox, {"width": "100%", "gap": "12px"}, {}, [_gogo_element_2, _gogo_element_3, _gogo_element_4, _gogo_element_5, _gogo_element_6, _gogo_element_7, _gogo_element_8, _gogo_element_9, _gogo_element_13, _gogo_element_14], "examples/ux01/Ergonomics.gogo:20:3", null, false)
		var _gogo_element_0 := _GogoElement_0.new(Entry2D, {"width": "100%", "height": "100%"}, {}, [_gogo_element_1], "examples/ux01/Ergonomics.gogo:19:9", null, false)
		return _gogo_element_0
